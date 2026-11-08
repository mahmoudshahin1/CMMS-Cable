-- Production compatibility follow-up for the drifted hosted schema.
--
-- The hosted project has newer write-RPC signatures than the compact local
-- baseline. This migration deliberately avoids replacing those functions
-- with older overloads: it hardens every existing overload by OID, adds the
-- missing voice-note attachment RPC, and preserves the hosted
-- rpc_confirm_test_run outcome/department behavior while moving auth before
-- the idempotency read.

UPDATE storage.buckets
SET allowed_mime_types = ARRAY[
  'image/jpeg', 'image/png', 'image/webp',
  'audio/mp4', 'audio/mpeg', 'audio/aac', 'audio/wav', 'audio/ogg'
]
WHERE id = 'work-order-attachments';

-- The hosted policies were using the machine name when extracting the first
-- storage path segment. Voice uploads use <work-order-id>/..., so keep the
-- existing policy names but evaluate storage.objects.name instead.
DROP POLICY IF EXISTS "Authenticated users view work order attachments" ON storage.objects;
CREATE POLICY "Authenticated users view work order attachments"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'work-order-attachments'
  AND EXISTS (
    SELECT 1
    FROM public.work_orders wo
    JOIN public.machines m ON m.id = wo.machine_id
    WHERE wo.id::text = split_part(name, '/', 1)
      AND (
        private.current_app_role() IN (
          'ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager',
          'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR',
          'maintenance_supervisor'
        )
        OR m.department = private.current_app_department()
        OR wo.assigned_to_technician_id = auth.uid()
        OR wo.reported_by = auth.uid()
      )
  )
);

DROP POLICY IF EXISTS "Authorized staff upload work order attachments" ON storage.objects;
CREATE POLICY "Authorized staff upload work order attachments"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'work-order-attachments'
  AND EXISTS (
    SELECT 1
    FROM public.work_orders wo
    JOIN public.machines m ON m.id = wo.machine_id
    WHERE wo.id::text = split_part(name, '/', 1)
      AND (
        private.current_app_role() IN (
          'ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager',
          'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR',
          'maintenance_supervisor'
        )
        OR m.department = private.current_app_department()
        OR wo.assigned_to_technician_id = auth.uid()
        OR wo.reported_by = auth.uid()
      )
  )
);

DROP POLICY IF EXISTS "Authorized staff update work order attachments" ON storage.objects;
CREATE POLICY "Authorized staff update work order attachments"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'work-order-attachments'
  AND EXISTS (
    SELECT 1
    FROM public.work_orders wo
    JOIN public.machines m ON m.id = wo.machine_id
    WHERE wo.id::text = split_part(name, '/', 1)
      AND (
        private.current_app_role() IN (
          'ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager',
          'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR',
          'maintenance_supervisor'
        )
        OR m.department = private.current_app_department()
        OR wo.assigned_to_technician_id = auth.uid()
        OR wo.reported_by = auth.uid()
      )
  )
)
WITH CHECK (
  bucket_id = 'work-order-attachments'
  AND EXISTS (
    SELECT 1
    FROM public.work_orders wo
    JOIN public.machines m ON m.id = wo.machine_id
    WHERE wo.id::text = split_part(name, '/', 1)
      AND (
        private.current_app_role() IN (
          'ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager',
          'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR',
          'maintenance_supervisor'
        )
        OR m.department = private.current_app_department()
        OR wo.assigned_to_technician_id = auth.uid()
        OR wo.reported_by = auth.uid()
      )
  )
);

