import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'core/config/supabase_config.dart';
import 'core/database/hive_service.dart';
import 'core/di/service_locator.dart';
import 'core/notifications/push_notification_service.dart';
import 'features/work_orders/domain/repositories/work_order_repository.dart';
import 'app.dart';

/// Top-level FCM background message handler.
///
/// Must be a top-level function (not a class method) — this is a hard
/// requirement from the firebase_messaging plugin.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FCM automatically displays the system notification when the app is in
  // background or terminated. No additional handling is needed here.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase safely
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    }
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.projectUrl,
      publishableKey: SupabaseConfig.publishableKey,
    );
  } catch (e) {
    debugPrint('⚠️ Supabase initialization failed: $e');
    // App can still run — auth operations will fail gracefully
  }

  // Initialize Hive Storage & Register Adapters
  try {
    await HiveService.init();
  } catch (e) {
    debugPrint('⚠️ HiveService initialization failed: $e');
  }

  // Initialize Dependency Injection
  await setupServiceLocator();

  // Initialize Push Notification Service
  // (navigator key is a global from app.dart; actual navigation is deferred
  //  until the widget tree is mounted and auth state is confirmed)
  try {
    await PushNotificationService.instance.init(
      navigatorKey: appNavigatorKey,
      workOrderRepository: getIt<WorkOrderRepository>(),
    );
  } catch (e) {
    debugPrint('⚠️ PushNotificationService initialization failed: $e');
  }

  runApp(const CableCmmsApp());
}
