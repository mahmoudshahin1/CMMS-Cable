-- Restore the work-order-scoped Storage policy behavior that existed before
-- this migration. Preserve audio MIME support from the preceding compatibility
-- migration so rollback does not disable the original fault-audio flow.
UPDATE storage.buckets
SET allowed_mime_types = ARRAY[
  'image/jpeg', 'image/png', 'image/webp',
  'audio/mp4', 'audio/mpeg', 'audio/aac', 'audio/wav', 'audio/ogg'
]
WHERE id = 'work-order-attachments';

DROP POLICY IF EXISTS "Authorized staff update work order attachments" ON storage.objects;
CREATE POLICY "Authorized staff update work order attachments"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'work-order-attachments'
  AND EXISTS (
    SELECT 1 FROM public.work_orders wo
    JOIN public.machines m ON m.id = wo.machine_id
    WHERE wo.id::text = split_part(name, '/', 1)
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
    WHERE wo.id::text = split_part(name, '/', 1)
      AND (
        private.current_app_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager', 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor')
        OR m.department = private.current_app_department()
        OR wo.assigned_to_technician_id = auth.uid()
        OR wo.reported_by = auth.uid()
      )
  )
);

DROP POLICY IF EXISTS "Authenticated users view work order attachments" ON storage.objects;
CREATE POLICY "Authenticated users view work order attachments"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'work-order-attachments'
  AND EXISTS (
    SELECT 1 FROM public.work_orders wo
    JOIN public.machines m ON m.id = wo.machine_id
    WHERE wo.id::text = split_part(name, '/', 1)
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
    SELECT 1 FROM public.work_orders wo
    JOIN public.machines m ON m.id = wo.machine_id
    WHERE wo.id::text = split_part(name, '/', 1)
      AND (
        private.current_app_role() IN ('ADMIN', 'admin', 'PLANT_MANAGER', 'plant_manager', 'SUPERVISOR', 'supervisor', 'MAINTENANCE_SUPERVISOR', 'maintenance_supervisor')
        OR m.department = private.current_app_department()
        OR wo.assigned_to_technician_id = auth.uid()
        OR wo.reported_by = auth.uid()
      )
  )
);
