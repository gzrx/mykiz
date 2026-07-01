# MyKIZ Features & Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the "Failed to load" bugs (frontend parse mismatches) + student login nav, seed demo data, and add admin session persistence, a collapsible sidebar shell, an Overview landing page, and demo-credential fill buttons on both login screens.

**Architecture:** Three phases. **Phase A** fixes shared parse bugs in `shared_core` + `api_client` (used by both apps), extends the seed, and adds a defensive migrate/seed-on-boot to the Dart Frog backend. **Phase B** reworks `admin_web` navigation into a persistent shell with an Overview page and adds session persistence. **Phase C** touches `student_app` login. Phases are ordered because B and C consume the Phase A client changes.

**Tech Stack:** Dart Frog backend (Postgres via `postgres` pkg), Flutter + flutter_riverpod + go_router, Dio API client, freezed/json_serializable models, mocktail + flutter_test.

## Global Constraints

- Dart SDK floor `>=3.5.0 <4.0.0` (per `deploy.sh` rewrite of built pubspec).
- Models in `shared_core` use `freezed` + `json_serializable`; after editing any model run `melos run build_runner` (or `dart run build_runner build --delete-conflicting-outputs` in that package).
- API base URL default `https://api.isaacfurqan.dev` (via `--dart-define=API_BASE_URL`).
- All accounts seed password: `password123`. Seeded admins: `S98765` (Dr. Aminah), `S87654` (Encik Razak). Seeded students: `A123456` (Ahmad), `A234567` (Siti), `A345678` (Farah).
- Accommodation application `status` enum is `submitted | approved | checked_in | checked_out | rejected` (NOT "pending"). Booking `status` enum is `pending | confirmed | cancelled | completed | no_show | rejected`.
- Deployment server reachable via `ssh vps`; backend `mykiz-backend` on `localhost:8080`; Postgres container `mykiz-postgres` (db/user `mykiz`). `melos run seed` = `dart run bin/seed.dart` (scope backend).
- Commit after every task. Use existing test style: `mocktail` `MockDio` for `api_client`; `ProviderContainer` overrides for router/provider tests.

---

## Phase A — Backend / data + shared parse fixes

### Task A1: `RoomOccupancy` model in shared_core

**Files:**
- Create: `packages/shared_core/lib/src/models/room_occupancy.dart`
- Modify: `packages/shared_core/lib/src/models/models.dart` (add export)
- Test: `packages/shared_core/test/models/room_occupancy_test.dart`

**Interfaces:**
- Produces: `RoomOccupancy` with fields `roomId (String)`, `roomNumber (String)`, `roomType (String)`, `total (int)`, `occupied (int)`; `RoomOccupancy.fromJson(Map<String,dynamic>)`.

- [ ] **Step 1: Write the failing test**

```dart
// packages/shared_core/test/models/room_occupancy_test.dart
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

void main() {
  test('RoomOccupancy.fromJson maps occupancy endpoint shape', () {
    final json = {
      'roomId': '00000000-0000-4000-d100-000000000001',
      'roomNumber': 'A-101',
      'roomType': 'single',
      'total': 1,
      'occupied': 0,
    };
    final room = RoomOccupancy.fromJson(json);
    expect(room.roomId, json['roomId']);
    expect(room.roomNumber, 'A-101');
    expect(room.roomType, 'single');
    expect(room.total, 1);
    expect(room.occupied, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/shared_core && dart test test/models/room_occupancy_test.dart`
Expected: FAIL — `RoomOccupancy` undefined / part file missing.

- [ ] **Step 3: Create the model**

```dart
// packages/shared_core/lib/src/models/room_occupancy.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_occupancy.freezed.dart';
part 'room_occupancy.g.dart';

/// Occupancy summary for a single room, as returned by
/// GET /api/v1/accommodation/occupancy. Distinct from [Room]: it carries
/// aggregate bed counts, not the full bed list or block linkage.
@freezed
class RoomOccupancy with _$RoomOccupancy {
  const factory RoomOccupancy({
    required String roomId,
    required String roomNumber,
    required String roomType, // 'single' | 'twin_sharing'
    required int total,
    required int occupied,
  }) = _RoomOccupancy;

  factory RoomOccupancy.fromJson(Map<String, dynamic> json) =>
      _$RoomOccupancyFromJson(json);
}
```

Add the export (keep alphabetical order) to `packages/shared_core/lib/src/models/models.dart`:

```dart
export 'room.dart';
export 'room_occupancy.dart';
```

- [ ] **Step 4: Generate freezed/json code**

Run: `cd packages/shared_core && dart run build_runner build --delete-conflicting-outputs`
Expected: creates `room_occupancy.freezed.dart` and `room_occupancy.g.dart`.

- [ ] **Step 5: Run test to verify it passes**

Run: `cd packages/shared_core && dart test test/models/room_occupancy_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/shared_core/lib/src/models/room_occupancy.dart \
        packages/shared_core/lib/src/models/room_occupancy.freezed.dart \
        packages/shared_core/lib/src/models/room_occupancy.g.dart \
        packages/shared_core/lib/src/models/models.dart \
        packages/shared_core/test/models/room_occupancy_test.dart
git commit -m "feat(shared_core): add RoomOccupancy model for occupancy endpoint"
```

---

### Task A2: api_client — occupancy returns `RoomOccupancy`, tolerate null `meta`

**Files:**
- Modify: `packages/api_client/lib/src/api_client_base.dart` (`getOccupancy`, `listBookings`, `listAllBookings`)
- Test: `packages/api_client/test/pagination_and_occupancy_test.dart`

**Interfaces:**
- Consumes: `RoomOccupancy` (Task A1), `PaginationMeta`.
- Produces: `Future<List<RoomOccupancy>> getOccupancy(String blockId)`; `listBookings` / `listAllBookings` return `PaginatedResponse<Booking>` even when the server sends `"meta": null` (synthesized default meta).

- [ ] **Step 1: Write the failing tests**

```dart
// packages/api_client/test/pagination_and_occupancy_test.dart
import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockDio extends Mock implements Dio {}
class MockBaseOptions extends Mock implements BaseOptions {}

void main() {
  late MockDio dio;
  late MyKizApiClient client;

  setUp(() {
    dio = MockDio();
    final opts = MockBaseOptions();
    when(() => dio.options).thenReturn(opts);
    when(() => opts.headers).thenReturn(<String, dynamic>{});
    client = MyKizApiClient(baseUrl: 'http://x', dio: dio);
  });

  Response<Map<String, dynamic>> resp(Map<String, dynamic> body) => Response(
        data: body,
        requestOptions: RequestOptions(path: '/'),
        statusCode: 200,
      );

  test('listBookings tolerates null meta', () async {
    when(() => dio.get<Map<String, dynamic>>('/api/v1/bookings',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => resp({'data': <dynamic>[], 'meta': null}));

    final result = await client.listBookings(type: 'active');
    expect(result.items, isEmpty);
    expect(result.meta.totalItems, 0);
    expect(result.meta.currentPage, 1);
  });

  test('listAllBookings tolerates null meta', () async {
    when(() => dio.get<Map<String, dynamic>>('/api/v1/admin/bookings',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => resp({'data': <dynamic>[], 'meta': null}));

    final result = await client.listAllBookings();
    expect(result.items, isEmpty);
    expect(result.meta.totalItems, 0);
  });

  test('getOccupancy parses RoomOccupancy list', () async {
    when(() => dio.get<Map<String, dynamic>>('/api/v1/accommodation/occupancy',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => resp({
              'data': [
                {
                  'roomId': 'r1',
                  'roomNumber': 'A-101',
                  'roomType': 'single',
                  'total': 1,
                  'occupied': 1,
                }
              ],
              'meta': null,
            }));

    final rooms = await client.getOccupancy('block-1');
    expect(rooms, hasLength(1));
    expect(rooms.first.occupied, 1);
    expect(rooms.first.roomNumber, 'A-101');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/api_client && dart test test/pagination_and_occupancy_test.dart`