CREATE OR REPLACE FUNCTION public.rpc_attach_work_order_voice_note(
  p_command_id UUID,
  p_wo_id UUID,
  p_voice_note_url TEXT,
  p_occurred_at TIMESTAMPTZ DEFAULT NOW()
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_existing_cmd JSONB;
  v_work_order public.work_orders%ROWTYPE;
  v_result JSONB;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  SELECT result INTO v_existing_cmd
  FROM public.work_order_commands
  WHERE command_id = p_command_id;
  IF v_existing_cmd IS NOT NULL THEN
    RETURN v_existing_cmd;
  END IF;

  IF p_voice_note_url IS NULL OR
     split_part(p_voice_note_url, '/', 1) <> p_wo_id::text THEN
    RAISE EXCEPTION 'FORBIDDEN: Voice note path does not match work order' USING errcode = '42501';
  END IF;

  SELECT * INTO v_work_order
  FROM public.work_orders
  WHERE id = p_wo_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: Work order does not exist' USING errcode = 'P0002';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM storage.objects
    WHERE bucket_id = 'work-order-attachments'
      AND name = p_voice_note_url
  ) THEN
    RAISE EXCEPTION 'NOT_FOUND: Uploaded voice note does not exist' USING errcode = 'P0002';
  END IF;

  IF v_work_order.reported_by <> v_caller_id
     AND v_work_order.assigned_to_technician_id <> v_caller_id
     AND private.current_app_role() NOT IN (
       'ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager', 'SUPERVISOR',
       'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor'
     ) THEN
    RAISE EXCEPTION 'FORBIDDEN: Caller cannot attach voice note to work order' USING errcode = '42501';
  END IF;

  UPDATE public.work_orders
  SET voice_note_url = p_voice_note_url,
      updated_at = NOW()
  WHERE id = p_wo_id;

  SELECT to_jsonb(w) INTO v_result
  FROM public.work_orders w
  WHERE w.id = p_wo_id;

  INSERT INTO public.work_order_events (
    id, work_order_id, command_id, event_type, actor_id,
    occurred_at, received_at, old_status, new_status, payload
  ) VALUES (
    gen_random_uuid(), p_wo_id, p_command_id, 'VOICE_NOTE_ATTACHED', v_caller_id,
    p_occurred_at, NOW(), v_work_order.status, v_work_order.status,
    jsonb_build_object('voice_note_url', p_voice_note_url)
  );

  INSERT INTO public.work_order_commands (
    command_id, work_order_id, command_type, actor_id, created_at, processed_at, result
  ) VALUES (
    p_command_id, p_wo_id, 'ATTACH_WORK_ORDER_VOICE_NOTE', v_caller_id,
    p_occurred_at, NOW(), v_result
  );

  RETURN v_result;
END;
$$;

