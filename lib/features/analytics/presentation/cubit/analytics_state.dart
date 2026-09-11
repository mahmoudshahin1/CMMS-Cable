import 'package:equatable/equatable.dart';
import '../../domain/oee_calculator.dart';
import '../../../assets/domain/enums/department_type.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final PlantAnalyticsData data;
  final DepartmentType? selectedDepartment;

  const AnalyticsLoaded({
    required this.data,
    this.selectedDepartment,
  });

  @override
  List<Object?> get props => [data, selectedDepartment];
}
