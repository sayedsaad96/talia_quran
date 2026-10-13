import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/adult_journey/adult_journey_feature_flags.dart';
import 'package:talia_quran/features/adult_journey/application/adult_journey_usecases.dart';
import 'package:talia_quran/features/adult_journey/data/adult_journey_repository_impl.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_context.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/presentation/cubits/adult_journey_cubit.dart';

/// Home and Settings each own a cubit over the same repository. A save in
/// Settings must refresh Home, and a cubit's own save must not trigger a
/// redundant re-read of itself.
void main() {
  const owner = FixedRecordOwnerProvider('owner-a');
  final now = DateTime(2026, 10, 13, 10);
  late AdultJourneyRepositoryImpl repo;
  late List<String> loads;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = AdultJourneyRepositoryImpl(prefs, owner);
    loads = [];
  });

  AdultJourneyCubit cubitNamed(String name) {
    final cubit = AdultJourneyCubit(
      loadAdultJourney: _CountingLoad(LoadAdultJourney(repo), () {
        loads.add(name);
      }),
      updateAdultJourney: UpdateAdultJourney(repo),
      flags: AdultJourneyFlags((_) => true),
      owner: owner,
      accountChanges: const Stream<void>.empty(),
      now: () => now,
      preferenceChanges: repo.changes,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test(
    'a profile saved in Settings shows on Home without a Home reload',
    () async {
      final home = cubitNamed('home');
      final settings = cubitNamed('settings');
      await home.refreshContext(
        AdultJourneyContext(
          ownerId: 'owner-a',
          isAdult: true,
          now: now,
          actions: const [],
          hasActiveAdultPlan: false,
          hasAdultReviewRecords: false,
          hasDueAdultReview: false,
        ),
      );
      await settings.loadPreferences();
      expect(home.state.setupInviteDue, isTrue);
      loads.clear();

      expect(await settings.saveProfile(AdultJourneyGoal.review, null), isTrue);
      await pumpEventQueue();

      expect(home.state.preferences.goal, AdultJourneyGoal.review);
      expect(home.state.setupInviteDue, isFalse);
      expect(loads, ['home'], reason: 'Settings did not re-read its own save');
    },
  );
}

/// Records each read while delegating to the real use case.
class _CountingLoad implements LoadAdultJourney {
  _CountingLoad(this._inner, this._onCall);

  final LoadAdultJourney _inner;
  final void Function() _onCall;

  @override
  Future<AdultJourneyLoadResult> call(String expectedOwnerId) {
    _onCall();
    return _inner(expectedOwnerId);
  }
}
