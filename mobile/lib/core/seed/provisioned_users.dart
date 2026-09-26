import '../../features/assets/domain/enums/department_type.dart';
import '../../features/auth/domain/enums/user_role.dart';
import '../../features/auth/domain/models/user_model.dart';

/// Pre-provisioned standard users and technicians with production UUIDs
/// ensuring zero-delay offline availability, local Hive persistence,
/// and seamless identity resolution across all CMMS workflows.
final List<UserModel> provisionedUsers = [
  // --- Maintenance Technicians (Electrical & Mechanical) ---
  const UserModel(
    id: 'cc9f6212-bf05-4610-b8a5-64f911565f37',
    name: 'طارق المنصور - فني كهرباء وتحكم',
    email: 'tech.elec@cable.com',
    role: UserRole.maintenanceTech,
    speciality: 'Electrical',
    employeeCode: 'EMP-004',
  ),
  const UserModel(
    id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    name: 'طارق المنصور - فني كهرباء',
    email: 'tech.elec@cableops.com',
    role: UserRole.maintenanceTech,
    speciality: 'Electrical',
    employeeCode: 'EMP-004',
  ),
  const UserModel(
    id: 'a777edcb-e42e-4c94-aac9-1b89dd364ce5',
    name: 'طارق المنصور - فني كهرباء وتحكم',
    email: 'tech.elec@cableops.local',
    role: UserRole.maintenanceTech,
    speciality: 'Electrical',
    employeeCode: 'EMP-004',
  ),
  const UserModel(
    id: '90e23813-fe01-4796-8138-61f17275f432',
    name: 'سمير فوزي - فني ميكانيكا وهيدروليك',
    email: 'tech.mech@cable.com',
    role: UserRole.maintenanceTech,
    speciality: 'Mechanical',
    employeeCode: 'EMP-005',
  ),
  const UserModel(
    id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    name: 'سمير فوزي - فني ميكانيكا',
    email: 'tech.mech@cableops.com',
    role: UserRole.maintenanceTech,
    speciality: 'Mechanical',
    employeeCode: 'EMP-005',
  ),

  // --- Maintenance & Production Supervisors ---
  const UserModel(
    id: 'c79d06f1-09b2-4d01-99e9-0c8fced1e56b',
    name: 'م. هشام راضي - مشرف الصيانة',
    email: 'maint.sup@cableops.com',
    role: UserRole.maintenanceSupervisor,
  ),
  const UserModel(
    id: '99999999-9999-4999-8999-999999999999',
    name: 'م. هشام راضي - مشرف الصيانة',
    email: 'maint.sup@cableops.local',
    role: UserRole.maintenanceSupervisor,
  ),
  const UserModel(
    id: '859c128e-5ad6-42c5-b5b5-ec6a99b0defe',
    name: 'م. كريم عزت - مشرف الإنتاج',
    email: 'prod.sup@cableops.com',
    role: UserRole.productionSupervisor,
  ),
  const UserModel(
    id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    name: 'م. كريم عزت - مشرف الإنتاج',
    email: 'prod.sup@cableops.local',
    role: UserRole.productionSupervisor,
  ),

  // --- Plant Management ---
  const UserModel(
    id: '97d56aef-5089-4741-8942-cca54dde3750',
    name: 'مدير علي - مدير عام المصنع',
    email: 'manager@cableops.com',
    role: UserRole.plantManager,
  ),
  const UserModel(
    id: '88888888-8888-4888-8888-888888888888',
    name: 'م. محمود علي - مدير المصنع',
    email: 'manager@cableops.local',
    role: UserRole.plantManager,
  ),

  // --- Department Machine Operators ---
  const UserModel(
    id: 'a1111111-1111-4111-8111-111111111111',
    name: 'أحمد سعيد - مشغل سحب الأسلاك',
    email: 'drawing.lead@cableops.com',
    role: UserRole.operator,
    department: DepartmentType.drawing,
  ),
  const UserModel(
    id: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
    name: 'أحمد سعيد - مشغل خط السحب',
    email: 'drawing.op@cableops.local',
    role: UserRole.operator,
    department: DepartmentType.drawing,
  ),
  const UserModel(
    id: '0a03468c-8212-4c44-9c1f-3ac98fe625bf',
    name: 'عمر خالد - مشغل خط الجدل والتجميع',
    email: 'stranding.lead@cableops.com',
    role: UserRole.operator,
    department: DepartmentType.stranding,
  ),
  const UserModel(
    id: '11111111-1111-4111-8111-111111111111',
    name: 'عمر خالد - مشغل خط الجدل',
    email: 'stranding.op@cableops.local',
    role: UserRole.operator,
    department: DepartmentType.stranding,
  ),
  const UserModel(
    id: 'b2222222-2222-4222-8222-222222222222',
    name: 'محمد يوسف - مشغل خط CCV',
    email: 'ccv.op@cableops.local',
    role: UserRole.operator,
    department: DepartmentType.ccv,
  ),
  const UserModel(
    id: 'c3333333-3333-4333-8333-333333333333',
    name: 'علي حسن - مشغل خطوط العزل والبثق',
    email: 'extrusion.op@cableops.local',
    role: UserRole.operator,
    department: DepartmentType.extrusion,
  ),
  const UserModel(
    id: 'd4444444-4444-4444-8444-444444444444',
    name: 'مصطفى إبراهيم - مشغل التجميع والتسليح',
    email: 'assembly.op@cableops.local',
    role: UserRole.operator,
    department: DepartmentType.assembly,
  ),
  const UserModel(
    id: 'e5555555-5555-4555-8555-555555555555',
    name: 'ياسر حمدي - مشغل الحجب والشريط',
    email: 'screening.op@cableops.local',
    role: UserRole.operator,
    department: DepartmentType.screening,
  ),
  const UserModel(
    id: 'f6666666-6666-4666-8666-666666666666',
    name: 'تامر نبيل - مشغل تدريع الأشرطة',
    email: 'tape.op@cableops.local',
    role: UserRole.operator,
    department: DepartmentType.tapeArmour,
  ),
];
