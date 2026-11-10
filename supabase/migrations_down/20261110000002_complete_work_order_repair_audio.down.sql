DROP FUNCTION IF EXISTS public.rpc_complete_work_order(
  UUID, UUID, INT, TEXT, TEXT, JSONB, TEXT, TEXT, TEXT, TIMESTAMPTZ
);

-- Keep repair_steps and repair_voice_url columns on rollback to avoid deleting
-- repair data and to remain safe where either column pre-dated this migration.
