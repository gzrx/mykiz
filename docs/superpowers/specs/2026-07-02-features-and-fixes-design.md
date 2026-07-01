# MyKIZ — Features & Bug Fixes Design

Date: 2026-07-02
Status: Approved-pending-review

## Overview

Batch of features + bug fixes across the MyKIZ monorepo (Dart Frog backend,
`admin_web` Flutter web app, `student_app` Flutter mobile app). Work splits into
three groups:

- **A. Backend / data** — fixes the root cause behind all four "Failed to load"
  bugs, plus extends seed data.
- **B. Admin web** — session persistence, collapsible sidebar shell, Overview
  landing page, demo-credential fill.
- **C. Student app** — demo-credential fill, login premature-navigation fix.

Target environment for the bugs: the deployed server at `https://api.isaacfurqan.dev`.

---

## Root-cause analysis (bugs)

### The four "Failed to load" errors share one root cause

`occupancy`, `applications`, admin `bookings`, and `facilities` all live in
migrations **004_create_accommodation.sql** and **005_create_bookings.sql**.

Migrations are applied **only** via the Postgres container's
`docker-entrypoint-initdb.d` mount (`docker-compose.yml`), which runs the SQL
files **once, when the data volume is first initialised**. Migrations 004 and
005 were added after the server's volume already existed, so those tables were
never created on the deployed DB. Every endpoint that queries them throws and is
caught by the route's `catch (_)` → `500 INTERNAL_ERROR` → the Flutter apps show
their generic "Failed to load ..." message.

`deploy.sh` pulls, rebuilds, and restarts — it never runs migrations or the seed.
So a normal deploy cannot heal this.

Confirmed by reading: `docker-compose.yml`, `deploy.sh`, the route handlers
(e.g. `routes/api/v1/facilities/index.dart` returns `[]` cleanly when the table
is empty, so an *empty* table would NOT error — only a *missing* table errors).

**Verification step (first task in implementation):** reproduce against
`api.isaacfurqan.dev` (login as `S98765`, GET `/api/v1/facilities`) and confirm
a 500 with a missing-relation error, versus an empty `[]`. This decides whether
the fix is purely "apply migrations + seed" or whether a genuine query bug also
exists. Follow systematic-debugging; do not assume.

### Student login premature navigation

`student_app` router: `initialLocation: AppRoutes.dashboard`, and
`computeRedirect` returns `null` while `status == loading`. On a cold start the
user is unauthenticated → redirect to `/login` (correct). The reported symptom
("login flashes dashboard then bounces back on invalid credentials") must be
root-caused against the actual build before changing the redirect table — the
current `login_screen.dart` already only sets `authenticated` on success, so the
bug is either in redirect timing or a stale deployed build. Use
systematic-debugging; write a failing test against `computeRedirect` first.

---

## Group A — Backend / data

### A1. Auto-migrate on boot (chosen approach)

Add a Dart Frog custom entrypoint `packages/backend/main.dart` exporting:

```dart
Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  await Database.migrate();   // idempotent
  await Database.seedIfEmpty(); // idempotent, demo data
  return serve(handler, ip, port);
}
```

`Database.migrate()`:
- Creates a `schema_migrations (filename TEXT PRIMARY KEY, applied_at TIMESTAMPTZ)`
  table if absent.
- Reads `migrations/*.sql` in sorted order (path resolved relative to the
  backend working dir; the dart_frog `build/` output must be able to find the
  files — bundle the `migrations` dir or read from a known path. Decide exact
  path resolution during implementation and verify it works from
  `packages/backend/build`).
- For each file not in `schema_migrations`, execute it inside a transaction and
  record it. Migrations must be idempotent-friendly (they use `CREATE TABLE` —
  wrap each in a tx so a re-run that partially failed is safe; existing files
  already only run once per filename so this is fine).

This makes every future deploy self-healing and removes the "runs once" trap.
No SSH required.

### A2. `seedIfEmpty()` + extended seed data

Refactor the logic in `bin/seed.dart` into a reusable
`Database.seed()` / library function so both the CLI (`melos run seed`) and the
boot hook call the same code. `seedIfEmpty()` runs the seed only when the
`users` table is empty (keeps existing data intact; seed is already idempotent
via `ON CONFLICT DO NOTHING`, so running always is also safe — prefer
"seed always, idempotent" for demo predictability, guarded so it never wipes).

Extend the seed with deterministic fixed-UUID data:

- **Accommodation applications** — several `accommodation_applications` rows for
  the seeded students across statuses (`pending`, `approved` w/ bed assignment,
  `rejected`), so the admin Applications tab and Occupancy tab show data and
  the student "My applications" screen is populated. Match the schema in
  `004_create_accommodation.sql` (read it during implementation for exact
  columns/enum values).
- **Facilities** (2–3): e.g. "Badminton Court", "Futsal Court", "Study Room" —
  mixed `approval_mode` (`auto` + `manual`), `is_active = true`, sensible
  `capacity`.
- **Facility slot configs** — a few non-overlapping time slots per facility.
- **Bookings** — a spread across facilities/dates/statuses (`pending`,
  `confirmed`, `completed`, `cancelled`, `no_show`, `rejected`) for the seeded
  students, dated so that admin reports (summary/utilization) and the student
  bookings screens all render. Use `next_booking_reference()` or explicit
  references. Reports are **derived** from bookings — no separate "reports"
  table exists, so seeding bookings is what makes reports non-empty.

