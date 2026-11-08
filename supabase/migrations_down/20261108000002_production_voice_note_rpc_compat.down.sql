-- Keep the hardened grants and auth ordering in place when rolling back the
-- compatibility layer. Remove only the RPC and update policy introduced here.
DROP FUNCTION IF EXISTS public.rpc_attach_work_order_voice_note(
  UUID, UUID, TEXT, TIMESTAMPTZ
);
DROP POLICY IF EXISTS "Authorized staff update work order attachments"
  ON storage.objects;

-- Audio MIME types and corrected SELECT/INSERT policies are retained because
-- they are required by the mobile voice-note flow and are safe improvements
-- over the drifted hosted definitions.
