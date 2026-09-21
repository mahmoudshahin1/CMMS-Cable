# CMMS-Cable: Production Deployment, Migration & Disaster Recovery Runbook

**Revision:** 1.0 (Hardened)  
**Classification:** Operational Security & Infrastructure  
**Target Platform:** Supabase Cloud PostgreSQL 15+ & Flutter Multi-Platform Client  

---

## 1. Production Environment Configuration

### 1.1 Secure Client Compilation
The CMMS-Cable Flutter application communicates directly with Supabase Cloud using row-level security (RLS) policies. Under no circumstances should backend administrative credentials ever be provided to the client.

#### Mandatory Compilation Flags
When compiling or launching the production Flutter application, specify the environment variables using `--dart-define`:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL="https://<project-ref>.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="<public-anon-key>"
```

For web deployments:
```bash
flutter build web --release \
  --dart-define=SUPABASE_URL="https://<project-ref>.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="<public-anon-key>"
```

### 1.2 Credential Security Standard
| Credential | Permitted Location | Forbidden Location |
| :--- | :--- | :--- |
| **`anon` Key (Public)** | App compilation flags (`--dart-define`), Client runtime | Hardcoded in source code, committed to Git |
| **`service_role` Key (Secret)**| CI/CD database migration runners, secure serverless functions | **NEVER in Flutter code, NEVER in client binaries, NEVER in Git** |
| **Database Passwords** | Secure Secret Manager / Vault | Committed SQL scripts, repository files |

---

## 2. Staging-to-Production Migration Sequencing

Database schema migrations are strictly ordered and idempotent. Migrations must be executed sequentially via the Supabase CLI or direct psql connection with `service_role` privileges.

### 2.1 Pre-Flight Checklist
- [ ] Production database snapshot / PITR checkpoint confirmed.
- [ ] All team members notified of maintenance window (if applying live schema alterations).
- [ ] No uncommitted or local-only migration scripts present.
- [ ] Environment variables validated on staging environment first.

### 2.2 Migration Execution Sequence
Migrations are located in `supabase/migrations/` and must be applied in ascending timestamp order:

1. **`20260921000001_core_schema.sql`**
   - Core tables: `machines`, `downtime_events`, `work_orders`, `work_order_parts`, `work_order_test_runs`, `audit_logs`.
   - Constraints, indexes, foreign keys, and audit trigger.
2. **`20260921000002_rls_policies.sql`**
   - RLS activation on all operational tables.
   - User profile helper (`current_user_profile()`), department and role-based policies.
3. **`20260921000003_handshake_rpc.sql`**
   - Atomic state transitions: `assign_work_order`, `start_repair`, `complete_repair`, `verify_handshake`, `handover_work_order`.
   - Concurrency locking (`FOR UPDATE`) and monotonic version checks (`version = p_expected_version`).
4. **`20260921000004_downtime_sync_rpc.sql`**
   - Downtime event synchronization: `upsert_downtime_event`, `sync_downtime_batch`.
5. **`20260921000005_realtime.sql`**
   - Replication publications for Supabase Realtime (`supabase_realtime` publication addition).
6. **`20260921000006_auth_provisioning.sql`**
   - Secure role seeding, `user_profiles` schema, role and department constraints.
7. **`20260921000007_idempotent_sync_rpc.sql`**
   - Outbox deduplication: `processed_commands` table, `execute_work_order_command`, `execute_downtime_command`.
8. **`20260921000008_storage_attachments.sql`**
   - Dedicated private bucket `work-order-attachments` (10MB limit, image MIME check).
   - Storage RLS policies matching work order authorization.
   - Rate limiting helper `private.check_rpc_rate_limit(p_user_id, p_endpoint, 60, 60)`.

---

## 3. Rollback Procedures & Contingency Protocol

In the event of an unrecoverable failure during a deployment, rollback scripts are maintained in `supabase/migrations_down/` matching each forward migration 1:1.

### 3.1 Emergency Rollback Triggers
- Migration syntax error or dependency failure midway through deployment.
- High-severity data corruption or deadlocking detected on primary transactional tables.
- Flutter client crash loop caused by unexpected schema variance.

### 3.2 Down Migration Sequence
Execute down migrations in reverse numerical order:

1. `supabase/migrations_down/20260921000008_storage_attachments.down.sql`
2. `supabase/migrations_down/20260921000007_idempotent_sync_rpc.down.sql`
3. `supabase/migrations_down/20260921000006_auth_provisioning.down.sql`
4. `supabase/migrations_down/20260921000005_realtime.down.sql`
5. `supabase/migrations_down/20260921000004_downtime_sync_rpc.down.sql`
6. `supabase/migrations_down/20260921000003_handshake_rpc.down.sql`
7. `supabase/migrations_down/20260921000002_rls_policies.down.sql`
8. `supabase/migrations_down/20260921000001_core_schema.down.sql`

---

## 4. Disaster Recovery & Point-in-Time Recovery (PITR)

### 4.1 Target Objectives
- **Recovery Point Objective (RPO):** < 5 minutes (via continuous WAL archiving).
- **Recovery Time Objective (RTO):** < 30 minutes (restoration to target checkpoint).

### 4.2 Restoring from PITR via Supabase Cloud
1. Navigate to the **Supabase Dashboard** -> Select Project -> **Project Settings** -> **Backups**.
2. Select **Point-in-Time Recovery**.
3. Specify the exact timestamp prior to the incident (in UTC).
4. Initiate clone/restore. Supabase will provision a restored instance with WAL replayed to the specified second.
5. Update DNS / project reference in CI/CD pipeline.
6. Verify data integrity (see Section 4.3).

### 4.3 Post-Recovery Integrity Verification Protocol
Run the following verification queries post-restore before allowing client traffic:

```sql
-- 1. Check for orphaned work orders or broken aggregates
SELECT COUNT(*) FROM work_orders WHERE machine_id NOT IN (SELECT id FROM machines);

-- 2. Verify all active work orders have consistent state versions
SELECT status, COUNT(*), MIN(version), MAX(version) 
FROM work_orders 
GROUP BY status;

-- 3. Confirm processed commands table is intact for idempotency
SELECT COUNT(*) FROM processed_commands;

-- 4. Verify RLS remains enabled across all operational tables
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('work_orders', 'machines', 'downtime_events', 'audit_logs');
```

---

## 5. Emergency Credential Rotation & Incident Response

### 5.1 Compromised `anon` Key
1. In Supabase Dashboard -> **Settings** -> **API**.
2. Click **Generate new anon key**.
3. Deploy new Flutter client builds with the updated `--dart-define=SUPABASE_ANON_KEY` flag.
4. Old anon key will be immediately invalidated.

### 5.2 Compromised JWT Secret
1. In Supabase Dashboard -> **Settings** -> **API** -> **JWT Settings**.
2. Click **Generate new JWT Secret**.
3. **Impact:** All active client sessions will be immediately invalidated and users will be forced to log in again with their password/MFA.

### 5.3 Storage Bucket Access Lockdown
If unauthorized attachment access is suspected:
```sql
-- Temporarily revoke public object download permissions
ALTER POLICY "Allow authorized download of work order attachments" 
ON storage.objects 
USING (false);
```
Signed URLs will continue to honor cryptographic expiration without leaking public bucket contents.
