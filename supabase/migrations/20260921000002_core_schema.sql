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
  command_id UUID REFERENCES public.work_order_commands(command_id) ON DELETE SET NULL,
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
  command_id UUID REFERENCES public.work_order_commands(command_id) ON DELETE SET NULL,
  part_code TEXT,
  part_name TEXT NOT NULL,
  quantity NUMERIC NOT NULL CHECK (quantity > 0),
  unit_cost NUMERIC,
  added_by UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
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