Expected: FAIL — `getOccupancy` returns `List<Room>`; `listBookings` throws on null meta cast.

- [ ] **Step 3: Add a private meta helper and use it**

In `packages/api_client/lib/src/api_client_base.dart`, add this helper inside the class (near `_request`):

```dart
  /// Builds a [PaginationMeta] from a response, synthesizing a sensible
  /// default when the server omits or nulls the `meta` field.
  PaginationMeta _metaOf(Map<String, dynamic> response, int itemCount) {
    final meta = response['meta'];
    if (meta is Map<String, dynamic>) {
      return PaginationMeta.fromJson(meta);
    }
    return PaginationMeta(
      currentPage: 1,
      limit: itemCount == 0 ? 20 : itemCount,
      totalItems: itemCount,
      totalPages: 1,
    );
  }
```

Replace the meta line in `listBookings`:

```dart
    final items = (response['data'] as List<dynamic>)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = _metaOf(response, items.length);
    return PaginatedResponse(items: items, meta: meta);
```

Replace the meta line in `listAllBookings` identically:

```dart
    final items = (response['data'] as List<dynamic>)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = _metaOf(response, items.length);
    return PaginatedResponse(items: items, meta: meta);
```

- [ ] **Step 4: Change `getOccupancy` return type**

Replace the whole `getOccupancy` method with:

```dart
  /// Returns per-room occupancy counts for a block.
  ///
  /// GET /api/v1/accommodation/occupancy?blockId=...
  Future<List<RoomOccupancy>> getOccupancy(String blockId) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/accommodation/occupancy',
        queryParameters: {'blockId': blockId},
      ),
    );

    return (response['data'] as List<dynamic>)
        .map((e) => RoomOccupancy.fromJson(e as Map<String, dynamic>))
        .toList();
  }
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd packages/api_client && dart test test/pagination_and_occupancy_test.dart`
Expected: PASS (all 3).

- [ ] **Step 6: Run the full api_client suite (no regressions)**

Run: `cd packages/api_client && dart test`
Expected: PASS. If a pre-existing test asserted `getOccupancy` returned `Room`, update it to `RoomOccupancy` with the new fields.

- [ ] **Step 7: Commit**

```bash
git add packages/api_client/lib/src/api_client_base.dart \
        packages/api_client/test/pagination_and_occupancy_test.dart
git commit -m "fix(api_client): RoomOccupancy for occupancy + tolerate null pagination meta"
```

---

### Task A3: admin occupancy provider + tab use `RoomOccupancy`

**Files:**
- Modify: `packages/admin_web/lib/features/accommodation/application/occupancy_provider.dart`
- Modify: `packages/admin_web/lib/features/accommodation/data/accommodation_repository.dart:29-30`
- Modify: `packages/admin_web/lib/features/accommodation/presentation/occupancy_tab.dart` (`_RoomsPanel`, `_bedsFilled`)
- Test: `packages/admin_web/test/features/accommodation/occupancy_provider_test.dart`

**Interfaces:**
- Consumes: `getOccupancy` now returns `List<RoomOccupancy>` (Task A2).
- Produces: `OccupancyState.rooms` is `List<RoomOccupancy>`.

- [ ] **Step 1: Write the failing test**

```dart
// packages/admin_web/test/features/accommodation/occupancy_provider_test.dart
import 'package:admin_web/features/accommodation/application/occupancy_provider.dart';
import 'package:admin_web/features/accommodation/data/accommodation_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

class _FakeRepo implements AccommodationRepository {
  @override
  Future<List<Block>> listBlocks() async =>
      const [Block(id: 'b1', name: 'Block A', rooms: [])];
  @override
  Future<List<RoomOccupancy>> getOccupancy(String blockId) async => const [
        RoomOccupancy(
            roomId: 'r1',
            roomNumber: 'A-101',
            roomType: 'single',
            total: 1,
            occupied: 1),
      ];
  // Other members throw — not exercised here.
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test('selectBlock loads RoomOccupancy rows', () async {
    final container = ProviderContainer(overrides: [
      accommodationRepositoryProvider.overrideWithValue(_FakeRepo()),
    ]);
    addTearDown(container.dispose);

    await container.read(occupancyProvider.notifier).selectBlock('b1');
    final rooms = container.read(occupancyProvider).rooms;
    expect(rooms, hasLength(1));
    expect(rooms.first.occupied, 1);
  });
}
```

Note: if `AccommodationRepository` is a concrete class (not interface), instead extend it or reuse the existing `test/features/accommodation/fake_accommodation_repository.dart` and add a `getOccupancy` override returning `RoomOccupancy`. Match whichever pattern that fake already uses.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/admin_web && flutter test test/features/accommodation/occupancy_provider_test.dart`
Expected: FAIL — `OccupancyState.rooms` is `List<Room>`, type mismatch.

- [ ] **Step 3: Update the repository return type**

In `packages/admin_web/lib/features/accommodation/data/accommodation_repository.dart`, change:

```dart
  Future<List<RoomOccupancy>> getOccupancy(String blockId) =>
      _client.getOccupancy(blockId);
```

- [ ] **Step 4: Update the provider state type**

In `occupancy_provider.dart`, change every `List<Room> rooms` / `List<Room>? rooms` to `List<RoomOccupancy>` (the `OccupancyState` field, the constructor param, and `copyWith`). The `selectBlock` body already assigns `rooms` from `getOccupancy` — no logic change.

- [ ] **Step 5: Update the occupancy tab UI**

In `occupancy_tab.dart` `_RoomsPanel`, replace `_bedsFilled` and its call:

```dart
            DataCell(Text(
              '${room.occupied}/${room.total} beds filled',
              style: KizFonts.mono(),
            )),
```

Remove the now-unused `_bedsFilled(Room room)` method. Ensure the `for (final room in state.rooms)` loop compiles against `RoomOccupancy` (uses `room.roomNumber`, `room.roomType`, `room.occupied`, `room.total`).

- [ ] **Step 6: Run the test + analyze**

Run: `cd packages/admin_web && flutter test test/features/accommodation/occupancy_provider_test.dart && flutter analyze lib/features/accommodation`
Expected: test PASS, analyze clean.

- [ ] **Step 7: Commit**

```bash
git add packages/admin_web/lib/features/accommodation \
        packages/admin_web/test/features/accommodation/occupancy_provider_test.dart
