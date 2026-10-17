import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/guardian_milestone_seen_store.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/guardian_milestone_detector.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart';

class _Repo implements MemorizationPlusRepository {
  FamilyDashboard dashboard = const FamilyDashboard(
    children: [],
    settings: ParentSettings(),
  );

  @override
  Future<Either<Failure, FamilyDashboard>> getFamilyDashboard() async =>
      Right(dashboard);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

KidsSessionLog _log(int ayah) => KidsSessionLog(
  id: 'l$ayah',
  surahId: 114,
  ayahNumber: ayah,
  repeatsCompleted: 3,
  pointsEarned: 5,
  completedAt: DateTime.utc(2026, 10, 14),
);

FamilyDashboard _localChild(List<KidsSessionLog> logs) => FamilyDashboard(
  settings: const ParentSettings(weeklyGoalSessions: 99),
  children: [
    FamilyChildEntry(
      childUserId: 'local-id',
      displayName: 'Noor',
      isLocal: true,
      localData: ParentDashboard(
        progress: const KidsProgress.initial(),
        stages: const [],
        logs: logs,
        rewards: const [],
        settings: const ParentSettings(),
      ),
    ),
  ],
);

void main() {
  late _Repo repo;
  late SharedPreferences prefs;
  late GuardianMilestoneSeenStore store;
  var enabled = true;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = GuardianMilestoneSeenStore(
      prefs,
      const FixedRecordOwnerProvider('owner'),
    );
    repo = _Repo();
    enabled = true;
  });

  FamilyDashboardCubit build() => FamilyDashboardCubit(
    ParentAccessUsecase(repo),
    ParentRemoteLinkUsecase(repo),
    GetFamilyDashboardUsecase(repo),
    guardianSessionActive: () => true,
    milestoneStore: store,
    milestonesEnabled: () => enabled,
    ayahCounts: () async => {114: 2},
    localCertificates: () => const [],
    clock: () => DateTime.utc(2026, 10, 14, 10),
  );

  List<GuardianNewsItem> news(FamilyDashboardCubit cubit) =>
      (cubit.state as FamilyDashboardLoaded).news;

  test('first load marks what exists as seen and shows nothing', () async {
    repo.dashboard = _localChild([_log(1), _log(2)]);
    final cubit = build();
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(news(cubit), isEmpty);
    expect(await store.seen('local'), {'surah:114'});
  });

  test('something new after the first load shows; Done hides it', () async {
    repo.dashboard = _localChild([_log(1)]);
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.refresh();
    expect(news(cubit), isEmpty);

    repo.dashboard = _localChild([_log(1), _log(2)]);
    await cubit.refresh();

    expect(news(cubit).single.milestone, const SurahCompletedMilestone(114));
    expect(news(cubit).single.child.displayName, 'Noor');

    await cubit.dismissNews();

    expect(news(cubit), isEmpty);
    expect(await store.seen('local'), {'surah:114'});

    await cubit.refresh();
    expect(news(cubit), isEmpty);
  });

  test('the switch off shows nothing and never touches the store', () async {
    enabled = false;
    repo.dashboard = _localChild([_log(1), _log(2)]);
    final cubit = build();
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(news(cubit), isEmpty);
    expect(prefs.getKeys(), isEmpty);
  });
}
