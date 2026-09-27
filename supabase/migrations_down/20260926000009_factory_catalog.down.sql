-- Roll back policies and catalog objects introduced by the factory catalog migration.
-- Keep public.spare_parts and its additive dashboard columns: older deployments may
-- already use this table for warehouse stock, and dropping it could destroy data.
DROP TRIGGER IF EXISTS spare_parts_updated_at ON public.spare_parts;
DROP FUNCTION IF EXISTS public.set_spare_parts_updated_at();

-- machine_bom, factory_roles, and spare_parts predate this migration on some
-- deployments. Keep all catalog tables and read policies so rollback cannot
-- remove existing inventory, BOM rows, or role metadata. The new policies are
-- also retained so access does not silently disappear if this rollback runs.
