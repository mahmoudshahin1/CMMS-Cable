-- ==============================================================================
-- 20260921000001_profiles_hardening.down.sql
-- Rollback for 20260921000001_profiles_hardening.sql
-- ==============================================================================

-- 1. Drop RLS policies
DROP POLICY IF EXISTS "Profiles read policy" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own full_name" ON public.user_profiles;
DROP POLICY IF EXISTS "Allow authenticated users to read all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;

-- 2. Drop helper functions
DROP FUNCTION IF EXISTS public.current_user_role();
DROP FUNCTION IF EXISTS public.current_user_department();

-- 3. Revert privileges
REVOKE SELECT ON public.user_profiles FROM authenticated;
REVOKE UPDATE ON public.user_profiles FROM authenticated;
