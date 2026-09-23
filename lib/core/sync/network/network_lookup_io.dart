import 'dart:async';
import 'dart:io';

/// Native (Android/iOS/Desktop) implementation of network connectivity check using DNS lookup.
Future<bool> checkPlatformNetwork() async {
  try {
    final result = await InternetAddress.lookup('example.com')
        .timeout(const Duration(seconds: 4));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  } on TimeoutException catch (_) {
    return false;
  } catch (_) {
    return false;
  }
}
