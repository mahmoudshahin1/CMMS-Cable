-- ==============================================================================
-- Cable Ops CMMS — Comprehensive Unified Schema & Fixtures
-- Execute in: Supabase Dashboard -> SQL Editor -> New Query -> Run
-- ==============================================================================

-- Step 0: Drop old tables, legacy functions, and types if upgrading from legacy schema
DROP FUNCTION IF EXISTS public.current_user_specialty() CASCADE;
DROP FUNCTION IF EXISTS public.current_user_role() CASCADE;
DROP FUNCTION IF EXISTS public.current_user_department() CASCADE;
DROP FUNCTION IF EXISTS public.rpc_create_work_order CASCADE;
DROP FUNCTION IF EXISTS public.rpc_assign_work_order CASCADE;
DROP FUNCTION IF EXISTS public.rpc_start_work_order CASCADE;
DROP FUNCTION IF EXISTS public.rpc_complete_work_order CASCADE;
DROP FUNCTION IF EXISTS public.rpc_confirm_test_run CASCADE;
DROP FUNCTION IF EXISTS public.rpc_close_work_order CASCADE;
DROP FUNCTION IF EXISTS public.rpc_add_work_order_part CASCADE;
DROP TYPE IF EXISTS public.technician_specialty_enum CASCADE;

DROP TABLE IF EXISTS public.work_order_attachments CASCADE;
DROP TABLE IF EXISTS public.spare_parts CASCADE;
DROP TABLE IF EXISTS public.work_order_parts CASCADE;
DROP TABLE IF EXISTS public.work_order_events CASCADE;
DROP TABLE IF EXISTS public.work_order_commands CASCADE;
DROP TABLE IF EXISTS public.downtime_logs CASCADE;
DROP TABLE IF EXISTS public.work_orders CASCADE;
DROP TABLE IF EXISTS public.machines CASCADE;

-- File: 20260921000001_profiles_hardening.sql
-- ==============================================================================
-- 20260921000001_profiles_hardening.sql
-- Security Hardening for public.user_profiles
-- Prevents clients from updating role, department, specialty, or employee_code.
-- Only full_name can be updated by the authenticated user.
-- ==============================================================================

-- 1. Ensure table structure is present
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'OPERATOR',
  department TEXT,
  specialty TEXT,
  employee_code TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure role column is TEXT (in case table was previously created with user_role_enum)
ALTER TABLE public.user_profiles ALTER COLUMN role DROP DEFAULT;
ALTER TABLE public.user_profiles ALTER COLUMN role TYPE TEXT USING role::text;
ALTER TABLE public.user_profiles ALTER COLUMN role SET DEFAULT 'OPERATOR';

-- Ensure RLS is active
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 2. Revoke broad update privileges from authenticated and anon
REVOKE ALL ON public.user_profiles FROM anon;
REVOKE UPDATE ON public.user_profiles FROM authenticated;

-- 3. Grant column-specific update on full_name only
GRANT SELECT ON public.user_profiles TO authenticated;
GRANT UPDATE (full_name) ON public.user_profiles TO authenticated;

-- 4. Helper functions for role & department scoping (SECURITY DEFINER with empty search_path)
DROP FUNCTION IF EXISTS public.current_user_role() CASCADE;
DROP FUNCTION IF EXISTS public.current_user_department() CASCADE;

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT role FROM public.user_profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.current_user_department()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT department FROM public.user_profiles WHERE id = auth.uid();
$$;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION public.current_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_user_department() TO authenticated;

-- 5. Re-declare robust RLS policies on user_profiles
DROP POLICY IF EXISTS "Allow authenticated users to read all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Profiles read policy" ON public.user_profiles;

CREATE POLICY "Profiles read policy"
  ON public.user_profiles FOR SELECT
  TO authenticated
  USING (
    -- 1. Self row is always readable
    auth.uid() = id
    OR
    -- 2. Plant Managers / Admins can read all profiles
    public.current_user_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager')
    OR
    -- 3. Maintenance Supervisors can read technicians (for assignment) and supervisors
    (
      public.current_user_role() IN ('SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor')
      AND role IN ('TECHNICIAN', 'technician', 'MAINTENANCE_TECH', 'maintenance_tech', 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor')
    )
    OR
    -- 4. Production Supervisors can read operators in their own department and technicians
    (
      public.current_user_role() IN ('PRODUCTION_SUPERVISOR', 'production_supervisor')
      AND (
        department = public.current_user_department()
        OR role IN ('TECHNICIAN', 'technician', 'MAINTENANCE_TECH', 'maintenance_tech')
      )
    )
  );

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own full_name" ON public.user_profiles;
CREATE POLICY "Users can update own full_name"
  ON public.user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);



-- File: 20260921000002_core_schema.sql
-- ==============================================================================
-- 20260921000002_core_schema.sql
-- Core Industrial Schema: machines, work_orders, work_order_commands,
-- work_order_events, work_order_parts, downtime_logs.
-- ==============================================================================

-- 1. Private schema for internal security helpers
CREATE SCHEMA IF NOT EXISTS private;

