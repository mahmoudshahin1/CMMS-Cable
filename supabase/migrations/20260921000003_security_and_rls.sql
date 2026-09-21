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