git commit -m "fix(admin): occupancy tab uses RoomOccupancy counts (fixes Failed to load occupancy)"
```

---

### Task A4: Extend the seed with facilities, slots, bookings, applications

**Files:**
- Modify: `packages/backend/bin/seed.dart`

**Interfaces:**
- Produces: deterministic demo rows so bookings/applications/occupancy/reports screens are non-empty.

- [ ] **Step 1: Add fixed UUIDs + facility/slot/booking/application seed blocks**

After the existing bed seeding (before the final success `print`s), insert the following. Fixed UUIDs keep it idempotent with `ON CONFLICT DO NOTHING`.

```dart
    // --- Seed Facilities ---
    print('  Creating facilities...');
    const facilityIds = [
      '00000000-0000-4000-e000-000000000001', // Badminton (auto)
      '00000000-0000-4000-e000-000000000002', // Futsal (manual)
      '00000000-0000-4000-e000-000000000003', // Study Room (auto)
    ];
    await connection.execute(
      Sql.named(
        'INSERT INTO facilities (id, name, description, approval_mode, capacity) VALUES '
        "(@id1, 'Badminton Court', 'Indoor court', 'auto', 4), "
        "(@id2, 'Futsal Court', 'Outdoor futsal', 'manual', 10), "
        "(@id3, 'Study Room', 'Quiet study room', 'auto', 6) "
        'ON CONFLICT (id) DO NOTHING',
      ),
      parameters: {
        'id1': facilityIds[0],
        'id2': facilityIds[1],
        'id3': facilityIds[2],
      },
    );

    // --- Seed Slot Configs (2 per facility, non-overlapping) ---
    print('  Creating facility slot configs...');
    const slotIds = [
      '00000000-0000-4000-e100-000000000001',
      '00000000-0000-4000-e100-000000000002',
      '00000000-0000-4000-e100-000000000003',
      '00000000-0000-4000-e100-000000000004',
      '00000000-0000-4000-e100-000000000005',
      '00000000-0000-4000-e100-000000000006',
    ];
    final slots = [
      [slotIds[0], facilityIds[0], '08:00', '10:00'],
      [slotIds[1], facilityIds[0], '10:00', '12:00'],
      [slotIds[2], facilityIds[1], '16:00', '18:00'],
      [slotIds[3], facilityIds[1], '18:00', '20:00'],
      [slotIds[4], facilityIds[2], '09:00', '11:00'],
      [slotIds[5], facilityIds[2], '14:00', '16:00'],
    ];
    for (final s in slots) {
      await connection.execute(
        Sql.named(
          'INSERT INTO facility_slot_configs (id, facility_id, start_time, end_time) '
          'VALUES (@id, @fid, @st::time, @et::time) ON CONFLICT (id) DO NOTHING',
        ),
        parameters: {'id': s[0], 'fid': s[1], 'st': s[2], 'et': s[3]},
      );
    }

    // --- Seed Bookings (mixed statuses across facilities/dates) ---
    print('  Creating bookings...');
    const bookingIds = [
      '00000000-0000-4000-e200-000000000001',
      '00000000-0000-4000-e200-000000000002',
      '00000000-0000-4000-e200-000000000003',
      '00000000-0000-4000-e200-000000000004',
      '00000000-0000-4000-e200-000000000005',
    ];
    // [id, ref, student, facility, slot, dateOffsetDays, status]
    final bookings = [
      [bookingIds[0], 'BK-SEED-0001', studentIds[0], facilityIds[0], slotIds[0], 2, 'confirmed'],
      [bookingIds[1], 'BK-SEED-0002', studentIds[1], facilityIds[1], slotIds[2], 1, 'pending'],
      [bookingIds[2], 'BK-SEED-0003', studentIds[2], facilityIds[2], slotIds[4], -3, 'completed'],
      [bookingIds[3], 'BK-SEED-0004', studentIds[0], facilityIds[1], slotIds[3], -1, 'no_show'],
      [bookingIds[4], 'BK-SEED-0005', studentIds[1], facilityIds[2], slotIds[5], -5, 'cancelled'],
    ];
    for (final b in bookings) {
      await connection.execute(
        Sql.named(
          'INSERT INTO bookings '
          '(id, booking_reference, student_id, facility_id, slot_config_id, booking_date, status) '
          'VALUES (@id, @ref, @sid, @fid, @slot, CURRENT_DATE + @off, @status) '
          'ON CONFLICT (id) DO NOTHING',
        ),
        parameters: {
          'id': b[0], 'ref': b[1], 'sid': b[2], 'fid': b[3],
          'slot': b[4], 'off': b[5], 'status': b[6],
        },
      );
    }

    // --- Seed Accommodation Applications (mixed statuses) ---
    // status enum: submitted | approved | checked_in | checked_out | rejected
    print('  Creating accommodation applications...');
    const appIds = [
      '00000000-0000-4000-e300-000000000001',
      '00000000-0000-4000-e300-000000000002',
      '00000000-0000-4000-e300-000000000003',
    ];
    // Application 1: submitted (semester, no assignment)
    await connection.execute(
      Sql.named(
        'INSERT INTO accommodation_applications '
        '(id, student_id, application_type, status, room_type_preference, preferred_block_id, lifestyle_tags) '
        "VALUES (@id, @sid, 'semester', 'submitted', 'single', @block, ARRAY['non_smoker','early_sleeper']) "
        'ON CONFLICT (id) DO NOTHING',
      ),
      parameters: {'id': appIds[0], 'sid': studentIds[0], 'block': blockIds[0]},
    );
    // Application 2: approved with bed assignment (bed A-101 -> bedIds[0])
    await connection.execute(
      Sql.named(
        'INSERT INTO accommodation_applications '
        '(id, student_id, application_type, status, room_type_preference, '
        ' assigned_block_id, assigned_room_id, assigned_bed_id) '
        "VALUES (@id, @sid, 'semester', 'approved', 'single', @block, @room, @bed) "
        'ON CONFLICT (id) DO NOTHING',
      ),
      parameters: {
        'id': appIds[1],
        'sid': studentIds[1],
        'block': blockIds[0],
        'room': roomIds[0],
        'bed': bedIds[0],
      },
    );
    // Mark that bed occupied so occupancy shows 1/1 for A-101
    await connection.execute(
      Sql.named("UPDATE beds SET is_occupied = TRUE WHERE id = @bed"),
      parameters: {'bed': bedIds[0]},
    );
    // Application 3: rejected (out_of_semester)
    await connection.execute(
      Sql.named(
        'INSERT INTO accommodation_applications '
        '(id, student_id, application_type, status, check_in_date, check_out_date, '
        ' nightly_rate, total_cost, rejection_reason) '
        "VALUES (@id, @sid, 'out_of_semester', 'rejected', CURRENT_DATE + 5, CURRENT_DATE + 12, "
        ' 25.00, 175.00, @reason) '
        'ON CONFLICT (id) DO NOTHING',
      ),
      parameters: {
        'id': appIds[2],
        'sid': studentIds[2],
        'reason': 'Out-of-semester window is currently closed.',
      },
    );
```

Add to the final summary prints:

```dart
    print('   - 3 Facilities, 6 slot configs, 5 bookings');
    print('   - 3 Accommodation applications (submitted/approved/rejected)');
```

- [ ] **Step 2: Run the seed against a local/dev DB (or the server) to verify it executes**

If a local Postgres is available (`docker compose up -d postgres`), run:
Run: `cd packages/backend && dart run bin/seed.dart`
Expected: prints "✅ Seed completed successfully!" with the new lines, exit 0. Re-run once more → still exit 0 (idempotent, `ON CONFLICT DO NOTHING`).

If no local DB, defer execution to Task A6 (server) but still confirm the file compiles:
Run: `cd packages/backend && dart analyze bin/seed.dart`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add packages/backend/bin/seed.dart
git commit -m "feat(backend): seed facilities, slots, bookings, and accommodation applications"
```

---

### Task A5: Defensive migrate + seed-on-boot (Dart Frog entrypoint)

**Files:**
- Create: `packages/backend/main.dart` (Dart Frog custom entrypoint)
- Modify: `packages/backend/lib/services/database.dart` (add `migrate` + `seedIfEmpty`)
- Modify: `packages/backend/bin/seed.dart` (extract seed body into a reusable function)
- Test: `packages/backend/test/services/migrate_test.dart` (guarded — see note)

**Interfaces:**
- Produces: `Database.migrate()` applies unrun `migrations/*.sql` tracked in `schema_migrations`; `Database.seedIfEmpty()` runs the seed only when `users` is empty. Dart Frog calls both before serving.

Note: this is defensive (tables already exist on the server). Keep it minimal and idempotent. The DB test needs a live Postgres; gate it behind an env check so CI without a DB skips it.

- [ ] **Step 1: Extract the seed body into a reusable function**

In `packages/backend/bin/seed.dart`, refactor so the connection-using logic lives in:

```dart
Future<void> runSeed(Session connection) async { /* existing body, minus Connection.open/close */ }
```

