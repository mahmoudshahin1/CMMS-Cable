-- ==============================================================================
-- 20260921000005_audit_and_machine_rules.sql
-- Multi-Work-Order Machine State Consistency & Immutable Audit Guards
-- ==============================================================================

-- 1. Multi-Work-Order Aware Machine Status Synchronization
CREATE OR REPLACE FUNCTION public.sync_machine_from_work_order()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_has_active_breakdown BOOLEAN;
BEGIN
  -- When a breakdown work order is created, machine enters maintenance downtime
  IF TG_OP = 'INSERT' AND NEW.type = 'breakdown' THEN
    UPDATE public.machines
    SET status = 'downtimeMaintenance',
        updated_at = NOW()
    WHERE id = NEW.machine_id;

  -- When work order moves to inProgress, machine enters underRepair
  ELSIF NEW.status = 'inProgress' AND (TG_OP = 'INSERT' OR OLD.status <> 'inProgress') THEN
    UPDATE public.machines
    SET status = 'underRepair',
        updated_at = NOW()
    WHERE id = NEW.machine_id;

  -- When work order is completed or closed, check if ANY OTHER active breakdown ticket exists
  ELSIF (NEW.status IN ('completed', 'verified', 'verifiedClosed'))
        AND (TG_OP = 'UPDATE' AND OLD.status NOT IN ('completed', 'verified', 'verifiedClosed')) THEN

    -- Check if any other active breakdown ticket exists for this machine
    SELECT EXISTS (
      SELECT 1 FROM public.work_orders
      WHERE machine_id = NEW.machine_id
        AND id <> NEW.id
        AND type = 'breakdown'
        AND status IN ('open', 'assigned', 'inProgress', 'pendingParts')
    ) INTO v_has_active_breakdown;

    -- Only restore running status if NO OTHER active breakdown remains
    IF NOT v_has_active_breakdown THEN
      UPDATE public.machines
      SET status = 'running',
          last_maintenance_at = COALESCE(NEW.closed_at, NEW.completed_at, NOW()),
          updated_at = NOW()
      WHERE id = NEW.machine_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_work_orders_machine_sync ON public.work_orders;
CREATE TRIGGER trg_work_orders_machine_sync
AFTER INSERT OR UPDATE ON public.work_orders
FOR EACH ROW EXECUTE FUNCTION public.sync_machine_from_work_order();

-- 2. Audit Trail Immutability Guard (Prevent UPDATE/DELETE on audit tables)
CREATE OR REPLACE FUNCTION public.guard_audit_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION 'FORBIDDEN: Audit events and parts records are strictly immutable'
    USING errcode = '42501';
END;
$$;

DROP TRIGGER IF EXISTS trg_wo_events_immutable ON public.work_order_events;
CREATE TRIGGER trg_wo_events_immutable
BEFORE UPDATE OR DELETE ON public.work_order_events
FOR EACH ROW EXECUTE FUNCTION public.guard_audit_immutability();

DROP TRIGGER IF EXISTS trg_wo_parts_immutable ON public.work_order_parts;
CREATE TRIGGER trg_wo_parts_immutable
BEFORE UPDATE OR DELETE ON public.work_order_parts
FOR EACH ROW EXECUTE FUNCTION public.guard_audit_immutability();

DROP TRIGGER IF EXISTS trg_wo_commands_immutable ON public.work_order_commands;
CREATE TRIGGER trg_wo_commands_immutable
BEFORE UPDATE OR DELETE ON public.work_order_commands
FOR EACH ROW EXECUTE FUNCTION public.guard_audit_immutability();

-- 3. Downtime Log Management RPCs with Server Clock Authority
CREATE OR REPLACE FUNCTION public.rpc_create_downtime_log(
  p_id UUID,
  p_machine_id TEXT,
  p_category TEXT,
  p_reason TEXT,
  p_is_maintenance_requested BOOLEAN DEFAULT FALSE,
  p_work_order_id UUID DEFAULT NULL,
  p_comments TEXT DEFAULT NULL,
  p_start_chronology JSONB DEFAULT NULL,
  p_shift_minutes JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_server_time TIMESTAMPTZ := NOW();
  v_result JSONB;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  INSERT INTO public.downtime_logs (
    id, machine_id, category, reason, is_maintenance_requested,
    work_order_id, comments, started_at, production_date,
    start_chronology, shift_minutes, created_by, updated_at
  ) VALUES (
    p_id, p_machine_id, p_category, p_reason, p_is_maintenance_requested,
    p_work_order_id, p_comments, v_server_time, CURRENT_DATE,
    p_start_chronology, p_shift_minutes, v_caller_id, v_server_time
  );

  SELECT to_jsonb(d) INTO v_result
  FROM public.downtime_logs d
  WHERE d.id = p_id;

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.rpc_close_downtime_log(
  p_id UUID,
  p_end_chronology JSONB DEFAULT NULL,
  p_shift_minutes JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_server_time TIMESTAMPTZ := NOW();
  v_result JSONB;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  UPDATE public.downtime_logs
  SET ended_at = v_server_time,
      end_chronology = p_end_chronology,
      shift_minutes = p_shift_minutes,
      updated_at = v_server_time
  WHERE id = p_id AND ended_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: Active downtime log % not found or already closed', p_id USING errcode = 'P0002';
  END IF;

  SELECT to_jsonb(d) INTO v_result
  FROM public.downtime_logs d
  WHERE d.id = p_id;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rpc_create_downtime_log, public.rpc_close_downtime_log FROM public, anon;
GRANT EXECUTE ON FUNCTION public.rpc_create_downtime_log, public.rpc_close_downtime_log TO authenticated;
