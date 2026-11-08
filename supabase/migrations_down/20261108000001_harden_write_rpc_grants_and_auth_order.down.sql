-- Revert rpc_confirm_test_run to the original step order (idempotency check
-- before the auth/role check), matching 20260921000004_workflow_commands.sql.
-- The EXECUTE grants are left as authenticated-only: that restriction was
-- already the documented intent of every prior migration, so the down
-- migration does not re-open these RPCs to anon/public.
CREATE OR REPLACE FUNCTION public.rpc_confirm_test_run(
  p_command_id UUID,
  p_wo_id UUID,
  p_expected_version INT,
  p_comments TEXT DEFAULT NULL,
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
BEGIN
  -- 1. Check idempotency
  SELECT result INTO v_existing_cmd
  FROM public.work_order_commands
  WHERE command_id = p_command_id;
  IF v_existing_cmd IS NOT NULL THEN
    RETURN v_existing_cmd;
  END IF;

  -- 2. Validate caller authentication & role (Operator only)
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  SELECT role INTO v_role FROM public.user_profiles WHERE id = v_caller_id;

  IF v_role <> 'OPERATOR' THEN
    RAISE EXCEPTION 'FORBIDDEN: Only Line Operators can confirm field test runs' USING errcode = '42501';
  END IF;

  -- 3. Lock and validate work order
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

  IF v_current_wo.status <> 'completed' THEN
    RAISE EXCEPTION 'ILLEGAL_STATE: Cannot confirm test run when status is % (must be completed)', v_current_wo.status
      USING errcode = 'P0001';
  END IF;

  -- 4. Update work order
  UPDATE public.work_orders
  SET status = 'verified',
      version = version + 1,
      updated_at = v_server_time
  WHERE id = p_wo_id;

  -- 5. Insert Audit Event
  INSERT INTO public.work_order_events (
    id, work_order_id, command_id, event_type, actor_id,
    occurred_at, received_at, old_status, new_status, payload, device_id, app_version
  ) VALUES (
    gen_random_uuid(), p_wo_id, p_command_id, 'TEST_RUN_PASSED', v_caller_id,
    p_occurred_at, v_server_time, 'completed', 'verified',
    COALESCE(jsonb_build_object('comments', p_comments), '{}'::jsonb),
    p_device_id, p_app_version
  );

  -- 6. Construct result
  SELECT to_jsonb(w) INTO v_result
  FROM public.work_orders w
  WHERE w.id = p_wo_id;

  -- 7. Record command
  INSERT INTO public.work_order_commands (
    command_id, work_order_id, command_type, actor_id, created_at, processed_at, result
  ) VALUES (
    p_command_id, p_wo_id, 'CONFIRM_TEST_RUN', v_caller_id, p_occurred_at, v_server_time, v_result
  );

  RETURN v_result;
END;
$$;
