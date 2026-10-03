-- ==============================================================================
-- 20261003000011_device_tokens.sql
-- Push Notifications: Device FCM Tokens Schema, Indexes & RLS Policies
-- ==============================================================================

-- 1. Create device_tokens table
CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL UNIQUE,
    platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Create indexes for high-throughput push dispatch & token queries
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON public.device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_platform ON public.device_tokens(platform);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies: Authenticated users can only read, insert, update, and delete their own tokens
DROP POLICY IF EXISTS "Users can manage own device tokens" ON public.device_tokens;
CREATE POLICY "Users can manage own device tokens"
ON public.device_tokens
FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 5. Service role / backend functions have full access
DROP POLICY IF EXISTS "Service role full access on device_tokens" ON public.device_tokens;
CREATE POLICY "Service role full access on device_tokens"
ON public.device_tokens
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

COMMENT ON TABLE public.device_tokens IS 'Stores Firebase Cloud Messaging (FCM) registration tokens for mobile and web push notifications';
COMMENT ON COLUMN public.device_tokens.user_id IS 'Target user ID from auth.users';
COMMENT ON COLUMN public.device_tokens.fcm_token IS 'Unique Firebase Cloud Messaging device registration token';
COMMENT ON COLUMN public.device_tokens.platform IS 'Client platform: android, ios, or web';
COMMENT ON COLUMN public.device_tokens.last_seen_at IS 'Timestamp of last activity / token refresh';
