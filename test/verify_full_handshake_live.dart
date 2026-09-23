// ignore_for_file: avoid_print, depend_on_referenced_packages
import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  print('================================================================');
  print('⚡ CABLE OPS CMMS — VERIFYING 5-STEP HANDSHAKE LIFECYCLE ON SUPABASE');
  print('================================================================\n');

  const projectUrl = 'https://ptlzpwfrrxfqfprkvbuf.supabase.co';
  const anonKey = 'sb_publishable_EejIRNDd-fW5B60sgLKtWA_n5VQWwKt';

  // Client 1: Operator (Drawing Line: op.drawing@cable.com)
  final opClient = SupabaseClient(projectUrl, anonKey);
  // Client 2: Supervisor (eng.maint@cable.com)
  final supClient = SupabaseClient(projectUrl, anonKey);
  // Client 3: Electric Technician (tech.elec@cable.com)
  final techClient = SupabaseClient(projectUrl, anonKey);

  try {
    print('🔑 [0/7] Authenticating 3 Personas with Supabase Auth...');
    final opAuth = await opClient.auth.signInWithPassword(email: 'op.drawing@cable.com', password: '123456');
    final supAuth = await supClient.auth.signInWithPassword(email: 'eng.maint@cable.com', password: '123456');
    final techAuth = await techClient.auth.signInWithPassword(email: 'tech.elec@cable.com', password: '123456');

    final opId = opAuth.user!.id;
    final supId = supAuth.user!.id;
    final techId = techAuth.user!.id;

    print('   - المشغل: أحمد سعيد ($opId)');
    print('   - مشرف الصيانة: م. هشام راضي ($supId)');
    print('   - فني الكهرباء: طارق المنصور ($techId)\n');

    final testWoId = '33333333-4444-5555-6666-777777777777';
    final machineId = 'DR02'; // خط سحب نحاس 02

    // -------------------------------------------------------------
    // STAGE 1: Report Breakdown (المشغل يفتح بلاغ عطل)
    // -------------------------------------------------------------
    print('📝 [1/7] المرحلة 1: المشغل يفتح بلاغ عطل طارئ على ماكينة $machineId...');
    final cmd1 = '10000000-0000-0000-0000-000000000001';
    final res1 = await opClient.rpc('rpc_create_work_order', params: {
      'p_command_id': cmd1,
      'p_wo_id': testWoId,
      'p_title': 'عطل توقف محرك السحب الرئيسي Line 02',
      'p_description': 'توقف مفاجئ في الموتور الرئيسي مع تصاعد دخان ورائحة احتراق.',
      'p_machine_id': machineId,
      'p_type': 'breakdown',
      'p_priority': 'critical',
      'p_device_id': 'op-tablet-01',
      'p_app_version': '1.0.0',
    });
    print('   ✅ تم إنشاء أمر العمل في جدول work_orders (الحالة: ${res1['status']}, النسخة: ${res1['version']})');

    // Check machine status
    final m1 = await opClient.from('machines').select('status').eq('id', machineId).single();
    print('   ⚡ حالة الماكينة في جدول machines تحولت تلقائياً إلى: ${m1['status']}\n');

    // -------------------------------------------------------------
    // STAGE 2: Assign Technician (مشرف الصيانة يعين الفني)
    // -------------------------------------------------------------
    print('📋 [2/7] المرحلة 2: مشرف الصيانة يعيّن فني الكهرباء طارق المنصور...');
    final cmd2 = '10000000-0000-0000-0000-000000000002';
    final res2 = await supClient.rpc('rpc_assign_work_order', params: {
      'p_command_id': cmd2,
      'p_wo_id': testWoId,
      'p_expected_version': res1['version'],
      'p_technician_id': techId,
      'p_device_id': 'sup-laptop-01',
      'p_app_version': '1.0.0',
    });
    print('   ✅ تم تحديث أمر العمل في قاعدة البيانات (الحالة: ${res2['status']}, الفني: $techId, النسخة: ${res2['version']})\n');

    // -------------------------------------------------------------
    // STAGE 3: Start Repair (فني الكهرباء يبدأ أعمال الصيانة)
    // -------------------------------------------------------------
    print('🔧 [3/7] المرحلة 3: فني الكهرباء يسجل بدء أعمال الإصلاح...');
    final cmd3 = '10000000-0000-0000-0000-000000000003';
    final res3 = await techClient.rpc('rpc_start_work_order', params: {
      'p_command_id': cmd3,
      'p_wo_id': testWoId,
      'p_expected_version': res2['version'],
      'p_device_id': 'tech-mobile-01',
      'p_app_version': '1.0.0',
    });
    print('   ✅ تم تحديث أمر العمل في قاعدة البيانات (الحالة: ${res3['status']}, بدأ في: ${res3['started_at']}, النسخة: ${res3['version']})');

    final m3 = await techClient.from('machines').select('status').eq('id', machineId).single();
    print('   ⚡ حالة الماكينة في جدول machines تحولت تلقائياً إلى: ${m3['status']}\n');

    // -------------------------------------------------------------
    // STAGE 4: Add Spare Part (الفني يسجل استهلاك قطعة غيار من المخزن)
    // -------------------------------------------------------------
    print('📦 [4/7] المرحلة 4: الفني يسجل استبدال حساس حرارة PT100 من المخزن...');
    final cmd4 = '10000000-0000-0000-0000-000000000004';
    final partId = '44444444-1111-2222-3333-444444444444';
    final res4 = await techClient.rpc('rpc_add_work_order_part', params: {
      'p_command_id': cmd4,
      'p_part_id': partId,
      'p_wo_id': testWoId,
      'p_part_code': 'THC-PT100-3M',
      'p_part_name': 'حساس حرارة بلاتينيوم PT100 كابل 3 متر',
      'p_quantity': 1,
      'p_unit_cost': 45.00,
      'p_device_id': 'tech-mobile-01',
      'p_app_version': '1.0.0',
    });
    print('   ✅ تم تسجيل قطعة الغيار في جدول work_order_parts (القطعة: ${res4['part_name']}, الكمية: ${res4['quantity']})\n');

    // -------------------------------------------------------------
    // STAGE 5: Complete Repair (الفني يوثق السبب والإجراء وينهي الإصلاح)
    // -------------------------------------------------------------
    print('🛠️ [5/7] المرحلة 5: الفني يوثق السبب الجذري والإجراء المتخذ وينهي الإصلاح...');
    final cmd5 = '10000000-0000-0000-0000-000000000005';
    final res5 = await techClient.rpc('rpc_complete_work_order', params: {
      'p_command_id': cmd5,
      'p_wo_id': testWoId,
      'p_expected_version': res3['version'],
      'p_root_cause': 'تلف حساس الحرارة PT100 أدى إلى ارتفاع حرارة الموتور وفصل القاطع الأوتوماتيكي.',
      'p_actions_taken': 'تم استبدال حساس الحرارة التالف وضبط إعدادات حماية الانفرتر وإعادة تشغيل الدائرة الكهربائية.',
      'p_device_id': 'tech-mobile-01',
      'p_app_version': '1.0.0',
    });
    print('   ✅ تم تحديث أمر العمل (الحالة: ${res5['status']}, السبب: ${res5['root_cause']}, النسخة: ${res5['version']})\n');

    // -------------------------------------------------------------
    // STAGE 6: Confirm Test Run (المشغل يؤكد نجاح تجربة التشغيل الميداني)
    // -------------------------------------------------------------
    print('🎯 [6/7] المرحلة 6: المشغل يؤكد نجاح اختبار التشغيل الميداني للماكينة...');
    final cmd6 = '10000000-0000-0000-0000-000000000006';
    final res6 = await opClient.rpc('rpc_confirm_test_run', params: {
      'p_command_id': cmd6,
      'p_wo_id': testWoId,
      'p_expected_version': res5['version'],
      'p_comments': 'تم تشغيل الخط بنجاح لمدة 15 دقيقة وسحب 500 متر سلك دون أي اهتزاز أو حرارة.',
      'p_device_id': 'op-tablet-01',
      'p_app_version': '1.0.0',
    });
    print('   ✅ تم تحديث أمر العمل في قاعدة البيانات (الحالة: ${res6['status']}, النسخة: ${res6['version']})\n');

    // -------------------------------------------------------------
    // STAGE 7: Verified Close (مشرف الصيانة يغلق أمر العمل رسمياً)
    // -------------------------------------------------------------
    print('🏁 [7/7] المرحلة 7: مشرف الصيانة يصادق ويغلق أمر العمل نهائياً...');
    final cmd7 = '10000000-0000-0000-0000-000000000007';
    final res7 = await supClient.rpc('rpc_close_work_order', params: {
      'p_command_id': cmd7,
      'p_wo_id': testWoId,
      'p_expected_version': res6['version'],
      'p_comments': 'تمت المراجعة والاعتماد الفني، الماكينة جاهزة للإنتاج بكامل طاقتها.',
      'p_device_id': 'sup-laptop-01',
      'p_app_version': '1.0.0',
    });
    print('   ✅ تم إغلاق أمر العمل في قاعدة البيانات (الحالة: ${res7['status']}, النسخة: ${res7['version']}, أُغلق في: ${res7['closed_at']})');

    final m7 = await supClient.from('machines').select('status').eq('id', machineId).single();
    print('   ⚡ حالة الماكينة في جدول machines عادت تلقائياً إلى: ${m7['status']}\n');

    // -------------------------------------------------------------
    // AUDIT TRAIL VERIFICATION
    // -------------------------------------------------------------
    print('📊 التحقق من سجل التدقيق الزمني الكامل (Audit Events):');
    final events = await supClient
        .from('work_order_events')
        .select('event_type, old_status, new_status, received_at')
        .eq('work_order_id', testWoId)
        .order('received_at', ascending: true);

    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      print('   ${i + 1}. الحدث: [${e['event_type']}] (${e['old_status']} ➔ ${e['new_status']}) بتوقيت: ${e['received_at']}');
    }

    print('\n🎉 النتيجة النهائية: دورة حياة أمر العمل مكتملة 100%، وتم تسجيل ومزامنة جميع المراحل مع قاعدة بيانات Supabase بنجاح باهر!');
    exit(0);
  } catch (e, st) {
    print('❌ حدث خطأ أثناء التحقق: $e');
    print(st);
    exit(1);
  }
}
