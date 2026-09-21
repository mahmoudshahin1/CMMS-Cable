-- ==============================================================================
-- 20260921000005_audit_and_machine_rules.down.sql
-- Rollback for 20260921000005_audit_and_machine_rules.sql
-- ==============================================================================

-- 1. Drop downtime RPCs
DROP FUNCTION IF EXISTS public.rpc_close_downtime_log(UUID, JSONB, JSONB);
DROP FUNCTION IF EXISTS public.rpc_create_downtime_log(UUID, TEXT, TEXT, TEXT, BOOLEAN, UUID, TEXT, JSONB, JSONB);

-- 2. Drop immutability triggers and guard
DROP TRIGGER IF EXISTS trg_wo_commands_immutable ON public.work_order_commands;
DROP TRIGGER IF EXISTS trg_wo_parts_immutable ON public.work_order_parts;
DROP TRIGGER IF EXISTS trg_wo_events_immutable ON public.work_order_events;
DROP FUNCTION IF EXISTS public.guard_audit_immutability();

-- 3. Drop machine sync trigger and function
DROP TRIGGER IF EXISTS trg_work_orders_machine_sync ON public.work_orders;
DROP FUNCTION IF EXISTS public.sync_machine_from_work_order();
