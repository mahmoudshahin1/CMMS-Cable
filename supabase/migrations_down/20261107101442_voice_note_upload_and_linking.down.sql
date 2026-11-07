-- Remove voice-note upload behavior. Keep work_orders.voice_note_url because
-- the column may predate this migration on the hosted database and can contain
-- valid existing object paths.
DROP FUNCTION IF EXISTS public.rpc_attach_work_order_voice_note(
  UUID, UUID, TEXT, TIMESTAMPTZ
);
DROP POLICY IF EXISTS "Authorized staff update work order attachments"
  ON storage.objects;

UPDATE storage.buckets
SET allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']
WHERE id = 'work-order-attachments';

DROP FUNCTION IF EXISTS public.rpc_create_work_order(
  UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ
);

CREATE FUNCTION public.rpc_create_work_order(
  p_command_id UUID,
  p_wo_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_machine_id TEXT,
  p_type TEXT,
  p_priority TEXT,
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
  v_dept TEXT;
  v_machine_dept TEXT;
  v_existing_cmd JSONB;
  v_result JSONB;
  v_server_time TIMESTAMPTZ := NOW();
BEGIN
  SELECT result INTO v_existing_cmd
  FROM public.work_order_commands WHERE command_id = p_command_id;
  IF v_existing_cmd IS NOT NULL THEN RETURN v_existing_cmd; END IF;
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  SELECT role, department INTO v_role, v_dept
  FROM public.user_profiles WHERE id = v_caller_id;
  SELECT department INTO v_machine_dept
  FROM public.machines WHERE id = p_machine_id;
  IF v_machine_dept IS NULL THEN
    RAISE EXCEPTION 'NOT_FOUND: Machine % does not exist', p_machine_id USING errcode = 'P0002';
  END IF;
  IF v_role = 'OPERATOR' THEN
    IF v_dept IS DISTINCT FROM v_machine_dept THEN
      RAISE EXCEPTION 'FORBIDDEN: Operators can only report for their own department machines' USING errcode = '42501';
    END IF;
  ELSIF v_role NOT IN ('SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR',
                       'maintenance_supervisor', 'PRODUCTION_SUPERVISOR',
                       'production_supervisor', 'ADMIN', 'admin',
                       'PLANT_MANAGER', 'plant_manager') THEN
    RAISE EXCEPTION 'FORBIDDEN: Role % cannot create work orders', v_role USING errcode = '42501';
  END IF;

  INSERT INTO public.work_orders (
    id, title, description, machine_id, type, status, priority,
    reported_by, created_at, version, updated_at
  ) VALUES (
    p_wo_id, p_title, p_description, p_machine_id, p_type, 'open', p_priority,
    v_caller_id, v_server_time, 1, v_server_time
  );
  INSERT INTO public.work_order_events (
    id, work_order_id, command_id, event_type, actor_id,
    occurred_at, received_at, old_status, new_status, payload, device_id, app_version
  ) VALUES (
    gen_random_uuid(), p_wo_id, p_command_id, 'REPORTED', v_caller_id,
    p_occurred_at, v_server_time, NULL, 'open',
    jsonb_build_object('title', p_title, 'type', p_type, 'priority', p_priority),
    p_device_id, p_app_version
  );
  SELECT to_jsonb(w) INTO v_result FROM public.work_orders w WHERE w.id = p_wo_id;
  INSERT INTO public.work_order_commands (
    command_id, work_order_id, command_type, actor_id, created_at, processed_at, result
  ) VALUES (
    p_command_id, p_wo_id, 'CREATE_WORK_ORDER', v_caller_id,
    p_occurred_at, v_server_time, v_result
  );
  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rpc_create_work_order(
  UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rpc_create_work_order(
  UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ
) TO authenticated;
