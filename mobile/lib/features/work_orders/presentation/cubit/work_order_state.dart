import 'package:equatable/equatable.dart';
import '../../domain/models/work_order_model.dart';

abstract class WorkOrderState extends Equatable {
  const WorkOrderState();

  @override
  List<Object?> get props => [];
}

class WorkOrderInitial extends WorkOrderState {}

class WorkOrderLoading extends WorkOrderState {}

class WorkOrderLoaded extends WorkOrderState {
  final List<WorkOrderModel> allWorkOrders;
  final List<WorkOrderModel> activeWorkOrders;

  const WorkOrderLoaded({
    required this.allWorkOrders,
    required this.activeWorkOrders,
  });

  @override
  List<Object?> get props => [allWorkOrders, activeWorkOrders];
}

class WorkOrderError extends WorkOrderState {
  final String message;
  final List<WorkOrderModel> previousWorkOrders;

  const WorkOrderError(this.message, {this.previousWorkOrders = const []});

  @override
  List<Object?> get props => [message, previousWorkOrders];
}
