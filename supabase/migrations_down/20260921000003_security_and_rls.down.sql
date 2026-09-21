-- ==============================================================================
-- 20260921000003_security_and_rls.down.sql
-- Rollback for 20260921000003_security_and_rls.sql
-- ==============================================================================

-- 1. Drop RLS policies
DROP POLICY IF EXISTS dt_update ON public.downtime_logs;
DROP POLICY IF EXISTS dt_insert ON public.downtime_logs;
DROP POLICY IF EXISTS dt_select ON public.downtime_logs;
DROP POLICY IF EXISTS wop_select ON public.work_order_parts;
DROP POLICY IF EXISTS woe_select ON public.work_order_events;
DROP POLICY IF EXISTS wo_commands_select ON public.work_order_commands;
DROP POLICY IF EXISTS wo_select ON public.work_orders;
DROP POLICY IF EXISTS machines_select ON public.machines;

-- 2. Drop helper functions in private schema
DROP FUNCTION IF EXISTS private.can_view_work_order(UUID);
DROP FUNCTION IF EXISTS private.is_assigned_to_machine(TEXT);
DROP FUNCTION IF EXISTS private.machine_department(TEXT);
DROP FUNCTION IF EXISTS private.current_app_department();
DROP FUNCTION IF EXISTS private.current_app_role();
