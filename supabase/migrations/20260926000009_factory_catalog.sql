-- Reference data for the factory dashboard. Auth identities remain managed by Supabase Auth.
CREATE TABLE IF NOT EXISTS public.factory_departments (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_ar TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.factory_roles (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_ar TEXT NOT NULL,
  web_access BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.spare_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  part_code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  unit TEXT NOT NULL DEFAULT 'piece',
  quantity_on_hand NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
  reorder_level NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (reorder_level >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.machine_bom (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  machine_id TEXT NOT NULL REFERENCES public.machines(id) ON DELETE CASCADE,
  spare_part_id UUID NOT NULL REFERENCES public.spare_parts(id) ON DELETE CASCADE,
  quantity_per_machine NUMERIC(12, 2) NOT NULL DEFAULT 1 CHECK (quantity_per_machine > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (machine_id, spare_part_id)
);

ALTER TABLE public.factory_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.factory_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spare_parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.machine_bom ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.factory_departments, public.factory_roles, public.spare_parts, public.machine_bom TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.spare_parts, public.machine_bom TO authenticated;

DROP POLICY IF EXISTS "Authenticated users can read factory departments" ON public.factory_departments;
CREATE POLICY "Authenticated users can read factory departments" ON public.factory_departments
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Authenticated users can read factory roles" ON public.factory_roles;
CREATE POLICY "Authenticated users can read factory roles" ON public.factory_roles
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Authenticated users can read spare parts" ON public.spare_parts;
CREATE POLICY "Authenticated users can read spare parts" ON public.spare_parts
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Admins manage spare parts" ON public.spare_parts;
CREATE POLICY "Admins manage spare parts" ON public.spare_parts
  FOR ALL TO authenticated USING (public.current_user_role() = 'ADMIN')
  WITH CHECK (public.current_user_role() = 'ADMIN');
DROP POLICY IF EXISTS "Authenticated users can read machine BOM" ON public.machine_bom;
CREATE POLICY "Authenticated users can read machine BOM" ON public.machine_bom
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Admins manage machine BOM" ON public.machine_bom;
CREATE POLICY "Admins manage machine BOM" ON public.machine_bom
  FOR ALL TO authenticated USING (public.current_user_role() = 'ADMIN')
  WITH CHECK (public.current_user_role() = 'ADMIN');

CREATE OR REPLACE FUNCTION public.set_spare_parts_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS spare_parts_updated_at ON public.spare_parts;
CREATE TRIGGER spare_parts_updated_at BEFORE UPDATE ON public.spare_parts
FOR EACH ROW EXECUTE FUNCTION public.set_spare_parts_updated_at();
