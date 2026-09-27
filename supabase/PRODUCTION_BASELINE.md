# Production Supabase Baseline

Last inspected: 2026-09-28 in Supabase Studio SQL Editor, project `ptlzpwfrrxfqfprkvbuf`.

This is a read-only inventory of the production migration ledger and the repository migration files. It does not modify the production database.

## Production migration ledger

The project has these 13 recorded versions in `supabase_migrations.schema_migrations`:

| Version | Name |
| --- | --- |
| `20260922075802` | `security_hardening_role_and_provisioning` |
| `20260922075910` | `align_work_orders_schema_with_flutter` |
| `20260922075928` | `rename_activity_logs_to_work_order_events` |
| `20260922080043` | `align_machines_and_departments_with_flutter` |
| `20260922080116` | `work_order_rpc_functions` |
| `20260922080215` | `fix_role_column_type_mismatch_v2` |
| `20260922080233` | `normalize_priority_enum_casing` |
| `20260922080249` | `make_failure_category_nullable` |
| `20260922080316` | `make_spare_parts_category_nullable` |
| `20260923103647` | `dashboard_kpi_views` |
| `20260923103720` | `fix_shift_split_view_keys_v2` |
| `20260924091435` | `re_lock_provisioning_functions` |
| `20260927073853` | `reconcile_role_helpers_and_spare_parts_rls` |

None of these version IDs equals the repository migration IDs. The live ledger contains incremental alignment/security/reporting changes, while the repository also contains a core-schema migration and other migrations that cannot be assumed to have run under equivalent definitions. Similar names or observed tables are not sufficient proof of SQL equivalence.

## Repository-only migration status

| Repository migration | Production observation | Safe conclusion |
| --- | --- | --- |
| `20260921000001`–`20260921000008` | Their exact SQL is not recorded under these IDs in the live ledger. The live database has related historical changes, but no one-to-one mapping was proven. | Do not mark these applied or replay them on production. |
| `20260926000009_factory_catalog.sql` | Factory catalog schema and reference rows were applied manually through SQL Editor; its version is absent from the ledger. | Schema/data are present, but migration tracking is unresolved. |
| `20260927000010_web_reporting_views.sql` | Reporting views existed from earlier recorded migrations and were successfully queried by the authenticated app. This exact local SQL was not applied. | Do not mark it applied based on matching view names or output columns. |

The factory seed's sample spare-part, machine, and BOM fixture rows were not inserted into production. Only the seven department and eight role reference rows were seeded.

## Safe reconciliation path

1. Provision an isolated development Supabase project or branch. Do not use production for this step.
2. Apply the repository migrations from a clean state and validate schema, policies, RPCs, reporting views, and the mobile/web clients.
3. Capture a schema-only snapshot of production and compare definitions with the clean development result. Resolve any intentional legacy differences in reviewed SQL migrations.
4. Create an explicit production baseline/reconciliation plan that accounts for the 13 ledger entries and the manually applied factory catalog migration.
5. Only after review, choose and execute the supported Supabase migration-history repair/deployment workflow. Never insert rows into `supabase_migrations.schema_migrations` manually and never run `db push` against production while the histories differ.

## Access/tooling limitation

The current checkout has no Supabase CLI installed and no `supabase/config.toml`. The Supabase Studio session was sufficient for read-only inspection, but not for a reproducible schema diff or CLI-led reconciliation. No database password, service-role key, or production connection string is stored in the repository.
