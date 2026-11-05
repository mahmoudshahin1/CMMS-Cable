import '../../../../core/errors/security_exceptions.dart';
import '../../../assets/domain/enums/department_type.dart';
import '../../../assets/domain/models/machine_model.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../auth/domain/models/user_model.dart';

/// Domain security rules enforcing Role-Based Access Control (RBAC)
/// and department isolation for downtime log mutations.
class DowntimeSecurityGuard {
  /// Validates whether [caller] is authorized to create a downtime log for [machine].
  ///
  /// - [UserRole.operator] and [UserRole.productionSupervisor]: restricted to machines
  ///   in their assigned department (`caller.department == machine.department`).
  /// - [UserRole.maintenanceSupervisor], [UserRole.plantManager], [UserRole.admin],
  ///   and [UserRole.supervisor]: authorized across all departments.
  /// - [UserRole.maintenanceTech]: strictly blocked (technicians do not log downtime).
  static void validateCreate(UserModel? caller, MachineModel machine) {
    if (caller == null) return;

    if (caller.role == UserRole.maintenanceTech) {
      throw UnauthorizedRoleException(
        requiredRole: 'Operator or Supervisor',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Maintenance Technicians cannot create downtime logs.',
      );
    }

    if (caller.role == UserRole.operator ||
        caller.role == UserRole.productionSupervisor) {
      if (caller.department != null &&
          caller.department != machine.department) {
        throw UnauthorizedRoleException(
          requiredRole:
              '${caller.role.name} of ${machine.department.displayName}',
          actualRole:
              '${caller.role.name} of ${caller.department!.displayName}',
          message:
              'SECURITY ERROR: ${caller.role.name} can only report downtime for machines in their own department.',
        );
      }
    }
  }

  /// Validates whether [caller] is authorized to close a downtime log for [machine].
  ///
  /// - Option A (Supervisors only):
  ///   - [UserRole.productionSupervisor]: restricted to machines in their department.
  ///   - [UserRole.maintenanceSupervisor], [UserRole.plantManager], [UserRole.admin],
  ///     and [UserRole.supervisor]: authorized plant-wide.
  ///   - [UserRole.operator] and [UserRole.maintenanceTech]: unauthorized.
  static void validateClose(UserModel? caller, MachineModel machine) {
    if (caller == null) return;

    if (caller.role == UserRole.operator ||
        caller.role == UserRole.maintenanceTech) {
      throw UnauthorizedRoleException(
        requiredRole: 'Supervisor',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Operators and Technicians cannot close downtime logs.',
      );
    }

    if (caller.role == UserRole.productionSupervisor) {
      if (caller.department != null &&
          caller.department != machine.department) {
        throw UnauthorizedRoleException(
          requiredRole:
              'Production Supervisor of ${machine.department.displayName}',
          actualRole:
              'Production Supervisor of ${caller.department!.displayName}',
          message:
              'SECURITY ERROR: Production Supervisors can only close downtime in their own department.',
        );
      }
    }
  }
}
