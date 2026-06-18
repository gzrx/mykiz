// Feature: booking-services, Property 1: Domain model serialization round-trip
import 'dart:math';

import 'package:glados/glados.dart';
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 1.1, 2.1, 9.2, 14.1**
///
/// Property 1: Domain model serialization round-trip
/// For any valid Facility, FacilitySlotConfig, Booking, or BlockedSlot object,
/// serializing to JSON and deserializing back SHALL produce an object equal to
/// the original.

String _uuid(Random random) {
  const chars = 'abcdef0123456789';
  String seg(int len) =>
      List.generate(len, (_) => chars[random.nextInt(chars.length)]).join();
  return '${seg(8)}-${seg(4)}-${seg(4)}-${seg(4)}-${seg(12)}';
}

DateTime _utcDt(Random random) => DateTime.utc(
      2020 + random.nextInt(10),
      1 + random.nextInt(12),
      1 + random.nextInt(28),
      random.nextInt(24),
      random.nextInt(60),
      random.nextInt(60),
    );

extension BookingModelGenerators on Any {
  Generator<Facility> get facility => simple(
        generate: (random, size) {
          final hasDesc = random.nextBool();
          return Facility(
            id: _uuid(random),
            name: 'Facility${random.nextInt(9999)}',
            description: hasDesc ? 'Desc ${random.nextInt(100)}' : null,
            approvalMode: random.nextBool() ? 'auto' : 'manual',
            isActive: random.nextBool(),
            capacity: 1 + random.nextInt(50),
            graceBeforeMinutes: random.nextInt(61),
            graceAfterMinutes: random.nextInt(121),
            createdAt: _utcDt(random),
            updatedAt: _utcDt(random),
          );
        },
        shrink: (input) => [],
      );

  Generator<FacilitySlotConfig> get facilitySlotConfig => simple(
        generate: (random, size) {
          final h1 = random.nextInt(23);
          return FacilitySlotConfig(
            id: _uuid(random),
            facilityId: _uuid(random),
            startTime:
                '${h1.toString().padLeft(2, '0')}:${random.nextInt(60).toString().padLeft(2, '0')}',
            endTime:
                '${(h1 + 1).toString().padLeft(2, '0')}:${random.nextInt(60).toString().padLeft(2, '0')}',
            isActive: random.nextBool(),
            createdAt: _utcDt(random),
          );
        },
        shrink: (input) => [],
      );

  Generator<Booking> get booking => simple(
        generate: (random, size) {
          const statuses = [
            'pending', 'confirmed', 'cancelled', 'completed', 'no_show', 'rejected'
          ];
          final status = statuses[random.nextInt(statuses.length)];
          final hasCreatedBy = random.nextBool();
          return Booking(
            id: _uuid(random),
            bookingReference:
                'KIZ-${2020 + random.nextInt(10)}-${(1 + random.nextInt(99999)).toString().padLeft(5, '0')}',
            studentId: _uuid(random),
            facilityId: _uuid(random),
            slotConfigId: _uuid(random),
            bookingDate: _utcDt(random),
            status: status,
            rejectionReason:
                status == 'rejected' ? 'Reason ${random.nextInt(100)}' : null,
            createdBy: hasCreatedBy ? _uuid(random) : null,
            createdAt: _utcDt(random),
            updatedAt: _utcDt(random),
          );
        },
        shrink: (input) => [],
      );

  Generator<BlockedSlot> get blockedSlot => simple(
        generate: (random, size) {
          final hasReason = random.nextBool();
          return BlockedSlot(
            id: _uuid(random),
            facilityId: _uuid(random),
            slotConfigId: _uuid(random),
            blockedDate: _utcDt(random),
            reason: hasReason ? 'Maintenance ${random.nextInt(100)}' : null,
            createdAt: _utcDt(random),
          );
        },
        shrink: (input) => [],
      );
}

void main() {
  group('Property 1: Domain model serialization round-trip', () {
    Glados(any.facility, ExploreConfig(numRuns: 100)).test(
      'Facility: fromJson(toJson(x)) == x',
      (facility) {
        expect(Facility.fromJson(facility.toJson()), equals(facility));
      },
    );

    Glados(any.facilitySlotConfig, ExploreConfig(numRuns: 100)).test(
      'FacilitySlotConfig: fromJson(toJson(x)) == x',
      (config) {
        expect(FacilitySlotConfig.fromJson(config.toJson()), equals(config));
      },
    );

    Glados(any.booking, ExploreConfig(numRuns: 100)).test(
      'Booking: fromJson(toJson(x)) == x',
      (booking) {
        expect(Booking.fromJson(booking.toJson()), equals(booking));
      },
    );

    Glados(any.blockedSlot, ExploreConfig(numRuns: 100)).test(
      'BlockedSlot: fromJson(toJson(x)) == x',
      (slot) {
        expect(BlockedSlot.fromJson(slot.toJson()), equals(slot));
      },
    );
  });
}