-- 2. Machines table (factory lines 1-7)
CREATE TABLE IF NOT EXISTS public.machines (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  department TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'running',
  sub_category TEXT DEFAULT '',
  current_speed_mpm NUMERIC NOT NULL DEFAULT 0,
  total_meters_produced NUMERIC NOT NULL DEFAULT 0,
  last_maintenance_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Work orders table (root maintenance ticket)
CREATE TABLE IF NOT EXISTS public.work_orders (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  machine_id TEXT NOT NULL REFERENCES public.machines(id),
  type TEXT NOT NULL DEFAULT 'breakdown'
    CHECK (type IN ('breakdown', 'preventive', 'corrective', 'inspection')),
  status TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'assigned', 'inProgress', 'pendingParts', 'completed', 'verified', 'verifiedClosed')),
  priority TEXT NOT NULL DEFAULT 'medium'
    CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  reported_by UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id),
  assigned_to_technician_id UUID REFERENCES auth.users(id),
  assigned_by_supervisor_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,
  closed_by UUID REFERENCES auth.users(id),
  root_cause TEXT,
  actions_taken TEXT,
  chronology JSONB,
  version INTEGER NOT NULL DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Work order commands (Durable Idempotency Store)
CREATE TABLE IF NOT EXISTS public.work_order_commands (
  command_id UUID PRIMARY KEY,
  work_order_id UUID REFERENCES public.work_orders(id) ON DELETE CASCADE,
  command_type TEXT NOT NULL,
  actor_id UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  result JSONB NOT NULL DEFAULT '{}'::jsonb
);

-- 5. Work order events (Authoritative, Append-only immutable audit history)
CREATE TABLE IF NOT EXISTS public.work_order_events (
  id UUID PRIMARY KEY,
  work_order_id UUID NOT NULL REFERENCES public.work_orders(id) ON DELETE CASCADE,
  command_id UUID REFERENCES public.work_order_commands(command_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED,
  event_type TEXT NOT NULL,
  actor_id UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id),
  occurred_at TIMESTAMPTZ NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  old_status TEXT,
  new_status TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  device_id TEXT,
  app_version TEXT
);

