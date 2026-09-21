-- ==============================================================================
-- seed_demo.sql
-- Staging / Demo Fixtures: Sample Work Orders, Events, Parts & Downtime Logs
-- ==============================================================================

DO $$
DECLARE
  v_admin_id UUID;
  v_tech_id UUID;
  v_now TIMESTAMPTZ := NOW();
  v_wo1_id UUID := '00000001-0000-0000-0000-000000000001';
  v_wo2_id UUID := '00000002-0000-0000-0000-000000000002';
  v_wo3_id UUID := '00000003-0000-0000-0000-000000000003';
  v_wo4_id UUID := '00000004-0000-0000-0000-000000000004';
  v_dt1_id UUID := '00000005-0000-0000-0000-000000000001';
BEGIN
  -- Grab first available user for demo actor linkage
  SELECT id INTO v_admin_id FROM auth.users ORDER BY created_at ASC LIMIT 1;

  IF v_admin_id IS NULL THEN
    RAISE NOTICE 'Skipping seed_demo: No users found in auth.users. Create users first.';
    RETURN;
  END IF;

  v_tech_id := v_admin_id;

  -- 1. Demo Work Order: Open Breakdown on DR01
  INSERT INTO public.work_orders (
    id, title, description, machine_id, type, status, priority,
    reported_by, created_at, updated_at
  ) VALUES (
    v_wo1_id,
    'انقطاع مفاجئ في كابل التغذية الرئيسي لمحرك السحب',
    'توقف خط سحب النحاس 01 بسبب شرارة في لوحة القواطع الرئيسية.',
    'DR01', 'breakdown', 'open', 'critical',
    v_admin_id, v_now - INTERVAL '3 hours', v_now - INTERVAL '3 hours'
  ) ON CONFLICT (id) DO NOTHING;

  -- 2. Demo Work Order: In-Progress on EX01
  INSERT INTO public.work_orders (
    id, title, description, machine_id, type, status, priority,
    reported_by, assigned_to_technician_id, assigned_by_supervisor_id,
    created_at, started_at, updated_at
  ) VALUES (
    v_wo2_id,
    'تذبذب قراءة حساس الحرارة Zone 3 برأس البثق',
    'يلزم فحص التوصيلات الكهربائية واستبدال الثيرموكبل إن تطلب الأمر.',
    'EX01', 'corrective', 'inProgress', 'high',
    v_admin_id, v_tech_id, v_admin_id,
    v_now - INTERVAL '2 hours', v_now - INTERVAL '1 hour', v_now - INTERVAL '1 hour'
  ) ON CONFLICT (id) DO NOTHING;

  -- 3. Demo Parts consumed on EX01
  INSERT INTO public.work_order_parts (
    id, work_order_id, part_code, part_name, quantity, unit_cost, added_by, occurred_at, received_at
  ) VALUES (
    gen_random_uuid(),
    v_wo2_id,
    'THC-PT100-3M',
    'حساس حرارة بلاتينيوم PT100 كابل 3 متر',
    1,
    45.00,
    v_admin_id,
    v_now - INTERVAL '45 minutes',
    v_now - INTERVAL '45 minutes'
  ) ON CONFLICT (id) DO NOTHING;

  -- 4. Demo Work Order: Completed / Test-Run on RS01
  INSERT INTO public.work_orders (
    id, title, description, machine_id, type, status, priority,
    reported_by, assigned_to_technician_id, assigned_by_supervisor_id,
    created_at, started_at, completed_at, root_cause, actions_taken, updated_at
  ) VALUES (
    v_wo3_id,
    'صيانة وتغيير رولمان بلي قفص الجدل الرئيسي',
    'صوت احتكاك غير طبيعي واهتزاز متصاعد في الكرسي الحامل لقفص 61 سلك.',
    'RS01', 'breakdown', 'completed', 'critical',
    v_admin_id, v_tech_id, v_admin_id,
    v_now - INTERVAL '5 hours', v_now - INTERVAL '4 hours', v_now - INTERVAL '30 minutes',
    'جفاف الشحم وتآكل كرات المحمل نتيجة تشغيل متواصل',
    'استبدال رولمان البلي الأصلي وإعادة وزن المحاذاة والتشحيم الهيدروليكي',
    v_now - INTERVAL '30 minutes'
  ) ON CONFLICT (id) DO NOTHING;

  -- 5. Demo Downtime Log on DR01
  INSERT INTO public.downtime_logs (
    id, machine_id, work_order_id, category, reason, is_maintenance_requested,
    comments, started_at, production_date, shift_minutes, created_by, updated_at
  ) VALUES (
    v_dt1_id,
    'DR01',
    v_wo1_id,
    'Electrical Breakdown',
    'شرارة في القاطع الرئيسي لمحرك السحب',
    TRUE,
    'تم إبلاغ الصيانة الكهربائية فوراً وفتح طلب عمل',
    v_now - INTERVAL '3 hours',
    CURRENT_DATE,
    '{"morning": 180}'::jsonb,
    v_admin_id,
    v_now - INTERVAL '3 hours'
  ) ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'seed_demo completed successfully.';
END;
$$;
