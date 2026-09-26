import '../../features/work_orders/domain/models/work_order_model.dart';
import '../../features/work_orders/domain/enums/work_order_status.dart';
import '../../features/work_orders/domain/enums/work_order_type.dart';
import '../../features/work_orders/domain/enums/priority.dart';
import '../chronology/event_chronology.dart';

List<WorkOrderModel> getInitialWorkOrdersList() {
  final now = DateTime.now();
  return [
    // 1. Electrical Maintenance Task 01 (Assigned to Tariq Al-Mansoor)
    WorkOrderModel(
      id: 'WO-ELEC-001',
      title: 'عطل في درايف محرك السحب الرئيسي (Inverter Overcurrent)',
      description:
          'فصل مفاجئ لمحرك خط السحب مع ظهور إنذار Overcurrent على شاشة الإنفرتر الرئيسي. يلزم فحص ملفات المحرك ووحدة التحكم.',
      machineId: 'DR01',
      type: WorkOrderType.breakdown,
      status: WorkOrderStatus.assigned,
      priority: Priority.critical,
      assignedToTechnicianId: 'usr-tech-elec-02',
      assignedBySupervisorId: 'usr-maint-sup-04',
      createdAt: now.subtract(const Duration(hours: 2)),
      chronology: EventChronology.fromDateTime(
          now.subtract(const Duration(hours: 2))),
    ),

    // 2. Electrical Maintenance Task 02 (In Progress - Tariq Al-Mansoor)
    WorkOrderModel(
      id: 'WO-ELEC-002',
      title: 'استبدال حساس حرارة (Thermocouple) رأس البثق Zone 3',
      description:
          'تذبذب مستمر في قراءة درجات الحرارة لـ Zone 3 بخط العزل الرئيسي مما يؤثر على لزوجة المادة العازلة.',
      machineId: 'EX01',
      type: WorkOrderType.corrective,
      status: WorkOrderStatus.inProgress,
      priority: Priority.high,
      assignedToTechnicianId: 'usr-tech-elec-02',
      assignedBySupervisorId: 'usr-maint-sup-04',
      createdAt: now.subtract(const Duration(hours: 5)),
      startedAt: now.subtract(const Duration(minutes: 45)),
      chronology: EventChronology.fromDateTime(
          now.subtract(const Duration(hours: 5))),
    ),

    // 3. Mechanical Maintenance Task 01 (Assigned to Samir Fawzy)
    WorkOrderModel(
      id: 'WO-MECH-001',
      title: 'اهتزاز غير طبيعي وصوت احتكاك في رولمان بلي قفص الجدل',
      description:
          'رصد صوت احتكاك وارتفاع في حرارة كرسي التحميل الخلفي لقفص الجدل Rigid Strander 61. يلزم فحص المحامل والتشحيم فوراً.',
      machineId: 'RS01',
      type: WorkOrderType.breakdown,
      status: WorkOrderStatus.assigned,
      priority: Priority.critical,
      assignedToTechnicianId: 'usr-tech-mech-03',
      assignedBySupervisorId: 'usr-maint-sup-04',
      createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
      chronology: EventChronology.fromDateTime(
          now.subtract(const Duration(hours: 1, minutes: 30))),
    ),

    // 4. Mechanical Maintenance Task 02 (In Progress - Samir Fawzy)
    WorkOrderModel(
      id: 'WO-MECH-002',
      title: 'صيانة وقائية وفحص منظومة الشد الهيدروليكي لخط التدريع',
      description:
          'استبدال مانع تسرب الزيت الهيدروليكي وضبط ضغط البساتم لشداد خط التكفيل بالشريط الفولاذي.',
      machineId: 'ST01',
      type: WorkOrderType.preventive,
      status: WorkOrderStatus.inProgress,
      priority: Priority.medium,
      assignedToTechnicianId: 'usr-tech-mech-03',
      assignedBySupervisorId: 'usr-maint-sup-04',
      createdAt: now.subtract(const Duration(hours: 6)),
      startedAt: now.subtract(const Duration(hours: 2)),
      chronology: EventChronology.fromDateTime(
          now.subtract(const Duration(hours: 6))),
    ),

    // 5. Unassigned ticket for Drawing Department (Demonstrating department isolation)
    WorkOrderModel(
      id: 'WO-DR-003',
      title: 'فحص منظومة تبريد سائل السحب وإزالة الرواسب',
      description:
          'انسداد جزئي في دورة سائل التبريد المستحلب لخط سحب النحاس 02، بانتظار توزيع المهندس للفني المختص.',
      machineId: 'DR02',
      type: WorkOrderType.corrective,
      status: WorkOrderStatus.pending,
      priority: Priority.medium,
      assignedToTechnicianId: null,
      assignedBySupervisorId: null,
      createdAt: now.subtract(const Duration(hours: 4)),
      chronology: EventChronology.fromDateTime(
          now.subtract(const Duration(hours: 4))),
    ),
  ];
}
