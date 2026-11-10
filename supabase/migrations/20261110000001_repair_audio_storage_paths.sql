-- Keep work-order attachments private while allowing the audio MIME types used by the mobile recorder.
UPDATE storage.buckets
SET public = false,
    allowed_mime_types = ARRAY[
      'image/jpeg', 'image/png', 'image/webp',
      'audio/mp4', 'audio/mpeg', 'audio/aac', 'audio/wav', 'audio/ogg'
    ]
WHERE id = 'work-order-attachments';

-- Current paths are <work_order_id>/..., legacy mobile paths are voice-notes/<work_order_id>/....
DROP POLICY IF EXISTS "Authenticated users view work order attachments" ON storage.objects;
CREATE POLICY "Authenticated users view work order attachments"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'work-order-attachments'
  AND EXISTS (
    SELECT 1
    FROM public.work_orders wo
    JOIN public.machines m ON m.id = wo.machine_id
    WHERE wo.id::text = CASE
      WHEN split_part(storage.objects.name, '/', 1) = 'voice-notes' THEN split_part(storage.objects.name, '/', 2)
      ELSE split_part(storage.objects.name, '/', 1)
    END
    AND (
      private.current_app_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager', 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor')
      OR m.department = private.current_app_department()
      OR wo.assigned_to_technician_id = auth.uid()
      OR wo.reported_by = auth.uid()
    )
  )
);

DROP POLICY IF EXISTS "Authorized staff upload work order attachments" ON storage.objects;
CREATE POLICY "Authorized staff upload work order attachments"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'work-order-attachments'
  AND EXISTS (
    SELECT 1
    FROM public.work_orders wo
    JOIN public.machines m ON m.id = wo.machine_id
    WHERE wo.id::text = CASE
      WHEN split_part(storage.objects.name, '/', 1) = 'voice-notes' THEN split_part(storage.objects.name, '/', 2)
      ELSE split_part(storage.objects.name, '/', 1)
    END
    AND (
      private.current_app_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager', 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor')
      OR m.department = private.current_app_department()
      OR wo.assigned_to_technician_id = auth.uid()
      OR wo.reported_by = auth.uid()
    )
  )
);

DROP POLICY IF EXISTS "Authorized staff update work order attachments" ON storage.objects;
CREATE POLICY "Authorized staff update work order attachments"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'work-order-attachments'
  AND EXISTS (
    SELECT 1 FROM public.work_orders wo
    JOIN public.machines m ON m.id = wo.machine_id
    WHERE wo.id::text = CASE
      WHEN split_part(storage.objects.name, '/', 1) = 'voice-notes' THEN split_part(storage.objects.name, '/', 2)
      ELSE split_part(storage.objects.name, '/', 1)
    END
    AND (
      private.current_app_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager', 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor')
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
    WHERE wo.id::text = CASE
      WHEN split_part(storage.objects.name, '/', 1) = 'voice-notes' THEN split_part(storage.objects.name, '/', 2)
      ELSE split_part(storage.objects.name, '/', 1)
    END
    AND (
      private.current_app_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager', 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor')
      OR m.department = private.current_app_department()
      OR wo.assigned_to_technician_id = auth.uid()
      OR wo.reported_by = auth.uid()
    )
  )
);
