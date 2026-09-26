import 'package:hive/hive.dart';

@HiveType(typeId: 3)
enum MachineStatus {
  @HiveField(0)
  running,

  @HiveField(1)
  downtimeProcess,

  @HiveField(2)
  downtimeMaintenance,

  @HiveField(3)
  preventiveMaintenance,

  @HiveField(4)
  idle,

  @HiveField(5)
  offline,

  @HiveField(6)
  underRepair,
}

extension MachineStatusExtension on MachineStatus {
  String get displayName {
    switch (this) {
      case MachineStatus.running:
        return 'Running';
      case MachineStatus.downtimeProcess:
        return 'Process Downtime';
      case MachineStatus.downtimeMaintenance:
        return 'Maintenance Downtime';
      case MachineStatus.preventiveMaintenance:
        return 'Preventive Maintenance';
      case MachineStatus.idle:
        return 'Idle';
      case MachineStatus.offline:
        return 'Offline';
      case MachineStatus.underRepair:
        return 'Under Repair';
    }
  }

  bool get isDowntime =>
      this == MachineStatus.downtimeProcess ||
      this == MachineStatus.downtimeMaintenance ||
      this == MachineStatus.preventiveMaintenance ||
      this == MachineStatus.underRepair;
}
