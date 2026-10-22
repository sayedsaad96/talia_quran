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
    final spy = _ThrowingStore(prefs);
    repo.dashboard = _localChild([_log(1), _log(2)]);
    final cubit = FamilyDashboardCubit(
      ParentAccessUsecase(repo),
      ParentRemoteLinkUsecase(repo),
      GetFamilyDashboardUsecase(repo),
      guardianSessionActive: () => true,
      milestoneStore: spy,
      milestonesEnabled: () => enabled,
      ayahCounts: () async => {114: 2},
    );
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(news(cubit), isEmpty);
    expect(spy.calls, 0);
    expect(prefs.getKeys(), isEmpty);
  });

  group('linked children', () {
    test('details still loading: skipped and not marked seen', () async {
      repo.dashboard = _dashboardOf([
        _remote('c1', [_log(1), _log(2)], loading: true),
      ]);
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.refresh();

      expect(news(cubit), isEmpty);
      expect(await store.hasRecord('c1'), isFalse);
    });

    test('no logs at all: skipped and not marked seen', () async {
      repo.dashboard = _dashboardOf([
        const FamilyChildEntry(
          childUserId: 'local-id',
          displayName: 'Noor',
          isLocal: true,
        ),
        const FamilyChildEntry(
          childUserId: 'c1',
          displayName: 'Sami',
          isLocal: false,
        ),
      ]);
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.refresh();

      expect(news(cubit), isEmpty);
      expect(await store.hasRecord('local'), isFalse);
      expect(await store.hasRecord('c1'), isFalse);
    });

    test(
      'first load marks complete data seen; later news is keyed by id',
      () async {
        repo.dashboard = _dashboardOf([
          _remote('c1', [_log(1), _log(2)]),
        ]);
        final cubit = build();
        addTearDown(cubit.close);

        await cubit.refresh();
        expect(news(cubit), isEmpty);
        expect(await store.seen('c1'), {'surah:114'});

        repo.dashboard = _dashboardOf([
          _remote(
            'c1',
            [_log(1), _log(2)],
            certs: [
              RemoteCertificateAward(
                certId: 'cert_surah_114',
                titleAr: 'شهادة',
                certType: 'surah',
                earnedAt: DateTime.utc(2026, 10, 14),
              ),
            ],
          ),
        ]);
        await cubit.refresh();

        final item = news(cubit).single;
        expect(item.childKey, 'c1');
        expect(item.milestone.id, 'cert:cert_surah_114');

        await cubit.dismissNews();
        expect(await store.seen('c1'), {'surah:114', 'cert:cert_surah_114'});
      },
    );

    test('a child that throws does not affect the others', () async {
      final spy = _SpyStore(prefs)..failFor = 'bad';
      repo.dashboard = _dashboardOf([
        _remote('bad', [_log(1)]),
        _remote('good', [_log(1)]),
      ]);
      final cubit = FamilyDashboardCubit(
        ParentAccessUsecase(repo),
        ParentRemoteLinkUsecase(repo),
        GetFamilyDashboardUsecase(repo),
        guardianSessionActive: () => true,
        milestoneStore: spy,
        milestonesEnabled: () => true,
        ayahCounts: () async => {114: 2},
        clock: () => DateTime.utc(2026, 10, 14, 10),
      );
      addTearDown(cubit.close);
      await cubit.refresh();

      repo.dashboard = _dashboardOf([
        _remote('bad', [_log(1), _log(2)]),
        _remote('good', [_log(1), _log(2)]),
      ]);
      await cubit.refresh();

      expect(news(cubit).map((n) => n.childKey), ['good']);
    });
  });
}

FamilyDashboard _dashboardOf(List<FamilyChildEntry> children) =>
    FamilyDashboard(
      settings: const ParentSettings(weeklyGoalSessions: 99),
      children: children,
    );

FamilyChildEntry _remote(
  String id,
  List<KidsSessionLog> logs, {
  bool loading = false,
  List<RemoteCertificateAward> certs = const [],
}) => FamilyChildEntry(
  childUserId: id,
  displayName: 'Child $id',
  isLocal: false,
  remoteSummary: RemoteChildSummary(
    childUserId: id,
    displayName: 'Child $id',
    progress: const KidsProgress.initial(),
    logs: logs,
    rewards: const [],
    detailsLoading: loading,
    production: certs.isEmpty
        ? null
        : RemoteChildProductionSummary(
            totalMemorizedAyahs: 0,
            totalAyahsTracked: 0,
            completionPercent: 0,
            reviewsCompleted: 0,
            reviewsOverdue: 0,
            dailyPlanTotal: 0,
            dailyPlanCompleted: 0,
            activeDaysLast30: 0,
            certificates: certs,
          ),
  ),
);

/// Fails any store access, so a read that writes nothing is caught too.
class _ThrowingStore extends GuardianMilestoneSeenStore {
  _ThrowingStore(SharedPreferences prefs)
    : super(prefs, const FixedRecordOwnerProvider('owner'));
  int calls = 0;

  @override
  Future<bool> hasRecord(String childKey) async {
    calls++;
    throw StateError('store read');
  }

  @override
  Future<Set<String>> seen(String childKey) async {
    calls++;
    throw StateError('store read');
  }

  @override
  Future<Set<String>> unseen(String childKey, Iterable<String> detected) async {
    calls++;
    throw StateError('store read');
  }

  @override
  Future<void> markSeen(String childKey, Iterable<String> ids) async {
    calls++;
    throw StateError('store write');
  }
}

class _SpyStore extends GuardianMilestoneSeenStore {
  _SpyStore(SharedPreferences prefs)
    : super(prefs, const FixedRecordOwnerProvider('owner'));
  String? failFor;

  @override
  Future<Set<String>> unseen(String childKey, Iterable<String> detected) {
    if (childKey == failFor) throw StateError('boom');
    return super.unseen(childKey, detected);
  }
}