and `main()` opens the connection, calls `await runSeed(connection)`, and closes it. (`Session` is `package:postgres`'s base type implemented by `Connection`.) This lets `seedIfEmpty` reuse it. Keep the CLI behavior identical.

- [ ] **Step 2: Add `migrate` + `seedIfEmpty` to `Database`**

Add to `packages/backend/lib/services/database.dart`:

```dart
  /// Applies any migration files not yet recorded in `schema_migrations`.
  /// Idempotent: safe to call on every boot.
  static Future<void> migrate({String migrationsDir = 'migrations'}) async {
    await query(
      'CREATE TABLE IF NOT EXISTS schema_migrations ('
      'filename TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW())',
    );
    final dir = Directory(migrationsDir);
    if (!dir.existsSync()) return; // build output may not bundle migrations
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final done = await query(
        'SELECT 1 FROM schema_migrations WHERE filename = @n',
        parameters: {'n': name},
      );
      if (done.isNotEmpty) continue;
      await transaction((tx) async {
        await tx.execute(file.readAsStringSync());
        await tx.execute(
          Sql.named('INSERT INTO schema_migrations (filename) VALUES (@n)'),
          parameters: {'n': name},
        );
      });
    }
  }

  /// Runs the seed only if the users table is empty.
  static Future<void> seedIfEmpty() async {
    final rows = await query('SELECT COUNT(*)::int AS c FROM users');
    final count = rows.first[0] as int;
    if (count > 0) return;
    // Delegated to the seed CLI's reusable function.
    // Import path: package:backend cannot import bin/, so inline a call via
    // a shared library function instead — see Step 3.
  }
```

- [ ] **Step 3: Move the reusable seed function into `lib/` so both callers share it**

Create `packages/backend/lib/services/seed_data.dart` exporting `Future<void> runSeed(Session connection)` (move the body from `bin/seed.dart` here). Update `bin/seed.dart` to `import 'package:backend/services/seed_data.dart';` and call `runSeed`. Update `Database.seedIfEmpty` to open a connection and call `runSeed`:

```dart
  static Future<void> seedIfEmpty() async {
    final rows = await query('SELECT COUNT(*)::int AS c FROM users');
    if ((rows.first[0] as int) > 0) return;
    final conn = await Connection.open(
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? 'localhost',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME'] ?? 'mykiz',
        username: Platform.environment['DB_USER'] ?? 'mykiz',
        password: Platform.environment['DB_PASSWORD'] ?? 'mykiz_secret',
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    try {
      await runSeed(conn);
    } finally {
      await conn.close();
    }
  }
```

Add `import 'package:backend/services/seed_data.dart';` to `database.dart`.

- [ ] **Step 4: Add the Dart Frog entrypoint**

Create `packages/backend/main.dart`:

```dart
import 'dart:io';

import 'package:backend/services/database.dart';
import 'package:dart_frog/dart_frog.dart';

/// Custom Dart Frog entrypoint: run migrations + seed-if-empty before serving.
Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  try {
    await Database.migrate();
    await Database.seedIfEmpty();
  } catch (e) {
    stderr.writeln('Startup migrate/seed failed (continuing): $e');
  }
  return serve(handler, ip, port);
}
```

- [ ] **Step 5: Verify it compiles**

Run: `cd packages/backend && dart analyze lib/services/database.dart lib/services/seed_data.dart bin/seed.dart main.dart`
Expected: no errors. (Confirm `Sql`, `Connection`, `Endpoint`, `Session` imports resolve in each file.)

- [ ] **Step 6: Commit**

```bash
git add packages/backend/main.dart packages/backend/lib/services/database.dart \
        packages/backend/lib/services/seed_data.dart packages/backend/bin/seed.dart
git commit -m "feat(backend): migrate + seed-if-empty on boot (defensive, idempotent)"
```

---

### Task A6: Deploy the parse fixes + seed the server, verify endpoints

**Files:** none (ops task).

- [ ] **Step 1: Push and deploy**

```bash
git push
ssh vps 'cd ~/mykiz && bash deploy.sh'
```
Expected: deploy script completes; backend restarts (triggering `migrate` + `seedIfEmpty`).

- [ ] **Step 2: If DB was already non-empty (users>0), seed explicitly**

Because `seedIfEmpty` skips when users exist, run the seed CLI once to add the new facilities/bookings/applications:

```bash
ssh vps 'cd ~/mykiz/packages/backend && dart run bin/seed.dart'
```
Expected: "✅ Seed completed successfully!" including the new rows.

- [ ] **Step 3: Verify endpoints now return data**

```bash
ssh vps 'T=$(curl -s -X POST localhost:8080/api/v1/auth/login -H "Content-Type: application/json" -d "{\"identifier\":\"S98765\",\"password\":\"password123\"}" | grep -oE "\"token\":\"[^\"]*\"" | sed "s/\"token\":\"//;s/\"//")
curl -s localhost:8080/api/v1/facilities -H "Authorization: Bearer $T" | head -c 200; echo
curl -s localhost:8080/api/v1/admin/bookings -H "Authorization: Bearer $T" | head -c 200; echo
curl -s "localhost:8080/api/v1/accommodation/occupancy?blockId=00000000-0000-4000-d000-000000000001" -H "Authorization: Bearer $T" | head -c 300; echo'
```
Expected: facilities non-empty; admin bookings has ≥5 items; occupancy shows A-101 `occupied:1`.

- [ ] **Step 4: Manual UI check**

Open the admin web app (deployed), log in `S98765` / `password123`, open Accommodation → Occupancy (no "Failed to load occupancy"), Bookings tab (no "Failed to load bookings"). No commit (ops task).

---

## Phase B — Admin web

### Task B1: Session storage helper (`shared_preferences`)

**Files:**
- Modify: `packages/admin_web/pubspec.yaml` (add `shared_preferences`)
- Create: `packages/admin_web/lib/features/auth/data/auth_storage.dart`
- Test: `packages/admin_web/test/features/auth/auth_storage_test.dart`

**Interfaces:**
- Produces: `AuthStorage` with `Future<void> save(String token, User user)`, `Future<({String token, User user})?> read()`, `Future<void> clear()`. Backed by `SharedPreferences` (localStorage on web). `authStorageProvider`.

- [ ] **Step 1: Add the dependency**

In `packages/admin_web/pubspec.yaml` under `dependencies:` add:

```yaml
  shared_preferences: ^2.2.2
```

Run: `cd packages/admin_web && flutter pub get`
Expected: resolves.

- [ ] **Step 2: Write the failing test**

```dart
// packages/admin_web/test/features/auth/auth_storage_test.dart
import 'package:admin_web/features/auth/data/auth_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save then read round-trips token and user', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = AuthStorage();
    const user = User(
        id: 'u1', identifier: 'S98765', role: 'admin', name: 'Dr. Aminah');

    await storage.save('tok-123', user);
    final restored = await storage.read();

    expect(restored, isNotNull);
    expect(restored!.token, 'tok-123');
    expect(restored.user.identifier, 'S98765');

    await storage.clear();
    expect(await storage.read(), isNull);
  });
}
```

(Confirm the `User` constructor field names from `packages/shared_core/lib/src/models/user.dart` and adjust the literal if needed.)

- [ ] **Step 3: Run test to verify it fails**

Run: `cd packages/admin_web && flutter test test/features/auth/auth_storage_test.dart`
Expected: FAIL — `AuthStorage` undefined.

- [ ] **Step 4: Implement `AuthStorage`**

```dart
// packages/admin_web/lib/features/auth/data/auth_storage.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the auth token + user to local storage (localStorage on web).
class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  Future<void> save(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<({String token, User user})?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (token == null || userJson == null) return null;
    final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    return (token: token, user: user);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd packages/admin_web && flutter test test/features/auth/auth_storage_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/admin_web/pubspec.yaml packages/admin_web/pubspec.lock \
        packages/admin_web/lib/features/auth/data/auth_storage.dart \
        packages/admin_web/test/features/auth/auth_storage_test.dart
git commit -m "feat(admin): AuthStorage for persisting session to local storage"
```

---

### Task B2: Persist + rehydrate session; bootstrap state

**Files:**
- Modify: `packages/admin_web/lib/features/auth/application/auth_provider.dart`
- Modify: `packages/admin_web/lib/core/router/app_router.dart` (splash while bootstrapping; default → `/overview`)
- Modify: `packages/admin_web/lib/main.dart` (trigger bootstrap)
- Test: `packages/admin_web/test/features/auth/application/auth_provider_test.dart` (extend)

**Interfaces:**
- Consumes: `AuthStorage` (B1).
- Produces: `AuthNotifier` writes storage on login, clears on logout, and exposes `Future<void> bootstrap()` that restores a persisted session. New `AuthStatus.unknown` (initial) so the router can show a splash until bootstrap resolves.

- [ ] **Step 1: Write the failing test**

Add to `auth_provider_test.dart`:

```dart
  test('bootstrap restores persisted session and sets token on client', () async {
    // Arrange a fake storage returning a saved session, and a spy api client.
    // Use the existing test harness pattern in this file for building the
    // notifier with overridden repository + api client + storage.
    // Assert: after bootstrap(), state.status == AuthStatus.authenticated
    // and the api client received setToken(<persisted token>).
  });

  test('bootstrap with no persisted session ends unauthenticated', () async {
    // storage.read() -> null ; after bootstrap() status == unauthenticated
  });
```

Fill these in using the file's existing mocks/fakes (mirror how `login` is already tested there). Add a fake `AuthStorage` returning a fixed session / null.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/admin_web && flutter test test/features/auth/application/auth_provider_test.dart`
Expected: FAIL — no `bootstrap`, no `AuthStatus.unknown`.

- [ ] **Step 3: Update `AuthStatus` + `AuthNotifier`**

In `auth_provider.dart`:
- Add `unknown` as the first enum value; make the initial `AuthState()` use `status: AuthStatus.unknown` (update the default constructor arg).
- Inject storage: `AuthNotifier(this._repository, this._apiClient, this._storage)` and `final AuthStorage _storage;`.
- On successful login, before setting state, `await _storage.save(response.token, response.user);`.
- In `logout()`, `await _storage.clear();` (make it `Future<void>`), clear token, set `const AuthState(status: AuthStatus.unauthenticated)`.
- Add:

```dart
  Future<void> bootstrap() async {
    final saved = await _storage.read();
    if (saved == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    _apiClient.setToken(saved.token);
    state = AuthState(
      status: AuthStatus.authenticated,
      token: saved.token,
      user: saved.user,
    );
  }
```

- Update the provider to read `authStorageProvider`:

```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(authStorageProvider);
  return AuthNotifier(repository, apiClient, storage);
});
```

- [ ] **Step 4: Router — splash on `unknown`, default to `/overview`**

In `app_router.dart` `redirect`:

```dart
      final status = authState.status;
      if (status == AuthStatus.unknown) return null; // stay; splash shows
      final isAuthenticated = status == AuthStatus.authenticated;
      final isOnLogin = state.matchedLocation == AppRoutes.login;
      if (!isAuthenticated && !isOnLogin) return AppRoutes.login;
      if (isAuthenticated && (isOnLogin || state.matchedLocation == '/')) {
        return AppRoutes.overview; // see Task B4 for AppRoutes.overview
      }
      return null;
```

Until Task B4 introduces `/overview`, temporarily keep `AppRoutes.dashboard`; Task B4 switches it. (If doing B4 in the same session, add `AppRoutes.overview` now.)

Set the login route to render a splash while `unknown`: in `main.dart` trigger bootstrap so `unknown` is transient (Step 5). No separate splash route needed — a brief `unknown` shows the existing login initial location; to avoid a login flash, gate the `MaterialApp.router` on bootstrap (Step 5).

- [ ] **Step 5: Trigger bootstrap at startup without a login flash**

Replace `main.dart` body so bootstrap runs before first frame decisions:

```dart
void main() {
  runApp(const ProviderScope(child: AdminWebApp()));
}

class AdminWebApp extends ConsumerStatefulWidget {
  const AdminWebApp({super.key});
  @override
  ConsumerState<AdminWebApp> createState() => _AdminWebAppState();
}

class _AdminWebAppState extends ConsumerState<AdminWebApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authProvider).status;
    final router = ref.watch(appRouterProvider);
    if (status == AuthStatus.unknown) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
      );
    }
    return MaterialApp.router(
      title: 'MyKIZ Admin',
      theme: KizTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

Add imports for `flutter/material.dart` (already), `WidgetsBinding` (in material), and `auth_provider.dart`.

- [ ] **Step 6: Run tests + analyze**

Run: `cd packages/admin_web && flutter test test/features/auth && flutter analyze lib/features/auth lib/main.dart lib/core/router`
Expected: PASS + clean. Fix any existing router test that assumed initial `unauthenticated` (now `unknown`): update expectations or call `bootstrap()`.

- [ ] **Step 7: Commit**

```bash
git add packages/admin_web/lib packages/admin_web/test
git commit -m "feat(admin): persist and rehydrate login session across reload"
```

---

### Task B3: Auto-logout on 401

**Files:**
- Modify: `packages/admin_web/lib/features/auth/data/auth_repository.dart` (apiClientProvider) OR `main.dart` — attach an `onUnauthorized` callback.
- Modify: `packages/api_client/lib/src/api_client_base.dart` (add optional `onUnauthorized` callback)
- Test: `packages/api_client/test/unauthorized_callback_test.dart`

**Interfaces:**
- Produces: `MyKizApiClient({..., void Function()? onUnauthorized})`; when a request maps to `UnauthorizedException` (401), the callback fires (once) before the exception propagates.

- [ ] **Step 1: Write the failing test**

```dart
// packages/api_client/test/unauthorized_callback_test.dart
import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockDio extends Mock implements Dio {}
class MockBaseOptions extends Mock implements BaseOptions {}

void main() {
  test('onUnauthorized fires on 401', () async {
    final dio = MockDio();
    final opts = MockBaseOptions();
    when(() => dio.options).thenReturn(opts);
    when(() => opts.headers).thenReturn(<String, dynamic>{});
    var fired = false;
    final client = MyKizApiClient(
      baseUrl: 'http://x',
      dio: dio,
      onUnauthorized: () => fired = true,
    );
    when(() => dio.get<Map<String, dynamic>>(any(),
            queryParameters: any(named: 'queryParameters')))
        .thenThrow(DioException(
      requestOptions: RequestOptions(path: '/'),
      response: Response(
        requestOptions: RequestOptions(path: '/'),
        statusCode: 401,
        data: {'error': {'code': 'UNAUTHORIZED', 'message': 'nope'}},
      ),
    ));

    await expectLater(
      client.listFacilities(),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(fired, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/api_client && dart test test/unauthorized_callback_test.dart`
Expected: FAIL — constructor has no `onUnauthorized`.

- [ ] **Step 3: Implement the callback**

In `api_client_base.dart`:
- Add field + constructor param: `final void Function()? _onUnauthorized;` and `void Function()? onUnauthorized` → `_onUnauthorized = onUnauthorized`.
- In `_mapDioException`, in the `401` case, invoke it:

```dart
      return switch (response.statusCode) {
        401 => () {
            _onUnauthorized?.call();
            return UnauthorizedException(code: code, message: message);
          }(),
        403 => ForbiddenException(code: code, message: message),
        // ...unchanged
      };
```

- [ ] **Step 4: Wire it in admin app**

In `packages/admin_web/lib/features/auth/data/auth_repository.dart`, the `apiClientProvider` currently constructs the client without a callback. Move the callback wiring so logout can be triggered: since the provider can't reference `authProvider.notifier` at construction cleanly, use a top-level `ref`:

```dart
final apiClientProvider = Provider<MyKizApiClient>((ref) {
  return MyKizApiClient(
    baseUrl: const String.fromEnvironment('API_BASE_URL',
        defaultValue: 'https://api.isaacfurqan.dev'),
    onUnauthorized: () {
      // Fire-and-forget logout; guards against loops (logout is idempotent).
      ref.read(authProvider.notifier).logout();
    },
  );
});
```

Add `import '../application/auth_provider.dart';`. Note: `authProvider` reads `apiClientProvider` → to avoid a circular init, `onUnauthorized` only calls `ref.read` lazily at 401 time (after both providers exist), which is safe.

- [ ] **Step 5: Run tests + analyze**

Run: `cd packages/api_client && dart test && cd ../admin_web && flutter analyze lib/features/auth`
Expected: PASS + clean.

- [ ] **Step 6: Commit**

```bash
git add packages/api_client/lib/src/api_client_base.dart \
        packages/api_client/test/unauthorized_callback_test.dart \
        packages/admin_web/lib/features/auth/data/auth_repository.dart
git commit -m "feat: auto-logout admin session on 401 unauthorized"
```

---

### Task B4: Collapsible sidebar shell + Overview route wiring

**Files:**
- Create: `packages/admin_web/lib/core/widgets/app_shell.dart`
- Modify: `packages/admin_web/lib/core/router/app_router.dart` (StatefulShellRoute; add `AppRoutes.overview`; remove `/dashboard` grid route or redirect it)
- Modify: `packages/admin_web/lib/features/auth/application/auth_provider.dart` redirect target already `/overview` (B2)
- Test: `packages/admin_web/test/core/widgets/app_shell_test.dart`

**Interfaces:**
- Consumes: module screens (`AnnouncementsScreen`, `ComplaintsScreen`, `AccommodationShell`, `BookingsScreen`) + new `OverviewScreen` (Task B5).
- Produces: `AppShell` widget wrapping a `NavigationRail` (expanded by default, toggle to collapse) + child content; `AppRoutes.overview = '/overview'`.

- [ ] **Step 1: Write the failing widget test**

```dart
// packages/admin_web/test/core/widgets/app_shell_test.dart
import 'package:admin_web/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppShell shows nav labels expanded, toggles to collapsed',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AppShell(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        child: const Text('BODY'),
      ),
    ));
    // Expanded: labels visible.
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('BODY'), findsOneWidget);

    // Toggle collapse.
    await tester.tap(find.byTooltip('Toggle sidebar'));
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsNothing); // labels hidden when collapsed
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/admin_web && flutter test test/core/widgets/app_shell_test.dart`
Expected: FAIL — `AppShell` undefined.

- [ ] **Step 3: Implement `AppShell`**

```dart
// packages/admin_web/lib/core/widgets/app_shell.dart
import 'package:flutter/material.dart';

import '../theme/kiz_theme.dart';

/// Persistent admin navigation shell: a collapsible left rail + content area.
/// Expanded by default; the header button toggles collapsed (icons only).
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  static const destinations = <({IconData icon, String label})>[
    (icon: Icons.dashboard_outlined, label: 'Overview'),
    (icon: Icons.campaign_outlined, label: 'Announcements'),
    (icon: Icons.report_problem_outlined, label: 'Complaints'),
    (icon: Icons.apartment_outlined, label: 'Accommodation'),
    (icon: Icons.event_available_outlined, label: 'Bookings'),
  ];

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _extended = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: _extended,
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: KizSpacing.sm),
              child: IconButton(
                tooltip: 'Toggle sidebar',
                icon: Icon(_extended ? Icons.menu_open : Icons.menu),
                onPressed: () => setState(() => _extended = !_extended),
              ),
            ),
            destinations: [
              for (final d in AppShell.destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
```

(If persisting the collapsed preference is desired, store `_extended` via `SharedPreferences` in `initState`/on toggle. Optional; not required by the test.)

- [ ] **Step 4: Convert the router to a StatefulShellRoute**

In `app_router.dart`:
- Add `static const String overview = '/overview';` to `AppRoutes` and remove `dashboard` usage (or keep the constant but redirect). 
- Replace the flat module `GoRoute`s (dashboard, announcements, complaints, accommodation, bookings) with a `StatefulShellRoute.indexedStack` whose branches are `[/overview, /announcements, /complaints, /accommodation, /bookings]`, using `AppShell` as the shell builder mapping `navigationShell.currentIndex` ↔ `AppShell.selectedIndex` and `navigationShell.goBranch` for `onDestinationSelected`. Keep detail routes (`/announcements/:id`, `/complaints/:id`, etc.) as sub-routes of their branch. Redirect `/dashboard` → `/overview`.

```dart
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: navigationShell.goBranch,
          child: navigationShell,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.overview, builder: (c, s) => const OverviewScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.announcements, builder: (c, s) => const AnnouncementsScreen(), routes: [
              GoRoute(path: 'create', builder: (c, s) => const AnnouncementFormScreen()),
              GoRoute(path: ':id', builder: (c, s) => AnnouncementDetailScreen(announcementId: s.pathParameters['id']!)),
              GoRoute(path: ':id/edit', builder: (c, s) => AnnouncementFormScreen(announcementId: s.pathParameters['id']!)),
            ]),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.complaints, builder: (c, s) => const ComplaintsScreen(), routes: [
              GoRoute(path: ':id', builder: (c, s) => ComplaintDetailScreen(complaintId: s.pathParameters['id']!)),
            ]),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.accommodation, builder: (c, s) => const AccommodationShell()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.bookings, builder: (c, s) => const BookingsScreen()),
          ]),
        ],
      ),
