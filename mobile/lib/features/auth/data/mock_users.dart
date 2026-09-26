import '../domain/models/user_model.dart';
import '../domain/enums/user_role.dart';
import '../../assets/domain/enums/department_type.dart';

class MockUsers {
  // --- 7 Department-Dedicated Users ---
  static const UserModel drawingLead = UserModel(
    id: 'usr-dept-drawing',
    name: 'Eng. Ahmed Saeed (Drawing Lead)',
    email: 'drawing.lead@cableops.com',
    role: UserRole.operator,
    department: DepartmentType.drawing,
  );

  static const UserModel strandingLead = UserModel(
    id: 'usr-dept-stranding',
    name: 'Eng. Omar Khaled (Stranding Lead)',
    email: 'stranding.lead@cableops.com',
    role: UserRole.operator,
    department: DepartmentType.stranding,
  );

  static const UserModel ccvLead = UserModel(
    id: 'usr-dept-ccv',
    name: 'Eng. Mohamed Youssef (CCV Lead)',
    email: 'ccv.lead@cableops.com',
    role: UserRole.operator,
    department: DepartmentType.ccv,
  );

  static const UserModel extrusionLead = UserModel(
    id: 'usr-dept-extrusion',
    name: 'Eng. Ali Hassan (Extrusion Lead)',
    email: 'extrusion.lead@cableops.com',
    role: UserRole.operator,
    department: DepartmentType.extrusion,
  );

  static const UserModel assemblyLead = UserModel(
    id: 'usr-dept-assembly',
    name: 'Eng. Mostafa Ibrahim (Assembly Lead)',
    email: 'assembly.lead@cableops.com',
    role: UserRole.operator,
    department: DepartmentType.assembly,
  );

  static const UserModel screeningLead = UserModel(
    id: 'usr-dept-screening',
    name: 'Eng. Yasser Hamdy (Screening Lead)',
    email: 'screening.lead@cableops.com',
    role: UserRole.operator,
    department: DepartmentType.screening,
  );

  static const UserModel tapeArmourLead = UserModel(
    id: 'usr-dept-tape',
    name: 'Eng. Tamer Nabil (Tape Armour Lead)',
    email: 'tape.lead@cableops.com',
    role: UserRole.operator,
    department: DepartmentType.tapeArmour,
  );

  // Backward-compatible alias
  static const UserModel operatorUser = extrusionLead;

  // --- Field Technicians (Plant-Wide) ---
  static const UserModel electricalTech = UserModel(
    id: 'usr-tech-elec-02',
    name: 'Tariq Al-Mansoor (Electrical Tech)',
    email: 'tech.elec@cableops.com',
    role: UserRole.maintenanceTech,
    speciality: 'Electrical',
  );

  static const UserModel mechanicalTech = UserModel(
    id: 'usr-tech-mech-03',
    name: 'Samir Fawzy (Mechanical Tech)',
    email: 'tech.mech@cableops.com',
    role: UserRole.maintenanceTech,
    speciality: 'Mechanical',
  );

  // --- Plant Management & Supervision ---
  static const UserModel maintenanceSupervisor = UserModel(
    id: 'usr-maint-sup-04',
    name: 'Eng. Hisham Radi (Maint. Supervisor)',
    email: 'maint.sup@cableops.com',
    role: UserRole.maintenanceSupervisor,
  );

  static const UserModel productionSupervisor = UserModel(
    id: 'usr-prod-sup-05',
    name: 'Eng. Kareem Ezzat (Prod. Supervisor)',
    email: 'prod.sup@cableops.com',
    role: UserRole.productionSupervisor,
  );

  static const UserModel plantManager = UserModel(
    id: 'usr-manager-06',
    name: 'Eng. Mahmoud Ali (Plant Manager)',
    email: 'manager@cableops.com',
    role: UserRole.plantManager,
  );

  static const List<UserModel> departmentUsers = [
    drawingLead,
    strandingLead,
    ccvLead,
    extrusionLead,
    assemblyLead,
    screeningLead,
    tapeArmourLead,
  ];

  static const List<UserModel> plantWideUsers = [
    plantManager,
    maintenanceSupervisor,
    productionSupervisor,
    electricalTech,
    mechanicalTech,
  ];

  static const List<UserModel> allMockUsers = [
    ...departmentUsers,
    ...plantWideUsers,
  ];

  static List<UserModel> getTechnicians({String? speciality}) {
    return allMockUsers.where((u) {
      if (u.role != UserRole.maintenanceTech) return false;
      if (speciality != null && speciality.isNotEmpty) {
        final uSpec = (u.speciality ?? '').toLowerCase();
        final target = speciality.toLowerCase();
        return uSpec.contains(target) || uSpec.contains('all') || target == 'all';
      }
      return true;
    }).toList();
  }

  static UserModel findById(String id) {
    return allMockUsers.firstWhere(
      (u) => u.id == id,
      orElse: () => maintenanceSupervisor,
    );
  }
}