-- 6. Work order parts (Authoritative, Append-only spare parts consumption)
CREATE TABLE IF NOT EXISTS public.work_order_parts (
  id UUID PRIMARY KEY,
  work_order_id UUID NOT NULL REFERENCES public.work_orders(id) ON DELETE CASCADE,
  command_id UUID REFERENCES public.work_order_commands(command_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED,
  part_code TEXT,
  part_name TEXT NOT NULL,
  quantity NUMERIC NOT NULL CHECK (quantity > 0),
  unit_cost NUMERIC,
  added_by UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6.1 Spare parts inventory catalog (Warehouse / Stock)
CREATE TABLE IF NOT EXISTS public.spare_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  part_code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  category TEXT,
  quantity_in_stock INT NOT NULL DEFAULT 0,
  min_stock_level INT DEFAULT 5,
  unit_cost NUMERIC(10,2) DEFAULT 0.0,
  location TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Downtime logs table (shift minutes and category breakdown)
CREATE TABLE IF NOT EXISTS public.downtime_logs (
  id UUID PRIMARY KEY,
  machine_id TEXT NOT NULL REFERENCES public.machines(id),
  work_order_id UUID REFERENCES public.work_orders(id) ON DELETE SET NULL,
  category TEXT,
  reason TEXT NOT NULL DEFAULT '',
  is_maintenance_requested BOOLEAN NOT NULL DEFAULT FALSE,
  comments TEXT,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  production_date DATE NOT NULL DEFAULT CURRENT_DATE,
  shift_minutes JSONB NOT NULL DEFAULT '{}'::jsonb,
  start_chronology JSONB,
  end_chronology JSONB,
  created_by UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (ended_at IS NULL OR ended_at >= started_at)
);

-- 8. Automated touch_updated_at trigger function
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS machines_touch ON public.machines;
CREATE TRIGGER machines_touch BEFORE UPDATE ON public.machines
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS work_orders_touch ON public.work_orders;
CREATE TRIGGER work_orders_touch BEFORE UPDATE ON public.work_orders
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS downtime_logs_touch ON public.downtime_logs;
CREATE TRIGGER downtime_logs_touch BEFORE UPDATE ON public.downtime_logs
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();


-- File: 20260921000003_security_and_rls.sql
-- ==============================================================================
-- 20260921000003_security_and_rls.sql
-- Operational Security, Private Schema Security Helpers, and Strict RLS Policies
-- ==============================================================================

-- 1. Private security helpers in private schema with empty search_path
CREATE OR REPLACE FUNCTION private.current_app_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT role FROM public.user_profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION private.current_app_department()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT department FROM public.user_profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION private.machine_department(p_machine_id TEXT)
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT department FROM public.machines WHERE id = p_machine_id;
$$;

CREATE OR REPLACE FUNCTION private.is_assigned_to_machine(p_machine_id TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.work_orders
    WHERE machine_id = p_machine_id
      AND assigned_to_technician_id = auth.uid()
      AND status IN ('assigned', 'inProgress', 'pendingParts')
  );
$$;

CREATE OR REPLACE FUNCTION private.can_view_work_order(p_wo_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.work_orders w
    WHERE w.id = p_wo_id
      AND (
        private.current_app_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager',
                                       'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor',
                                       'PRODUCTION_SUPERVISOR', 'production_supervisor')
        OR (
          private.current_app_role() = 'OPERATOR'
          AND private.machine_department(w.machine_id) = private.current_app_department()
        )
        OR (
          private.current_app_role() IN ('TECHNICIAN', 'technician', 'MAINTENANCE_TECH', 'maintenance_tech')
          AND w.assigned_to_technician_id = auth.uid()
        )
      )
  );
$$;

-- Grant execution to authenticated users
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA private FROM public, anon;
GRANT EXECUTE ON FUNCTION private.current_app_role() TO authenticated;
GRANT EXECUTE ON FUNCTION private.current_app_department() TO authenticated;
GRANT EXECUTE ON FUNCTION private.machine_department(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_assigned_to_machine(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_view_work_order(UUID) TO authenticated;

-- 2. Enable Row-Level Security on all operational tables
ALTER TABLE public.machines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_order_commands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_order_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_order_parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.downtime_logs ENABLE ROW LEVEL SECURITY;

-- 3. Revoke broad permissions
REVOKE ALL ON public.machines, public.work_orders, public.work_order_commands,
              public.work_order_events, public.work_order_parts, public.downtime_logs FROM anon;

REVOKE DELETE, TRUNCATE ON public.machines, public.work_orders, public.work_order_commands,
              public.work_order_events, public.work_order_parts, public.downtime_logs FROM authenticated;

-- Direct client updates/deletes to work orders, events, parts, and commands are blocked.
-- Workflow state changes must go through transactional RPCs.
REVOKE INSERT, UPDATE, DELETE ON public.work_order_events, public.work_order_parts, public.work_order_commands FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.machines FROM authenticated;

-- Grant SELECT on all operational tables to authenticated
GRANT SELECT ON public.machines, public.work_orders, public.work_order_commands,
              public.work_order_events, public.work_order_parts, public.downtime_logs TO authenticated;

-- Downtime logs can be inserted/viewed by authorized operators/supervisors
GRANT INSERT, UPDATE ON public.downtime_logs TO authenticated;

-- ==============================================================================
-- 4. Machines Policies
-- ==============================================================================
DROP POLICY IF EXISTS machines_select ON public.machines;
CREATE POLICY machines_select ON public.machines FOR SELECT TO authenticated USING (
  private.current_app_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager',
                                 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor',
                                 'PRODUCTION_SUPERVISOR', 'production_supervisor')
  OR (private.current_app_role() = 'OPERATOR' AND department = private.current_app_department())
  OR (private.current_app_role() IN ('TECHNICIAN', 'technician', 'MAINTENANCE_TECH', 'maintenance_tech')
      AND private.is_assigned_to_machine(id))
);

-- ==============================================================================
-- 5. Work Orders Policies
-- ==============================================================================
DROP POLICY IF EXISTS wo_select ON public.work_orders;
CREATE POLICY wo_select ON public.work_orders FOR SELECT TO authenticated USING (
  private.current_app_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager',
                                 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor',
                                 'PRODUCTION_SUPERVISOR', 'production_supervisor')
  OR (private.current_app_role() = 'OPERATOR'
      AND private.machine_department(machine_id) = private.current_app_department())
  OR (private.current_app_role() IN ('TECHNICIAN', 'technician', 'MAINTENANCE_TECH', 'maintenance_tech')
      AND assigned_to_technician_id = auth.uid())
);

-- ==============================================================================
-- 6. Work Order Commands Policies (Idempotency Store)
-- ==============================================================================
DROP POLICY IF EXISTS wo_commands_select ON public.work_order_commands;
CREATE POLICY wo_commands_select ON public.work_order_commands FOR SELECT TO authenticated USING (
  actor_id = auth.uid()
);

-- ==============================================================================
-- 7. Work Order Events Policies (Append-Only Audit Log)
-- ==============================================================================
DROP POLICY IF EXISTS woe_select ON public.work_order_events;
CREATE POLICY woe_select ON public.work_order_events FOR SELECT TO authenticated USING (
  private.can_view_work_order(work_order_id)
);

-- ==============================================================================
-- 8. Work Order Parts Policies (Append-Only Spare Parts)
-- ==============================================================================
DROP POLICY IF EXISTS wop_select ON public.work_order_parts;
CREATE POLICY wop_select ON public.work_order_parts FOR SELECT TO authenticated USING (
  private.can_view_work_order(work_order_id)
);

-- ==============================================================================
-- 9. Downtime Logs Policies
-- ==============================================================================
DROP POLICY IF EXISTS dt_select ON public.downtime_logs;
CREATE POLICY dt_select ON public.downtime_logs FOR SELECT TO authenticated USING (
  private.current_app_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager',
                                 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor',
                                 'PRODUCTION_SUPERVISOR', 'production_supervisor')
  OR (private.current_app_role() = 'OPERATOR'
      AND private.machine_department(machine_id) = private.current_app_department())
  OR (private.current_app_role() IN ('TECHNICIAN', 'technician', 'MAINTENANCE_TECH', 'maintenance_tech')
      AND private.is_assigned_to_machine(machine_id))
);

DROP POLICY IF EXISTS dt_insert ON public.downtime_logs;
CREATE POLICY dt_insert ON public.downtime_logs FOR INSERT TO authenticated WITH CHECK (
  created_by = auth.uid()
  AND (
    private.current_app_role() IN ('SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor',
                                   'PRODUCTION_SUPERVISOR', 'production_supervisor')
    OR (
      private.current_app_role() = 'OPERATOR'
      AND private.machine_department(machine_id) = private.current_app_department()
    )
  )
);

