import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/core/sync/network/network_connectivity_checker.dart';

void main() {
  group('NetworkConnectivityChecker Unit Tests', () {
    test('DefaultNetworkConnectivityChecker instantiates and disposes cleanly', () {
      final checker = DefaultNetworkConnectivityChecker(
        checkInterval: const Duration(seconds: 60),
      );

      expect(checker, isA<NetworkConnectivityChecker>());
      expect(checker.onConnectivityChanged, isNotNull);

      // Verify dispose can be called without exception
      expect(() => checker.dispose(), returnsNormally);
    });

    test('isOnline getter returns a boolean Future', () async {
      final checker = DefaultNetworkConnectivityChecker(
        checkInterval: const Duration(seconds: 60),
      );

      final status = await checker.isOnline;
      expect(status, isA<bool>());

      checker.dispose();
    });
  });
}
