-- ==============================================================================
-- 20260921000008_storage_attachments.down.sql
-- Reversal of Storage Bucket, Attachment RLS Policies, and Rate Limiter
-- ==============================================================================

-- 1. Drop Rate Limiting Helper and Table
DROP FUNCTION IF EXISTS private.check_rpc_rate_limit(UUID, TEXT, INT, INT);
DROP TABLE IF EXISTS private.rate_limit_tracker;

-- 2. Drop Storage RLS Policies
DROP POLICY IF EXISTS "Supervisors and admins delete work order attachments" ON storage.objects;
DROP POLICY IF EXISTS "Authorized staff upload work order attachments" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users view work order attachments" ON storage.objects;

-- 3. Remove Storage Bucket
DELETE FROM storage.buckets WHERE id = 'work-order-attachments';