DROP POLICY IF EXISTS dt_update ON public.downtime_logs;
CREATE POLICY dt_update ON public.downtime_logs FOR UPDATE TO authenticated USING (
  created_by = auth.uid()
  OR private.current_app_role() IN ('SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor',
                                    'PRODUCTION_SUPERVISOR', 'production_supervisor')
) WITH CHECK (
  created_by = auth.uid()
  OR private.current_app_role() IN ('SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor',
                                    'PRODUCTION_SUPERVISOR', 'production_supervisor')
);

-- 10. Spare Parts Catalog Policies
ALTER TABLE public.spare_parts ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.spare_parts TO authenticated;
DROP POLICY IF EXISTS spare_parts_select ON public.spare_parts;
CREATE POLICY spare_parts_select ON public.spare_parts FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS spare_parts_all ON public.spare_parts;
CREATE POLICY spare_parts_all ON public.spare_parts FOR ALL TO authenticated USING (true) WITH CHECK (true);



-- File: 20260921000004_workflow_commands.sql
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


-- File: 20260921000005_audit_and_machine_rules.sql
-- ==============================================================================
-- 20260921000005_audit_and_machine_rules.sql
-- Multi-Work-Order Machine State Consistency & Immutable Audit Guards
-- ==============================================================================

-- 1. Multi-Work-Order Aware Machine Status Synchronization
CREATE OR REPLACE FUNCTION public.sync_machine_from_work_order()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_has_active_breakdown BOOLEAN;
BEGIN
  -- When a breakdown work order is created, machine enters maintenance downtime
  IF TG_OP = 'INSERT' AND NEW.type = 'breakdown' THEN
    UPDATE public.machines
    SET status = 'downtimeMaintenance',
        updated_at = NOW()
    WHERE id = NEW.machine_id;

  -- When work order moves to inProgress, machine enters underRepair
  ELSIF NEW.status = 'inProgress' AND (TG_OP = 'INSERT' OR OLD.status <> 'inProgress') THEN
    UPDATE public.machines
    SET status = 'underRepair',
        updated_at = NOW()
    WHERE id = NEW.machine_id;

  -- When work order is completed or closed, check if ANY OTHER active breakdown ticket exists
  ELSIF (NEW.status IN ('completed', 'verified', 'verifiedClosed'))
        AND (TG_OP = 'UPDATE' AND OLD.status NOT IN ('completed', 'verified', 'verifiedClosed')) THEN

    -- Check if any other active breakdown ticket exists for this machine
    SELECT EXISTS (
      SELECT 1 FROM public.work_orders
      WHERE machine_id = NEW.machine_id
        AND id <> NEW.id
        AND type = 'breakdown'
        AND status IN ('open', 'assigned', 'inProgress', 'pendingParts')
    ) INTO v_has_active_breakdown;

    -- Only restore running status if NO OTHER active breakdown remains
    IF NOT v_has_active_breakdown THEN
      UPDATE public.machines
      SET status = 'running',
          last_maintenance_at = COALESCE(NEW.closed_at, NEW.completed_at, NOW()),
          updated_at = NOW()
      WHERE id = NEW.machine_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_work_orders_machine_sync ON public.work_orders;
CREATE TRIGGER trg_work_orders_machine_sync
AFTER INSERT OR UPDATE ON public.work_orders
FOR EACH ROW EXECUTE FUNCTION public.sync_machine_from_work_order();

-- 2. Audit Trail Immutability Guard (Prevent UPDATE/DELETE on audit tables)
CREATE OR REPLACE FUNCTION public.guard_audit_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION 'FORBIDDEN: Audit events and parts records are strictly immutable'
    USING errcode = '42501';
END;
$$;

DROP TRIGGER IF EXISTS trg_wo_events_immutable ON public.work_order_events;
CREATE TRIGGER trg_wo_events_immutable
BEFORE UPDATE OR DELETE ON public.work_order_events
FOR EACH ROW EXECUTE FUNCTION public.guard_audit_immutability();

DROP TRIGGER IF EXISTS trg_wo_parts_immutable ON public.work_order_parts;
CREATE TRIGGER trg_wo_parts_immutable
BEFORE UPDATE OR DELETE ON public.work_order_parts
FOR EACH ROW EXECUTE FUNCTION public.guard_audit_immutability();

DROP TRIGGER IF EXISTS trg_wo_commands_immutable ON public.work_order_commands;
CREATE TRIGGER trg_wo_commands_immutable
BEFORE UPDATE OR DELETE ON public.work_order_commands
FOR EACH ROW EXECUTE FUNCTION public.guard_audit_immutability();