-- Recreate the hosted outcome-aware function with authentication before the
-- idempotency read. All outcome, department, audit, and bounce-back behavior
-- remains unchanged from the currently deployed definition.
CREATE OR REPLACE FUNCTION public.rpc_confirm_test_run(
  p_command_id UUID,
  p_wo_id UUID,
  p_expected_version INT,
  p_outcome TEXT DEFAULT 'fixed',
  p_comments TEXT DEFAULT NULL,
  p_confirmed_downtime_minutes INT DEFAULT NULL,
  p_device_id TEXT DEFAULT NULL,
  p_app_version TEXT DEFAULT NULL,
  p_occurred_at TIMESTAMPTZ DEFAULT NOW()
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_role TEXT;
  v_caller_department TEXT;
  v_machine_department TEXT;
  v_existing_cmd JSONB;
  v_current_wo RECORD;
  v_next_status TEXT;
  v_check_entry JSONB;
  v_result JSONB;
  v_server_time TIMESTAMPTZ := NOW();
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  SELECT role, department INTO v_role, v_caller_department
  FROM public.user_profiles WHERE id = v_caller_id;

  IF v_role NOT IN ('OPERATOR', 'PRODUCTION_SUPERVISOR') THEN
    RAISE EXCEPTION 'FORBIDDEN: Only Line Operators or Production Supervisors can confirm field test runs' USING errcode = '42501';
  END IF;

  SELECT result INTO v_existing_cmd
  FROM public.work_order_commands
  WHERE command_id = p_command_id;
  IF v_existing_cmd IS NOT NULL THEN
    RETURN v_existing_cmd;
  END IF;

  IF p_outcome NOT IN ('fixed', 'needs_followup', 'not_fixed') THEN
    RAISE EXCEPTION 'INVALID_ARGUMENT: p_outcome must be fixed, needs_followup, or not_fixed' USING errcode = 'P0001';
  END IF;

  IF p_outcome IN ('needs_followup', 'not_fixed')
     AND NULLIF(TRIM(COALESCE(p_comments, '')), '') IS NULL THEN
    RAISE EXCEPTION 'INVALID_ARGUMENT: Comments are required when outcome is needs_followup or not_fixed' USING errcode = 'P0001';
  END IF;

  SELECT * INTO v_current_wo
  FROM public.work_orders
  WHERE id = p_wo_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: Work order % not found', p_wo_id USING errcode = 'P0002';
  END IF;

  SELECT department INTO v_machine_department
  FROM public.machines WHERE id = v_current_wo.machine_id;
  IF v_caller_department IS NULL OR v_machine_department IS NULL
     OR v_caller_department <> v_machine_department THEN
    RAISE EXCEPTION 'FORBIDDEN: You can only confirm test runs for machines in your own department' USING errcode = '42501';
  END IF;

  IF v_current_wo.version <> p_expected_version THEN
    RAISE EXCEPTION 'CONFLICT: Version mismatch (current: %, expected: %)', v_current_wo.version, p_expected_version
      USING errcode = '40001';
  END IF;
  IF v_current_wo.status <> 'completed' THEN
    RAISE EXCEPTION 'ILLEGAL_STATE: Cannot confirm test run when status is % (must be completed)', v_current_wo.status
      USING errcode = 'P0001';
  END IF;

  v_next_status := CASE WHEN p_outcome = 'fixed' THEN 'verified' ELSE 'inProgress' END;
  v_check_entry := jsonb_build_object(
    'at', v_server_time, 'by', v_caller_id, 'outcome', p_outcome,
    'notes', p_comments, 'confirmed_downtime_minutes', p_confirmed_downtime_minutes
  );

  UPDATE public.work_orders
  SET status = v_next_status, checks = checks || v_check_entry,
      version = version + 1, updated_at = v_server_time
  WHERE id = p_wo_id;

  INSERT INTO public.work_order_events (
    id, work_order_id, command_id, event_type, actor_id,
    occurred_at, received_at, old_status, new_status, payload, device_id, app_version
  ) VALUES (
    gen_random_uuid(), p_wo_id, p_command_id,
    CASE WHEN p_outcome = 'fixed' THEN 'TEST_RUN_PASSED' ELSE 'TEST_RUN_REJECTED' END,
    v_caller_id, p_occurred_at, v_server_time, 'completed', v_next_status,
    v_check_entry, p_device_id, p_app_version
  );

  SELECT to_jsonb(w) INTO v_result FROM public.work_orders w WHERE w.id = p_wo_id;
  INSERT INTO public.work_order_commands (
    command_id, work_order_id, command_type, actor_id, created_at, processed_at, result
  ) VALUES (
    p_command_id, p_wo_id, 'CONFIRM_TEST_RUN', v_caller_id,
    p_occurred_at, v_server_time, v_result
  );
  RETURN v_result;
END;
$$;

-- Re-assert grants for every currently installed overload without assuming
-- the hosted schema has the local function signatures.
DO $$
DECLARE
  v_signature TEXT;
BEGIN
  FOR v_signature IN
    SELECT p.oid::regprocedure::text
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'rpc_create_work_order', 'rpc_assign_work_order',
        'rpc_start_work_order', 'rpc_add_work_order_part',
        'rpc_complete_work_order', 'rpc_confirm_test_run',
        'rpc_close_work_order', 'rpc_attach_work_order_voice_note',
        'rpc_create_downtime_log', 'rpc_close_downtime_log'
      )
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon', v_signature);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_signature);
  END LOOP;
END;
$$;
