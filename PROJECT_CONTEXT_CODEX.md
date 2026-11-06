# 🏭 Cable Ops CMMS — Project Context & Codex Execution Guide
> **Version:** 2.0.0 | **Branch:** `feature/mobile-logic` | **Date:** November 2026  
> **Repository:** `https://github.com/mahmoudshahin1/CMMS-Cable`  
> **Target Audience:** AI Planner (Codex / Claude) & Developers

---

## 📌 1. Project Identity & Architecture Overview

**Cable Ops CMMS** is an enterprise-grade Computerized Maintenance Management System engineered for **Energya Cables** industrial plant (8 specialized cable production departments, 58 heavy industrial machines). It digitizes the shop-floor breakdown lifecycle, machine downtime tracking, and preventive maintenance.

### 🏗️ Technical Stack:
* **Mobile (Flutter):**
  - **State Management:** `flutter_bloc: ^9.1.1` (Event -> State, single event/state file per feature, Equatable).
  - **Dependency Injection:** `get_it: ^8.0.3`.
  - **Local Persistence & Offline-First:** `hive: ^2.2.3` + `hive_flutter: ^1.1.0`.
  - **Networking & Realtime:** `supabase_flutter: ^2.8.4` + Supabase PostgreSQL RPCs + Channels.
  - **Localization:** In-house bilingual dictionary system (Arabic `ar` & English `en` with RTL/LTR support).
  - **Code Standard Rule:** **Strict max 250 lines per file** in `lib/`.
* **Web Dashboard (Vue 3):**
  - **Framework:** Vue 3 Composition API (`<script setup lang="ts">`) + Vite 8.
  - **State & Routing:** Pinia 4 + Vue Router 5.
  - **Styling:** Tailwind CSS 3.4 + Lucide Icons + ECharts.
  - **Hosting:** GitHub Pages via automated GitHub Actions CI/CD (`deploy-web.yml`).
* **Backend (Supabase / PostgreSQL):**
  - PostgreSQL schema with Row-Level Security (RLS).
  - Atomic Stored Procedures (`rpc_*`) enforcing security guards, versioning, and idempotency keys.
  - Storage Bucket: `work-order-attachments` (with path prefix `voice-notes/{workOrderId}/{timestamp}.m4a`).

---

## 🏭 2. Factory Catalog & Industrial Specs

The plant is organized into **8 specialized manufacturing departments**:

| Code | Department (EN) | القسم (AR) | Lines Count | Key Machines & Equipment |
| :---: | :--- | :--- | :---: | :--- |
| `drawing` | Drawing | السحب | 7 | Copper (DR01-DR03), Aluminum (DR04-DR05), Multiwire 14W (DR06-DR07) |
| `stranding` | Stranding | الجدل | 16 | Rigid 61 (RS01-RS04), Cage 37 (CS01-CS02), DTS, Bunchers (BN01-BN08) |
| `ccv` | CCV Insulation | العزل والتكسية | 5 | Medium & High Voltage CCV Lines (CCV01-CCV05 up to 500kV/750kV) |
| `extrusion` | Extrusion | الغلاف الخارجي | 11 | Insulation lines (EX01-02, 06-07), Bedding (EX03, 08-09), Jacketing (EX04-05, 10-11) |
| `assembly` | Assembly | التجميع | 5 | Drum Twisters (DT01-DT04 from 3000mm to 4000mm), Bow Cabler (BW01) |
| `screening` | Screening | التجهيز | 6 | Copper Tape Shield (CT01-CT03), Copper Wire Shield (CW01-CW03) |
| `armouring` | Armouring | التسليح والتدريع | 6 | Steel Tape STA (ST01-ST04), Steel Wire SWA (SWA01), Aluminum Wire AWA (AWA01) |
| `rewinding` | Rewinding | إعادة اللف والتجهيز | 2 | Cable Rewinding & Testing (RW01, RW02) |

---

## ⚙️ 3. Core Business Rules & Security Guards

1. **The 3-Phase Breakdown Lifecycle (Energya Form `MN-01F03`):**
   - **Phase 1: Report (`mnt_report`):**
     - Line Operator / Production Supervisor logs breakdown.
     - Dynamic auto-shift calculation, machine picker, description, breakdown type.
     - Voice note recording attachment (uploaded to `work-order-attachments`).
     - Triggers the **Live Running Downtime Counter** (`down X h Y min so far`).
     - Initial Status: `open`.
   - **Phase 2: Repair / Work (`mnt_work`):**
     - Maintenance Technician picks ticket (Status: `in_progress`).
     - Logs dynamic **Structured Repair Steps & Spare Parts table** (Step description + Spare Part).
     - Records technician repair voice note.
     - Submits completion via `rpc_complete_work_order(p_repair_steps, p_repair_voice_url)`.
     - Status transitions to `finished`.
   - **Phase 3: Check & Handover (`mnt_check`):**
     - In-department Operator or Production Supervisor tests machine.
     - 3 Outcomes:
       1. `fixed`: Closes work order (`closed`), confirms downtime duration.
       2. `needs_followup`: Bounces ticket back to technician (`in_progress`), reopens live downtime counter, requires operator comments.
       3. `not_fixed`: Bounces ticket back to technician (`in_progress`), reopens live downtime counter, requires operator comments.
