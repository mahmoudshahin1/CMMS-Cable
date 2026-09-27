# Cable Ops CMMS — Handoff Notes

## Repository update

- Repository: `https://github.com/mahmoudshahin1/CMMS-Cable`
- Project layout: Flutter lives under `mobile/`; the Vue dashboard lives under `web/`; Supabase SQL stays under `supabase/`.
- Flutter directories and app configuration were moved with Git renames to preserve history. The previous Flutter web client is now `mobile/web/`.
- Added a root `.gitignore` for Flutter/Dart, Node builds and dependencies, local environment files, editor folders, and OS files. `.vscode/settings.json` was removed from tracking.
- Added a monorepo quick-start and hosting directions to `README.md` and corrected old local-only file links.

## Web scaffold

- Vue 3 + Vite + TypeScript, Tailwind CSS, Pinia, Vue Router, Supabase JS, ECharts / Vue-ECharts, and Lucide Vue dependency are configured in `web/`.
- Main areas: `web/src/api/supabase.ts`, `web/src/stores/`, `web/src/router/`, `web/src/components/`, and `web/src/views/` (login, live plant, work orders, analytics).
- Arabic RTL and Energya navy/cyan styling are in place. The pages are a working scaffold; full CMMS workflows, the advanced work-order Kanban/detail flows, and production dashboards are follow-up work.
- Copy `web/.env.example` to `web/.env.local` and set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` before connecting the web app. No keys were added to Git.
- npm marks the specifically requested `lucide-vue-next` package as deprecated and suggests `@lucide/vue`; decide whether to migrate after confirming the desired package.

## Supabase

- Existing migration history and seeds were retained.
- Added `supabase/migrations/20260926000009_factory_catalog.sql` for department and role catalogs, spare parts, machine BOM, RLS policies, and the spare-parts update trigger.
- Updated `supabase/seed.sql` with seven departments, role catalog entries, sample spare parts, and an EX01 BOM. `EX01` remains the database id/code used by the mobile app and is referred to as EX-01 in some business documents.
- Production project `ptlzpwfrrxfqfprkvbuf` was inspected in Supabase Studio. Migration 9's schema changes were applied manually in SQL Editor and verified: the three catalog tables exist, and the seven departments/eight role-reference rows were seeded. Sample spare-parts, machine, and BOM fixtures were not inserted into production.
- The manual application was not added to `supabase_migrations.schema_migrations`. The live history has 13 entries, including earlier reporting-view migrations (`20260923103647`, `20260923103720`) and a later role/RLS reconciliation (`20260927073853`). The repository migration filenames do not line up exactly with the live history. **Do not run `supabase db push` against production until the baseline and migration history are deliberately reconciled.** Do not insert migration-history rows by hand.
- Exact production version IDs/names, known gaps, and a safe reconciliation procedure are recorded in [`supabase/PRODUCTION_BASELINE.md`](supabase/PRODUCTION_BASELINE.md). No Supabase CLI or `supabase/config.toml` is currently available in this checkout.
- The seven reporting views already existed in production before local migration 10 and were queried successfully by the authenticated dashboard. The local `20260927000010_web_reporting_views.sql` was therefore not applied to production; treat it as the migration definition for a clean/reconciled environment, not as confirmation of the exact production view SQL.
- The dashboard's authenticated reads were smoke-tested on Analytics, Plant Floor (54 machines, seven departments), and Work Orders. The production reporting views return data. A write-based Realtime test was intentionally skipped to avoid changing operational production records.
- Auth users were deliberately not fabricated in SQL. Invite/create real users using Supabase Auth, then assign roles through the approved admin process. Never store user passwords or service-role keys in Git.

## Verification performed

- `web`: `npm run build` passed TypeScript checks and Vite production build. ECharts remains in a lazy-loaded analytics chunk of about 503 kB minified; Vite reports a size warning but build exits successfully.
- `mobile`: `flutter pub get` passed.
- `mobile`: `flutter run -d chrome --no-pub` started successfully; Supabase Auth, initial sync, and Realtime subscription completed in the running app. Quit the existing Flutter run with `q` if it is still active.
- `mobile`: `flutter run -d windows --no-pub` could not run because Visual Studio C++ build tools are missing in the current environment. This does not block running Flutter Web on Chrome.
- `git diff --check` was run; address any whitespace/line-ending warning if your local Git reports one after checkout.

## Suggested next steps

1. In the new Codex account, clone the repository and open its root (not just `web/`) to keep both apps and the Supabase files in scope.
2. Configure `web/.env.local` locally and confirm login against the intended Supabase project.
3. Provision an isolated development Supabase project/branch and validate the complete repo migration chain there.
4. Obtain a schema-only production snapshot and compare it against the clean development schema. Then review a production baseline/reconciliation migration with the owner before enabling CLI deployment.
5. Reconcile and verify production reporting-view definitions against migration 10; the existing views returned data, but matching output does not prove identical SQL.
6. Seed production only through explicitly reviewed data migrations; keep demo machine/spare-parts fixtures in development.
7. For deployment, set Vercel/Cloudflare project root to `web` and set the two `VITE_SUPABASE_*` environment variables in hosting settings.
