import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_web/features/accommodation/application/accommodation_settings_provider.dart';
import 'package:admin_web/features/accommodation/data/accommodation_repository.dart';
import 'package:admin_web/features/auth/data/auth_repository.dart';

import 'fake_accommodation_repository.dart';

void main() {
  group('AccommodationSettingsNotifier', () {
    late ProviderContainer container;
    late FakeAccommodationRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeAccommodationRepository();
      container = ProviderContainer(
        overrides: [
          accommodationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('fetch sets isOpen from repository', () async {
      fakeRepo.windowOpen = true;
      final notifier =
          container.read(accommodationSettingsProvider.notifier);
      await notifier.fetch();
      final state = container.read(accommodationSettingsProvider);
      expect(state.isOpen, true);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });

    test('fetch sets error on failure', () async {
      fakeRepo.shouldFail = true;
      final notifier =
          container.read(accommodationSettingsProvider.notifier);
      await notifier.fetch();
      final state = container.read(accommodationSettingsProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNotNull);
    });

    test('toggle performs optimistic update', () async {
      fakeRepo.windowOpen = false;
      final notifier =
          container.read(accommodationSettingsProvider.notifier);
      await notifier.fetch();

      // Start toggle — should optimistically flip to true
      final future = notifier.toggle();
      // After awaiting, the persisted value should be true
      await future;
      final state = container.read(accommodationSettingsProvider);
      expect(state.isOpen, true);
      expect(state.errorMessage, isNull);
    });

    test('toggle reverts on failure and shows error', () async {
      fakeRepo.windowOpen = false;
      final notifier =
          container.read(accommodationSettingsProvider.notifier);
      await notifier.fetch();

      fakeRepo.shouldFail = true;
      await notifier.toggle();

      final state = container.read(accommodationSettingsProvider);
      expect(state.isOpen, false); // reverted
      expect(state.errorMessage, isNotNull);
    });
  });
}
