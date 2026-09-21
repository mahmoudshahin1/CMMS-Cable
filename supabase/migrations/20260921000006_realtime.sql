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