2. **Department Isolation Rule:**
   - `UserRole.operator` and `UserRole.productionSupervisor` are **strictly scoped to their own department**. They are rejected by both client-side security guards (`WorkOrderSecurityGuard`, `DowntimeSecurityGuard`) and server-side RPCs if they attempt to create, edit, close, or confirm test-runs for another department.
   - Plant-wide roles (`UserRole.maintenanceTech`, `UserRole.maintenanceSupervisor`, `UserRole.plantManager`) operate plant-wide.
3. **Idempotency & Offline Replay:**
   - Every mutation generates an Outbox command with UUID v4 idempotency key.
   - Background delta sync heartbeat runs every 15 seconds (`SyncManager` + `DeltaSyncCoordinator`).

---

## 🏆 4. Completed Milestones & Current State

* **Departments & Machines Synchronized:** 8 departments and 58 machines fully synced across mobile seed, web, and PostgreSQL.
* **Handshake Bounce-Back Loop:** Operator test run validation with `fixed`, `needs_followup`, and `not_fixed` transitions.
* **Live Downtime Counter:** Active ticking counter (`LiveDowntimeCounterWidget`) calculating elapsed downtime from occurrence.
* **Structured Repair Steps & Spare Parts:** `RepairStepModel` with JSON serialization, dynamic item tile addition, and RPC mapping.
* **Voice Notes Recording & Player:** Audio record & playback integrated into breakdown creation and technician repair handshake.
* **Global Open-Forms Strip:** Top-level widget showing dirty/saving/saved/error state of active drafts.
* **Downtime Security Hardening:** Department scoping implemented on both mobile and web.
* **Test Suite:** **137 unit and widget tests passing (100% green)**.
* **Automated CI/CD:**
  - `.github/workflows/ci.yml`: Tests Mobile (`flutter analyze` + `flutter test`) & Web (`vue-tsc` + `vite build`) on push & PRs.
  - `.github/workflows/deploy-web.yml`: Deploys Web Dashboard to GitHub Pages on merge to `main`.
* **Git Branches:**
  - `main`: Verified production base.
  - `feature/energya-web-ui-refresh`: UI & styling enhancements by Claude on web.
  - `feature/mobile-logic`: Current active branch for mobile core logic.

---

## 🗺️ 5. Next Planned Scope (Roadmap for Codex)

The remaining tasks to complete in the mobile application:

### Priority A: Mobile Offline Voice Notes & Outbox Robustness
- Ensure recorded `.m4a` audio files recorded while offline are queued in Hive and uploaded automatically once connectivity restores before executing the remote RPC.
- Add retry/backoff policies for failed binary uploads.

### Priority B: Push Notifications Module (FCM & Local Alerts)
- Integrate Firebase Cloud Messaging (FCM) device token registration with `rpc_register_device_token`.
- Surface local notifications for critical breakdown alerts and handover bounce-backs (`needs_followup`).

### Priority C: Preventive Maintenance (PM) Module
- Implement periodic maintenance checklists (daily/weekly/monthly).
- Recurring PM work order generation with step-by-step verification and signature.

### Priority D: Final Integration & Release
- Create `integration/release-v1` branch.
- Merge `feature/mobile-logic` (our core backend/mobile logic) with `feature/energya-web-ui-refresh` (Claude's web UI).
- Run full CI quality gate and merge into `main`.

---

## 📋 6. Codex Prompting Instructions (How to Request Tasks)

When prompting Codex for any step, use this standard template:

```markdown
### TASK: [Task Name]
- **Target Branch:** feature/mobile-logic
- **Component:** [e.g. mobile/lib/features/work_orders/...]
- **Rule:** Strict limit of 250 lines per Dart file. Clean Architecture (Data/Domain/Presentation).
- **Scope:** [Describe exact requirement]
- **Deliverables:**
  1. File modifications / additions.
  2. Unit/Widget tests verifying the changes.
  3. Run `flutter analyze` and `flutter test` to ensure 0 errors.
```
