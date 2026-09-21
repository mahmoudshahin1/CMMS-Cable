-- ==============================================================================
-- 20260921000002_core_schema.down.sql
-- Rollback for 20260921000002_core_schema.sql
-- ==============================================================================

-- 1. Drop triggers
DROP TRIGGER IF EXISTS downtime_logs_touch ON public.downtime_logs;
DROP TRIGGER IF EXISTS work_orders_touch ON public.work_orders;
DROP TRIGGER IF EXISTS machines_touch ON public.machines;
DROP FUNCTION IF EXISTS public.touch_updated_at();

-- 2. Drop tables in reverse foreign-key order
DROP TABLE IF EXISTS public.downtime_logs CASCADE;
DROP TABLE IF EXISTS public.work_order_parts CASCADE;
DROP TABLE IF EXISTS public.work_order_events CASCADE;
DROP TABLE IF EXISTS public.work_order_commands CASCADE;
DROP TABLE IF EXISTS public.work_orders CASCADE;
DROP TABLE IF EXISTS public.machines CASCADE;

-- 3. Drop private schema if empty
DROP SCHEMA IF EXISTS private CASCADE;
