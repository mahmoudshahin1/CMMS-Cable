-- ==============================================================================
-- 20260921000004_workflow_commands.down.sql
-- Rollback for 20260921000004_workflow_commands.sql
-- ==============================================================================

DROP FUNCTION IF EXISTS public.rpc_close_work_order(UUID, UUID, INT, TEXT, TEXT, TEXT, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS public.rpc_confirm_test_run(UUID, UUID, INT, TEXT, TEXT, TEXT, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS public.rpc_complete_work_order(UUID, UUID, INT, TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS public.rpc_add_work_order_part(UUID, UUID, UUID, TEXT, TEXT, NUMERIC, NUMERIC, TEXT, TEXT, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS public.rpc_start_work_order(UUID, UUID, INT, TEXT, TEXT, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS public.rpc_assign_work_order(UUID, UUID, INT, UUID, TEXT, TEXT, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS public.rpc_create_work_order(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ);
