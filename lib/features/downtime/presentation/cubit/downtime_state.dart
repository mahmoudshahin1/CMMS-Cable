import 'package:equatable/equatable.dart';
import '../../domain/models/downtime_log_model.dart';

abstract class DowntimeState extends Equatable {
  const DowntimeState();

  @override
  List<Object?> get props => [];
}

class DowntimeInitial extends DowntimeState {}

class DowntimeLoading extends DowntimeState {}

class DowntimeLoaded extends DowntimeState {
  final List<DowntimeLogModel> allLogs;
  final List<DowntimeLogModel> activeLogs;

  const DowntimeLoaded({required this.allLogs, required this.activeLogs});

  @override
  List<Object?> get props => [allLogs, activeLogs];
}

class DowntimeError extends DowntimeState {
  final String message;

  const DowntimeError(this.message);

  @override
  List<Object?> get props => [message];
}
