# MyKIZ — Features & Bug Fixes Design

Date: 2026-07-02
Status: Approved-pending-review

## Overview

Batch of features + bug fixes across the MyKIZ monorepo (Dart Frog backend,
`admin_web` Flutter web app, `student_app` Flutter mobile app). Work splits into
three groups:

- **A. Backend / data** — frontend parse fixes (occupancy model mismatch,
  bookings `meta:null` crash) that are the actual "Failed to load" causes, plus
  extended seed data and a defensive boot-time migrate/seed.
- **B. Admin web** — session persistence, collapsible sidebar shell, Overview
  landing page, demo-credential fill.
- **C. Student app** — demo-credential fill, login premature-navigation fix.

Target environment for the bugs: the deployed server at `https://api.isaacfurqan.dev`.

---

## Root-cause analysis (bugs)

**Verified live on the deployed server (`ssh vps`, backend on `localhost:8080`,
Postgres container `mykiz-postgres`).** The original "missing migrations"
hypothesis was **wrong** and is discarded. Findings:

- All 12 tables exist (migrations 004 + 005 applied). The DB is simply **empty**
  of demo data: `facilities=0, bookings=0, accommodation_applications=0,
  facility_slot_configs=0` (only 5 seeded users + blocks/rooms/beds).
- Every endpoint returns **HTTP 200** with valid JSON — `facilities`,
  `admin/bookings`, `bookings`, `my-applications`, `occupancy`, `applications`,
  `settings` all succeed. **There are no 500s.** So the "Failed to load" errors
  are **frontend parsing failures**, not backend failures.

### Bug 1 — Occupancy: model mismatch (definite)

`GET /accommodation/occupancy` returns rows shaped
`{roomId, roomNumber, roomType, total, occupied}`. The client
`getOccupancy()` maps each into `Room.fromJson`, but `Room` **requires** `id`
and `blockId` (absent in the response) → `_$RoomFromJson` throws → caught by
`occupancy_provider.dart` → "Failed to load occupancy data." Present even with
zero occupancy, because it fires on the room list itself.

### Bug 2 — Bookings: `meta` null-cast (definite)

`GET /bookings`, `/admin/bookings`, `/facilities` return `"meta": null`. The
paginated client methods do
`PaginationMeta.fromJson(response['meta'] as Map<String, dynamic>)`; casting
`null` to a non-nullable `Map` throws → "Failed to load bookings" on both the
admin bookings tab (`listAllBookings`) and the student bookings/facilities tab
(`listBookings` via `fetchActiveBookings`). `listFacilities` does not read
`meta`, so the facility list itself is fine — the crash is the bookings fetch on
that screen.

### Bug 3 — Student "Could not load applications" (verify against data)

`GET /my-applications` returns valid `{active:[], history:[]}`; the model is
freezed-symmetric (service builds the model, route emits `.toJson()`), so the
empty case parses cleanly and does **not** currently reproduce. Most likely a
stale deployed build or a data-dependent parse issue. **Action:** after seeding
real applications, load the student accommodation screen and the admin
applications tab; if a parse error appears, fix the specific field mismatch.
Treat as lower-confidence until observed with data.

### Consequence for empty screens

Even after the parse fixes, bookings / applications / reports / occupancy-
assignments are **empty** because no such rows are seeded. So seeding
(Group A) is required for the screens to show anything, and seeding is also what
may surface Bug 3. Parse fixes + seed are complementary, not alternatives.

### Why a normal deploy didn't help

`deploy.sh` rebuilds and restarts but never seeds. The frontend parse bugs ship
in the built web/mobile artifacts, so they persist until fixed and redeployed.

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

## Group A — Backend / data + frontend parse fixes

### A0. Frontend parse fixes (the actual bug fixes)

- **Occupancy (Bug 1):** stop reusing `Room` for occupancy. Add a
  `RoomOccupancy` DTO in `shared_core` (`roomId, roomNumber, roomType, total,
  occupied`); change `MyKizApiClient.getOccupancy` to return
  `List<RoomOccupancy>`; update `occupancy_provider.dart` state + the occupancy
  tab UI to consume it. (Alternatively make `Room.id/blockId` optional and map
  `roomId→id`, but a dedicated DTO is clearer and matches the endpoint.)
- **Bookings meta (Bug 2):** make the client tolerant of null `meta`. In
  `listBookings` and `listAllBookings`, when `response['meta']` is null,
  synthesize a default `PaginationMeta` (page 1, limit, totalItems = data
  length, totalPages 1) instead of casting null. Also fix `bookingsBadgeProvider`
  which reads `response.meta.totalItems`. Keeps client robust regardless of
  backend inconsistency.
- **Applications (Bug 3):** verify against seeded data (see analysis); fix only
  if a concrete mismatch is observed.
- Add unit tests: occupancy JSON → `RoomOccupancy`; paginated parse with
  `meta:null` → default meta, no throw.

### A1. Auto-migrate on boot (defensive; not the bug fix)

Tables already exist on the server, so this is a **no-op today** — but it is a
cheap safety net that makes future migrations self-applying and lets a deploy
seed automatically. Lower priority than A0 + A2.

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

### A3. Deploy / getting data onto the server

Two paths, both available (we have `ssh vps`):
- **Automatic:** the boot hook's `seedIfEmpty()` populates the empty server DB
  on the next `systemctl restart mykiz-backend` (which `deploy.sh` already does).
- **Manual (fastest for verification):** run `melos run seed` (i.e.
  `dart run bin/seed.dart` from `packages/backend`) over SSH once the seed is
  extended. Backend server has the Dart SDK on PATH.

Verify the extended seed populates rows, then re-check each endpoint returns
non-empty 200 JSON.

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
- **Manual verification:** against the live server (`ssh vps`, seeded), load
  each affected screen in both apps and confirm no "Failed to load" — occupancy
  tab, admin bookings tab, student bookings/facilities tab, student + admin
  applications. Per verification-before-completion.

## Out of scope

- Reworking `Database.query` per-request connection handling (pre-existing;
  not required for this batch).
- Student-app session persistence across app restarts.
- Any new module features beyond those listed.

## Open items to resolve during implementation

1. Exact filesystem path for reading `migrations/*.sql` from the dart_frog
   `build/` output on the server (bundle vs. relative path). Verify on server.
   (Only relevant to the defensive A1 boot hook.)
2. Confirm `accommodation_applications` schema (columns, enum values, bed
   assignment linkage) from `004_create_accommodation.sql` before writing seed.
3. RESOLVED: no missing tables / no 500s — bugs are frontend parse (occupancy
   `Room` mismatch, bookings `meta:null` cast). Confirmed live on server.
4. Whether Bug 3 (student applications) reproduces with seeded data — verify.
