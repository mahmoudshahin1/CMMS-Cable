-- ==============================================================================
-- 20260921000007_composite_indexes.down.sql
-- Rollback for 20260921000007_composite_indexes.sql
-- ==============================================================================

DROP INDEX IF EXISTS public.idx_machines_dept_status;
DROP INDEX IF EXISTS public.idx_wo_commands_wo_type;
DROP INDEX IF EXISTS public.idx_downtime_logs_work_order;
DROP INDEX IF EXISTS public.idx_downtime_logs_prod_date;
DROP INDEX IF EXISTS public.idx_downtime_logs_machine_ended;
DROP INDEX IF EXISTS public.idx_downtime_logs_updated_at_id;
DROP INDEX IF EXISTS public.idx_wo_parts_received_at_id;
DROP INDEX IF EXISTS public.idx_wo_parts_wo_received;
DROP INDEX IF EXISTS public.idx_wo_events_received_at_id;
DROP INDEX IF EXISTS public.idx_wo_events_wo_received;
DROP INDEX IF EXISTS public.idx_work_orders_type_status;
DROP INDEX IF EXISTS public.idx_work_orders_reported_by;
DROP INDEX IF EXISTS public.idx_work_orders_assigned_status;
DROP INDEX IF EXISTS public.idx_work_orders_machine_status;
DROP INDEX IF EXISTS public.idx_work_orders_updated_at_id;