```

Keep the `/login` route outside the shell. Add `import` for `OverviewScreen` (Task B5). Update `initialLocation` to stay `AppRoutes.login`.

- [ ] **Step 5: Run tests + analyze**

Run: `cd packages/admin_web && flutter test test/core/widgets/app_shell_test.dart && flutter analyze lib/core`
Expected: shell test PASS. The router won't fully compile until `OverviewScreen` exists (Task B5) — if doing B4 and B5 together, run analyze after B5. Otherwise stub `OverviewScreen` as `const Placeholder()` temporarily and replace in B5.

- [ ] **Step 6: Commit**

```bash
git add packages/admin_web/lib/core/widgets/app_shell.dart \
        packages/admin_web/lib/core/router/app_router.dart \
        packages/admin_web/test/core/widgets/app_shell_test.dart
git commit -m "feat(admin): collapsible sidebar shell replacing dashboard grid"
```

---

### Task B5: Overview landing page with actionable counts

**Files:**
- Create: `packages/admin_web/lib/features/overview/application/overview_providers.dart`
- Create: `packages/admin_web/lib/features/overview/presentation/overview_screen.dart`
- Test: `packages/admin_web/test/features/overview/overview_providers_test.dart`

**Interfaces:**
- Consumes: `MyKizApiClient` (`listComplaints`, `listAllBookings`, `listApplications`, `listBlocks` + `getOccupancy`).
- Produces: `overviewCountsProvider` → `OverviewCounts(submittedComplaints, pendingBookings, submittedApplications, pendingCheckIns, nearFullBlocks)`; `OverviewScreen` renders one tappable card per count.

- [ ] **Step 1: Write the failing test**

```dart
// packages/admin_web/test/features/overview/overview_providers_test.dart
import 'package:admin_web/features/overview/application/overview_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OverviewCounts holds the five actionable metrics', () {
    const c = OverviewCounts(
      submittedComplaints: 2,
      pendingBookings: 1,
      submittedApplications: 3,
      pendingCheckIns: 0,
      nearFullBlocks: 1,
    );
    expect(c.submittedComplaints, 2);
    expect(c.total, 7); // sum of actionable items
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/admin_web && flutter test test/features/overview/overview_providers_test.dart`
Expected: FAIL — undefined `OverviewCounts`.

- [ ] **Step 3: Implement the providers**

```dart
// packages/admin_web/lib/features/overview/application/overview_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart'; // apiClientProvider

/// Actionable counts surfaced on the Overview landing page.
class OverviewCounts {
  const OverviewCounts({
    required this.submittedComplaints,
    required this.pendingBookings,
    required this.submittedApplications,
    required this.pendingCheckIns,
    required this.nearFullBlocks,
  });

  final int submittedComplaints;
  final int pendingBookings;
  final int submittedApplications;
  final int pendingCheckIns;
  final int nearFullBlocks;

  int get total =>
      submittedComplaints +
      pendingBookings +
      submittedApplications +
      pendingCheckIns +
      nearFullBlocks;
}

/// Fetches all actionable counts. Each source is fetched independently so one
/// failing source degrades to 0 rather than failing the whole page.
final overviewCountsProvider = FutureProvider<OverviewCounts>((ref) async {
  final api = ref.watch(apiClientProvider);

  Future<int> safe(Future<int> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return 0;
    }
  }

  final complaints = await safe(() async {
    final r = await api.listComplaints(limit: 1);
    // meta.totalItems is the total; but we need submitted-only.
    // Fetch a page filtered client-side is not supported; use a dedicated
    // count via listComplaints then filter. For simplicity, fetch page 1
    // (limit 100) and count status == 'submitted'.
    final page = await api.listComplaints(limit: 100);
    return page.items.where((c) => c.status == 'submitted').length;
  });

  final pendingBookings = await safe(() async {
    final r = await api.listAllBookings(status: 'pending', limit: 1);
    return r.meta.totalItems;
  });

  final submittedApps = await safe(() async {
    final resp = await api.listApplications(status: 'submitted', limit: 1);
    final meta = resp['meta'] as Map<String, dynamic>?;
    return (meta?['totalItems'] as int?) ?? 0;
  });

  final pendingCheckIns = await safe(() async {
    final resp = await api.listApplications(status: 'approved', limit: 1);
    final meta = resp['meta'] as Map<String, dynamic>?;
    return (meta?['totalItems'] as int?) ?? 0;
  });

  final nearFullBlocks = await safe(() async {
    final blocks = await api.listBlocks();
    var count = 0;
    for (final b in blocks) {
      final rooms = await api.getOccupancy(b.id);
      final total = rooms.fold<int>(0, (s, r) => s + r.total);
      final occupied = rooms.fold<int>(0, (s, r) => s + r.occupied);
      if (total > 0 && occupied / total >= 0.8) count++;
    }
    return count;
  });

  return OverviewCounts(
    submittedComplaints: complaints,
    pendingBookings: pendingBookings,
    submittedApplications: submittedApps,
    pendingCheckIns: pendingCheckIns,
    nearFullBlocks: nearFullBlocks,
  );
});
```

(Confirm `Complaint.status` field name and the `submitted` literal from `shared_core`. Confirm `listComplaints` accepts `limit`.)

- [ ] **Step 4: Run the unit test**

Run: `cd packages/admin_web && flutter test test/features/overview/overview_providers_test.dart`
Expected: PASS.

- [ ] **Step 5: Implement `OverviewScreen`**

```dart
// packages/admin_web/lib/features/overview/presentation/overview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/kiz_theme.dart';
import '../application/overview_providers.dart';

