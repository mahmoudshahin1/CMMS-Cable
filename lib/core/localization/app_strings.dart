import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'locale_cubit.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Header & Navigation
      'app_title': 'Cable Manufacturing CMMS',
      'shift_manager': 'Eng. Mahmoud',
      'shift_sub': 'Shift A • Day Operational Manager',
      'tab_factory': 'Factory Floor',
      'tab_work_orders': 'Work Orders',
      'tab_analytics': 'Analytics OEE',
      'tab_my_tasks': 'My Tasks',
      'tab_notifications': 'Alerts',
      'tab_executive': 'Executive KPI',
      'repair_request_btn': 'Repair Request',
      'qr_scanner_btn': 'QR Scanner',
      'theme_toggle': 'Toggle Theme',
      'lang_toggle': 'العربية',
      'settings_title': 'Settings & Profile',
      'profile_section': 'User Profile Information',
      'appearance_section': 'Appearance & Theme',
      'accent_color_section': 'Primary Accent Color',
      'language_section': 'System Language',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'permissions_title': 'Active Role Permissions',
      'switch_account': 'Switch Persona',
      'app_version': 'CMMS System Version',

      // Factory Floor KPIs
      'total_machines': 'TOTAL MACHINES',
      'running': 'RUNNING',
      'active_downtime': 'ACTIVE DOWNTIME',
      'all_departments': 'All Departments',
      'running_status': 'Running',
      'speed': 'SPEED',
      'production': 'PROD',
      'report_issue': 'REPORT ISSUE',
      'view_downtime': 'VIEW DOWNTIME',

      // Work Orders
      'work_orders_title': 'Work Orders & Maintenance',
      'filter_all': 'All',
      'filter_open': 'Open',
      'filter_in_progress': 'In Progress',
      'filter_completed': 'Completed',
      'new_repair_request': 'Submit New Work Order',
      'no_work_orders': 'No work orders in this section',
      'no_work_orders_sub': 'Tap the button to submit a new breakdown ticket.',
      'machine': 'Machine',
      'priority': 'Priority',
      'status': 'Status',
      'create_wo_title': 'Submit Breakdown Repair Ticket',
      'track_orders': 'Track Orders',
      'select_machine': '1. Select Machine',
      'type_and_priority': '2. Request Type & Priority',
      'quick_presets': '3. Quick Fault Presets',
      'fault_details': '4. Fault Title & Notes',
      'fault_title_hint': 'e.g. Wire break on capstan puller',
      'notes_hint': 'Additional notes and technician observations...',
      'submit_wo_btn': 'Submit Work Order',

      // Work Order Details
      'wo_timeline': 'REPAIR STATUS TIMELINE',
      'wo_elapsed_time': 'LIVE ELAPSED REPAIR TIME (MTTR)',
      'technician_working': 'Technician Working...',
      'technician_completed': 'Maintenance Completed & Tested',
      'spare_parts_title': 'SPARE PARTS CONSUMED',
      'spare_part_hint': 'Part name (e.g. Bearing 6205)',
      'root_cause_title': 'ROOT CAUSE & MAINTENANCE ACTIONS',
      'root_cause_hint': 'Root cause breakdown analysis...',
      'actions_taken_hint': 'Actions taken and repair notes...',
      'complete_wo_btn': 'Complete Work Order & Restore Machine',

      // OEE Analytics
      'analytics_title': 'Plant Analytics & OEE',
      'recalculate_btn': 'Recalculate KPIs',
      'oee_overall_title': 'OVERALL EQUIPMENT EFFECTIVENESS',
      'oee_overall_sub': 'Overall Equipment Effectiveness (OEE)',
      'oee_formula': 'Formula: Availability × Performance × Quality',
      'prod_output': 'PROD OUTPUT',
      'total_downtime': 'TOTAL DOWNTIME',
      'scrap_rate': 'SCRAP RATE',
      'parts_cost': 'PARTS COST',
      'oee_pillars': 'OEE Pillars (Availability • Performance • Quality)',
      'availability_title': 'Availability',
      'availability_sub': 'Operational uptime vs planned time',
      'performance_title': 'Performance',
      'performance_sub': 'Actual line speed vs design speed',
      'quality_title': 'Quality',
      'quality_sub': 'Good cable meters vs scrap rate',
      'reliability_title': 'Maintenance Reliability KPIs',
      'mttr_title': 'Mean Time To Repair',
      'mtbf_title': 'Mean Time Between Failures',
      'downtime_pareto': 'DOWNTIME PARETO ANALYSIS',
      'downtime_pareto_sub': 'Root Cause Downtime Loss Breakdown',
      'dept_oee_title': 'Department OEE Comparison',
      'dept_machines_running': 'machines active',

      // QR Scanner
      'qr_scanner_title': 'Machine Barcode & QR Scanner',
      'qr_scanner_ready': 'Industrial Scanner Ready',
      'qr_point_camera': 'Point camera at machine QR plate',
      'manual_code_lookup': 'Or enter machine code manually:',
      'search_btn': 'Search',
      'machine_detected': 'Machine Code Identified Successfully',
      'report_breakdown_btn': 'Report Breakdown (Work Order)',
      'log_downtime_btn': 'Log Downtime',

      // Switch Persona Bottom Sheet
      'switch_persona_title': 'Switch Active Persona (RBAC)',
      'switch_persona_sub': 'Test screen rendering & button-level access gates',
      'dept_users_header': 'Department Leads (7 Departments)',
      'plant_wide_header': 'Plant Management & Field Technicians',
      'switched_to_user': 'Switched to {name} ({detail})',
      'open_settings_btn': 'Open Settings & Customize Theme',

      // Settings Screen — Permissions
      'perm_log_downtime': 'Log Downtime & Breakdown Reports',
      'perm_assign_tech': 'Dispatch & Assign Technicians',
      'perm_start_repair': 'Accept Ticket & Start Field Repair',
      'perm_spare_parts': 'Record Spare Parts Consumed',
      'perm_complete_repair': 'Record Root Cause & Complete Repair',
      'perm_confirm_test': 'Confirm Production Test Run',
      'perm_reclassify': 'Reclassify Downtime Type',
      'perm_approve_close': 'Approve & Close Work Order',
      'perm_view_analytics': 'View Plant Analytics & KPIs',

      // Settings Screen — Extra
      'current_shift_label': 'Current Shift: Shift 1 (Day)',
      'accent_color_hint': 'Choose your preferred accent color to customize buttons and UI elements:',
      'hive_db_active': 'Local Hive Offline-First Database Active',
      'company_label': 'Energya Cables (Elsewedy Helal)',

      // Work Orders List Screen
      'wo_screen_title': 'Work Orders & Breakdowns',
      'new_breakdown_tooltip': 'Submit new breakdown ticket',
      'more_btn': 'More',
      'refresh_btn': 'Refresh',
      'dept_scope_label': 'Dept. Scope: {dept}',
      'dept_scope_sub': 'You can only view and track tickets for machines in your department',
      'ticket_count': '{count} tickets',
      'plant_mgr_scope': 'Plant Manager View: Full visibility across all 7 departments',
      'tech_scope_electrical': 'Electrical maintenance tasks assigned to you',
      'tech_scope_mechanical': 'Mechanical maintenance tasks assigned to you',
      'tech_scope_sub': 'You can only see breakdowns distributed to you by the supervisor across the entire plant',
      'pending_assignments_msg': 'You have {count} new work order(s) awaiting your acceptance to start repair.',
      'filter_all_label': 'All',
      'filter_pending_label': 'New Breakdowns (Pending)',
      'filter_assigned_label': 'Assigned',
      'filter_in_progress_label': 'In Repair (In Progress)',
      'filter_completed_label': 'Repaired (Completed)',
      'filter_verified_label': 'Tested (Verified)',
      'filter_closed_label': 'Closed',
      'no_wo_tech': 'No work orders currently assigned to you by the supervisor',
      'no_wo_tech_sub': 'Tickets will appear here once the supervisor distributes and assigns them to you.',
      'no_wo_dept': 'No work orders for {dept} department',

      // Activity Timeline Widget
      'timeline_reported': 'Breakdown Reported',
      'timeline_assigned': 'Assigned & Dispatched',
      'timeline_started': 'Repair Started',
      'timeline_spare_part': 'Spare Part Added',
      'timeline_completed': 'Repair Completed',
      'timeline_test_run': 'Test Run Passed',
      'timeline_closed': 'Approved & Closed',
      'field_machine_code': 'Machine Code',
      'field_priority': 'Priority Level',
      'field_type': 'Request Type',
      'field_technician': 'Assigned Technician',
      'field_supervisor': 'Responsible Supervisor',
      'field_start_time': 'Repair Start',
      'field_root_cause': 'Root Cause',
      'field_actions_taken': 'Repair Actions',
      'field_part_no': 'Part Number',
      'field_part_name': 'Part Name',
      'field_qty': 'Quantity',
      'field_unit_price': 'Unit Price',
      'field_spare_parts': 'Spare Parts',
      'field_test_run': 'Test Run',
      'field_close_date': 'Approval Date',
      'audit_log_title': 'Activity & Operations Audit Log',
      'audit_log_tamper_proof': 'Tamper-Proof Authenticated Record',
      'sort_newest_first': 'Newest First',
      'sort_oldest_first': 'Oldest First',
      'no_events_yet': 'No activity events recorded yet',
      'cross_shift_title': 'Cross-Shift Breakdown Status',
      'cross_shift_start': '• Origin: Started at {time} in [{shift}]',
      'cross_shift_extended': '• Extended: Continued to [{shift}] (ongoing since {time} - total {duration})',
      'cross_shift_oee_dist': 'Per-Shift Downtime Distribution for OEE Calculations:',
      'shift_minutes': '{label}: {mins} min',
      'shift_1_short': 'S1',
      'shift_2_short': 'S2',
      'shift_3_short': 'S3',
      'production_date_label': '• Production Date: {date}',
      'time_label': 'Time: {time}',

      // OEE Analytics Screen
      'analytics_screen_title': 'Plant Analytics & OEE',
      'recalculate_tooltip': 'Recalculate KPIs',
      'oee_updated_snack': 'OEE effectiveness indicators updated successfully',
      'computing_kpis': 'Computing performance indicators...',
      'all_depts_filter': 'All Departments',
      'prod_output_sub': 'Total Production (km)',
      'downtime_hours_sub': 'Downtime Hours',
      'scrap_km_sub': 'Production Scrap (km)',
      'parts_cost_sub': 'Spare Parts Cost',
      'oee_pillars_title': 'OEE Pillars (Availability • Performance • Quality)',
      'availability_ar_sub': 'Actual uptime ratio vs planned',
      'performance_ar_sub': 'Line speed efficiency vs design speed',
      'quality_ar_sub': 'Good cable meters vs scrap',
      'reliability_kpis_title': 'Maintenance Reliability KPIs',
      'mttr_label': 'Avg. Repair Time',
      'mtbf_label': 'Time Between Failures',
      'minutes_unit': '{val} min',
      'hours_unit': '{val} hrs',
      'dept_oee_compare': 'Department OEE Comparison',
      'dept_machines_info': 'Machines: {running}/{total} active • Output: {km} km',

      // OEE Radial Gauge
      'oee_world_class': 'WORLD CLASS',
      'oee_acceptable': 'ACCEPTABLE',
      'oee_attention': 'ATTENTION REQUIRED',
      'oee_gauge_title': 'Overall Equipment Effectiveness (OEE)',
      'oee_formula_label': 'Formula: Availability × Performance × Quality',

      // Downtime Pareto Card
      'pareto_title': 'Downtime Cause Analysis (Pareto)',
      'total_hours': 'Total: {val} hrs',
      'minutes_pct': '{mins} min ({pct}%)',

      // Scanned Machine Sheet
      'machine_identified': 'Machine Code Identified Successfully',
      'dept_label': 'Department',
      'current_status_label': 'Current Status',
      'instant_speed_label': 'Instant Speed',
      'report_breakdown_immediate': 'Report Immediate Breakdown',
      'log_downtime_operational': 'Log Operational Downtime',

      // Downtime Report Sheet
      'downtime_logged_snack': 'Breakdown logged & work order sent for machine {code}!',
      'track_orders_btn': 'Track Orders',
      'downtime_wo_desc': 'Breakdown reported for machine {name} ({code}) - Dept: {dept}. Reason: {reason}',

      // Plant Overview & Extra Assets
      'tech_banner_elec': 'Electrical Maintenance Tech • Plant-wide Coverage',
      'tech_banner_mech': 'Mechanical Maintenance Tech • Plant-wide Coverage',
      'dept_machines_scope': 'Showing machines for: {dept}',
      'requires_action': 'Requires Action',
      'all_clear': 'All Clear',
      'no_dept_machines': 'No machines registered in {dept}',
      'no_machines_found': 'No machines found for this department.',

      // QR Scanner Screen
      'machine_not_found_snack': 'Machine code ({code}) is not registered in the system',
      'flash_toggle_tooltip': 'Toggle Flash',
      'camera_toggle_tooltip': 'Toggle Camera',
      'industrial_scanner_ready': 'Industrial Barcode Scanner Ready',
      'scanner_instruction': 'Scan machine QR plate with camera or enter code manually below.',
      'point_camera_at_barcode': 'Point camera at machine barcode plate',
      'manual_code_lookup_title': 'Or enter machine code manually:',
      'manual_code_hint': 'Enter machine code e.g. EXT-01, DR01...',
      'search_code_btn': 'Search',
      'chip_ext01': 'Extruder 90mm',
      'chip_dr01': 'Wire Drawing',
      'chip_rs01': 'Rigid Stranding',
      'chip_ext02': 'Sheathing Line',
      'chip_arm01': 'Wire Armouring',
      'chip_tb01': 'Tubular Stranding',

      // Technician Notifications Screen
      'please_login': 'Please log in',
      'notifications_center_title': 'Maintenance Notification Center',
      'maint_dept_speciality': 'Maintenance Dept • {spec}',
      'default_tech_title': 'Maintenance Tech',
      'new_tasks_badge': '{count} New Tasks',
      'ready_for_work': 'Ready for Work',
      'new_tickets_waiting': 'New tickets assigned to you awaiting start ({count})',
      'active_field_repairs': 'Active field repairs in progress ({count})',
      'repaired_orders_section': 'Repaired work orders ({count})',
      'no_tickets_assigned_tech': 'No work orders currently assigned to you',
      'no_tickets_assigned_sub': 'Real-time alerts will appear here as soon as the supervisor assigns a work order.',
      'priority_label': 'Priority: {priority}',
      'machine_label': 'Machine: {machine}',
      'details_btn': 'Details',
      'start_repair_btn': 'Start Repair',
      'repair_in_progress_banner': 'Machine: {machine} • Repair in progress',
      'track_btn': 'Track',

      // Create Repair Request Screen
      'no_machines_registered': 'No machines registered in the system',
      'wo_request_desc': 'Maintenance & repair request submitted for machine {code}',
      'wo_submitted_snack': 'Repair request submitted successfully for machine {code}!',
      'dept_machines_restricted': 'Machines in: {dept} (restricted to your department)',
      'select_machine_hint': 'Select the machine that is stopped or has a fault...',
      'type_priority_step': '2. Request Type & Priority',
      'request_type_label': 'Request Type',
      'severity_priority_label': 'Severity / Priority:',
      'quick_presets_step': '3. Quick Fault Presets',
      'fault_title_notes_step': '4. Fault Title & Notes',
      'fault_title_field': 'Fault Title *',
      'fault_title_error': 'Please enter the fault title',
      'additional_notes_field': 'Additional Description & Technician Notes',
      'submitting_request': 'Submitting Request...',
      'submit_work_order_btn': 'Submit Work Order',

      // Form Hints & Defaults
      'additional_notes_hint': 'Enter additional details about fault cause or observations...',
      'maint_tech_default': 'Maintenance Tech',
      'lang_arabic_label': 'Arabic',
      'lang_english_label': 'English',

      // Badge
      'plant_time_label': 'Plant Time: {time}',
      'prod_date_label': 'Production Date: {date}',
    },
    'ar': {
      // Header & Navigation
      'app_title': 'نظام صيانة مصنع الكابلات',
      'shift_manager': 'م. محمود علي',
      'shift_sub': 'الوردية الأولى • مدير تشغيل المصنع',
      'tab_factory': 'أرضية المصنع',
      'tab_work_orders': 'أوامر الصيانة',
      'tab_analytics': 'تحليلات OEE',
      'tab_my_tasks': 'مهامي المسندة',
      'tab_notifications': 'التنبيهات',
      'tab_executive': 'لوحة المؤشرات',
      'repair_request_btn': 'طلب إصلاح',
      'qr_scanner_btn': 'مسح QR',
      'theme_toggle': 'تبديل الوضع',
      'lang_toggle': 'English',
      'settings_title': 'الإعدادات والملف الشخصي',
      'profile_section': 'الملف الشخصي للمستخدم',
      'appearance_section': 'المظهر ونمط العرض',
      'accent_color_section': 'لون التطبيق الرئيسي (Accent Color)',
      'language_section': 'لغة النظام',
      'dark_mode': 'الوضع الداكن',
      'light_mode': 'الوضع الفاتح',
      'permissions_title': 'الصلاحيات المعتمدة لهذا الدور',
      'switch_account': 'تبديل الحساب',
      'app_version': 'إصدار نظام الصيانة',

      // Factory Floor KPIs
      'total_machines': 'إجمالي الماكينات',
      'running': 'قيد التشغيل',
      'active_downtime': 'ماكينات متوقفة',
      'all_departments': 'جميع الأقسام',
      'running_status': 'تعمل',
      'speed': 'السرعة',
      'production': 'الإنتاج',
      'report_issue': 'إبلاغ عن عطل',
      'view_downtime': 'سجل التوقف',

      // Work Orders
      'work_orders_title': 'أوامر الصيانة والتذاكر',
      'filter_all': 'الكل',
      'filter_open': 'مفتوحة',
      'filter_in_progress': 'قيد التنفيذ',
      'filter_completed': 'مكتملة',
      'new_repair_request': 'طلب إصلاح جديد',
      'no_work_orders': 'لا توجد أوامر صيانة في هذا القسم',
      'no_work_orders_sub': 'اضغط على الزر بالأسفل لتقديم بلاغ عطل جديد.',
      'machine': 'الماكينة',
      'priority': 'الأولوية',
      'status': 'الحالة',
      'create_wo_title': 'تقديم طلب إصلاح عطل',
      'track_orders': 'متابعة الطلبات',
      'select_machine': '1. اختيار الماكينة',
      'type_and_priority': '2. نوع الطلب والأولوية',
      'quick_presets': '3. أعطال متكررة جاهزة',
      'fault_details': '4. تفاصيل العطل والملاحظات',
      'fault_title_hint': 'مثال: انقطاع السلك في وحدة الساحب',
      'notes_hint': 'اكتب تفاصيل إضافية عن سبب العطل...',
      'submit_wo_btn': 'إرسال طلب الإصلاح',

      // Work Order Details
      'wo_timeline': 'مراحل ومسار تذكرة الصيانة',
      'wo_elapsed_time': 'زمن الإصلاح الفعلي الجاري (MTTR)',
      'technician_working': 'الفني يباشر أعمال الإصلاح...',
      'technician_completed': 'تم إنجاز الصيانة واختبار الماكينة',
      'spare_parts_title': 'قطع الغيار المستهلكة في العملية',
      'spare_part_hint': 'اسم القطعة (مثال: رولمان بلي 6205)',
      'root_cause_title': 'السبب الجذري وإجراءات الصيانة المنفذة',
      'root_cause_hint': 'تحليل السبب الجذري للعطل...',
      'actions_taken_hint': 'الإجراءات التي تم اتخاذها لإصلاح الماكينة...',
      'complete_wo_btn': 'إنهاء الصيانة وإعادة تشغيل الماكينة',

      // OEE Analytics
      'analytics_title': 'تحليلات كفاءة المصنع و OEE',
      'recalculate_btn': 'تحديث المؤشرات',
      'oee_overall_title': 'المؤشر العام للكفاءة التشغيلية OEE',
      'oee_overall_sub': 'Overall Equipment Effectiveness (OEE)',
      'oee_formula': 'المعادلة: الجاهزية التشغيلية × معدل الأداء × نسبة الجودة',
      'prod_output': 'الإنتاج الكلي',
      'total_downtime': 'إجمالي التوقف',
      'scrap_rate': 'نسبة الهالك',
      'parts_cost': 'تكلفة القطع',
      'oee_pillars': 'أعمدة كفاءة OEE الثلاثة (Availability • Performance • Quality)',
      'availability_title': 'الجاهزية التشغيلية (Availability)',
      'availability_sub': 'نسبة وقت التشغيل الفعلي مقارنة بالمخطط',
      'performance_title': 'معدل الأداء والسرعة (Performance)',
      'performance_sub': 'السرعة الفعلية مقارنة بالسرعة التصميمية القصوى',
      'quality_title': 'نسبة الجودة والمطابقة (Quality)',
      'quality_sub': 'أمتار الكابلات السليمة مقابل الهالك والخردة',
      'reliability_title': 'مؤشرات الاعتمادية الفنية للصيانة',
      'mttr_title': 'متوسط زمن الإصلاح (MTTR)',
      'mtbf_title': 'متوسط الوقت بين الأعطال (MTBF)',
      'downtime_pareto': 'تحليل باريتو لأسباب التوقف والأعطال',
      'downtime_pareto_sub': 'توزيع أسباب التوقفات وفواقد الإنتاج التراكمية',
      'dept_oee_title': 'مقارنة كفاءة الأقسام التشغيلية',
      'dept_machines_running': 'ماكينات نشطة',

      // QR Scanner
      'qr_scanner_title': 'قارئ الباركود و QR للماكينات',
      'qr_scanner_ready': 'الماسح الصناعي جاهز للالتقاط',
      'qr_point_camera': 'وجّه الكاميرا نحو لوحة QR المعدنية المثبتة على الماكينة',
      'manual_code_lookup': 'أو أدخل كود الماكينة يدوياً:',
      'search_btn': 'بحث',
      'machine_detected': 'تم التعرف على الماكينة بنجاح',
      'report_breakdown_btn': 'إبلاغ عن عطل (أمر صيانة)',
      'log_downtime_btn': 'تسجيل توقف مباشر',

      // Switch Persona Bottom Sheet
      'switch_persona_title': 'تبديل الحساب النشط (RBAC)',
      'switch_persona_sub': 'اختبار عرض الشاشات وصلاحيات الأزرار',
      'dept_users_header': 'مسؤولو الأقسام (7 أقسام)',
      'plant_wide_header': 'الإدارة العامة والفنيون',
      'switched_to_user': 'تم التحويل إلى {name} ({detail})',
      'open_settings_btn': 'فتح الإعدادات وتخصيص الألوان والثيم',

      // Settings Screen — Permissions
      'perm_log_downtime': 'تسجيل بلاغات الأعطال والتوقف',
      'perm_assign_tech': 'فرز وتوزيع التذاكر وتعيين الفنيين',
      'perm_start_repair': 'استلام التذكرة وبدء الإصلاح الميداني',
      'perm_spare_parts': 'تسجيل قطع الغيار المستهلكة',
      'perm_complete_repair': 'تسجيل السبب الجذري وإتمام الإصلاح',
      'perm_confirm_test': 'تأكيد اختبار التشغيل بخام الإنتاج',
      'perm_reclassify': 'إعادة تصنيف نوع العطل',
      'perm_approve_close': 'اعتماد وإغلاق أمر الصيانة نهائياً',
      'perm_view_analytics': 'استعراض تحليلات ومؤشرات المصنع',

      // Settings Screen — Extra
      'current_shift_label': 'الوردية الحالية: الوردية الأولى (نهار)',
      'accent_color_hint': 'اختر لون التطبيق الرئيسي المفضل لديك لتخصيص الأزرار والعناصر:',
      'hive_db_active': 'قاعدة بيانات محلية Hive Offline-First نشطة',
      'company_label': 'إنرجيا كابلز (السويدي هلال) • قطاع كابلات إنرجيا',

      // Work Orders List Screen
      'wo_screen_title': 'أوامر الصيانة والأعطال',
      'new_breakdown_tooltip': 'تقديم بلاغ عطل جديد',
      'more_btn': 'المزيد',
      'refresh_btn': 'تحديث',
      'dept_scope_label': 'نطاق القسم: {dept}',
      'dept_scope_sub': 'أنت مقيد برؤية ومتابعة تذاكر ماكينات قسمك فقط',
      'ticket_count': '{count} تذكرة',
      'plant_mgr_scope': 'رؤية مدير المصنع: متابعة شاملة لجميع تذاكر الأقسام السبعة',
      'tech_scope_electrical': 'مهام الصيانة الكهربائية المسندة إليك',
      'tech_scope_mechanical': 'مهام الصيانة الميكانيكية المسندة إليك',
      'tech_scope_sub': 'أنت مقيد برؤية الأعطال الموزعة عليك فقط من المهندس عبر المصنع بالكامل',
      'pending_assignments_msg': 'لديك {count} أمر صيانة جديد بانتظار استلامك وبدء الإصلاح.',
      'filter_all_label': 'الكل',
      'filter_pending_label': 'أعطال جديدة (Pending)',
      'filter_assigned_label': 'تم التعيين (Assigned)',
      'filter_in_progress_label': 'قيد الإصلاح (In Progress)',
      'filter_completed_label': 'تم الإصلاح (Completed)',
      'filter_verified_label': 'تم الاختبار (Verified)',
      'filter_closed_label': 'مغلقة (Closed)',
      'no_wo_tech': 'لا توجد أوامر صيانة مسندة إليك حالياً من المهندس المشرف',
      'no_wo_tech_sub': 'ستظهر هنا التذاكر فور قيام المهندس المشرف بتوزيعها وتكليفك بها.',
      'no_wo_dept': 'لا توجد أوامر صيانة لقسم {dept}',

      // Activity Timeline Widget
      'timeline_reported': 'إبلاغ عن عطل',
      'timeline_assigned': 'إسناد وتوجيه',
      'timeline_started': 'بدء الصيانة',
      'timeline_spare_part': 'إضافة قطعة غيار',
      'timeline_completed': 'اكتمال الإصلاح',
      'timeline_test_run': 'تشغيل تجريبي ناجح',
      'timeline_closed': 'اعتماد وإغلاق نهائي',
      'field_machine_code': 'كود الماكينة',
      'field_priority': 'درجة الأولوية',
      'field_type': 'نوع الطلب',
      'field_technician': 'الفني المسند',
      'field_supervisor': 'المشرف المسؤول',
      'field_start_time': 'بدء الإصلاح',
      'field_root_cause': 'السبب الجذري',
      'field_actions_taken': 'إجراءات الإصلاح',
      'field_part_no': 'رقم القطعة',
      'field_part_name': 'اسم القطعة',
      'field_qty': 'الكمية',
      'field_unit_price': 'سعر الوحدة',
      'field_spare_parts': 'قطع الغيار',
      'field_test_run': 'التشغيل التجريبي',
      'field_close_date': 'تاريخ الاعتماد',
      'audit_log_title': 'سجل تدقيق الأنشطة والعمليات',
      'audit_log_tamper_proof': 'سجل موثق ومشفر ضد التعديل',
      'sort_newest_first': 'الأحدث أولاً',
      'sort_oldest_first': 'الأقدم أولاً',
      'no_events_yet': 'لا توجد سجلات أحداث مسجلة بعد',
      'cross_shift_title': 'حالة استمرار العطل عبر الورديات',
      'cross_shift_start': '• نقطة البداية: بدأ في الساعة {time} ضمن [{shift}]',
      'cross_shift_extended': '• الامتداد: امتد إلى [{shift}] (مستمر منذ {time} - إجمالي {duration})',
      'cross_shift_oee_dist': 'توزيع دقائق التوقف لحسابات الـ OEE:',
      'shift_minutes': '{label}: {mins} دقيقة',
      'shift_1_short': 'وردية 1',
      'shift_2_short': 'وردية 2',
      'shift_3_short': 'وردية 3',
      'production_date_label': '• تاريخ الإنتاج: {date}',
      'time_label': 'الوقت: {time}',

      // OEE Analytics Screen
      'analytics_screen_title': 'تحليلات المصنع والـ OEE',
      'recalculate_tooltip': 'إعادة حساب المؤشرات',
      'oee_updated_snack': 'تم تحديث مؤشرات الفعالية OEE بنجاح',
      'computing_kpis': 'جاري حساب مؤشرات الأداء...',
      'all_depts_filter': 'جميع الأقسام',
      'prod_output_sub': 'إجمالي الإنتاج (كم)',
      'downtime_hours_sub': 'ساعات التوقف',
      'scrap_km_sub': 'هالك الإنتاج (كم)',
      'parts_cost_sub': 'تكلفة قطع الغيار',
      'oee_pillars_title': 'ركائز معادلة الـ OEE (Availability • Performance • Quality)',
      'availability_ar_sub': 'معدل التوافر والتشغيل الفعلي',
      'performance_ar_sub': 'كفاءة وسرعة خطوط الإنتاج',
      'quality_ar_sub': 'معدل جودة الكابلات السليمة',
      'reliability_kpis_title': 'مؤشرات اعتمادية الصيانة',
      'mttr_label': 'متوسط وقت الإصلاح',
      'mtbf_label': 'الوقت بين الأعطال',
      'minutes_unit': '{val} دقيقة',
      'hours_unit': '{val} ساعة',
      'dept_oee_compare': 'مقارنة كفاءة الأقسام',
      'dept_machines_info': 'الماكينات: {running}/{total} تعمل • إنتاج: {km} كم',

      // OEE Radial Gauge
      'oee_world_class': 'ممتاز (WORLD CLASS)',
      'oee_acceptable': 'مقبول (ACCEPTABLE)',
      'oee_attention': 'منخفض (ATTENTION)',
      'oee_gauge_title': 'معدل الفعالية الكلية للمعدات (OEE)',
      'oee_formula_label': 'الصيغة المعيارية: Availability × Performance × Quality',

      // Downtime Pareto Card
      'pareto_title': 'تحليل أسباب التوقف والأعطال (Pareto)',
      'total_hours': 'إجمالي: {val} ساعة',
      'minutes_pct': '{mins} دقيقة ({pct}%)',

      // Scanned Machine Sheet
      'machine_identified': 'تم التعرف على كود الماكينة بنجاح',
      'dept_label': 'القسم',
      'current_status_label': 'الحالة الحالية',
      'instant_speed_label': 'السرعة اللحظية',
      'report_breakdown_immediate': 'تقديم طلب إصلاح فوري',
      'log_downtime_operational': 'تسجيل توقف تشغيلي',

      // Downtime Report Sheet
      'downtime_logged_snack': 'تم تسجيل العطل وإرسال أمر الصيانة للماكينة {code}!',
      'track_orders_btn': 'متابعة الطلبات',
      'detailed_wo_btn': 'تقديم طلب إصلاح مفصل',
      'downtime_wo_desc': 'بلاغ عطل تم تقديمه للماكينة {name} ({code}) - القسم: {dept}. السبب: {reason}',

      // Plant Overview & Extra Assets
      'tech_banner_elec': 'فني صيانة كهربائية عامة • تغطية المصنع بالكامل',
      'tech_banner_mech': 'فني صيانة ميكانيكية عامة • تغطية المصنع بالكامل',
      'dept_machines_scope': 'عرض ماكينات قسم: {dept}',
      'requires_action': 'يتطلب إجراء',
      'all_clear': 'الحالة مستقرة',
      'no_dept_machines': 'لا توجد ماكينات مسجلة في قسم {dept}',
      'no_machines_found': 'لا توجد ماكينات مسجلة في هذا القسم.',

      // QR Scanner Screen
      'machine_not_found_snack': 'كود الماكينة ({code}) غير مسجل في قاعدة البيانات',
      'flash_toggle_tooltip': 'تشغيل الفلاش',
      'camera_toggle_tooltip': 'تبديل الكاميرا',
      'industrial_scanner_ready': 'ماسح الباركود الصناعي جاهز',
      'scanner_instruction': 'يمكنك مسح الكود بالكاميرا أو كتابة كود الماكينة أو النقر على الأكواد السريعة بالأسفل.',
      'point_camera_at_barcode': 'وجّه الكاميرا نحو باركود الماكينة',
      'manual_code_lookup_title': 'أو إدخال كود الماكينة يدوياً:',
      'manual_code_hint': 'اكتب كود الماكينة مثل: EXT-01, DR01...',
      'search_code_btn': 'بحث',
      'chip_ext01': 'إكسترودر 90 مم',
      'chip_dr01': 'سحب الأسلاك',
      'chip_rs01': 'جدل صلب',
      'chip_ext02': 'تغليف نهائي',
      'chip_arm01': 'تسليح أسلاك',
      'chip_tb01': 'جدل أنبوبي',

      // Technician Notifications Screen
      'please_login': 'يرجى تسجيل الدخول',
      'notifications_center_title': 'مركز تنبيهات الصيانة',
      'maint_dept_speciality': 'قسم الصيانة • {spec}',
      'default_tech_title': 'فني صيانة',
      'new_tasks_badge': '{count} مهام جديدة',
      'ready_for_work': 'جاهز للعمل',
      'new_tickets_waiting': 'تذاكر جديدة مُسندة إليك بانتظار البدء ({count})',
      'active_field_repairs': 'إصلاحات ميدانية جارية ({count})',
      'repaired_orders_section': 'أوامر صيانة تم إصلاحها ({count})',
      'no_tickets_assigned_tech': 'لا توجد أوامر صيانة مسندة إليك حالياً',
      'no_tickets_assigned_sub': 'ستصلك تنبيهات فورية هنا بمجرد أن يقوم المشرف بإسناد تذكرة صيانة لماكينة إلى تخصصك.',
      'priority_label': 'أولوية: {priority}',
      'machine_label': 'الماكينة: {machine}',
      'details_btn': 'التفاصيل',
      'start_repair_btn': 'بدء الإصلاح',
      'repair_in_progress_banner': 'الماكينة: {machine} • الإصلاح جارٍ الآن',
      'track_btn': 'متابعة',

      // Create Repair Request Screen
      'no_machines_registered': 'لا توجد ماكينات مسجلة في النظام',
      'wo_request_desc': 'طلب صيانة وإصلاح تم تقديمه للماكينة {code}',
      'wo_submitted_snack': 'تم تقديم طلب الإصلاح للماكينة {code} بنجاح!',
      'dept_machines_restricted': 'ماكينات قسم: {dept} (مقيد بماكينات قسمك)',
      'select_machine_hint': 'اختر الماكينة المتوقفة أو التي بها عطل...',
      'type_priority_step': '2. نوع الطلب ودرجة الأولوية',
      'request_type_label': 'نوع الطلب',
      'severity_priority_label': 'درجة الخطورة / الأولوية:',
      'quick_presets_step': '3. أعطال متكررة جاهزة',
      'fault_title_notes_step': '4. تفاصيل العطل والملاحظات',
      'fault_title_field': 'عنوان العطل *',
      'fault_title_error': 'يرجى كتابة عنوان العطل',
      'additional_notes_field': 'وصف إضافي وملاحظات الفني',
      'submitting_request': 'جاري إرسال الطلب...',
      'submit_work_order_btn': 'إرسال طلب الإصلاح',

      // Form Hints & Defaults
      'additional_notes_hint': 'اكتب تفاصيل إضافية عن سبب العطل أو المشاهدات...',
      'maint_tech_default': 'فني صيانة',
      'lang_arabic_label': 'العربية',
      'lang_english_label': 'الإنجليزية',

      // Badge
      'plant_time_label': 'توقيت المصنع: {time}',
      'prod_date_label': 'تاريخ الإنتاج: {date}',
    },
  };

  static String get(String key, String langCode) {
    return _localizedValues[langCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

extension AppStringsExtension on BuildContext {
  String tr(String key) {
    String langCode = 'en';
    try {
      langCode = read<LocaleCubit>().state.languageCode;
    } catch (_) {
      langCode = Localizations.maybeLocaleOf(this)?.languageCode ?? 'en';
    }
    return AppStrings.get(key, langCode);
  }

  /// Translate with placeholder replacement: {key} → value
  String trArgs(String key, Map<String, String> args) {
    String result = tr(key);
    args.forEach((k, v) {
      result = result.replaceAll('{$k}', v);
    });
    return result;
  }

  /// Read-only locale check (safe in callbacks and build methods alike)
  String trRead(String key) => tr(key);

  bool get isArabic {
    String langCode = 'en';
    try {
      langCode = read<LocaleCubit>().state.languageCode;
    } catch (_) {
      langCode = Localizations.maybeLocaleOf(this)?.languageCode ?? 'en';
    }
    return langCode == 'ar';
  }
}