-- 3. Downtime Log Management RPCs with Server Clock Authority
CREATE OR REPLACE FUNCTION public.rpc_create_downtime_log(
  p_id UUID,
  p_machine_id TEXT,
  p_category TEXT,
  p_reason TEXT,
  p_is_maintenance_requested BOOLEAN DEFAULT FALSE,
  p_work_order_id UUID DEFAULT NULL,
  p_comments TEXT DEFAULT NULL,
  p_start_chronology JSONB DEFAULT NULL,
  p_shift_minutes JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_server_time TIMESTAMPTZ := NOW();
  v_result JSONB;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  INSERT INTO public.downtime_logs (
    id, machine_id, category, reason, is_maintenance_requested,
    work_order_id, comments, started_at, production_date,
    start_chronology, shift_minutes, created_by, updated_at
  ) VALUES (
    p_id, p_machine_id, p_category, p_reason, p_is_maintenance_requested,
    p_work_order_id, p_comments, v_server_time, CURRENT_DATE,
    p_start_chronology, p_shift_minutes, v_caller_id, v_server_time
  );

  SELECT to_jsonb(d) INTO v_result
  FROM public.downtime_logs d
  WHERE d.id = p_id;

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.rpc_close_downtime_log(
  p_id UUID,
  p_end_chronology JSONB DEFAULT NULL,
  p_shift_minutes JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_server_time TIMESTAMPTZ := NOW();
  v_result JSONB;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  UPDATE public.downtime_logs
  SET ended_at = v_server_time,
      end_chronology = p_end_chronology,
      shift_minutes = p_shift_minutes,
      updated_at = v_server_time
  WHERE id = p_id AND ended_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: Active downtime log % not found or already closed', p_id USING errcode = 'P0002';
  END IF;

  SELECT to_jsonb(d) INTO v_result
  FROM public.downtime_logs d
  WHERE d.id = p_id;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rpc_create_downtime_log, public.rpc_close_downtime_log FROM public, anon;
GRANT EXECUTE ON FUNCTION public.rpc_create_downtime_log, public.rpc_close_downtime_log TO authenticated;


-- File: 20260921000006_realtime.sql
-- ==============================================================================
-- 20260921000006_realtime.sql
-- Realtime Publication & Replica Identity Setup
-- ==============================================================================

-- 1. Ensure publication exists (standard on Supabase Cloud, guarded for local/ci)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
END;
$$;

-- 2. Configure REPLICA IDENTITY FULL for tables requiring complete delta payloads
ALTER TABLE public.machines REPLICA IDENTITY FULL;
ALTER TABLE public.work_orders REPLICA IDENTITY FULL;
ALTER TABLE public.downtime_logs REPLICA IDENTITY FULL;

-- 3. Add operational tables to supabase_realtime publication
DO $$
BEGIN
  -- machines
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'machines'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.machines;
  END IF;

  -- work_orders
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'work_orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.work_orders;
  END IF;

  -- work_order_events
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'work_order_events'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.work_order_events;
  END IF;

  -- work_order_parts
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'work_order_parts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.work_order_parts;
  END IF;

  -- downtime_logs
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'downtime_logs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.downtime_logs;
  END IF;
END;
$$;


-- File: 20260921000007_composite_indexes.sql
-- ==============================================================================
-- 20260921000007_composite_indexes.sql
-- Composite Indexes for RLS Filters, Delta Sync Cursors & Shift Chronology
-- ==============================================================================

-- 1. work_orders indexes
CREATE INDEX IF NOT EXISTS idx_work_orders_updated_at_id
  ON public.work_orders (updated_at ASC, id ASC);

CREATE INDEX IF NOT EXISTS idx_work_orders_machine_status
  ON public.work_orders (machine_id, status);

CREATE INDEX IF NOT EXISTS idx_work_orders_assigned_status
  ON public.work_orders (assigned_to_technician_id, status)
  WHERE assigned_to_technician_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_work_orders_reported_by
  ON public.work_orders (reported_by, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_work_orders_type_status
  ON public.work_orders (type, status);

-- 2. work_order_events indexes
CREATE INDEX IF NOT EXISTS idx_wo_events_wo_received
  ON public.work_order_events (work_order_id, received_at DESC);

CREATE INDEX IF NOT EXISTS idx_wo_events_received_at_id
  ON public.work_order_events (received_at ASC, id ASC);

-- 3. work_order_parts indexes
CREATE INDEX IF NOT EXISTS idx_wo_parts_wo_received
  ON public.work_order_parts (work_order_id, received_at ASC);

CREATE INDEX IF NOT EXISTS idx_wo_parts_received_at_id
  ON public.work_order_parts (received_at ASC, id ASC);

-- 4. downtime_logs indexes
CREATE INDEX IF NOT EXISTS idx_downtime_logs_updated_at_id
  ON public.downtime_logs (updated_at ASC, id ASC);

CREATE INDEX IF NOT EXISTS idx_downtime_logs_machine_ended
  ON public.downtime_logs (machine_id, ended_at);

CREATE INDEX IF NOT EXISTS idx_downtime_logs_prod_date
  ON public.downtime_logs (production_date, started_at);

CREATE INDEX IF NOT EXISTS idx_downtime_logs_work_order
  ON public.downtime_logs (work_order_id)
  WHERE work_order_id IS NOT NULL;

-- 5. work_order_commands indexes
CREATE INDEX IF NOT EXISTS idx_wo_commands_wo_type
  ON public.work_order_commands (work_order_id, command_type);

-- 6. machines indexes
CREATE INDEX IF NOT EXISTS idx_machines_dept_status
  ON public.machines (department, status);


-- File: 20260921000008_storage_attachments.sql
-- ==============================================================================
-- 20260921000008_storage_attachments.sql
-- Supabase Storage Configuration, Attachment RLS & Server Rate Limiter
-- ==============================================================================

-- 1. Create Private Storage Bucket for Work Order Fault / Maintenance Attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'work-order-attachments',
  'work-order-attachments',
  false,
  10485760, -- 10MB maximum file size limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- 2. Storage RLS Policies (storage.objects)
-- 2.1 SELECT Policy: View attachments for authorized work orders
DROP POLICY IF EXISTS "Authenticated users view work order attachments" ON storage.objects;
CREATE POLICY "Authenticated users view work order attachments"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'work-order-attachments'
  AND (
    -- Admin, Plant Manager, or Maintenance Supervisor can view all attachments
    private.current_app_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager', 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor')
    OR
    -- Check work order department / technician scoping from path <work_order_id>/<file>
    EXISTS (
      SELECT 1 FROM public.work_orders wo
      JOIN public.machines m ON m.id = wo.machine_id
      WHERE wo.id::text = split_part(name, '/', 1)
        AND (
          m.department = private.current_app_department()
          OR wo.assigned_to_technician_id = auth.uid()
          OR wo.reported_by = auth.uid()
        )
    )
  )
);

-- 2.2 INSERT Policy: Upload attachments matching authorized work order scope
DROP POLICY IF EXISTS "Authorized staff upload work order attachments" ON storage.objects;
CREATE POLICY "Authorized staff upload work order attachments"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'work-order-attachments'
  AND (
    private.current_app_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager', 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor')
    OR
    EXISTS (
      SELECT 1 FROM public.work_orders wo
      JOIN public.machines m ON m.id = wo.machine_id
      WHERE wo.id::text = split_part(name, '/', 1)
        AND (
          m.department = private.current_app_department()
          OR wo.assigned_to_technician_id = auth.uid()
          OR wo.reported_by = auth.uid()
        )
    )
  )
);

