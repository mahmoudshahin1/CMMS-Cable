-- ==============================================================================
-- 20260921000004_workflow_commands.sql
-- Server-Authoritative Transactional Workflow RPCs with UUID Idempotency & Audit
-- ==============================================================================

-- 1. rpc_create_work_order
CREATE OR REPLACE FUNCTION public.rpc_create_work_order(
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
  -- 1. Check idempotency
  SELECT result INTO v_existing_cmd
  FROM public.work_order_commands
  WHERE command_id = p_command_id;
  IF v_existing_cmd IS NOT NULL THEN
    RETURN v_existing_cmd;
  END IF;

  -- 2. Validate caller authentication
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  SELECT role, department INTO v_role, v_dept
  FROM public.user_profiles
  WHERE id = v_caller_id;

  SELECT department INTO v_machine_dept
  FROM public.machines
  WHERE id = p_machine_id;

  IF v_machine_dept IS NULL THEN
    RAISE EXCEPTION 'NOT_FOUND: Machine % does not exist', p_machine_id USING errcode = 'P0002';
  END IF;

  -- 3. Authorization check
  -- Operators can only report for machines in their own department
  -- Supervisors & Admins can report for any department
  IF v_role = 'OPERATOR' THEN
    IF v_dept IS DISTINCT FROM v_machine_dept THEN
      RAISE EXCEPTION 'FORBIDDEN: Operators can only report for their own department machines' USING errcode = '42501';
    END IF;
  ELSIF v_role NOT IN ('SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor',
                       'PRODUCTION_SUPERVISOR', 'production_supervisor', 'ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager') THEN
    RAISE EXCEPTION 'FORBIDDEN: Role % cannot create work orders', v_role USING errcode = '42501';
  END IF;

  -- 4. Insert Work Order
  INSERT INTO public.work_orders (
    id, title, description, machine_id, type, status, priority,
    reported_by, created_at, version, updated_at
  ) VALUES (
    p_wo_id, p_title, p_description, p_machine_id, p_type, 'open', p_priority,
    v_caller_id, v_server_time, 1, v_server_time
  );

  -- 5. Insert Audit Event
  INSERT INTO public.work_order_events (
    id, work_order_id, command_id, event_type, actor_id,
    occurred_at, received_at, old_status, new_status, payload, device_id, app_version
  ) VALUES (
    gen_random_uuid(), p_wo_id, p_command_id, 'REPORTED', v_caller_id,
    p_occurred_at, v_server_time, NULL, 'open',
    jsonb_build_object('title', p_title, 'type', p_type, 'priority', p_priority),
    p_device_id, p_app_version
  );

  -- 6. Construct result
  SELECT to_jsonb(w) INTO v_result
  FROM public.work_orders w
  WHERE w.id = p_wo_id;

  -- 7. Record command result for idempotency
  INSERT INTO public.work_order_commands (
    command_id, work_order_id, command_type, actor_id, created_at, processed_at, result
  ) VALUES (
    p_command_id, p_wo_id, 'CREATE_WORK_ORDER', v_caller_id, p_occurred_at, v_server_time, v_result
  );

  RETURN v_result;
END;
$$;

-- 2. rpc_assign_work_order
CREATE OR REPLACE FUNCTION public.rpc_assign_work_order(
  p_command_id UUID,
  p_wo_id UUID,
  p_expected_version INT,
  p_technician_id UUID,
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

  -- 2. Validate caller authentication & role
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  SELECT role INTO v_role FROM public.user_profiles WHERE id = v_caller_id;

  IF v_role NOT IN ('SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor',
                    'ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager') THEN
    RAISE EXCEPTION 'FORBIDDEN: Only Maintenance Supervisors can assign work orders' USING errcode = '42501';
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

  IF v_current_wo.status NOT IN ('open', 'assigned') THEN
    RAISE EXCEPTION 'ILLEGAL_STATE: Cannot assign ticket in status %', v_current_wo.status USING errcode = 'P0001';
  END IF;

  -- 4. Update work order
  UPDATE public.work_orders
  SET assigned_to_technician_id = p_technician_id,
      assigned_by_supervisor_id = v_caller_id,
      status = 'assigned',
      version = version + 1,
      updated_at = v_server_time
  WHERE id = p_wo_id;

  -- 5. Insert Audit Event
  INSERT INTO public.work_order_events (
    id, work_order_id, command_id, event_type, actor_id,
    occurred_at, received_at, old_status, new_status, payload, device_id, app_version
  ) VALUES (
    gen_random_uuid(), p_wo_id, p_command_id, 'ASSIGNED', v_caller_id,
    p_occurred_at, v_server_time, v_current_wo.status, 'assigned',
    jsonb_build_object('technician_id', p_technician_id),
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
    p_command_id, p_wo_id, 'ASSIGN_WORK_ORDER', v_caller_id, p_occurred_at, v_server_time, v_result
  );

  RETURN v_result;
END;
$$;

-- 3. rpc_start_work_order
CREATE OR REPLACE FUNCTION public.rpc_start_work_order(
  p_command_id UUID,
  p_wo_id UUID,
  p_expected_version INT,
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

  -- 2. Validate caller authentication & role
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  SELECT role INTO v_role FROM public.user_profiles WHERE id = v_caller_id;

  IF v_role NOT IN ('TECHNICIAN', 'technician', 'MAINTENANCE_TECH', 'maintenance_tech') THEN
    RAISE EXCEPTION 'FORBIDDEN: Only Maintenance Technicians can start repair' USING errcode = '42501';
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

  IF v_current_wo.assigned_to_technician_id <> v_caller_id THEN
    RAISE EXCEPTION 'FORBIDDEN: You are not assigned to this work order' USING errcode = '42501';
  END IF;

  IF v_current_wo.status <> 'assigned' THEN
    RAISE EXCEPTION 'ILLEGAL_STATE: Cannot start ticket in status % (must be assigned)', v_current_wo.status
      USING errcode = 'P0001';
  END IF;

  -- 4. Update work order
  UPDATE public.work_orders
  SET status = 'inProgress',
      started_at = COALESCE(started_at, v_server_time),
      version = version + 1,
      updated_at = v_server_time
  WHERE id = p_wo_id;

  -- 5. Insert Audit Event
  INSERT INTO public.work_order_events (
    id, work_order_id, command_id, event_type, actor_id,
    occurred_at, received_at, old_status, new_status, payload, device_id, app_version
  ) VALUES (
    gen_random_uuid(), p_wo_id, p_command_id, 'REPAIR_STARTED', v_caller_id,
    p_occurred_at, v_server_time, 'assigned', 'inProgress', '{}'::jsonb,
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
    p_command_id, p_wo_id, 'START_WORK_ORDER', v_caller_id, p_occurred_at, v_server_time, v_result
  );

  RETURN v_result;
END;
$$;

-- 4. rpc_add_work_order_part
CREATE OR REPLACE FUNCTION public.rpc_add_work_order_part(
  p_command_id UUID,
  p_part_id UUID,
  p_wo_id UUID,
  p_part_code TEXT,
  p_part_name TEXT,
  p_quantity NUMERIC,
  p_unit_cost NUMERIC DEFAULT NULL,
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

  -- 2. Validate caller authentication
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  SELECT role INTO v_role FROM public.user_profiles WHERE id = v_caller_id;

  IF v_role NOT IN ('TECHNICIAN', 'technician', 'MAINTENANCE_TECH', 'maintenance_tech') THEN
    RAISE EXCEPTION 'FORBIDDEN: Only Maintenance Technicians can record spare parts' USING errcode = '42501';
  END IF;

  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'INVALID_ARGUMENT: Quantity must be positive' USING errcode = 'P0001';
  END IF;

  -- 3. Lock and validate work order
  SELECT * INTO v_current_wo
  FROM public.work_orders
  WHERE id = p_wo_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: Work order % not found', p_wo_id USING errcode = 'P0002';
  END IF;

  IF v_current_wo.assigned_to_technician_id <> v_caller_id THEN
    RAISE EXCEPTION 'FORBIDDEN: You are not assigned to this work order' USING errcode = '42501';
  END IF;

  IF v_current_wo.status NOT IN ('inProgress', 'pendingParts') THEN
    RAISE EXCEPTION 'ILLEGAL_STATE: Cannot add parts when ticket status is %', v_current_wo.status USING errcode = 'P0001';
  END IF;

  -- 4. Insert Part
  INSERT INTO public.work_order_parts (
    id, work_order_id, command_id, part_code, part_name, quantity, unit_cost,
    added_by, occurred_at, received_at
  ) VALUES (
    p_part_id, p_wo_id, p_command_id, p_part_code, p_part_name, p_quantity, p_unit_cost,
    v_caller_id, p_occurred_at, v_server_time
  );

  -- 5. Insert Audit Event
  INSERT INTO public.work_order_events (
    id, work_order_id, command_id, event_type, actor_id,
    occurred_at, received_at, old_status, new_status, payload, device_id, app_version
  ) VALUES (
    gen_random_uuid(), p_wo_id, p_command_id, 'SPARE_PART_ADDED', v_caller_id,
    p_occurred_at, v_server_time, v_current_wo.status, v_current_wo.status,
    jsonb_build_object('part_name', p_part_name, 'part_code', p_part_code, 'quantity', p_quantity, 'unit_cost', p_unit_cost),
    p_device_id, p_app_version
  );

  -- 6. Construct result
  SELECT to_jsonb(p) INTO v_result
  FROM public.work_order_parts p
  WHERE p.id = p_part_id;

  -- 7. Record command
  INSERT INTO public.work_order_commands (
    command_id, work_order_id, command_type, actor_id, created_at, processed_at, result
  ) VALUES (
    p_command_id, p_wo_id, 'ADD_WORK_ORDER_PART', v_caller_id, p_occurred_at, v_server_time, v_result
  );

  RETURN v_result;
END;
$$;

-- 5. rpc_complete_work_order
CREATE OR REPLACE FUNCTION public.rpc_complete_work_order(
  p_command_id UUID,
  p_wo_id UUID,
  p_expected_version INT,
  p_root_cause TEXT,
  p_actions_taken TEXT,
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

  -- 2. Validate caller authentication & role
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  SELECT role INTO v_role FROM public.user_profiles WHERE id = v_caller_id;

  IF v_role NOT IN ('TECHNICIAN', 'technician', 'MAINTENANCE_TECH', 'maintenance_tech') THEN
    RAISE EXCEPTION 'FORBIDDEN: Only Maintenance Technicians can complete repair' USING errcode = '42501';
  END IF;

  IF NULLIF(TRIM(p_root_cause), '') IS NULL OR NULLIF(TRIM(p_actions_taken), '') IS NULL THEN
    RAISE EXCEPTION 'INVALID_ARGUMENT: Both root_cause and actions_taken are strictly required' USING errcode = 'P0001';
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

  IF v_current_wo.assigned_to_technician_id <> v_caller_id THEN
    RAISE EXCEPTION 'FORBIDDEN: You are not assigned to this work order' USING errcode = '42501';
  END IF;

  IF v_current_wo.status NOT IN ('inProgress', 'pendingParts') THEN
    RAISE EXCEPTION 'ILLEGAL_STATE: Cannot complete repair from status %', v_current_wo.status USING errcode = 'P0001';
  END IF;

  -- 4. Update work order
  UPDATE public.work_orders
  SET status = 'completed',
      root_cause = p_root_cause,
      actions_taken = p_actions_taken,
      completed_at = COALESCE(completed_at, v_server_time),
      version = version + 1,
      updated_at = v_server_time
  WHERE id = p_wo_id;

  -- 5. Insert Audit Event
  INSERT INTO public.work_order_events (
    id, work_order_id, command_id, event_type, actor_id,
    occurred_at, received_at, old_status, new_status, payload, device_id, app_version
  ) VALUES (
    gen_random_uuid(), p_wo_id, p_command_id, 'REPAIR_COMPLETED', v_caller_id,
    p_occurred_at, v_server_time, v_current_wo.status, 'completed',
    jsonb_build_object('root_cause', p_root_cause, 'actions_taken', p_actions_taken),
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
    p_command_id, p_wo_id, 'COMPLETE_WORK_ORDER', v_caller_id, p_occurred_at, v_server_time, v_result
  );

  RETURN v_result;
END;
$$;

-- 6. rpc_confirm_test_run
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

-- 7. rpc_close_work_order
CREATE OR REPLACE FUNCTION public.rpc_close_work_order(
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

  -- 2. Validate caller authentication & role (Supervisors only)
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  SELECT role INTO v_role FROM public.user_profiles WHERE id = v_caller_id;

  IF v_role NOT IN ('SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor',
                    'PRODUCTION_SUPERVISOR', 'production_supervisor', 'ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager') THEN
    RAISE EXCEPTION 'FORBIDDEN: Only Supervisors can approve and close work orders' USING errcode = '42501';
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

  IF v_current_wo.status NOT IN ('verified', 'completed') THEN
    RAISE EXCEPTION 'ILLEGAL_STATE: Cannot close ticket in status % (must be verified or completed)', v_current_wo.status
      USING errcode = 'P0001';
  END IF;

  -- 4. Update work order
  UPDATE public.work_orders
  SET status = 'verifiedClosed',
      closed_by = v_caller_id,
      closed_at = COALESCE(closed_at, v_server_time),
      version = version + 1,
      updated_at = v_server_time
  WHERE id = p_wo_id;

  -- 5. Insert Audit Event
  INSERT INTO public.work_order_events (
    id, work_order_id, command_id, event_type, actor_id,
    occurred_at, received_at, old_status, new_status, payload, device_id, app_version
  ) VALUES (
    gen_random_uuid(), p_wo_id, p_command_id, 'CLOSED', v_caller_id,
    p_occurred_at, v_server_time, v_current_wo.status, 'verifiedClosed',
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
    p_command_id, p_wo_id, 'CLOSE_WORK_ORDER', v_caller_id, p_occurred_at, v_server_time, v_result
  );

  RETURN v_result;
END;
$$;

-- Revoke execute from public/anon and grant to authenticated
REVOKE EXECUTE ON FUNCTION public.rpc_create_work_order, public.rpc_assign_work_order,
  public.rpc_start_work_order, public.rpc_add_work_order_part, public.rpc_complete_work_order,
  public.rpc_confirm_test_run, public.rpc_close_work_order FROM public, anon;

GRANT EXECUTE ON FUNCTION public.rpc_create_work_order, public.rpc_assign_work_order,
  public.rpc_start_work_order, public.rpc_add_work_order_part, public.rpc_complete_work_order,
  public.rpc_confirm_test_run, public.rpc_close_work_order TO authenticated;