/// Admin landing page: actionable count cards linking to each module.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(overviewCountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Overview')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: KizColors.error, size: 40),
            const SizedBox(height: KizSpacing.sm),
            const Text('Could not load overview.'),
            const SizedBox(height: KizSpacing.sm),
            ElevatedButton(
              onPressed: () => ref.invalidate(overviewCountsProvider),
              child: const Text('Retry'),
            ),
          ]),
        ),
        data: (c) => GridView.count(
          padding: const EdgeInsets.all(KizSpacing.base),
          crossAxisCount: 3,
          mainAxisSpacing: KizSpacing.base,
          crossAxisSpacing: KizSpacing.base,
          childAspectRatio: 1.6,
          children: [
            _OverviewCard(
              label: 'Submitted complaints',
              count: c.submittedComplaints,
              icon: Icons.report_problem_outlined,
              onTap: () => context.go(AppRoutes.complaints),
            ),
            _OverviewCard(
              label: 'Pending bookings',
              count: c.pendingBookings,
              icon: Icons.event_available_outlined,
              onTap: () => context.go(AppRoutes.bookings),
            ),
            _OverviewCard(
              label: 'New applications',
              count: c.submittedApplications,
              icon: Icons.assignment_outlined,
              onTap: () => context.go(AppRoutes.accommodation),
            ),
            _OverviewCard(
              label: 'Pending check-ins',
              count: c.pendingCheckIns,
              icon: Icons.login_outlined,
              onTap: () => context.go(AppRoutes.accommodation),
            ),
            _OverviewCard(
              label: 'Near-full blocks',
              count: c.nearFullBlocks,
              icon: Icons.apartment_outlined,
              onTap: () => context.go(AppRoutes.accommodation),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(KizSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: KizColors.primary),
              Text('$count', style: theme.textTheme.headlineMedium),
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Analyze + run affected tests**

Run: `cd packages/admin_web && flutter analyze lib/features/overview lib/core/router && flutter test test/features/overview test/core/widgets/app_shell_test.dart`
Expected: clean + PASS.

- [ ] **Step 7: Commit**

```bash
git add packages/admin_web/lib/features/overview packages/admin_web/test/features/overview \
        packages/admin_web/lib/core/router/app_router.dart
git commit -m "feat(admin): Overview landing page with actionable count cards"
```

---

### Task B6: Demo-credential fill button (admin login)

**Files:**
- Modify: `packages/admin_web/lib/features/auth/presentation/login_screen.dart`
- Test: `packages/admin_web/test/features/auth/login_demo_fill_test.dart`

**Interfaces:**
- Produces: a small "Demo" button that opens a menu of seeded admins; selecting one fills the Staff ID + password fields (no auto-submit).

- [ ] **Step 1: Write the failing widget test**

```dart
// packages/admin_web/test/features/auth/login_demo_fill_test.dart
import 'package:admin_web/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Demo menu fills Staff ID + password', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LoginScreen()),
    ));

    await tester.tap(find.text('Demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('S98765 — Dr. Aminah').last);
    await tester.pumpAndSettle();

    final staffField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Staff ID'));
    // Controller assertion: find the EditableText values.
    expect(find.text('S98765'), findsWidgets);
    expect(find.text('password123'), findsWidgets);
  });
}
```

(If asserting controller text via `find.text` is flaky because the field obscures the password, assert on the controllers by keying the fields; add `key: const Key('staffField')` / `Key('passwordField')` and read `tester.widget<TextField>()`. Adjust as needed to a stable assertion.)

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/admin_web && flutter test test/features/auth/login_demo_fill_test.dart`
Expected: FAIL — no "Demo" button.

- [ ] **Step 3: Add the demo fill UI**

In `login_screen.dart`, add a const list and a helper, and a button after the Sign In button (inside the form `Column`):

```dart
  static const _demoAccounts = <({String id, String name})>[
    (id: 'S98765', name: 'Dr. Aminah'),
    (id: 'S87654', name: 'Encik Razak'),
  ];

  void _fillDemo(String id) {
    _identifierController.text = id;
    _passwordController.text = 'password123';
  }
```

UI (after the login button `SizedBox`):

```dart
                      const SizedBox(height: KizSpacing.sm),
                      Align(
                        alignment: Alignment.center,
                        child: PopupMenuButton<String>(
                          tooltip: 'Fill demo credentials',
                          onSelected: _fillDemo,
                          itemBuilder: (context) => [
                            for (final a in _demoAccounts)
                              PopupMenuItem(
                                value: a.id,
                                child: Text('${a.id} — ${a.name}'),
                              ),
                          ],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.science_outlined, size: 16),
                              SizedBox(width: 4),
                              Text('Demo'),
                            ],
                          ),
                        ),
                      ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/admin_web && flutter test test/features/auth/login_demo_fill_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/admin_web/lib/features/auth/presentation/login_screen.dart \
        packages/admin_web/test/features/auth/login_demo_fill_test.dart
git commit -m "feat(admin): demo-credential fill button on login"
```

---

## Phase C — Student app

### Task C1: Demo-credential fill button (student login)

**Files:**
- Modify: `packages/student_app/lib/features/auth/presentation/login_screen.dart`
- Test: `packages/student_app/test/features/auth/login_demo_fill_test.dart`

**Interfaces:**
- Produces: a "Demo" menu filling matric + password with a seeded student (no auto-submit).

- [ ] **Step 1: Write the failing widget test**

```dart
// packages/student_app/test/features/auth/login_demo_fill_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('Demo menu fills matric + password', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LoginScreen()),
    ));
    await tester.tap(find.text('Demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A123456 — Ahmad').last);
    await tester.pumpAndSettle();
    expect(find.text('A123456'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/student_app && flutter test test/features/auth/login_demo_fill_test.dart`
Expected: FAIL — no "Demo" button.

- [ ] **Step 3: Add the demo fill UI**

In the student `login_screen.dart`, add:

```dart
  static const _demoAccounts = <({String id, String name})>[
    (id: 'A123456', name: 'Ahmad'),
    (id: 'A234567', name: 'Siti'),
    (id: 'A345678', name: 'Farah'),
  ];

  void _fillDemo(String id) {
    _matricController.text = id;
    _passwordController.text = 'password123';
  }
```

Add, after the Login button `SizedBox` (inside the `Column`):

```dart
                  const SizedBox(height: KizSpacing.sm),
                  Center(
                    child: PopupMenuButton<String>(
                      tooltip: 'Fill demo credentials',
                      onSelected: _fillDemo,
                      itemBuilder: (context) => [
                        for (final a in _demoAccounts)
                          PopupMenuItem(
                            value: a.id,
                            child: Text('${a.id} — ${a.name}'),
                          ),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.science_outlined, size: 16),
                          SizedBox(width: 4),
                          Text('Demo'),
                        ],
                      ),
                    ),
                  ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/student_app && flutter test test/features/auth/login_demo_fill_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/student_app/lib/features/auth/presentation/login_screen.dart \
        packages/student_app/test/features/auth/login_demo_fill_test.dart
git commit -m "feat(student): demo-credential fill button on login"
```

---

### Task C2: Fix student login premature navigation

**Files:**
- Modify: `packages/student_app/lib/core/router/app_router.dart` (`computeRedirect` + initial location / bootstrap gating)
- Modify: `packages/student_app/lib/features/auth/application/auth_provider.dart` (add `AuthStatus.unknown` initial)
- Modify: `packages/student_app/lib/main.dart` (splash while `unknown`)
- Test: `packages/student_app/test/core/router/app_router_test.dart` (extend) + `computeRedirect` unit cases

**Interfaces:**
- Produces: cold start shows a splash (no dashboard flash); unauthenticated → `/login`; invalid login stays on `/login` with error; valid login → `/dashboard`.

**Root-cause note:** The router's `initialLocation` is `/dashboard`; on a cold start the very first frame can render the dashboard branch before the redirect settles, causing the reported flash. Introducing an `unknown` bootstrap state + splash (mirroring admin B2) removes the flash. `computeRedirect` must treat `unknown` as "stay" and unauthenticated as "→ /login". Follow systematic-debugging: reproduce the flash first, then apply.

- [ ] **Step 1: Write failing unit tests for `computeRedirect`**

Add to `app_router_test.dart` (or a new `compute_redirect_test.dart`):

```dart
import 'package:student_app/core/router/app_router.dart';
import 'package:student_app/features/auth/application/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeRedirect', () {
    test('unknown status stays (no redirect, no flash)', () {
      expect(computeRedirect(AuthStatus.unknown, '/dashboard'), isNull);
    });
    test('unauthenticated on /dashboard -> /login', () {
      expect(computeRedirect(AuthStatus.unauthenticated, '/dashboard'), '/login');
    });
    test('loading stays', () {
      expect(computeRedirect(AuthStatus.loading, '/login'), isNull);
    });
    test('authenticated on /login -> /dashboard', () {
      expect(computeRedirect(AuthStatus.authenticated, '/login'), '/dashboard');
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/student_app && flutter test test/core/router/app_router_test.dart`
Expected: FAIL — `AuthStatus.unknown` undefined.

- [ ] **Step 3: Add `unknown` and handle it**

In student `auth_provider.dart`, add `unknown` as the first `AuthStatus` value and make the default `AuthState` use `status: AuthStatus.unknown`.

In `computeRedirect`, add at the top:

```dart
String? computeRedirect(AuthStatus status, String currentRoute) {
  if (status == AuthStatus.unknown) return null; // bootstrapping: show splash
  if (status == AuthStatus.loading) return null;
  final isAuthenticated = status == AuthStatus.authenticated;
  final isOnLogin = currentRoute == AppRoutes.login;
  if (!isAuthenticated && !isOnLogin) return AppRoutes.login;
  if (isAuthenticated && isOnLogin) return AppRoutes.dashboard;
  return null;
}
```

- [ ] **Step 4: Splash while `unknown` + resolve bootstrap**

Since the student app has no persistence requirement, resolve `unknown` immediately to `unauthenticated` at startup so the redirect sends a cold start to `/login` (no dashboard flash). In `main.dart`, mirror the admin bootstrap pattern:

```dart
class StudentApp extends ConsumerStatefulWidget {
  const StudentApp({super.key});
  @override
  ConsumerState<StudentApp> createState() => _StudentAppState();
}

class _StudentAppState extends ConsumerState<StudentApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).resolveInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authProvider).status;
    final router = ref.watch(appRouterProvider);
    if (status == AuthStatus.unknown) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
      );
    }
    return MaterialApp.router(
      title: 'MyKIZ Siswa',
      theme: KizTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

Add `resolveInitial()` to the student `AuthNotifier`:

```dart
  /// Resolves the initial bootstrap state. No persistence in this app, so a
  /// cold start simply becomes unauthenticated (prevents dashboard flash).
  void resolveInitial() {
    if (state.status == AuthStatus.unknown) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
```

- [ ] **Step 5: Run tests + analyze**

Run: `cd packages/student_app && flutter test test/core/router && flutter analyze lib/core/router lib/features/auth lib/main.dart`
Expected: PASS + clean. Fix any existing router test that relied on `initialLocation:/dashboard` rendering immediately (it must now pump past the splash: set the notifier to a resolved state in the override, or call `resolveInitial`).

- [ ] **Step 6: Commit**

```bash
git add packages/student_app/lib packages/student_app/test
git commit -m "fix(student): no dashboard flash before auth resolves on login"
```

---

### Task C3: Full verification pass + deploy

**Files:** none (ops/verification).

- [ ] **Step 1: Run all package test suites**

```bash
cd packages/shared_core && dart test
cd ../api_client && dart test
cd ../admin_web && flutter test
cd ../student_app && flutter test
```
Expected: all green. Fix regressions before proceeding.

- [ ] **Step 2: Analyze the whole workspace**

Run: `melos run analyze` (or `flutter analyze` per package)
Expected: no errors.

- [ ] **Step 3: Deploy + reseed if needed**

```bash
git push && ssh vps 'cd ~/mykiz && bash deploy.sh'
```
(If bookings/apps still empty, run the seed CLI as in Task A6 Step 2.)

- [ ] **Step 4: Manual verification checklist (per verification-before-completion)**

Against the deployed apps:
- Admin: reload after login → still logged in (session persists).
- Admin: sidebar collapses/expands; Overview is the landing page with non-zero counts; each card navigates.
- Admin: Accommodation→Occupancy loads; Bookings loads (no "Failed to load").
- Admin + Student: Demo button fills credentials; login works.
- Student: cold start shows login (no dashboard flash); invalid creds stay on login with error; valid creds reach dashboard.
- Student: Accommodation applications load; Bookings/facilities load.

---

## Self-Review

- **Spec coverage:** A0/A1–A3 (occupancy + meta parse bugs), A4/A6 (seed bookings/facilities/applications), A5 (auto-migrate on boot), B1–B3 (session persistence), B4 (sidebar shell), B5 (Overview), B6 + C1 (demo fill), C2 (student nav). All spec items mapped.
- **Placeholder scan:** UI copy, code, and commands are concrete. Two tasks (B4/B5) note an ordering dependency (`OverviewScreen`); a `Placeholder()` stub bridge is specified so each still compiles.
- **Type consistency:** `RoomOccupancy` (roomId/roomNumber/roomType/total/occupied) used consistently in A1→A3, A5, B5; `_metaOf` used in A2; `AuthStatus.unknown` added consistently in B2 + C2; `OverviewCounts` fields consistent A5(B5).
- **Known verify-time confirmations:** exact `User`/`Complaint` field names + `listComplaints(limit:)` signature; whether `AccommodationRepository` is class vs interface for the A3 fake. These are called out inline for the implementer to confirm against source, not guessed silently.
