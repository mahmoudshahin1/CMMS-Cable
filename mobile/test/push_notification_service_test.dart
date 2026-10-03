import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/core/notifications/push_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushNotificationService & Payload Tests', () {
    test('PushNotificationService singleton instance is identical across accesses', () {
      final instance1 = PushNotificationService.instance;
      final instance2 = PushNotificationService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('Valid payload parsing for work_order_assigned', () {
      const rawPayload = '{"type":"work_order_assigned","work_order_id":"wo-1234-uuid"}';
      final decoded = jsonDecode(rawPayload) as Map<String, dynamic>;

      expect(decoded['type'], equals('work_order_assigned'));
      expect(decoded['work_order_id'], equals('wo-1234-uuid'));
    });

    test('Valid payload parsing for work_order_opened', () {
      const rawPayload = '{"type":"work_order_opened","work_order_id":"wo-5678-uuid"}';
      final decoded = jsonDecode(rawPayload) as Map<String, dynamic>;

      expect(decoded['type'], equals('work_order_opened'));
      expect(decoded['work_order_id'], equals('wo-5678-uuid'));
    });

    test('Payload handles missing or malformed fields safely', () {
      const malformedPayload = '{"title":"Alert","body":"Test"}';
      final decoded = jsonDecode(malformedPayload) as Map<String, dynamic>;

      expect(decoded['work_order_id'], isNull);
      expect(decoded['type'], isNull);
    });
  });
}
