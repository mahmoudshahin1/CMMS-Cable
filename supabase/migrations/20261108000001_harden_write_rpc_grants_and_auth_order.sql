-- Security hardening migration.
--
-- Context: production was found to allow `anon` to execute
-- rpc_confirm_test_run, rpc_complete_work_order and rpc_create_work_order,
-- even though every local migration file already REVOKEs execute from
-- anon/public on these functions. The local migrations (11 files) and the
-- production database (22 applied migrations) have drifted apart, and the
-- most likely cause is that one or more of these functions were later
-- recreated directly on production (CREATE OR REPLACE FUNCTION, run outside
-- this migration pipeline) without re-issuing the REVOKE afterwards.
-- PostgreSQL grants EXECUTE to PUBLIC by default on every CREATE OR REPLACE
-- FUNCTION unless a REVOKE is re-applied, so a bare hotfix silently
-- re-exposes the function to anon.
--
-- This migration is intentionally idempotent and safe to run even though the
-- local files already contain these REVOKE/GRANT statements: it re-asserts
-- the correct privileges directly against the live database regardless of
-- its current (possibly drifted) state, and does not touch schema/data.
--
-- It also fixes a real ordering bug in rpc_confirm_test_run: the idempotency
-- check (reading public.work_order_commands by command_id) ran BEFORE the
-- auth.uid() / role check. Because the function is SECURITY DEFINER, any
-- caller who could execute it at all -- authenticated or not -- could read
-- back the full JSONB result of any previously processed command just by
-- supplying its command_id, without being authenticated or authorized. The
-- fix moves the authentication + role check to run first, so an
-- unauthenticated or wrong-role caller is rejected before the idempotency
-- table is ever touched. Legitimate retries by the same authenticated
-- operator are unaffected -- they still hit the idempotency short-circuit
-- right after passing the auth check.

-- =========================================================================
-- 1. Re-assert EXECUTE privileges on every write RPC (defense-in-depth).
--    Safe to re-run: REVOKE/GRANT are idempotent operations in Postgres.
-- =========================================================================
REVOKE EXECUTE ON FUNCTION public.rpc_create_work_order,
  public.rpc_assign_work_order,
  public.rpc_start_work_order,
  public.rpc_add_work_order_part,
  public.rpc_complete_work_order,
  public.rpc_confirm_test_run,
  public.rpc_close_work_order,
  public.rpc_attach_work_order_voice_note,
  public.rpc_create_downtime_log,
  public.rpc_close_downtime_log
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.rpc_create_work_order,
  public.rpc_assign_work_order,
  public.rpc_start_work_order,
  public.rpc_add_work_order_part,
  public.rpc_complete_work_order,
  public.rpc_confirm_test_run,
  public.rpc_close_work_order,
  public.rpc_attach_work_order_voice_note,
  public.rpc_create_downtime_log,
  public.rpc_close_downtime_log
TO authenticated;

-- =========================================================================
-- 2. Redefine rpc_confirm_test_run with auth check BEFORE idempotency read.
--    Logic is otherwise byte-for-byte identical to the version shipped in
--    20260921000004_workflow_commands.sql -- only the order of steps 1 and 2
--    is swapped, and the comments are renumbered to match.
-- =========================================================================
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
  -- 1. Validate caller authentication & role (Operator only) -- runs first
  --    so an unauthenticated/unauthorized caller never reaches the
  --    idempotency table below.
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  SELECT role INTO v_role FROM public.user_profiles WHERE id = v_caller_id;

  IF v_role <> 'OPERATOR' THEN
    RAISE EXCEPTION 'FORBIDDEN: Only Line Operators can confirm field test runs' USING errcode = '42501';
  END IF;

  -- 2. Check idempotency (only reached once the caller is authenticated).
  SELECT result INTO v_existing_cmd
  FROM public.work_order_commands
  WHERE command_id = p_command_id;
  IF v_existing_cmd IS NOT NULL THEN
    RETURN v_existing_cmd;
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

-- CREATE OR REPLACE resets EXECUTE to PUBLIC by default -- re-apply the
-- restriction immediately after redefining the function body.
REVOKE EXECUTE ON FUNCTION public.rpc_confirm_test_run FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rpc_confirm_test_run TO authenticated;
