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
- No SQL was applied to the live Supabase project. Review/apply the migration in the intended Supabase environment, then run the seed after the existing machine rows are installed.
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
3. Review migration `20260926000009_factory_catalog.sql` and execute the migrations/seed in a development Supabase project. Verify RLS and the existing mobile schema before applying to production.
4. Continue building the live plant detail interactions, work-order filters/Kanban/detail timeline, and executive analytics using actual database views.
5. For deployment, set Vercel/Cloudflare project root to `web` and set the two `VITE_SUPABASE_*` environment variables in hosting settings.
