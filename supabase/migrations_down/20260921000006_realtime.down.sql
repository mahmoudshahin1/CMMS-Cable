-- ==============================================================================
-- 20260921000006_realtime.down.sql
-- Rollback for 20260921000006_realtime.sql
-- ==============================================================================

-- 1. Remove tables from publication if present
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS public.downtime_logs;
    ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS public.work_order_parts;
    ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS public.work_order_events;
    ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS public.work_orders;
    ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS public.machines;
  END IF;
END;
$$;

-- 2. Restore default replica identity
ALTER TABLE public.downtime_logs REPLICA IDENTITY DEFAULT;
ALTER TABLE public.work_orders REPLICA IDENTITY DEFAULT;
ALTER TABLE public.machines REPLICA IDENTITY DEFAULT;
