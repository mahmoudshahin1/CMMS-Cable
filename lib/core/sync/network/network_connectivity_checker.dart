import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Contract for checking network connectivity and online status.
abstract class NetworkConnectivityChecker {
  Future<bool> get isOnline;
  Stream<bool> get onConnectivityChanged;
  void dispose();
}

/// Robust connectivity checker using DNS lookups with fallback and polling.
class DefaultNetworkConnectivityChecker implements NetworkConnectivityChecker {
  final _controller = StreamController<bool>.broadcast();
  Timer? _pollingTimer;
  bool _lastKnownStatus = true;

  DefaultNetworkConnectivityChecker({
    Duration checkInterval = const Duration(seconds: 15),
  }) {
    // Initial check
    checkOnline();
    _pollingTimer = Timer.periodic(checkInterval, (_) => checkOnline());
  }

  @override
  Future<bool> get isOnline async => checkOnline();

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<bool> checkOnline() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 4));
      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateStatus(connected);
      return connected;
    } on SocketException catch (_) {
      _updateStatus(false);
      return false;
    } on TimeoutException catch (_) {
      _updateStatus(false);
      return false;
    } catch (e) {
      debugPrint('⚠️ NetworkConnectivityChecker unexpected error: $e');
      _updateStatus(false);
      return false;
    }
  }

  void _updateStatus(bool current) {
    if (current != _lastKnownStatus) {
      _lastKnownStatus = current;
      _controller.add(current);
      debugPrint('🌐 Network connectivity changed: online=$current');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.close();
  }
}