-- 2.3 DELETE Policy: Only Supervisors and Admins may delete attachments
DROP POLICY IF EXISTS "Supervisors and admins delete work order attachments" ON storage.objects;
CREATE POLICY "Supervisors and admins delete work order attachments"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'work-order-attachments'
  AND private.current_app_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager', 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor')
);

-- 3. Application-Level Rate Limiter Table and Helper
CREATE TABLE IF NOT EXISTS private.rate_limit_tracker (
  actor_id UUID NOT NULL,
  action_key TEXT NOT NULL,
  window_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  request_count INT NOT NULL DEFAULT 1,
  PRIMARY KEY (actor_id, action_key)
);

ALTER TABLE private.rate_limit_tracker ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION private.check_rpc_rate_limit(
  p_actor_id UUID,
  p_action TEXT,
  p_max_requests INT DEFAULT 100,
  p_window_seconds INT DEFAULT 60
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_current_count INT;
  v_window_start TIMESTAMPTZ;
BEGIN
  SELECT window_start, request_count
  INTO v_window_start, v_current_count
  FROM private.rate_limit_tracker
  WHERE actor_id = p_actor_id AND action_key = p_action
  FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO private.rate_limit_tracker (actor_id, action_key, window_start, request_count)
    VALUES (p_actor_id, p_action, NOW(), 1);
  ELSIF NOW() - v_window_start > (p_window_seconds || ' seconds')::interval THEN
    UPDATE private.rate_limit_tracker
    SET window_start = NOW(), request_count = 1
    WHERE actor_id = p_actor_id AND action_key = p_action;
  ELSIF v_current_count >= p_max_requests THEN
    RAISE EXCEPTION 'RATE_LIMIT_EXCEEDED: Maximum request limit reached. Please wait before retrying.'
      USING errcode = 'P0429';
  ELSE
    UPDATE private.rate_limit_tracker
    SET request_count = request_count + 1
    WHERE actor_id = p_actor_id AND action_key = p_action;
  END IF;
END;
$$;


-- File: seed.sql
-- ==============================================================================
-- seed.sql
-- Production baseline fixtures: Industrial Cable Factory Machines (Lines 1 to 7)
-- ==============================================================================

INSERT INTO public.machines (id, code, name, department, status, sub_category, current_speed_mpm, total_meters_produced)
VALUES
  -- 1. Drawing Department (drawing)
  ('DR01', 'DR01', 'Copper Drawing Line 01', 'drawing', 'running', 'Copper Drawing', 1200.0, 450000.0),
  ('DR02', 'DR02', 'Copper Drawing Line 02', 'drawing', 'running', 'Copper Drawing', 1150.0, 420000.0),
  ('DR03', 'DR03', 'Copper Drawing Line 03', 'drawing', 'idle', 'Copper Drawing', 0.0, 390000.0),
  ('DR04', 'DR04', 'Aluminum & Al-Alloy Drawing 01', 'drawing', 'running', 'Aluminum & Al-Alloy Drawing', 950.0, 310000.0),
  ('DR05', 'DR05', 'Aluminum & Al-Alloy Drawing 02', 'drawing', 'running', 'Aluminum & Al-Alloy Drawing', 980.0, 330000.0),
  ('DR06', 'DR06', 'Copper Multiwire 14-Wire Line 01', 'drawing', 'running', 'Copper Multiwire (14 wires)', 1500.0, 890000.0),
  ('DR07', 'DR07', 'Copper Multiwire 14-Wire Line 02', 'drawing', 'running', 'Copper Multiwire (14 wires)', 1550.0, 920000.0),

  -- 2. Stranding & Bunching Department (stranding)
  ('RS01', 'RS01', 'Rigid Strander 61 - Line 01', 'stranding', 'running', 'Rigid Strander 61', 180.0, 125000.0),
  ('RS02', 'RS02', 'Rigid Strander 61 - Line 02', 'stranding', 'running', 'Rigid Strander 61', 175.0, 118000.0),
  ('RS03', 'RS03', 'Rigid Strander 61 - Line 03', 'stranding', 'running', 'Rigid Strander 61', 185.0, 130000.0),
  ('RS04', 'RS04', 'Rigid Strander 61 - Line 04', 'stranding', 'downtimeMaintenance', 'Rigid Strander 61', 0.0, 95000.0),
  ('CS01', 'CS01', 'Circular/Cage Strander 37 - Line 01', 'stranding', 'running', 'Circular/Cage Strander 37', 220.0, 210000.0),
  ('CS02', 'CS02', 'Circular/Cage Strander 37 - Line 02', 'stranding', 'running', 'Circular/Cage Strander 37', 215.0, 205000.0),
  ('RS05', 'RS05', 'Rigid Strander 19 - Line 05', 'stranding', 'running', 'Rigid Strander 19', 280.0, 340000.0),
  ('DTS01', 'DTS01', 'Double Twist Strander 7 - Line 01', 'stranding', 'running', 'Double Twist Strander 7', 450.0, 560000.0),
  ('BN01', 'BN01', 'Buncher 630 - Line 01', 'stranding', 'running', 'Buncher (630)', 350.0, 410000.0),
  ('BN02', 'BN02', 'Buncher 630 - Line 02', 'stranding', 'running', 'Buncher (630)', 360.0, 420000.0),
  ('BN03', 'BN03', 'Buncher 630 - Line 03', 'stranding', 'running', 'Buncher (630)', 355.0, 415000.0),
  ('BN04', 'BN04', 'Buncher 630 - Line 04', 'stranding', 'running', 'Buncher (630)', 345.0, 395000.0),
  ('BN05', 'BN05', 'Buncher 630 - Line 05', 'stranding', 'running', 'Buncher (630)', 350.0, 400000.0),
  ('BN06', 'BN06', 'Buncher 800 - Line 06', 'stranding', 'running', 'Buncher (800)', 300.0, 380000.0),
  ('BN07', 'BN07', 'Buncher 800 - Line 07', 'stranding', 'running', 'Buncher (800)', 310.0, 390000.0),
  ('BN08', 'BN08', 'Buncher 800 - Line 08', 'stranding', 'running', 'Buncher (800)', 305.0, 385000.0),

  -- 3. CCV Lines (ccv)
  ('CCV01', 'CCV01', 'Medium/High Voltage CCV Line 01 (500kV)', 'ccv', 'running', 'CCV Line (Up to 500kV)', 25.0, 85000.0),
  ('CCV02', 'CCV02', 'Medium/High Voltage CCV Line 02 (500kV)', 'ccv', 'running', 'CCV Line (Up to 500kV)', 28.0, 92000.0),
  ('CCV03', 'CCV03', 'Extra High Voltage CCV Line 03 (750kV)', 'ccv', 'running', 'CCV Line (Up to 750kV)', 18.0, 64000.0),
  ('CCV04', 'CCV04', 'Extra High Voltage CCV Line 04 (750kV)', 'ccv', 'downtimeProcess', 'CCV Line (Up to 750kV)', 0.0, 58000.0),
  ('CCV05', 'CCV05', 'Medium Voltage CCV Line 05', 'ccv', 'running', 'CCV Line (Medium Voltage)', 32.0, 110000.0),

  -- 4. Extrusion Department (extrusion)
  ('EX01', 'EX01', 'LV Extrusion Line 01 (Insulation)', 'extrusion', 'running', 'Low Voltage Extrusion', 450.0, 780000.0),
  ('EX02', 'EX02', 'LV Extrusion Line 02 (Insulation)', 'extrusion', 'running', 'Low Voltage Extrusion', 460.0, 810000.0),
  ('EX03', 'EX03', 'LV Extrusion Line 03 (Bedding)', 'extrusion', 'running', 'Low Voltage Extrusion', 420.0, 740000.0),
  ('EX04', 'EX04', 'LV Extrusion Line 04 (Jacketing)', 'extrusion', 'running', 'Low Voltage Extrusion', 380.0, 690000.0),
  ('EX05', 'EX05', 'LV Extrusion Line 05 (Jacketing)', 'extrusion', 'running', 'Low Voltage Extrusion', 390.0, 710000.0),
  ('EX06', 'EX06', 'LV Extrusion Line 06 (Insulation)', 'extrusion', 'running', 'Low Voltage Extrusion', 440.0, 760000.0),
  ('EX07', 'EX07', 'LV Extrusion Line 07 (Insulation)', 'extrusion', 'running', 'Low Voltage Extrusion', 430.0, 750000.0),
  ('EX08', 'EX08', 'LV Extrusion Line 08 (Bedding)', 'extrusion', 'running', 'Low Voltage Extrusion', 410.0, 720000.0),
  ('EX09', 'EX09', 'LV Extrusion Line 09 (Bedding)', 'extrusion', 'running', 'Low Voltage Extrusion', 415.0, 730000.0),
  ('EX10', 'EX10', 'LV Extrusion Line 10 (Jacketing)', 'extrusion', 'running', 'Low Voltage Extrusion', 375.0, 680000.0),
  ('EX11', 'EX11', 'LV Extrusion Line 11 (Jacketing)', 'extrusion', 'running', 'Low Voltage Extrusion', 385.0, 700000.0),

  -- 5. Assembly & Wire Armouring Department (assembly)
  ('DT01', 'DT01', 'Drum Twister DT-3000', 'assembly', 'running', 'Drum Twister', 45.0, 180000.0),
  ('DT02', 'DT02', 'Drum Twister DT-3600', 'assembly', 'running', 'Drum Twister', 40.0, 165000.0),
  ('DT03', 'DT03', 'Drum Twister DT-4000', 'assembly', 'running', 'Drum Twister', 35.0, 140000.0),
  ('DT04', 'DT04', 'Drum Twister DT-3200', 'assembly', 'running', 'Drum Twister', 42.0, 172000.0),
  ('BW01', 'BW01', 'Bow Cabling Line 01', 'assembly', 'running', 'Bow Cabling', 120.0, 290000.0),

  -- 6. Screening & Taping Department (screening)
  ('CT01', 'CT01', 'Copper Tape Line 01', 'screening', 'running', 'Copper Tape / Mica / PPT', 160.0, 310000.0),
  ('CT02', 'CT02', 'Copper Tape Line 02', 'screening', 'running', 'Copper Tape / Mica / PPT', 165.0, 325000.0),
  ('CT03', 'CT03', 'Copper Tape Line 03', 'screening', 'running', 'Copper Tape / Mica / PPT', 155.0, 295000.0),
  ('CW01', 'CW01', 'Copper Wire Screen Line 01', 'screening', 'running', 'Copper Wire Screen', 110.0, 240000.0),
  ('CW02', 'CW02', 'Copper Wire Screen Line 02', 'screening', 'running', 'Copper Wire Screen', 115.0, 250000.0),
  ('CW03', 'CW03', 'Copper Wire Screen Line 03', 'screening', 'running', 'Copper Wire Screen', 108.0, 235000.0),

  -- 7. Tape Armouring Department (tapeArmour)
  ('ST01', 'ST01', 'Steel Tape Armouring Line 01', 'tapeArmour', 'running', 'Steel Tape Armouring', 140.0, 280000.0),
  ('ST02', 'ST02', 'Steel Tape Armouring Line 02', 'tapeArmour', 'running', 'Steel Tape Armouring', 145.0, 290000.0),
  ('ST03', 'ST03', 'Steel Tape Armouring Line 03', 'tapeArmour', 'running', 'Steel Tape Armouring', 138.0, 275000.0),
  ('ST04', 'ST04', 'Steel Tape Armouring Line 04', 'tapeArmour', 'running', 'Steel Tape Armouring', 142.0, 285000.0)

ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  department = EXCLUDED.department,
  sub_category = EXCLUDED.sub_category,
  updated_at = NOW();

-- ==============================================================================
-- 8. Factory Spare Parts Inventory Catalog Seed
-- ==============================================================================
INSERT INTO public.spare_parts (part_code, name, category, quantity_in_stock, min_stock_level, unit_cost, location)
VALUES
  ('THC-PT100-3M', 'حساس حرارة بلاتينيوم PT100 كابل 3 متر', 'Electrical', 25, 5, 45.00, 'Warehouse Shelf A-12'),
  ('BRG-6205-2RS', 'رولمان بلي SKF 6205 2RS عالي السرعة', 'Mechanical', 40, 10, 22.50, 'Warehouse Shelf B-04'),
  ('DIE-TC-250', 'لقمة سحب تنجستن كاربايد مقاس 2.50 مم', 'Tooling', 15, 3, 120.00, 'Tooling Room C-01'),
  ('HTR-BND-400W', 'سخان حزام سيراميك 400 واط لخط البثق', 'Electrical', 30, 8, 35.00, 'Warehouse Shelf A-08'),
  ('SEAL-MECH-45', 'سيل ميكانيكي هيدروليك 45 مم لمضخة التبريد', 'Hydraulic', 12, 4, 65.00, 'Warehouse Shelf B-10'),
  ('PUL-CER-80', 'بكرة توجيه سيراميك 80 مم لخطوط الجدل', 'Consumables', 50, 15, 18.00, 'Warehouse Shelf C-05'),
  ('SW-LIM-NO-NC', 'مفتاح نهاية مشوار Limit Switch معدني', 'Electrical', 20, 5, 28.00, 'Warehouse Shelf A-15'),
  ('VLV-SOL-24V', 'صمام هيدروليك سولينويد 24V DC', 'Pneumatic', 8, 2, 85.00, 'Warehouse Shelf B-02')
ON CONFLICT (part_code) DO UPDATE SET
  name = EXCLUDED.name,
  quantity_in_stock = EXCLUDED.quantity_in_stock,
  unit_cost = EXCLUDED.unit_cost,
  location = EXCLUDED.location,
  updated_at = NOW();

