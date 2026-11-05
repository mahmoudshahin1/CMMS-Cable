import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/presentation/widgets/live_downtime_counter_widget.dart';

void main() {
  group('LiveDowntimeCounterWidget Tests', () {
    testWidgets('renders elapsed time correctly for active work order', (tester) async {
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2, minutes: 15));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveDowntimeCounterWidget(
              createdAt: twoHoursAgo,
              status: WorkOrderStatus.inProgress,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.textContaining('Down 2h 15m so far'), findsOneWidget);
    });

    testWidgets('hides widget for completed or closed work orders', (tester) async {
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveDowntimeCounterWidget(
              createdAt: twoHoursAgo,
              status: WorkOrderStatus.completed,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(LiveDowntimeCounterWidget), findsOneWidget);
      expect(find.textContaining('Down'), findsNothing);
    });

    testWidgets('renders banner style with full header label', (tester) async {
      final pastTime = DateTime.now().subtract(const Duration(hours: 1, minutes: 30));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveDowntimeCounterWidget(
              createdAt: pastTime,
              status: WorkOrderStatus.assigned,
              style: LiveDowntimeStyle.banner,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Total Machine Downtime Elapsed'), findsOneWidget);
      expect(find.textContaining('Down 1h 30m so far'), findsOneWidget);
    });
  });
}

