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
