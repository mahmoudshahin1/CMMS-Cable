-- Keep Supabase Storage validation aligned with voice recordings from mobile.
ALTER TABLE public.work_orders
  ADD COLUMN IF NOT EXISTS voice_note_url TEXT;

UPDATE storage.buckets
SET allowed_mime_types = ARRAY[
  'image/jpeg', 'image/png', 'image/webp',
  'audio/mp4', 'audio/mpeg', 'audio/aac', 'audio/wav', 'audio/ogg'
]
WHERE id = 'work-order-attachments';

DROP POLICY IF EXISTS "Authorized staff update work order attachments" ON storage.objects;
CREATE POLICY "Authorized staff update work order attachments"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'work-order-attachments'
  AND EXISTS (
    SELECT 1 FROM public.work_orders wo
    JOIN public.machines m ON m.id = wo.machine_id
    WHERE wo.id::text = split_part(name, '/', 1)
      AND (
        private.current_app_role() IN (
          'ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager',
          'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR',
          'maintenance_supervisor'
        )
        OR m.department = private.current_app_department()
        OR wo.assigned_to_technician_id = auth.uid()
        OR wo.reported_by = auth.uid()
      )
  )
)
WITH CHECK (
  bucket_id = 'work-order-attachments'
  AND EXISTS (
    SELECT 1 FROM public.work_orders wo
    JOIN public.machines m ON m.id = wo.machine_id
    WHERE wo.id::text = split_part(name, '/', 1)
      AND (
        private.current_app_role() IN (
          'ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager',
          'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR',
          'maintenance_supervisor'
        )
        OR m.department = private.current_app_department()
        OR wo.assigned_to_technician_id = auth.uid()
        OR wo.reported_by = auth.uid()
      )
  )
);

-- The app sends named RPC parameters, so drop the old overload before adding
-- the voice_note_url argument supported by the current mobile client.
DROP FUNCTION IF EXISTS public.rpc_create_work_order(
  UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ
);

