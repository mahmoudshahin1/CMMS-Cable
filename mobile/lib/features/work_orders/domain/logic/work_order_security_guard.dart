import '../../../../core/errors/security_exceptions.dart';
import '../../../assets/domain/models/machine_model.dart';
import '../../../assets/domain/enums/department_type.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../auth/domain/models/user_model.dart';
import '../models/work_order_model.dart';

/// Domain security rules enforcing Role-Based Access Control (RBAC)
/// across the 5-step maintenance handshake.
class WorkOrderSecurityGuard {
  static void validateCreate(UserModel? caller, [MachineModel? machine]) {
    if (caller != null &&
        caller.role != UserRole.operator &&
        caller.role != UserRole.maintenanceSupervisor &&
        caller.role != UserRole.productionSupervisor) {
      throw UnauthorizedRoleException(
        requiredRole: 'Operator or Supervisor',
        actualRole: caller.role.name,
      );
    }

    if (caller != null &&
        caller.role == UserRole.operator &&
        caller.department != null &&
        machine != null &&
        machine.department != caller.department) {
      throw UnauthorizedRoleException(
        requiredRole: 'Operator of ${machine.department.displayName}',
        actualRole: 'Operator of ${caller.department!.displayName}',
        message:
            'SECURITY ERROR: Line operators can only log work orders for machines in their own department.',
      );
    }
  }

  static void validateAssign(UserModel? caller) {
    if (caller != null && caller.role != UserRole.maintenanceSupervisor) {
      throw UnauthorizedRoleException(
        requiredRole: 'Maintenance Supervisor',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Only Maintenance Supervisors can assign technicians.',
      );
    }
  }

  static void validateStartRepair(UserModel caller, WorkOrderModel wo) {
    if (caller.role != UserRole.maintenanceTech) {
      throw UnauthorizedRoleException(
        requiredRole: 'Maintenance Technician',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Only Maintenance Technicians can start repair work.',
      );
    }

    if (wo.assignedToTechnicianId != null &&
        wo.assignedToTechnicianId != caller.id) {
      throw UnassignedTechnicianException(
        expectedTechId: wo.assignedToTechnicianId!,
        actualTechId: caller.id,
        message:
            'SECURITY ERROR: This ticket is assigned to a different technician.',
      );
    }
  }

  static void validateAddSparePart(UserModel? caller, WorkOrderModel wo) {
    if (caller != null && caller.role != UserRole.maintenanceTech) {
      throw UnauthorizedRoleException(
        requiredRole: 'Maintenance Technician',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Only Maintenance Technicians can record spare parts.',
      );
    }

    if (caller != null &&
        wo.assignedToTechnicianId != null &&
        wo.assignedToTechnicianId != caller.id) {
      throw UnassignedTechnicianException(
        expectedTechId: wo.assignedToTechnicianId!,
        actualTechId: caller.id,
      );
    }
  }

  static void validateComplete(UserModel? caller, WorkOrderModel wo) {
    if (caller != null && caller.role != UserRole.maintenanceTech) {
      throw UnauthorizedRoleException(
        requiredRole: 'Maintenance Technician',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Only Maintenance Technicians can complete repairs.',
      );
    }

    if (caller != null &&
        wo.assignedToTechnicianId != null &&
        wo.assignedToTechnicianId != caller.id) {
      throw UnassignedTechnicianException(
        expectedTechId: wo.assignedToTechnicianId!,
        actualTechId: caller.id,
      );
    }
  }

  static void validateConfirmTestRun(UserModel caller, [MachineModel? machine]) {
    if (caller.role != UserRole.operator) {
      throw UnauthorizedRoleException(
        requiredRole: 'Operator',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Only Line Operators can confirm field test runs.',
      );
    }

    if (caller.department != null &&
        machine != null &&
        machine.department != caller.department) {
      throw UnauthorizedRoleException(
        requiredRole: 'Operator of ${machine.department.displayName}',
        actualRole: 'Operator of ${caller.department!.displayName}',
        message:
            'SECURITY ERROR: Line operators can only confirm field test runs for machines in their own department.',
      );
    }
  }

  static void validateApproveAndClose(UserModel caller) {
    if (caller.role != UserRole.maintenanceSupervisor &&
        caller.role != UserRole.productionSupervisor) {
      throw UnauthorizedRoleException(
        requiredRole: 'Supervisor',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Only Supervisors can approve and close work orders.',
      );
    }
  }
}
