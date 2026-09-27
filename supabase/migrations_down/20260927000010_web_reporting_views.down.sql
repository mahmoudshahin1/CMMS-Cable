-- Remove only views introduced by this migration. Reporting views that already
-- existed before it are retained to avoid breaking live dashboard consumers.
DO $$
DECLARE
  created_view RECORD;
BEGIN
  FOR created_view IN
    SELECT view_name FROM private._cmms_migration_10_views_created
  LOOP
    EXECUTE format('DROP VIEW IF EXISTS public.%I', created_view.view_name);
  END LOOP;
END;
$$;

DROP TABLE IF EXISTS private._cmms_migration_10_views_created;
