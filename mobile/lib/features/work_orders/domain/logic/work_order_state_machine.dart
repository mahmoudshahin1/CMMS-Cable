import '../../../../core/errors/security_exceptions.dart';
import '../enums/work_order_status.dart';

/// Industrial 5-Step Handshake State Machine for Work Orders.
///
/// Enforces linear and deterministic state transitions across
/// the maintenance lifecycle:
/// Open -> Assigned -> InProgress <-> PendingParts -> Completed -> Verified -> VerifiedClosed.
class WorkOrderStateMachine {
  const WorkOrderStateMachine._();

  /// Validates that transitioning from [current] to [next] is allowed.
  ///
  /// Throws [IllegalStateTransitionException] if the transition is invalid.
  static void validateTransition(
      WorkOrderStatus current, WorkOrderStatus next) {
    if (current == next) return;

    if (!canTransition(current, next)) {
      throw IllegalStateTransitionException(
        fromStatus: current.name,
        toStatus: next.name,
      );
    }
  }

  /// Returns true if transitioning from [current] to [next] is permitted.
  static bool canTransition(WorkOrderStatus current, WorkOrderStatus next) {
    if (current == next) return true;

    switch (current) {
      case WorkOrderStatus.open:
        return next == WorkOrderStatus.assigned;
      case WorkOrderStatus.assigned:
        return next == WorkOrderStatus.inProgress;
      case WorkOrderStatus.inProgress:
        return next == WorkOrderStatus.completed ||
            next == WorkOrderStatus.pendingParts;
      case WorkOrderStatus.pendingParts:
        return next == WorkOrderStatus.inProgress;
      case WorkOrderStatus.completed:
        return next == WorkOrderStatus.verified;
      case WorkOrderStatus.verified:
        return next == WorkOrderStatus.verifiedClosed;
      case WorkOrderStatus.verifiedClosed:
        return false; // Terminal state
    }
  }

  /// Returns the list of valid subsequent states from [current].
  static List<WorkOrderStatus> getAllowedNextStates(WorkOrderStatus current) {
    switch (current) {
      case WorkOrderStatus.open:
        return const [WorkOrderStatus.assigned];
      case WorkOrderStatus.assigned:
        return const [WorkOrderStatus.inProgress];
      case WorkOrderStatus.inProgress:
        return const [
          WorkOrderStatus.completed,
          WorkOrderStatus.pendingParts,
        ];
      case WorkOrderStatus.pendingParts:
        return const [WorkOrderStatus.inProgress];
      case WorkOrderStatus.completed:
        return const [WorkOrderStatus.verified];
      case WorkOrderStatus.verified:
        return const [WorkOrderStatus.verifiedClosed];
      case WorkOrderStatus.verifiedClosed:
        return const [];
    }
  }
}
