-- ==============================================================================
-- 20260921000001_profiles_hardening.sql
-- Security Hardening for public.user_profiles
-- Prevents clients from updating role, department, specialty, or employee_code.
-- Only full_name can be updated by the authenticated user.
-- ==============================================================================

-- 1. Ensure table structure is present
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'OPERATOR',
  department TEXT,
  specialty TEXT,
  employee_code TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure RLS is active
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 2. Revoke broad update privileges from authenticated and anon
REVOKE ALL ON public.user_profiles FROM anon;
REVOKE UPDATE ON public.user_profiles FROM authenticated;

-- 3. Grant column-specific update on full_name only
GRANT SELECT ON public.user_profiles TO authenticated;
GRANT UPDATE (full_name) ON public.user_profiles TO authenticated;

-- 4. Helper functions for role & department scoping (SECURITY DEFINER with empty search_path)
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT role FROM public.user_profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.current_user_department()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT department FROM public.user_profiles WHERE id = auth.uid();
$$;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION public.current_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_user_department() TO authenticated;

-- 5. Re-declare robust RLS policies on user_profiles
DROP POLICY IF EXISTS "Allow authenticated users to read all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Profiles read policy" ON public.user_profiles;

CREATE POLICY "Profiles read policy"
  ON public.user_profiles FOR SELECT
  TO authenticated
  USING (
    -- 1. Self row is always readable
    auth.uid() = id
    OR
    -- 2. Plant Managers / Admins can read all profiles
    public.current_user_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager')
    OR
    -- 3. Maintenance Supervisors can read technicians (for assignment) and supervisors
    (
      public.current_user_role() IN ('SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor')
      AND role IN ('TECHNICIAN', 'technician', 'MAINTENANCE_TECH', 'maintenance_tech', 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor')
    )
    OR
    -- 4. Production Supervisors can read operators in their own department and technicians
    (
      public.current_user_role() IN ('PRODUCTION_SUPERVISOR', 'production_supervisor')
      AND (
        department = public.current_user_department()
        OR role IN ('TECHNICIAN', 'technician', 'MAINTENANCE_TECH', 'maintenance_tech')
      )
    )
  );

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own full_name" ON public.user_profiles;
CREATE POLICY "Users can update own full_name"
  ON public.user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

