import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'plant_shift.dart';

@HiveType(typeId: 15)
class EventChronology extends Equatable {
  @HiveField(0)
  final DateTime recordedAtUtc;

  @HiveField(1)
  final String plantTimeFormatted; // e.g., "2026-09-05 09:14:22"

  @HiveField(2)
  final String productionDate; // e.g., "2026-09-05"

  @HiveField(3)
  final PlantShift activeShift;

  @HiveField(4)
  final bool isOfflineGenerated;

  @HiveField(5)
  final DateTime? syncedAtUtc;

  const EventChronology({
    required this.recordedAtUtc,
    required this.plantTimeFormatted,
    required this.productionDate,
    required this.activeShift,
    this.isOfflineGenerated = false,
    this.syncedAtUtc,
  });

  factory EventChronology.now({bool isOffline = false}) {
    final nowUtc = DateTime.now().toUtc();
    final localTime = nowUtc.toLocal();
    final allocation = ShiftAllocation.fromDateTime(localTime);

    return EventChronology(
      recordedAtUtc: nowUtc,
      plantTimeFormatted: formatToPlantTime(localTime),
      productionDate: allocation.productionDate,
      activeShift: allocation.shift,
      isOfflineGenerated: isOffline,
    );
  }

  factory EventChronology.fromDateTime(DateTime dateTime,
      {bool isOffline = false, DateTime? syncedAtUtc}) {
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    final localTime = utc.toLocal();
    final allocation = ShiftAllocation.fromDateTime(localTime);

    return EventChronology(
      recordedAtUtc: utc,
      plantTimeFormatted: formatToPlantTime(localTime),
      productionDate: allocation.productionDate,
      activeShift: allocation.shift,
      isOfflineGenerated: isOffline,
      syncedAtUtc: syncedAtUtc,
    );
  }

  String get productionDateFormatted => productionDate;
  DateTime get productionDateTime => DateTime.parse(productionDate);

  String get plantTimeOnlyFormatted {
    if (plantTimeFormatted.length >= 19) {
      return plantTimeFormatted.substring(11, 19);
    }
    return plantTimeFormatted;
  }

  String get utcTimeOnlyFormatted {
    final s = recordedAtUtc.toIso8601String();
    return s.length >= 19 ? '${s.substring(11, 19)}Z' : s;
  }

  static PlantShift calculateShift(DateTime localTime) {
    return ShiftAllocation.fromDateTime(localTime).shift;
  }

  static String calculateProductionDate(DateTime localTime) {
    return ShiftAllocation.fromDateTime(localTime).productionDate;
  }

  static String formatToPlantTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  /// Checks whether an event or ongoing downtime has carried over across shifts
  /// from the initial [origin] chronology.
  bool isCrossShiftFrom(EventChronology origin) {
    return activeShift != origin.activeShift ||
        productionDate != origin.productionDate;
  }

  /// Computes the breakdown of downtime minutes allocated to each factory shift
  /// between [startUtc] and [endUtc]. Crucial for shift handover OEE accounting.
  static Map<PlantShift, int> computeDowntimeMinutesPerShift(
      DateTime startUtc, DateTime endUtc) {
    final result = <PlantShift, int>{
      PlantShift.shift1_Morning: 0,
      PlantShift.shift2_Evening: 0,
      PlantShift.shift3_Night: 0,
    };

    if (endUtc.isBefore(startUtc)) return result;

    var current = startUtc.toLocal();
    final endLocal = endUtc.toLocal();

    while (current.isBefore(endLocal)) {
      final shift = calculateShift(current);
      // Next minute boundary
      final nextMinute = DateTime(
        current.year,
        current.month,
        current.day,
        current.hour,
        current.minute + 1,
      );
      final stepEnd = nextMinute.isBefore(endLocal) ? nextMinute : endLocal;
      if (!stepEnd.isAfter(current)) {
        break;
      }
      final stepSeconds = stepEnd.difference(current).inSeconds;
      final stepMinutes = (stepSeconds / 60.0).round();
      if (stepMinutes > 0) {
        result[shift] = (result[shift] ?? 0) + stepMinutes;
      }
      current = stepEnd;
    }

    return result;
  }

  EventChronology copyWith({
    DateTime? recordedAtUtc,
    String? plantTimeFormatted,
    String? productionDate,
    PlantShift? activeShift,
    bool? isOfflineGenerated,
    DateTime? syncedAtUtc,
  }) {
    return EventChronology(
      recordedAtUtc: recordedAtUtc ?? this.recordedAtUtc,
      plantTimeFormatted: plantTimeFormatted ?? this.plantTimeFormatted,
      productionDate: productionDate ?? this.productionDate,
      activeShift: activeShift ?? this.activeShift,
      isOfflineGenerated: isOfflineGenerated ?? this.isOfflineGenerated,
      syncedAtUtc: syncedAtUtc ?? this.syncedAtUtc,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordedAtUtc': recordedAtUtc.toIso8601String(),
      'plantTimeFormatted': plantTimeFormatted,
      'productionDate': productionDate,
      'activeShift': activeShift.name,
      'isOfflineGenerated': isOfflineGenerated,
      'syncedAtUtc': syncedAtUtc?.toIso8601String(),
    };
  }

  factory EventChronology.fromJson(Map<String, dynamic> json) {
    final shiftStr = json['activeShift'] as String?;
    PlantShift shiftVal = PlantShift.shift1_Morning;
    if (shiftStr != null) {
      if (shiftStr.contains('1') || shiftStr.contains('A') || shiftStr.contains('Morning')) {
        shiftVal = PlantShift.shift1_Morning;
      } else if (shiftStr.contains('2') || shiftStr.contains('B') || shiftStr.contains('Evening')) {
        shiftVal = PlantShift.shift2_Evening;
      } else if (shiftStr.contains('3') || shiftStr.contains('C') || shiftStr.contains('Night')) {
        shiftVal = PlantShift.shift3_Night;
      } else {
        shiftVal = PlantShift.values.firstWhere(
          (e) => e.name == shiftStr,
          orElse: () => PlantShift.shift1_Morning,
        );
      }
    }

    return EventChronology(
      recordedAtUtc: DateTime.parse(json['recordedAtUtc'] as String),
      plantTimeFormatted: json['plantTimeFormatted'] as String,
      productionDate: json['productionDate'] as String,
      activeShift: shiftVal,
      isOfflineGenerated: json['isOfflineGenerated'] as bool? ?? false,
      syncedAtUtc: json['syncedAtUtc'] != null
          ? DateTime.parse(json['syncedAtUtc'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        recordedAtUtc,
        plantTimeFormatted,
        productionDate,
        activeShift,
        isOfflineGenerated,
        syncedAtUtc,
      ];
}
