import '../../../../core/chronology/event_chronology.dart';
import '../../../../core/chronology/plant_shift.dart';
import '../enums/work_order_status.dart';
import 'work_order_model.dart';

/// Extension providing plant shift chronology and cross-shift detection for [WorkOrderModel].
extension WorkOrderChronologyExtension on WorkOrderModel {
  EventChronology get effectiveChronology =>
      chronology ?? EventChronology.fromDateTime(createdAt);

  bool get isCrossShift {
    final origin = effectiveChronology;
    for (final log in activityLogs) {
      if (log.effectiveChronology.isCrossShiftFrom(origin)) {
        return true;
      }
    }
    if (status != WorkOrderStatus.completed &&
        status != WorkOrderStatus.verified &&
        status != WorkOrderStatus.verifiedClosed) {
      return EventChronology.now().isCrossShiftFrom(origin);
    }
    return false;
  }

  PlantShift get originShift => effectiveChronology.activeShift;

  PlantShift get currentOrEndShift {
    if (activityLogs.isNotEmpty) {
      return activityLogs.last.effectiveChronology.activeShift;
    }
    return effectiveChronology.activeShift;
  }
}

