-- ==============================================================================
-- 20260921000008_storage_attachments.sql
-- Supabase Storage Configuration, Attachment RLS & Server Rate Limiter
-- ==============================================================================

-- 1. Create Private Storage Bucket for Work Order Fault / Maintenance Attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'work-order-attachments',
  'work-order-attachments',
  false,
  10485760, -- 10MB maximum file size limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- 2. Storage RLS Policies (storage.objects)
-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 2.1 SELECT Policy: View attachments for authorized work orders
DROP POLICY IF EXISTS "Authenticated users view work order attachments" ON storage.objects;
CREATE POLICY "Authenticated users view work order attachments"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'work-order-attachments'
  AND (
    -- Admin, Plant Manager, or Maintenance Supervisor can view all attachments
    private.current_app_role() IN ('admin', 'plantManager', 'maintenanceSupervisor')
    OR
    -- Check work order department / technician scoping from path <work_order_id>/<file>
    EXISTS (
      SELECT 1 FROM public.work_orders wo
      JOIN public.machines m ON m.id = wo.machine_id
      WHERE wo.id::text = split_part(name, '/', 1)
        AND (
          m.department = private.current_app_department()
          OR wo.assigned_to_technician_id = auth.uid()::text
          OR wo.reported_by = auth.uid()::text
        )
    )
  )
);

-- 2.2 INSERT Policy: Upload attachments matching authorized work order scope
DROP POLICY IF EXISTS "Authorized staff upload work order attachments" ON storage.objects;
CREATE POLICY "Authorized staff upload work order attachments"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'work-order-attachments'
  AND (
    private.current_app_role() IN ('admin', 'plantManager', 'maintenanceSupervisor')
    OR
    EXISTS (
      SELECT 1 FROM public.work_orders wo
      JOIN public.machines m ON m.id = wo.machine_id
      WHERE wo.id::text = split_part(name, '/', 1)
        AND (
          m.department = private.current_app_department()
          OR wo.assigned_to_technician_id = auth.uid()::text
          OR wo.reported_by = auth.uid()::text
        )
    )
  )
);

-- 2.3 DELETE Policy: Only Supervisors and Admins may delete attachments
DROP POLICY IF EXISTS "Supervisors and admins delete work order attachments" ON storage.objects;
CREATE POLICY "Supervisors and admins delete work order attachments"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'work-order-attachments'
  AND private.current_app_role() IN ('admin', 'plantManager', 'maintenanceSupervisor')
);

-- 3. Application-Level Rate Limiter Table and Helper
CREATE TABLE IF NOT EXISTS private.rate_limit_tracker (
  actor_id UUID NOT NULL,
  action_key TEXT NOT NULL,
  window_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  request_count INT NOT NULL DEFAULT 1,
  PRIMARY KEY (actor_id, action_key)
);

CREATE OR REPLACE FUNCTION private.check_rpc_rate_limit(
  p_actor_id UUID,
  p_action TEXT,
  p_max_requests INT DEFAULT 100,
  p_window_seconds INT DEFAULT 60
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_current_count INT;
  v_window_start TIMESTAMPTZ;
BEGIN
  SELECT window_start, request_count
  INTO v_window_start, v_current_count
  FROM private.rate_limit_tracker
  WHERE actor_id = p_actor_id AND action_key = p_action
  FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO private.rate_limit_tracker (actor_id, action_key, window_start, request_count)
    VALUES (p_actor_id, p_action, NOW(), 1);
  ELSIF NOW() - v_window_start > (p_window_seconds || ' seconds')::interval THEN
    UPDATE private.rate_limit_tracker
    SET window_start = NOW(), request_count = 1
    WHERE actor_id = p_actor_id AND action_key = p_action;
  ELSIF v_current_count >= p_max_requests THEN
    RAISE EXCEPTION 'RATE_LIMIT_EXCEEDED: Maximum request limit reached. Please wait before retrying.'
      USING errcode = 'P0429';
  ELSE
    UPDATE private.rate_limit_tracker
    SET request_count = request_count + 1
    WHERE actor_id = p_actor_id AND action_key = p_action;
  END IF;
END;
$$;
