import 'package:hive/hive.dart';

@HiveType(typeId: 9)
enum WorkOrderStatus {
  @HiveField(0)
  open,

  @HiveField(1)
  assigned,

  @HiveField(2)
  inProgress,

  @HiveField(3)
  pendingParts,

  @HiveField(4)
  completed,

  @HiveField(5)
  verified,

  @HiveField(6)
  verifiedClosed;

  static const WorkOrderStatus pending = WorkOrderStatus.open;
  static const WorkOrderStatus closed = WorkOrderStatus.verifiedClosed;
}

extension WorkOrderStatusExtension on WorkOrderStatus {
  String get displayName {
    switch (this) {
      case WorkOrderStatus.open:
        return 'Pending / Open';
      case WorkOrderStatus.assigned:
        return 'Assigned';
      case WorkOrderStatus.inProgress:
        return 'In Progress';
      case WorkOrderStatus.pendingParts:
        return 'Pending Spare Parts';
      case WorkOrderStatus.completed:
        return 'Completed (Test Run Req.)';
      case WorkOrderStatus.verified:
        return 'Verified (Approval Req.)';
      case WorkOrderStatus.verifiedClosed:
        return 'Closed';
    }
  }

  String get displayNameAr {
    switch (this) {
      case WorkOrderStatus.open:
        return 'معلق / مفتوح';
      case WorkOrderStatus.assigned:
        return 'مسند';
      case WorkOrderStatus.inProgress:
        return 'قيد الإصلاح';
      case WorkOrderStatus.pendingParts:
        return 'بانتظار قطع الغيار';
      case WorkOrderStatus.completed:
        return 'مكتمل (بانتظار تجربة التشغيل)';
      case WorkOrderStatus.verified:
        return 'معتمد (بانتظار الاعتماد)';
      case WorkOrderStatus.verifiedClosed:
        return 'مغلق';
    }
  }

  String localizedName(bool isArabic) => isArabic ? displayNameAr : displayName;

  String get shortName {
    switch (this) {
      case WorkOrderStatus.open:
        return 'PENDING';
      case WorkOrderStatus.assigned:
        return 'ASSIGNED';
      case WorkOrderStatus.inProgress:
        return 'IN PROGRESS';
      case WorkOrderStatus.pendingParts:
        return 'PARTS WAIT';
      case WorkOrderStatus.completed:
        return 'COMPLETED';
      case WorkOrderStatus.verified:
        return 'VERIFIED';
      case WorkOrderStatus.verifiedClosed:
        return 'CLOSED';
    }
  }

  bool get isActive =>
      this == WorkOrderStatus.open ||
      this == WorkOrderStatus.assigned ||
      this == WorkOrderStatus.inProgress ||
      this == WorkOrderStatus.pendingParts ||
      this == WorkOrderStatus.completed ||
      this == WorkOrderStatus.verified;
}
