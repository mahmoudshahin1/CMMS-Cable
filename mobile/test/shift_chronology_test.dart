import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/core/chronology/plant_shift.dart';
import 'package:orning_and_evening_remembrances/core/chronology/event_chronology.dart';
import 'package:orning_and_evening_remembrances/features/downtime/domain/models/downtime_log_model.dart';
import 'package:orning_and_evening_remembrances/features/downtime/domain/enums/downtime_category.dart';

void main() {
  group('Factory Shift Allocation & Minute-Precise Boundaries Tests', () {
    test('Shift 1 (Morning): 07:30 to 15:29 belongs to Shift 1 and same production date', () {
      final t1 = DateTime(2026, 9, 5, 7, 30, 0);
      final c1 = EventChronology.fromDateTime(t1);
      expect(c1.activeShift, equals(PlantShift.shift1_Morning));
      expect(c1.productionDate, equals('2026-09-05'));

      final t2 = DateTime(2026, 9, 5, 15, 29, 59);
      final c2 = EventChronology.fromDateTime(t2);
      expect(c2.activeShift, equals(PlantShift.shift1_Morning));
      expect(c2.productionDate, equals('2026-09-05'));
    });

    test('Shift 2 (Evening): 15:30 to 22:59 belongs to Shift 2 and same production date', () {
      final t1 = DateTime(2026, 9, 5, 15, 30, 0);
      final c1 = EventChronology.fromDateTime(t1);
      expect(c1.activeShift, equals(PlantShift.shift2_Evening));
      expect(c1.productionDate, equals('2026-09-05'));

      final t2 = DateTime(2026, 9, 5, 22, 59, 59);
      final c2 = EventChronology.fromDateTime(t2);
      expect(c2.activeShift, equals(PlantShift.shift2_Evening));
      expect(c2.productionDate, equals('2026-09-05'));
    });

    test('Shift 3 (Night Pre-Midnight): 23:00 to 23:59 belongs to Shift 3 and same production date', () {
      final t1 = DateTime(2026, 9, 5, 23, 0, 0);
      final c1 = EventChronology.fromDateTime(t1);
      expect(c1.activeShift, equals(PlantShift.shift3_Night));
      expect(c1.productionDate, equals('2026-09-05'));

      final t2 = DateTime(2026, 9, 5, 23, 59, 59);
      final c2 = EventChronology.fromDateTime(t2);
      expect(c2.activeShift, equals(PlantShift.shift3_Night));
      expect(c2.productionDate, equals('2026-09-05'));
    });

    test('Shift 3 (Night Post-Midnight up to 07:29): belongs to Shift 3 and YESTERDAY production date', () {
      // 00:00:00 on 2026-09-06 belongs to Shift 3 of 2026-09-05
      final t1 = DateTime(2026, 9, 6, 0, 0, 0);
      final c1 = EventChronology.fromDateTime(t1);
      expect(c1.activeShift, equals(PlantShift.shift3_Night));
      expect(c1.productionDate, equals('2026-09-05'));

      // 04:30:00 on 2026-09-06 belongs to Shift 3 of 2026-09-05
      final t2 = DateTime(2026, 9, 6, 4, 30, 0);
      final c2 = EventChronology.fromDateTime(t2);
      expect(c2.activeShift, equals(PlantShift.shift3_Night));
      expect(c2.productionDate, equals('2026-09-05'));

      // 07:29:59 on 2026-09-06 belongs to Shift 3 of 2026-09-05
      final t3 = DateTime(2026, 9, 6, 7, 29, 59);
      final c3 = EventChronology.fromDateTime(t3);
      expect(c3.activeShift, equals(PlantShift.shift3_Night));
      expect(c3.productionDate, equals('2026-09-05'));

      // 07:30:00 on 2026-09-06 switches to Shift 1 of 2026-09-06!
      final t4 = DateTime(2026, 9, 6, 7, 30, 0);
      final c4 = EventChronology.fromDateTime(t4);
      expect(c4.activeShift, equals(PlantShift.shift1_Morning));
      expect(c4.productionDate, equals('2026-09-06'));
    });

    test('ShiftAllocation class accurately maps properties and localized names', () {
      final alloc = ShiftAllocation.fromDateTime(DateTime(2026, 9, 5, 10, 0));
      expect(alloc.shift, equals(PlantShift.shift1_Morning));
      expect(alloc.shiftNameAr, contains('الأولى'));
      expect(alloc.shiftNameEn, contains('Shift 1'));
      expect(alloc.productionDate, equals('2026-09-05'));
    });
  });

  group('Cross-Shift Breakdown & OEE Downtime Minute Splitter Tests', () {
    test('Cross-Shift detection flags when event spans across shift boundaries', () {
      final origin = EventChronology.fromDateTime(DateTime(2026, 9, 5, 14, 0, 0)); // Shift 1
      final nextShift = EventChronology.fromDateTime(DateTime(2026, 9, 5, 16, 0, 0)); // Shift 2

      expect(nextShift.isCrossShiftFrom(origin), isTrue);

      final sameShift = EventChronology.fromDateTime(DateTime(2026, 9, 5, 15, 0, 0)); // Shift 1
      expect(sameShift.isCrossShiftFrom(origin), isFalse);
    });

    test('DowntimeLogModel isCrossShift getter recognizes multi-shift carryover', () {
      final start = DateTime(2026, 9, 5, 15, 0, 0); // Shift 1 (15:00 < 15:30)
      final end = DateTime(2026, 9, 5, 16, 30, 0);   // Shift 2 (16:30 >= 15:30)

      final log = DowntimeLogModel(
        id: 'dt-01',
        machineId: 'EX01',
        reportedById: 'OP-104',
        startTime: start,
        endTime: end,
        category: DowntimeCategory.mechanicalBreakdown,
        reason: 'Capstan gear jam',
        startChronology: EventChronology.fromDateTime(start),
        endChronology: EventChronology.fromDateTime(end),
      );

      expect(log.isCrossShift, isTrue);
      expect(log.originShift, equals(PlantShift.shift1_Morning));
      expect(log.currentOrEndShift, equals(PlantShift.shift2_Evening));
    });

    test('computeDowntimeMinutesPerShift splits downtime minutes correctly for OEE accounting', () {
      // 14:30 to 16:30 = 120 minutes total
      // 14:30 to 15:30 = 60 minutes in Shift 1
      // 15:30 to 16:30 = 60 minutes in Shift 2
      final start = DateTime(2026, 9, 5, 14, 30, 0);
      final end = DateTime(2026, 9, 5, 16, 30, 0);

      final minutesPerShift = EventChronology.computeDowntimeMinutesPerShift(
        start.toUtc(),
        end.toUtc(),
      );

      expect(minutesPerShift[PlantShift.shift1_Morning], equals(60));
      expect(minutesPerShift[PlantShift.shift2_Evening], equals(60));
      expect(minutesPerShift[PlantShift.shift3_Night], equals(0));
    });

    test('computeDowntimeMinutesPerShift across 3 shifts assigns exact minutes', () {
      // From 14:30 (Shift 1) to 23:30 (Shift 3):
      // Shift 1 (14:30 to 15:30) = 60m
      // Shift 2 (15:30 to 23:00) = 450m (7.5h)
      // Shift 3 (23:00 to 23:30) = 30m
      final start = DateTime(2026, 9, 5, 14, 30, 0);
      final end = DateTime(2026, 9, 5, 23, 30, 0);

      final minutesPerShift = EventChronology.computeDowntimeMinutesPerShift(
        start.toUtc(),
        end.toUtc(),
      );

      expect(minutesPerShift[PlantShift.shift1_Morning], equals(60));
      expect(minutesPerShift[PlantShift.shift2_Evening], equals(450));
      expect(minutesPerShift[PlantShift.shift3_Night], equals(30));
    });
  });
}
