import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/dashboard/data/module_registry.dart';

/// Generates a random string of given [length] using [rng].
/// May produce empty strings when length is 0.
String _randomString(Random rng, int maxLength) {
  final length = rng.nextInt(maxLength + 1);
  const chars = 'abcdefghijklmnopqrstuvwxyz/_ ';
  return String.fromCharCodes(
    List.generate(length, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}

/// Generates a random route path (may or may not start with '/').
String _randomRoutePath(Random rng, int maxLength) {
  final length = rng.nextInt(maxLength + 1);
  if (length == 0) return '';
  const chars = 'abcdefghijklmnopqrstuvwxyz/-_';
  return String.fromCharCodes(
    List.generate(length, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}

/// Generates a random [ModuleRegistryEntry] — may be valid or invalid.
ModuleRegistryEntry _randomEntry(Random rng) {
  return ModuleRegistryEntry(
    label: _randomString(rng, 10),
    icon: Icons.circle,
    routePath: _randomRoutePath(rng, 15),
  );
}

/// A pool of route paths to create intentional duplicates.
const _routePool = ['/a', '/b', '/c', '/d', '/announcements', '/complaints'];

/// Generates a list of entries with intentional duplicate routePaths.
List<ModuleRegistryEntry> _listWithDuplicates(Random rng) {
  final count = 2 + rng.nextInt(15); // 2..16 entries
  return List.generate(count, (i) {
    final routePath = _routePool[rng.nextInt(_routePool.length)];
    return ModuleRegistryEntry(
      label: 'Module $i',
      icon: Icons.circle,
      routePath: routePath,
    );
  });
}

void main() {
  // Feature: student-dashboard, Property 4: Registry-to-tiles bijection
  group('Property 4: Registry-to-tiles bijection', () {
    /// **Validates: Requirements 4.1, 6.2, 6.3**
    ///
    /// For any list of ModuleRegistryEntry objects, filtering by isValid gives
    /// exactly the entries that should render as tiles (non-empty label AND
    /// non-empty routePath). Invalid entries are omitted.
    test(
      'valid entries produce tiles, invalid entries are omitted — 200 random inputs',
      () {
        final rng = Random(42); // deterministic seed for reproducibility

        for (var i = 0; i < 200; i++) {
          final listLength = rng.nextInt(20); // 0..19 entries
          final entries = List.generate(listLength, (_) => _randomEntry(rng));

          // The "tile list" is entries filtered by isValid
          final tiles = entries.where((e) => e.isValid).toList();

          // Property: every tile has non-empty label AND non-empty routePath
          for (final tile in tiles) {
            expect(tile.label.isNotEmpty, isTrue,
                reason: 'Tile should have non-empty label');
            expect(tile.routePath.isNotEmpty, isTrue,
                reason: 'Tile should have non-empty routePath');
          }

          // Property: every omitted entry has empty label OR empty routePath
          final omitted = entries.where((e) => !e.isValid).toList();
          for (final entry in omitted) {
            expect(entry.label.isEmpty || entry.routePath.isEmpty, isTrue,
                reason: 'Omitted entry should have empty label or routePath');
          }

          // Property: tiles + omitted = original list (bijection, no entries lost)
          expect(tiles.length + omitted.length, equals(entries.length),
              reason: 'Valid + invalid should account for all entries');
        }
      },
    );
  });

  // Feature: student-dashboard, Property 7: Unique route path enforcement
  group('Property 7: Unique route path enforcement', () {
    /// **Validates: Requirements 6.4**
    ///
    /// For any list with duplicate routePaths, dedupRegistry keeps only the
    /// first occurrence of each routePath.
    test(
      'duplicates are deduplicated keeping first occurrence — 200 random inputs',
      () {
        final rng = Random(7); // deterministic seed

        for (var i = 0; i < 200; i++) {
          final entries = _listWithDuplicates(rng);
          final deduped = dedupRegistry(entries);

          // Property 1: all route paths in output are unique
          final routePaths = deduped.map((e) => e.routePath).toList();
          expect(routePaths.toSet().length, equals(routePaths.length),
              reason: 'Deduped list should have unique route paths');

          // Property 2: first occurrence is kept
          for (final entry in deduped) {
            final firstInOriginal =
                entries.firstWhere((e) => e.routePath == entry.routePath);
            expect(identical(entry, firstInOriginal), isTrue,
                reason:
                    'Deduped entry should be the first occurrence from original');
          }

          // Property 3: every unique route path from input is represented
          final originalPaths = entries.map((e) => e.routePath).toSet();
          final dedupedPaths = deduped.map((e) => e.routePath).toSet();
          expect(dedupedPaths, equals(originalPaths),
              reason:
                  'Deduped should contain all unique paths from the original');

          // Property 4: order is preserved (relative order of first occurrences)
          final expectedOrder = <String>[];
          final seen = <String>{};
          for (final e in entries) {
            if (seen.add(e.routePath)) expectedOrder.add(e.routePath);
          }
          expect(routePaths, equals(expectedOrder),
              reason: 'Deduped order should match first-occurrence order');
        }
      },
    );
  });
}
