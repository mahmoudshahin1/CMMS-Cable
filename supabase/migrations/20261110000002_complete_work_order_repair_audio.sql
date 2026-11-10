-- Persist the structured repair details and private Storage key supplied by the
-- mobile completion Outbox. This overload extends the local RPC contract while
-- retaining the original overload for older clients.
DO $$
BEGIN
  IF to_regprocedure(
    'public.rpc_complete_work_order(uuid,uuid,integer,text,text,jsonb,text,text,text,timestamp with time zone)'
  ) IS NOT NULL THEN
    RAISE EXCEPTION 'The repair-audio completion RPC signature already exists; inspect it before applying this migration.';
  END IF;
END;
$$;

ALTER TABLE public.work_orders
  ADD COLUMN IF NOT EXISTS repair_steps JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS repair_voice_url TEXT;

CREATE FUNCTION public.rpc_complete_work_order(
  p_command_id UUID,
  p_wo_id UUID,
  p_expected_version INT,
  p_root_cause TEXT,
  p_actions_taken TEXT,
  p_repair_steps JSONB,
  p_repair_voice_url TEXT,
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
  v_existing_cmd JSONB;
  v_current_wo RECORD;
  v_result JSONB;
  v_server_time TIMESTAMPTZ := NOW();
  v_saved_repair_voice_url TEXT;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  SELECT role INTO v_role
  FROM public.user_profiles
  WHERE id = v_caller_id;

  IF v_role NOT IN ('TECHNICIAN', 'technician', 'MAINTENANCE_TECH', 'maintenance_tech') THEN
    RAISE EXCEPTION 'FORBIDDEN: Only Maintenance Technicians can complete repair' USING errcode = '42501';
  END IF;

  SELECT result INTO v_existing_cmd
  FROM public.work_order_commands
  WHERE command_id = p_command_id;
  IF v_existing_cmd IS NOT NULL THEN
    RETURN v_existing_cmd;
  END IF;

  IF NULLIF(TRIM(p_root_cause), '') IS NULL
     OR NULLIF(TRIM(p_actions_taken), '') IS NULL THEN
    RAISE EXCEPTION 'INVALID_ARGUMENT: Both root_cause and actions_taken are required' USING errcode = 'P0001';
  END IF;
  IF p_repair_steps IS NULL OR jsonb_typeof(p_repair_steps) <> 'array' THEN
    RAISE EXCEPTION 'INVALID_ARGUMENT: p_repair_steps must be a JSON array' USING errcode = 'P0001';
  END IF;

  IF p_repair_voice_url IS NOT NULL THEN
    IF p_repair_voice_url LIKE '%?%'
       OR p_repair_voice_url LIKE '%#%'
       OR POSITION(CHR(92) IN p_repair_voice_url) > 0
       OR p_repair_voice_url ~ '(^|/)\.\.?(/|$)'
       OR NOT (
         p_repair_voice_url ~* ('^' || p_wo_id::text || '/repair-voice-notes/[^/]+\.(m4a|mp3|aac|wav|ogg)$')
         OR p_repair_voice_url ~* ('^voice-notes/' || p_wo_id::text || '/[^/]+\.(m4a|mp3|aac|wav|ogg)$')
       ) THEN
      RAISE EXCEPTION 'INVALID_ARGUMENT: Repair audio must use a work-order-scoped Storage key' USING errcode = 'P0001';
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM storage.objects
      WHERE bucket_id = 'work-order-attachments'
        AND name = p_repair_voice_url
    ) THEN
      RAISE EXCEPTION 'NOT_FOUND: Repair audio is not present in private Storage' USING errcode = 'P0002';
    END IF;
  END IF;

  SELECT * INTO v_current_wo
  FROM public.work_orders
  WHERE id = p_wo_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: Work order % not found', p_wo_id USING errcode = 'P0002';
  END IF;

  IF v_current_wo.version <> p_expected_version THEN
    RAISE EXCEPTION 'CONFLICT: Version mismatch (current: %, expected: %)', v_current_wo.version, p_expected_version
      USING errcode = '40001';
  END IF;
  IF v_current_wo.assigned_to_technician_id <> v_caller_id THEN
    RAISE EXCEPTION 'FORBIDDEN: You are not assigned to this work order' USING errcode = '42501';
  END IF;
  IF v_current_wo.status NOT IN ('inProgress', 'pendingParts') THEN
    RAISE EXCEPTION 'ILLEGAL_STATE: Cannot complete repair from status %', v_current_wo.status USING errcode = 'P0001';
  END IF;

  v_saved_repair_voice_url := COALESCE(p_repair_voice_url, v_current_wo.repair_voice_url);

  UPDATE public.work_orders
  SET status = 'completed',
      root_cause = p_root_cause,
      actions_taken = p_actions_taken,
      repair_steps = p_repair_steps,
      repair_voice_url = v_saved_repair_voice_url,
      completed_at = COALESCE(completed_at, v_server_time),
      version = version + 1,
      updated_at = v_server_time
  WHERE id = p_wo_id;

  INSERT INTO public.work_order_events (
    id, work_order_id, command_id, event_type, actor_id,
    occurred_at, received_at, old_status, new_status, payload,
    device_id, app_version
  ) VALUES (
    gen_random_uuid(), p_wo_id, p_command_id, 'REPAIR_COMPLETED', v_caller_id,
    p_occurred_at, v_server_time, v_current_wo.status, 'completed',
    jsonb_build_object(
      'root_cause', p_root_cause,
      'actions_taken', p_actions_taken,
      'repair_steps', p_repair_steps,
      'repair_voice_url', v_saved_repair_voice_url
    ),
    p_device_id, p_app_version
  );

  SELECT to_jsonb(w) INTO v_result
  FROM public.work_orders w
  WHERE w.id = p_wo_id;

  INSERT INTO public.work_order_commands (
    command_id, work_order_id, command_type, actor_id, created_at, processed_at, result
  ) VALUES (
    p_command_id, p_wo_id, 'COMPLETE_WORK_ORDER', v_caller_id,
    p_occurred_at, v_server_time, v_result
  );

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.rpc_complete_work_order(
  UUID, UUID, INT, TEXT, TEXT, JSONB, TEXT, TEXT, TEXT, TIMESTAMPTZ
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rpc_complete_work_order(
  UUID, UUID, INT, TEXT, TEXT, JSONB, TEXT, TEXT, TEXT, TIMESTAMPTZ
) TO authenticated;