CREATE OR REPLACE FUNCTION public.rpc_create_work_order(
  p_command_id UUID,
  p_wo_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_machine_id TEXT,
  p_type TEXT,
  p_priority TEXT,
  p_voice_note_url TEXT DEFAULT NULL,
  p_device_id TEXT DEFAULT NULL,
  p_app_version TEXT DEFAULT NULL,
  p_occurred_at TIMESTAMPTZ DEFAULT NOW()
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_role TEXT;
  v_dept TEXT;
  v_machine_dept TEXT;
  v_existing_cmd JSONB;
  v_result JSONB;
  v_server_time TIMESTAMPTZ := NOW();
BEGIN
  SELECT result INTO v_existing_cmd
  FROM public.work_order_commands
  WHERE command_id = p_command_id;
  IF v_existing_cmd IS NOT NULL THEN RETURN v_existing_cmd; END IF;

  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;

  SELECT role, department INTO v_role, v_dept
  FROM public.user_profiles WHERE id = v_caller_id;
  SELECT department INTO v_machine_dept
  FROM public.machines WHERE id = p_machine_id;
  IF v_machine_dept IS NULL THEN
    RAISE EXCEPTION 'NOT_FOUND: Machine % does not exist', p_machine_id USING errcode = 'P0002';
  END IF;

  IF v_role = 'OPERATOR' THEN
    IF v_dept IS DISTINCT FROM v_machine_dept THEN
      RAISE EXCEPTION 'FORBIDDEN: Operators can only report for their own department machines' USING errcode = '42501';
    END IF;
  ELSIF v_role NOT IN ('SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR',
                       'maintenance_supervisor', 'PRODUCTION_SUPERVISOR',
                       'production_supervisor', 'ADMIN', 'admin',
                       'PLANT_MANAGER', 'plant_manager') THEN
    RAISE EXCEPTION 'FORBIDDEN: Role % cannot create work orders', v_role USING errcode = '42501';
  END IF;

  INSERT INTO public.work_orders (
    id, title, description, machine_id, type, status, priority,
    reported_by, created_at, version, updated_at, voice_note_url
  ) VALUES (
    p_wo_id, p_title, p_description, p_machine_id, p_type, 'open', p_priority,
    v_caller_id, v_server_time, 1, v_server_time, p_voice_note_url
  );

  INSERT INTO public.work_order_events (
    id, work_order_id, command_id, event_type, actor_id,
    occurred_at, received_at, old_status, new_status, payload, device_id, app_version
  ) VALUES (
    gen_random_uuid(), p_wo_id, p_command_id, 'REPORTED', v_caller_id,
    p_occurred_at, v_server_time, NULL, 'open',
    jsonb_build_object('title', p_title, 'type', p_type, 'priority', p_priority,
                       'voice_note_url', p_voice_note_url),
    p_device_id, p_app_version
  );

  SELECT to_jsonb(w) INTO v_result FROM public.work_orders w WHERE w.id = p_wo_id;
  INSERT INTO public.work_order_commands (
    command_id, work_order_id, command_type, actor_id, created_at, processed_at, result
  ) VALUES (
    p_command_id, p_wo_id, 'CREATE_WORK_ORDER', v_caller_id,
    p_occurred_at, v_server_time, v_result
  );
  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.rpc_attach_work_order_voice_note(
  p_command_id UUID,
  p_wo_id UUID,
  p_voice_note_url TEXT,
  p_occurred_at TIMESTAMPTZ DEFAULT NOW()
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_existing_cmd JSONB;
  v_work_order public.work_orders%ROWTYPE;
  v_result JSONB;
BEGIN
  SELECT result INTO v_existing_cmd
  FROM public.work_order_commands WHERE command_id = p_command_id;
  IF v_existing_cmd IS NOT NULL THEN RETURN v_existing_cmd; END IF;
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required' USING errcode = '42501';
  END IF;
  IF p_voice_note_url IS NULL OR
     split_part(p_voice_note_url, '/', 1) <> p_wo_id::text THEN
    RAISE EXCEPTION 'FORBIDDEN: Voice note path does not match work order' USING errcode = '42501';
  END IF;

  SELECT * INTO v_work_order FROM public.work_orders WHERE id = p_wo_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: Work order does not exist' USING errcode = 'P0002';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM storage.objects
    WHERE bucket_id = 'work-order-attachments' AND name = p_voice_note_url
  ) THEN
    RAISE EXCEPTION 'NOT_FOUND: Uploaded voice note does not exist' USING errcode = 'P0002';
  END IF;
  IF v_work_order.reported_by <> v_caller_id AND
     private.current_app_role() NOT IN (
       'ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager', 'SUPERVISOR',
       'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor'
     ) THEN
    RAISE EXCEPTION 'FORBIDDEN: Caller cannot attach voice note to work order' USING errcode = '42501';
  END IF;

  UPDATE public.work_orders SET voice_note_url = p_voice_note_url, updated_at = NOW()
  WHERE id = p_wo_id;
  SELECT to_jsonb(w) INTO v_result FROM public.work_orders w WHERE w.id = p_wo_id;
  INSERT INTO public.work_order_events (
    id, work_order_id, command_id, event_type, actor_id,
    occurred_at, received_at, old_status, new_status, payload
  ) VALUES (
    gen_random_uuid(), p_wo_id, p_command_id, 'VOICE_NOTE_ATTACHED', v_caller_id,
    p_occurred_at, NOW(), v_work_order.status, v_work_order.status,
    jsonb_build_object('voice_note_url', p_voice_note_url)
  );
  INSERT INTO public.work_order_commands (
    command_id, work_order_id, command_type, actor_id, created_at, processed_at, result
  ) VALUES (
    p_command_id, p_wo_id, 'ATTACH_WORK_ORDER_VOICE_NOTE', v_caller_id,
    p_occurred_at, NOW(), v_result
  );
  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rpc_create_work_order(
  UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rpc_create_work_order(
  UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ
) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.rpc_attach_work_order_voice_note(
  UUID, UUID, TEXT, TIMESTAMPTZ
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rpc_attach_work_order_voice_note(
  UUID, UUID, TEXT, TIMESTAMPTZ
) TO authenticated;
