# Supabase Data Contract

This document describes the contract implemented by the ordered files in `supabase/migrations/`. Apply those migrations to a development project and verify the policies with real role accounts before production use. `supabase/apply_complete_schema.sql` is a consolidated legacy/reference script; the ordered migrations are the canonical source for new installs.

## Identity and access

### `public.user_profiles`

One profile per Supabase Auth identity. `id` references `auth.users(id)`. The profile fields used by the app include `full_name`, `role`, `department`, `specialty`, and `employee_code`. Users can update their own name, while role and department changes require the trusted admin provisioning path.

Role values used by Flutter and the RLS policies include `ADMIN`, `PLANT_MANAGER`, `SUPERVISOR`, `MAINTENANCE_SUPERVISOR`, `PRODUCTION_SUPERVISOR`, `TECHNICIAN`, `MAINTENANCE_TECH`, and `OPERATOR` (case variants are accepted by several policies). The canonical RLS helper is `private.current_app_role()`; `private.current_app_department()` is the matching department helper. Both read the signed-in user's profile. Dashboard visibility is not a substitute for RLS.

### Reference catalog

- `public.factory_departments`: `code`, `name_en`, `name_ar`.
- `public.factory_roles`: `code`, `name_en`, `name_ar`, `web_access`. This is reference metadata, not an Auth account store.
- `public.spare_parts`: `id`, `part_code`, `name`, `description`, `unit`, `quantity_on_hand`, `reorder_level`, timestamps.
- `public.machine_bom`: `machine_id` (text FK to `machines.id`), `spare_part_id` (UUID FK to `spare_parts.id`), `quantity_per_machine`.

Catalog writes are restricted by RLS to `ADMIN`/`admin`. The seed does not create Auth users or passwords.

## Operational tables

### `public.machines`

`id` is a text primary key (currently equal to the machine code); other dashboard fields are `code`, `name`, `department`, `status`, `sub_category`, `current_speed_mpm`, `total_meters_produced`, `last_maintenance_at`, and `updated_at`.

### `public.work_orders`

Fields include UUID `id`, `title`, `description`, text `machine_id`, `type`, `status`, `priority`, UUID references `reported_by`, `assigned_to_technician_id`, `assigned_by_supervisor_id`, `closed_by`, timestamps `created_at`, `updated_at`, `started_at`, `completed_at`, `closed_at`, `root_cause`, `actions_taken`, JSONB `chronology`, and integer `version`.

**There is no `work_order_num` column.** Use `id` (the dashboard displays its first eight characters as a short label) unless a separate approved migration adds a business sequence.

Allowed workflow statuses are `open`, `assigned`, `inProgress`, `pendingParts`, `completed`, `verified`, and `verifiedClosed`. Types are `breakdown`, `preventive`, `corrective`, `inspection`; priorities are `low`, `medium`, `high`, `critical`.

### Audit, parts, and downtime

- `public.work_order_events`: immutable event history. Uses `actor_id`, `event_type`, `occurred_at`, `received_at`, status transitions, and JSONB `payload` (not `performed_by`).
- `public.work_order_parts`: immutable consumed-part records with `part_code`, `part_name`, `quantity`, `unit_cost`, `added_by`, and timestamps. It does **not** contain a `spare_part_id` FK; do not assume a join to the stock catalog. A future migration is needed for stock deduction and referential linkage.
- `public.downtime_logs`: `machine_id`, `work_order_id`, `category`, `reason`, `started_at`, `ended_at`, `production_date`, JSONB `shift_minutes`, chronology, creator, and update fields.

Flutter serializes `shift_minutes` with numeric keys `shift1_Morning`, `shift2_Evening`, and `shift3_Night`. The factory shifts use Cairo local time: 07:30–15:30, 15:30–23:00, and 23:00–07:30. Legacy or empty shift allocations require an estimate; they cannot recreate a precise cross-day split.

## Workflow RPCs

Workflow writes must go through the transactional RPCs; authenticated clients cannot directly mutate work orders, parts, events, or machines.

| RPC | Purpose |
| --- | --- |
| `rpc_create_work_order` | Create a work order and its audit/command records |
| `rpc_assign_work_order` | Assign a technician |
| `rpc_start_work_order` | Start an assigned repair |
| `rpc_add_work_order_part` | Append a used-part record |
| `rpc_complete_work_order` | Record root cause/actions and complete the repair |
| `rpc_confirm_test_run` | Verify the test run |
| `rpc_close_work_order` | Close the verified work order |
| `rpc_create_downtime_log` | Start downtime |
| `rpc_close_downtime_log` | Close downtime and record shift allocation |

Read each function signature in `20260921000004_workflow_commands.sql` or `20260921000005_audit_and_machine_rules.sql` before calling it. Flutter is the reference for parameter names, command IDs, expected-version handling, and payload shape.

## Reporting views (migration `20260927000010`)

All views use PostgreSQL `security_invoker = true` and grant `SELECT` to `authenticated`, so underlying grants and RLS still apply. The target Supabase Postgres must support security-invoker views (PostgreSQL 15+).

| View | Fields / meaning |
| --- | --- |
| `v_machine_status_live` | One visible machine row; machine identity/status/telemetry plus the latest visible open downtime id and reason |
| `v_downtime_pareto` | `category`, `total_minutes`; sums positive numeric shift allocations, otherwise estimates from start to end/current time |
| `v_work_order_funnel` | `status`, `count` for work orders visible to the caller |
| `v_line_availability_daily` | `department`, `production_date`, `machine_count`, `downtime_minutes`, `availability_pct` for the last seven dates |
| `v_mttr_by_department` | `department`, `closed_count`, average `completed_at - started_at` minutes |
| `v_bad_actors_30d` | Machine identity, 30-day breakdown count, and 30-day downtime estimate |
| `v_shift_downtime_split` | `production_date`, `department`, and minutes for the three shifts |

Availability assumes 1,440 scheduled minutes per machine per date and uses the current machine roster; historical department staffing is not stored. `downtime_logs.production_date` is the recorded bucket, so a log crossing calendar days is not redistributed across dates. Pareto prefers a positive numeric sum in `shift_minutes`; otherwise it uses elapsed duration. Shift charts use persisted shift values where present; for legacy/empty allocations they estimate the full event duration into the Cairo shift in which it started. These are reporting estimates, not payroll/OEE-grade historical reconstruction.

Realtime publication currently includes `machines`, `work_orders`, `work_order_events`, `work_order_parts`, and `downtime_logs`; the new views are read through normal authenticated queries and refreshed when their source table events arrive.

