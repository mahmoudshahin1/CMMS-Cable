-- Roll back policies and catalog objects introduced by the factory catalog migration.
-- Keep public.spare_parts and its additive dashboard columns: older deployments may
-- already use this table for warehouse stock, and dropping it could destroy data.
DROP TRIGGER IF EXISTS spare_parts_updated_at ON public.spare_parts;
DROP FUNCTION IF EXISTS public.set_spare_parts_updated_at();

DROP POLICY IF EXISTS "Admins manage machine BOM" ON public.machine_bom;
DROP POLICY IF EXISTS "Authenticated users can read machine BOM" ON public.machine_bom;
DROP TABLE IF EXISTS public.machine_bom;

DROP POLICY IF EXISTS "Admins manage spare parts" ON public.spare_parts;
DROP POLICY IF EXISTS spare_parts_all ON public.spare_parts;
DROP POLICY IF EXISTS "Authenticated users can read spare parts" ON public.spare_parts;

DROP POLICY IF EXISTS "Authenticated users can read factory roles" ON public.factory_roles;
DROP TABLE IF EXISTS public.factory_roles;

DROP POLICY IF EXISTS "Authenticated users can read factory departments" ON public.factory_departments;
DROP TABLE IF EXISTS public.factory_departments;
