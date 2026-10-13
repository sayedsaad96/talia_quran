import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_achievements.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_world_growth_snapshot.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_growth_controller.dart';

Map<String, DateTime> _ids(Iterable<String> names) => {
  for (final name in names) name: DateTime.utc(2026, 10, 1),
};

void main() {
  group('buildKidsWorldGrowthSnapshot', () {
    test('no milestones grow nothing', () {
      expect(
        buildKidsWorldGrowthSnapshot(const KidsWorldGrowthEvidence()),
        KidsWorldGrowthSnapshot.none,
      );
    });

    test('a plant per reached milestone and a blossom per effort one', () {
      final snapshot = buildKidsWorldGrowthSnapshot(
        KidsWorldGrowthEvidence(
          unlockedAchievements: _ids([
            'firstAyah',
            'firstPage',
            'streak3',
            'firstReview',
            'comeback',
          ]),
        ),
      );

      expect(snapshot.plants, 3);
      expect(snapshot.blossoms, 2);
    });

    test('ids this build does not know are ignored', () {
      final snapshot = buildKidsWorldGrowthSnapshot(
        KidsWorldGrowthEvidence(
          unlockedAchievements: _ids(['firstAyah', 'someFutureMilestone']),
        ),
      );

      expect(snapshot, const KidsWorldGrowthSnapshot(plants: 1));
    });

    test('plants are capped so the hills never crowd', () {
      final snapshot = buildKidsWorldGrowthSnapshot(
        KidsWorldGrowthEvidence(
          unlockedAchievements: _ids(
            KidsAchievementCatalog.specs.map((s) => s.id.name),
          ),
        ),
      );

      expect(KidsAchievementCatalog.specs.length, greaterThan(12));
      expect(snapshot.plants, KidsWorldGrowthSnapshot.maxPlants);
    });

    test('the same evidence always grows the same world', () {
      final evidence = KidsWorldGrowthEvidence(
        unlockedAchievements: _ids(['firstAyah', 'triedAgain']),
      );

      expect(
        buildKidsWorldGrowthSnapshot(evidence),
        buildKidsWorldGrowthSnapshot(evidence),
      );
    });
  });

  group('KidsWorldGrowthController', () {
    test('stays empty while the feature is off', () async {
      var reads = 0;
      final controller = KidsWorldGrowthController(
        unlockedAchievements: () {
          reads++;
          return _ids(['firstAyah']);
        },
        enabled: () => false,
      )..ensureStarted();
      await Future<void>.delayed(Duration.zero);

      expect(controller.value, KidsWorldGrowthSnapshot.none);
      expect(reads, 0);
      controller.dispose();
    });

    test('reads the stored milestones once started', () async {
      final controller = KidsWorldGrowthController(
        unlockedAchievements: () => _ids(['firstAyah', 'firstPage']),
        enabled: () => true,
      )..ensureStarted();
      // The read is deferred out of the caller's build.
      expect(controller.value, KidsWorldGrowthSnapshot.none);
      await Future<void>.delayed(Duration.zero);

      expect(controller.value.plants, 2);
      controller.dispose();
    });

    test('an unreadable store shows no growth instead of failing', () async {
      final controller = KidsWorldGrowthController(
        unlockedAchievements: () => throw StateError('storage unavailable'),
        enabled: () => true,
      )..ensureStarted();
      await Future<void>.delayed(Duration.zero);

      expect(controller.value, KidsWorldGrowthSnapshot.none);
      controller.dispose();
    });

    test('a progress change re-reads; dispose stops listening', () async {
      var stored = _ids(['firstAyah']);
      final changes = StreamController<void>.broadcast();
      final controller = KidsWorldGrowthController(
        unlockedAchievements: () => stored,
        enabled: () => true,
        changes: changes.stream,
      )..ensureStarted();
      await Future<void>.delayed(Duration.zero);
      expect(controller.value.plants, 1);

      stored = _ids(['firstAyah', 'ayahs10']);
      changes.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(controller.value.plants, 2);

      controller.dispose();
      changes.add(null);
      await Future<void>.delayed(Duration.zero);
      await changes.close();
    });

    test('a later start after an owner switch shows that owner', () async {
      var owner = 'a';
      final controller = KidsWorldGrowthController(
        unlockedAchievements: () =>
            owner == 'a' ? _ids(['firstAyah', 'firstPage']) : const {},
        enabled: () => true,
      )..ensureStarted();
      await Future<void>.delayed(Duration.zero);
      expect(controller.value.plants, 2);

      owner = 'b';
      controller.ensureStarted();
      await Future<void>.delayed(Duration.zero);

      expect(controller.value, KidsWorldGrowthSnapshot.none);
      controller.dispose();
    });
  });
}
