import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../assets/presentation/cubit/machine_cubit.dart';
import '../../../assets/presentation/cubit/machine_state.dart';
import '../../../downtime/presentation/cubit/downtime_cubit.dart';
import '../../../downtime/presentation/cubit/downtime_state.dart';
import '../../../work_orders/presentation/cubit/work_order_cubit.dart';
import '../../../work_orders/presentation/cubit/work_order_state.dart';
import '../../../assets/domain/enums/department_type.dart';
import '../../domain/oee_calculator.dart';
import 'analytics_state.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  final MachineCubit machineCubit;
  final DowntimeCubit downtimeCubit;
  final WorkOrderCubit workOrderCubit;

  StreamSubscription? _machineSubscription;
  StreamSubscription? _downtimeSubscription;
  StreamSubscription? _workOrderSubscription;

  DepartmentType? _selectedDepartment;

  AnalyticsCubit({
    required this.machineCubit,
    required this.downtimeCubit,
    required this.workOrderCubit,
  }) : super(AnalyticsInitial()) {
    _initSubscriptions();
    computeAnalytics();
  }

  void _initSubscriptions() {
    _machineSubscription = machineCubit.stream.listen((_) => computeAnalytics());
    _downtimeSubscription = downtimeCubit.stream.listen((_) => computeAnalytics());
    _workOrderSubscription = workOrderCubit.stream.listen((_) => computeAnalytics());
  }

  void selectDepartment(DepartmentType? department) {
    _selectedDepartment = department;
    computeAnalytics();
  }

  void computeAnalytics() {
    final machineState = machineCubit.state;
    final downtimeState = downtimeCubit.state;
    final workOrderState = workOrderCubit.state;

    final machines = machineState is MachineLoaded ? machineState.allMachines : [];
    final downtimes = downtimeState is DowntimeLoaded ? downtimeState.allLogs : [];
    final workOrders = workOrderState is WorkOrderLoaded ? workOrderState.allWorkOrders : [];

    final analyticsData = OeeCalculator.calculate(
      machines: machines.cast(),
      downtimeLogs: downtimes.cast(),
      workOrders: workOrders.cast(),
      filterDepartment: _selectedDepartment,
    );

    emit(AnalyticsLoaded(
      data: analyticsData,
      selectedDepartment: _selectedDepartment,
    ));
  }

  @override
  Future<void> close() {
    _machineSubscription?.cancel();
    _downtimeSubscription?.cancel();
    _workOrderSubscription?.cancel();
    return super.close();
  }
}
