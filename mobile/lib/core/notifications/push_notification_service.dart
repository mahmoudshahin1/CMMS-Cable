import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/work_orders/domain/repositories/work_order_repository.dart';
import '../../features/work_orders/presentation/screens/work_order_detail_screen.dart';

/// Centralized push notification service for Firebase Cloud Messaging.
///
/// Responsibilities:
/// - Register / unregister the device FCM token in Supabase `device_tokens`.
/// - Display foreground notifications via [flutter_local_notifications].
/// - Navigate to [WorkOrderDetailScreen] on notification tap (foreground,
///   background, and terminated states).
///
/// Usage:
/// ```dart
/// await PushNotificationService.instance.init(
///   navigatorKey: appNavigatorKey,
///   workOrderRepository: getIt<WorkOrderRepository>(),
/// );
/// ```
class PushNotificationService {
  PushNotificationService._();

  /// Singleton instance.
  static final PushNotificationService instance = PushNotificationService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  WorkOrderRepository? _workOrderRepository;

  bool _initialized = false;

  /// Cached FCM token obtained during registration.
  String? _registeredToken;

  /// Stores a notification that launched the app from terminated state,
  /// to be processed once the navigator and auth are ready.
  RemoteMessage? _pendingInitialMessage;

  // ──────────────────────────────────────────────────────────────────
  // Android Notification Channel
  // ──────────────────────────────────────────────────────────────────

  /// Android notification channel for work order alerts.
  static const _androidChannel = AndroidNotificationChannel(
    'work_order_alerts', // must match AndroidManifest meta-data value
    'Work Order Alerts',
    description:
        'Notifications for work order assignments and new fault reports',
    importance: Importance.high,
  );

  // ──────────────────────────────────────────────────────────────────
  // Initialization
  // ──────────────────────────────────────────────────────────────────

  /// Initialize the notification service.
  ///
  /// Call once in `main()` after `Firebase.initializeApp()` and
  /// `setupServiceLocator()`.
  Future<void> init({
    required GlobalKey<NavigatorState> navigatorKey,
    required WorkOrderRepository workOrderRepository,
  }) async {
    if (_initialized) return;
    _navigatorKey = navigatorKey;
    _workOrderRepository = workOrderRepository;

    try {
      if (!kIsWeb) {
        // --- flutter_local_notifications setup ---
        const androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosSettings = DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onLocalNotificationTap,
        );

        // Create the Android notification channel (no-op if it already exists).
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_androidChannel);
      }

      // --- FCM listeners ---
      // Foreground: show local notification manually (FCM doesn't auto-display).
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Background → tap: user tapped a system notification while app was in
      // the background (not terminated).
      FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);

      // Terminated → tap: app was killed, user tapped the notification to
      // launch it. Store the message; navigation is deferred until the
      // navigator and auth are ready (see [processPendingInitialMessage]).
      if (!kIsWeb) {
        _pendingInitialMessage = await _messaging.getInitialMessage();
      }

      _initialized = true;
      debugPrint('🔔 PushNotificationService initialized');
    } catch (e) {
      debugPrint('⚠️ PushNotificationService.init error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Device Token Registration (tied to auth lifecycle)
  // ──────────────────────────────────────────────────────────────────

  /// Request notification permission, obtain the FCM token, and upsert it
  /// into the Supabase `device_tokens` table.
  ///
  /// Call after successful sign-in or session restore.
  Future<void> registerDevice(String userId) async {
    try {
      // Request permission (iOS shows a system prompt; Android 13+ too).
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('🔔 Notification permission denied by user');
        return;
      }

      // Get the current FCM token.
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('⚠️ FCM token is null');
        return;
      }

      _registeredToken = token;
      debugPrint('🔔 FCM token obtained: ${token.substring(0, 20)}...');

      // Upsert into Supabase.
      await _upsertToken(userId, token);

      // Listen for automatic token refreshes (e.g. after app reinstall,
      // or when the OS rotates the token).
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔔 FCM token refreshed');
        _registeredToken = newToken;
        _upsertToken(userId, newToken);
      });
    } catch (e) {
      debugPrint('⚠️ PushNotificationService.registerDevice error: $e');
    }
  }

  /// Remove the current device token from `device_tokens`.
  ///
  /// Call **before** `Supabase.signOut()` so the delete query still has
  /// a valid session.
  Future<void> unregisterDevice() async {
    final token = _registeredToken;
    _registeredToken = null;

    if (token == null) {
      // No token was ever obtained or registered (e.g. permission was denied).
      // Nothing to delete from Supabase.
      return;
    }

    try {
      await Supabase.instance.client
          .from('device_tokens')
          .delete()
          .eq('fcm_token', token);

      debugPrint('🔔 Device token removed from device_tokens');
    } catch (e) {
      debugPrint('⚠️ PushNotificationService.unregisterDevice error: $e');
    }
  }

  /// Process a notification that launched the app from a terminated state.
  ///
  /// Call once after the navigator is mounted and the auth state is
  /// confirmed (e.g. inside `AuthCubit` after emitting [Authenticated]).
  void processPendingInitialMessage() {
    if (_pendingInitialMessage != null) {
      final data = _pendingInitialMessage!.data;
      _pendingInitialMessage = null;
      // Wait one frame so the navigation stack is settled after auth
      // state change triggers a rebuild.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(data);
      });
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Internal Helpers
  // ──────────────────────────────────────────────────────────────────

  Future<void> _upsertToken(String userId, String token) async {
    try {
      final platformStr = kIsWeb
          ? 'web'
          : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');

      await Supabase.instance.client.from('device_tokens').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'platform': platformStr,
          'last_seen_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'fcm_token',
      );
      debugPrint('🔔 Device token upserted for user $userId');
    } catch (e) {
      debugPrint('⚠️ PushNotificationService._upsertToken error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Foreground Message Display
  // ──────────────────────────────────────────────────────────────────

  /// Display a local notification when a message arrives while the app
  /// is in the foreground (FCM doesn't auto-display in this case).
  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message received: ${message.messageId}');

    final notification = message.notification;
    if (notification == null) return;

    if (!kIsWeb) {
      _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Notification Tap Handling
  // ──────────────────────────────────────────────────────────────────

  /// Called when the user taps a **local** notification that was displayed
  /// in the foreground.
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _handleNotificationTap(data);
    } catch (e) {
      debugPrint('⚠️ Failed to parse notification payload: $e');
    }
  }

  /// Called when the user taps a **system** notification that arrived while
  /// the app was in the background (not terminated).
  void _onNotificationOpenedApp(RemoteMessage message) {
    _handleNotificationTap(message.data);
  }

  /// Central navigation handler for all notification taps.
  ///
  /// Expected data payload:
  /// ```json
  /// {
  ///   "type": "work_order_assigned" | "work_order_opened",
  ///   "work_order_id": "<uuid>"
  /// }
  /// ```
  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    final workOrderId = data['work_order_id'] as String?;

    if (workOrderId == null) return;
    if (type != 'work_order_assigned' && type != 'work_order_opened') return;

    debugPrint('🔔 Notification tap: type=$type, workOrderId=$workOrderId');

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('⚠️ Navigator not available for notification navigation');
      return;
    }

    try {
      // Attempt to fetch the work order by ID.
      final workOrder =
          await _workOrderRepository?.getWorkOrderById(workOrderId);

      if (workOrder != null) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => WorkOrderDetailScreen(workOrder: workOrder),
          ),
        );
      } else {
        debugPrint('⚠️ Work order $workOrderId not found');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to navigate to work order: $e');
    }
  }
}
