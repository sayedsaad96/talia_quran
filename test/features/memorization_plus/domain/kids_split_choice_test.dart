import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_split_choice.dart';

void main() {
  final nas = KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas);
  KidsSessionLog reward(int surahId) => KidsSessionLog(
    id: 'r$surahId',
    surahId: surahId,
    ayahNumber: 1,
    repeatsCompleted: 3,
    pointsEarned: 10,
    completedAt: DateTime.utc(2026, 1, 1),
    missionType: KidsMissionType.newMemorization,
  );

  group('kidsSurahNeedsSplitChoice', () {
    bool needs({
      KidsJourneyPathDefinition? path,
      int ayahCount = 12,
      ParentSettings? settings = const ParentSettings(),
      List<KidsSessionLog>? logs = const [],
    }) => kidsSurahNeedsSplitChoice(
      path: path ?? nas,
      surahId: 66,
      ayahCount: ayahCount,
      settings: settings,
      logs: logs,
    );

    test('a fresh surah on the Quran journey asks', () {
      expect(needs(), isTrue);
    });

    test('the adventure never asks', () {
      expect(needs(path: KidsJourneyPathDefinition.adventure), isFalse);
    });

    test('unknown settings, logs or size never block', () {
      expect(needs(settings: null), isFalse);
      expect(needs(logs: null), isFalse);
      expect(needs(ayahCount: 0), isFalse);
    });

    test('a chosen split or started surah does not ask', () {
      expect(
        needs(settings: const ParentSettings(kidsWholeSurahIds: {66})),
        isFalse,
      );
      expect(
        needs(settings: const ParentSettings(kidsHouseSizesBySurah: {66: 3})),
        isFalse,
      );
      expect(needs(logs: [reward(66)]), isFalse);
      expect(needs(logs: [reward(67)]), isTrue);
    });
  });

  group('kidsMissionNeedsSplitChoice', () {
    test('only new memorization in a surah that needs the choice', () {
      const learn = KidsNextMission(
        type: KidsMissionType.newMemorization,
        surahId: 66,
        ayahNumbers: [1],
      );
      const review = KidsNextMission(
        type: KidsMissionType.dueReview,
        surahId: 66,
        ayahNumbers: [1],
      );
      expect(
        kidsMissionNeedsSplitChoice(learn, surahNeedsChoice: (_) => true),
        isTrue,
      );
      expect(
        kidsMissionNeedsSplitChoice(learn, surahNeedsChoice: (_) => false),
        isFalse,
      );
      expect(
        kidsMissionNeedsSplitChoice(review, surahNeedsChoice: (_) => true),
        isFalse,
      );
      expect(
        kidsMissionNeedsSplitChoice(null, surahNeedsChoice: (_) => true),
        isFalse,
      );
    });
  });

  group('kidsMissionLocation', () {
    const learn = KidsNextMission(
      type: KidsMissionType.newMemorization,
      surahId: 66,
      ayahNumbers: [1],
    );

    test('goes straight to the session by default', () {
      expect(
        kidsMissionLocation(learn),
        '${AppRoutes.memorizationPlusKids}?surahId=66&ayahNumber=1'
        '&missionType=newMemorization',
      );
    });

    test('opens the journey page to ask the split question first', () {
      expect(
        kidsMissionLocation(learn, needsSplitChoice: true),
        '${AppRoutes.memorizationPlusKidsJourney}?surahId=66',
      );
    });
  });
}