All new seed rows use fixed UUIDs and `ON CONFLICT DO NOTHING` for idempotency.

### A3. Deploy

No change to `deploy.sh` required for correctness (boot hook handles migrate +
seed on restart). Optionally note in the spec that `deploy.sh` already restarts
the backend, which now triggers migrate/seed.

---

## Group B — Admin web

### B1. Session persistence (rehydrate, lazy-validate)

- Persist `{token, user}` to browser storage on successful login using
  `shared_preferences` (localStorage on web). Clear on logout.
- On app startup, read persisted `{token, user}`; if present, set
  `AuthState.authenticated` and call `_apiClient.setToken(...)` before the
  router first evaluates, so a reload lands the user back where they were.
- Lazy validation: add a Dio interceptor (or wrap `_mapDioException`) so any
  `401 UnauthorizedException` triggers `authProvider.logout()`, which clears
  storage and routes to `/login`. No dedicated `/me` call.
- Add an `AuthStatus.unknown`/bootstrapping state (or reuse `loading`) so the
  router shows a splash while storage is read, preventing a login-flash.

### B2. Collapsible sidebar shell

- New `AppShell` widget: a `Scaffold` with a persistent left `NavigationRail`
  (or custom sidebar) + content area. Nav items: Overview, Announcements,
  Complaints, Accommodation, Bookings.
- Default **expanded** (labels shown); a toggle collapses to icons-only.
  Persist the collapsed/expanded preference in `shared_preferences`.
- Convert the router to a `StatefulShellRoute` (or a shell route wrapping the
  module routes) so the sidebar stays mounted across navigation. The old
  `DashboardScreen` grid is **removed**; its route (`/dashboard`) redirects to
  `/overview`.

### B3. Overview landing page (default content)

- New default route `/overview` inside the shell.
- Actionable **count cards + quick links**, each linking to its module filtered
  to the actionable subset:
  - Submitted complaints (status `submitted`)
  - Pending bookings (admin bookings, status `pending`)
  - Pending accommodation applications (status `pending`)
  - Pending check-ins (approved-but-not-checked-in applications)
  - Low/near-full occupancy blocks (from occupancy data)
- Data sourced from existing endpoints (complaints list, `/admin/bookings`,
  `/accommodation/applications`, `/accommodation/occupancy`,
  `/accommodation/blocks`). Each card shows a count and navigates on tap.
- Graceful empty/error states per card (a failing card shows a retry, not a
  whole-page failure).

### B4. Demo-credential fill button

- Small, unobtrusive "Demo" text/icon button near the login form.
- Tapping opens a menu listing seeded admins:
  - `S98765` — Dr. Aminah
  - `S87654` — Encik Razak
- Selecting one fills the Staff ID + password (`password123`) fields. Does not
  auto-submit (user still clicks Sign In), keeping the demo explicit.

---

## Group C — Student app

### C1. Demo-credential fill button

Same pattern as B4, seeded students:
- `A123456` — Ahmad
- `A234567` — Siti
- `A345678` — Farah

Fills matric + password (`password123`); no auto-submit.

### C2. Login premature-navigation fix

- Root-cause per systematic-debugging (see analysis above). Likely fixes:
  - Ensure the router does not treat the initial cold-start
    `unauthenticated` state as "flash dashboard" — add a bootstrapping state
    and splash, mirroring B1, OR gate `initialLocation` on auth.
  - Confirm `computeRedirect` truth table covers: cold start unauthenticated →
    `/login`; loading → stay; authenticated on `/login` → `/dashboard`;
    invalid-credential failure → `unauthenticated` → stay on `/login` with error.
- Write a failing unit test against `computeRedirect` (and any new bootstrap
  logic) first, then fix.
- Note: student app has no session-persistence requirement in this batch; only
  the premature-nav correctness fix. (Persistence could reuse the same storage
  approach later but is out of scope here.)

---

## Testing strategy

- **Backend:** unit test `Database.migrate()` idempotency (runs twice → no
  error, `schema_migrations` populated once). Test the seed produces the
  expected row counts. Existing service tests must still pass.
- **Frontend (both apps):** `computeRedirect` / auth-bootstrap unit tests;
  widget test for demo-fill menu populating fields; widget test for Overview
  cards rendering counts and navigating. Session-persistence test: mock storage
  returns a token → app boots authenticated.
- **Manual verification:** reproduce each of the 6 bugs against
  `api.isaacfurqan.dev` before and after, per verification-before-completion.

## Out of scope

- Reworking `Database.query` per-request connection handling (pre-existing;
  not required for this batch).
- Student-app session persistence across app restarts.
- Any new module features beyond those listed.

## Open items to resolve during implementation

1. Exact filesystem path for reading `migrations/*.sql` from the dart_frog
   `build/` output on the server (bundle vs. relative path). Verify on server.
2. Confirm `accommodation_applications` schema (columns, enum values, bed
   assignment linkage) from `004_create_accommodation.sql` before writing seed.
3. Confirm whether a genuine query bug exists beyond missing tables (from the
   verification step).
