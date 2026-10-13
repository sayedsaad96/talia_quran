import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/features/adult_journey/adult_journey_feature_flags.dart';
import 'package:talia_quran/features/adult_journey/application/adult_journey_usecases.dart';
import 'package:talia_quran/features/adult_journey/data/adult_journey_repository_impl.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_context.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/presentation/cubits/adult_journey_cubit.dart';

/// Adult Journey Package 1, Task 6: changing goal, experience, today's time,
/// light return, visits and dismissals changes nothing but the feature's own
/// record. Values are compared, not just key counts.
void main() {
  // Representative account and device data the feature must never touch.
  const seeded = <String, Object>{
    'user_primary_goal': 'reading',
    'mem_plus_profile': '{"selectedPath":"adult"}',
    'mem_plus_custom_plan': '{"id":"plan-1","isActive":true}',
    'mem_plus_cached_daily_plan': '{"date":"2026-10-13"}',
    'khatmah_active_plan': '{"id":"k1","currentPage":120}',
    'khatmah_history': '[]',
    'daily_read_pages_2026-10-13': '[1,2,3]',
    'daily_wird_target_2026-10-13': 4,
    'quran_bookmarks_owner_owner-a': '[{"page":12}]',
    'ayah_review_pull_cursor': '2026-10-01T00:00:00Z',
    'last_restorable_location': '/memorization-plus/v2/session?surahId=2',
    'unified_journey_enabled': true,
    'theme_mode': 'dark',
    'locale': 'ar',
  };

  test('every command leaves all other preferences byte-identical', () async {
    SharedPreferences.setMockInitialValues(Map.of(seeded));
    final prefs = await SharedPreferences.getInstance();
    const owner = FixedRecordOwnerProvider('owner-a');
    final repo = AdultJourneyRepositoryImpl(prefs, owner);
    final cubit = AdultJourneyCubit(
      loadAdultJourney: LoadAdultJourney(repo),
      updateAdultJourney: UpdateAdultJourney(repo),
      flags: AdultJourneyFlags((_) => true),
      owner: owner,
      accountChanges: const Stream<void>.empty(),
      now: () => DateTime(2026, 10, 13, 10),
    );
    addTearDown(cubit.close);

    await cubit.refreshContext(
      AdultJourneyContext(
        ownerId: 'owner-a',
        isAdult: true,
        now: DateTime(2026, 10, 13, 10),
        actions: const [
          UnifiedJourneyAction(
            route: '/memorization/review',
            priority: UnifiedJourneyPriority.p3ReviewBacklog,
            source: 'test',
            actionType: UnifiedJourneyActionType.reviewBacklog,
            intent: JourneyIntent.review,
          ),
        ],
        hasActiveAdultPlan: true,
        hasAdultReviewRecords: true,
        hasDueAdultReview: true,
      ),
    );
    expect(cubit.state.isVisible, isTrue);

    expect(
      await cubit.saveProfile(
        AdultJourneyGoal.memorization,
        AdultJourneyExperience.returning,
      ),
      isTrue,
    );
    expect(await cubit.snoozeSetup(), isTrue);
    expect(await cubit.setTodayMinutes(10), isTrue);
    await cubit.recordHomeVisit();
    expect(await cubit.startLightReturn(), isTrue);
    // Already dismissed by the light start: unchanged, and still a success.
    expect(await cubit.chooseReturnTime(), isTrue);
    expect(await cubit.continueAsUsual(), isTrue);
    // Nothing left to clear: unchanged, no write, still a success.
    expect(await cubit.clearToday(), isTrue);
    expect(await cubit.saveProfile(AdultJourneyGoal.azkar, null), isTrue);

    final after = {
      for (final key in prefs.getKeys())
        if (!key.startsWith(AdultJourneyRepositoryImpl.keyPrefix))
          key: prefs.get(key),
    };
    expect(after, seeded);
    expect(
      prefs.getKeys().where(
        (k) => k.startsWith(AdultJourneyRepositoryImpl.keyPrefix),
      ),
      [AdultJourneyRepositoryImpl.keyFor('owner-a')],
    );
  });

  test('the feature source has no path to progress, Quran or cloud data', () {
    final dir = Directory('lib/features/adult_journey');
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    const forbidden = [
      'package:isar',
      'supabase',
      'cloud_sync',
      'user_primary_goal',
      'assets/data',
      'quran_local_datasource',
      'review_outcome_committer',
      'StreakService',
      'XpService',
      'saveReviewRecord',
      'saveCustomPlan',
    ];
    final writers = <String>[];
    for (final file in files) {
      // Code only: doc comments may name what the feature must never do.
      final source = file
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      for (final token in forbidden) {
        expect(
          source.contains(token),
          isFalse,
          reason: '${file.path} mentions $token',
        );
      }
      if (RegExp(
        r'\.set(String|Bool|Int|Double|StringList)\(|\.remove\(',
      ).hasMatch(source)) {
        writers.add(file.uri.pathSegments.last);
      }
    }
    expect(writers, [
      'adult_journey_repository_impl.dart',
    ], reason: 'only the repository writes preferences');
  });
}
