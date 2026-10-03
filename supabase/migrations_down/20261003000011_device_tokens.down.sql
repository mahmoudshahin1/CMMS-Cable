-- ==============================================================================
-- 20261003000011_device_tokens.down.sql
-- Reversal of Device FCM Tokens Schema, Indexes & RLS Policies
-- ==============================================================================

-- 1. Drop RLS Policies
DROP POLICY IF EXISTS "Service role full access on device_tokens" ON public.device_tokens;
DROP POLICY IF EXISTS "Users can manage own device tokens" ON public.device_tokens;

-- 2. Drop Indexes
DROP INDEX IF EXISTS public.idx_device_tokens_platform;
DROP INDEX IF EXISTS public.idx_device_tokens_user_id;

-- 3. Drop Table
DROP TABLE IF EXISTS public.device_tokens CASCADE;
