import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/remote_children_dashboard_cache.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_cloud_mappers.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_family_service.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_kids_cloud_sync_service.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_kids_local_service.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_profile_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_home_mission.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

class _MockCloud extends Mock implements MemorizationKidsCloudSyncService {}

class _MockProfile extends Mock implements MemorizationProfileService {}

class _MockKidsLocal extends Mock implements MemorizationKidsLocalService {}

const _guardian = 'guardian-1';
final _mappers = MemorizationCloudMappers(const ProgressMetricsService());

Map<String, dynamic> _childRow(String id) => {
  'child_user_id': id,
  'display_name': 'Maryam',
  'logs': <dynamic>[],
  'rewards': <dynamic>[],
  'review_summary': {'review_count': 0},
  'daily_plan': null,
  'certificates': <dynamic>[],
  'streak': null,
  'activities': <dynamic>[],
  'activity_snapshot': null,
};

void main() {
  late SharedPreferences prefs;
  late RemoteChildrenDashboardCache cache;
  late _MockCloud cloud;
  late MemorizationFamilyService service;

  MemorizationFamilyService build({String owner = _guardian}) =>
      MemorizationFamilyService(
        MemorizationPlusLocalDatasourceImpl(prefs),
        _profile(),
        _MockKidsLocal(),
        cloud,
        _mappers,
        dashboardCache: cache,
        owner: FixedRecordOwnerProvider(owner),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cache = RemoteChildrenDashboardCache(
      prefs,
      clock: () => DateTime.utc(2026, 10, 5, 9),
    );
    cloud = _MockCloud();
    when(
      () => cloud.getRemoteHomeMissions(any()),
    ).thenAnswer((_) async => const Right(<KidsHomeMission>[]));
    when(
      () => cloud.getRemoteChildPolicy(any()),
    ).thenAnswer((_) async => const Right(null));
    service = build();
  });

  Future<FamilyDashboard> read() async => (await service.getFamilyDashboard())
      .getOrElse(() => throw StateError('dashboard failed'));

  void remoteFails(Failure failure) => when(
    () => cloud.getRemoteChildren(),
  ).thenAnswer((_) async => Left(failure));

  test('a fresh read is live and asks for missions and policy', () async {
    when(() => cloud.getRemoteChildren()).thenAnswer(
      (_) async =>
          Right(_mappers.parseRemoteChildrenDashboard([_childRow('c1')])),
    );

    final dashboard = await read();

    expect(dashboard.remoteStatus, FamilyRemoteStatus.live);
    expect(dashboard.children.single.childUserId, 'c1');
    verify(() => cloud.getRemoteHomeMissions('c1')).called(1);
  });

  test('a failed read shows the saved copy with its time', () async {
    await cache.save(_guardian, [_childRow('c1')]);
    remoteFails(const NetworkFailure());

    final dashboard = await read();

    expect(dashboard.remoteStatus, FamilyRemoteStatus.cached);
    expect(dashboard.remoteFetchedAt, DateTime.utc(2026, 10, 5, 9));
    final summary = dashboard.children.single.remoteSummary!;
    expect(summary.childUserId, 'c1');
    expect(summary.policyUnavailable, isTrue);
    expect(summary.homeMissionsUnavailable, isTrue);
    verifyNever(() => cloud.getRemoteHomeMissions(any()));
  });

  test('a failed read with nothing saved is unavailable, not empty', () async {
    remoteFails(const NetworkFailure());

    final dashboard = await read();

    expect(dashboard.remoteStatus, FamilyRemoteStatus.unavailable);
    expect(dashboard.remoteReadFailed, isTrue);
  });

  test('another account never sees the saved copy', () async {
    await cache.save('someone-else', [_childRow('c1')]);
    remoteFails(const NetworkFailure());

    final dashboard = await read();

    expect(dashboard.remoteStatus, FamilyRemoteStatus.unavailable);
    expect(dashboard.children, isEmpty);
  });

  test('a signed-out device is not connected and shows no banner', () async {
    await cache.save(_guardian, [_childRow('c1')]);
    remoteFails(const NetworkFailure(CubitMessageCodes.guardianSignInRequired));

    final dashboard = await read();

    expect(dashboard.remoteStatus, FamilyRemoteStatus.notConnected);
    expect(dashboard.remoteReadFailed, isFalse);
    expect(dashboard.children, isEmpty);
  });

  test('an unreadable saved copy counts as unavailable', () async {
    await cache.save(_guardian, 'not a list');
    remoteFails(const NetworkFailure());

    expect((await read()).remoteStatus, FamilyRemoteStatus.unavailable);
  });

  test('a failed mission read is flagged on a live child', () async {
    when(() => cloud.getRemoteChildren()).thenAnswer(
      (_) async =>
          Right(_mappers.parseRemoteChildrenDashboard([_childRow('c1')])),
    );
    when(
      () => cloud.getRemoteHomeMissions(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final summary = (await read()).children.single.remoteSummary!;

    expect(summary.homeMissionsUnavailable, isTrue);
    expect(summary.policyUnavailable, isFalse);
  });

  test(
    'children are read in small parallel batches, in server order',
    () async {
      final ids = [for (var i = 1; i <= 6; i++) 'c$i'];
      when(() => cloud.getRemoteChildren()).thenAnswer(
        (_) async => Right(
          _mappers.parseRemoteChildrenDashboard([
            for (final id in ids) _childRow(id),
          ]),
        ),
      );
      var inFlight = 0;
      var peak = 0;
      when(() => cloud.getRemoteHomeMissions(any())).thenAnswer((_) async {
        peak = ++inFlight > peak ? inFlight : peak;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        inFlight--;
        return const Right(<KidsHomeMission>[]);
      });

      final dashboard = await read();

      expect(dashboard.children.map((c) => c.childUserId), ids);
      expect(peak, MemorizationFamilyService.maxParallelChildReads);
    },
  );

  test('children show first, then their details fill in per batch', () async {
    final ids = [for (var i = 1; i <= 6; i++) 'c$i'];
    when(() => cloud.getRemoteChildren()).thenAnswer(
      (_) async => Right(
        _mappers.parseRemoteChildrenDashboard([
          for (final id in ids) _childRow(id),
        ]),
      ),
    );

    final events = await service.watchFamilyDashboard().toList();

    List<bool> loading(Either<Failure, FamilyDashboard> event) => [
      for (final child
          in event.getOrElse(() => throw StateError('failed')).children)
        child.remoteSummary!.detailsLoading,
    ];
    expect(events.map(loading), [
      List.filled(6, true),
      [false, false, false, false, true, true],
      List.filled(6, false),
    ]);
  });

  test('a throwing detail read flags that child instead of loading', () async {
    when(() => cloud.getRemoteChildren()).thenAnswer(
      (_) async => Right(
        _mappers.parseRemoteChildrenDashboard([
          _childRow('c1'),
          _childRow('c2'),
        ]),
      ),
    );
    when(
      () => cloud.getRemoteChildPolicy('c1'),
    ).thenAnswer((_) async => throw StateError('socket closed'));

    final children = (await read()).children;

    final broken = children.first.remoteSummary!;
    expect(broken.detailsLoading, isFalse);
    expect(broken.policyUnavailable, isTrue);
    expect(broken.homeMissionsUnavailable, isTrue);
    expect(children.last.remoteSummary!.policyUnavailable, isFalse);
  });

  test('a saved copy arrives in one event, without loading marks', () async {
    remoteFails(const NetworkFailure());
    await cache.save(_guardian, [_childRow('c1')]);

    final events = await service.watchFamilyDashboard().toList();

    expect(events, hasLength(1));
    final summary = events.single
        .getOrElse(() => throw StateError('failed'))
        .children
        .single
        .remoteSummary!;
    expect(summary.detailsLoading, isFalse);
    expect(summary.homeMissionsUnavailable, isTrue);
  });

  test(
    'on the child device it shows that child and skips the server',
    () async {
      final kidsLocal = _MockKidsLocal();
      when(
        () => kidsLocal.getKidsProgress(),
      ).thenAnswer((_) async => const Right(KidsProgress.initial()));
      when(
        () => kidsLocal.getKidsJourney(surahId: any(named: 'surahId')),
      ).thenAnswer((_) async => const Right(<KidsJourneyStage>[]));
      final childDevice = MemorizationFamilyService(
        MemorizationPlusLocalDatasourceImpl(prefs),
        _profile(path: MemorizationPath.child),
        kidsLocal,
        cloud,
        _mappers,
        dashboardCache: cache,
        owner: const FixedRecordOwnerProvider(_guardian),
      );

      final dashboard = (await childDevice.getFamilyDashboard()).getOrElse(
        () => throw StateError('dashboard failed'),
      );

      expect(dashboard.children.single.isLocal, isTrue);
      expect(dashboard.children.single.childUserId, 'local-child');
      expect(dashboard.remoteStatus, FamilyRemoteStatus.notConnected);
      verifyNever(() => cloud.getRemoteChildren());
    },
  );

  group('RemoteChildrenDashboardCache', () {
    test('round-trips a payload per owner', () async {
      await cache.save(_guardian, [_childRow('c1')]);

      final cached = cache.read(_guardian)!;

      expect(cached.fetchedAt, DateTime.utc(2026, 10, 5, 9));
      expect((cached.payload! as List).single['child_user_id'], 'c1');
      expect(cache.read('someone-else'), isNull);
    });

    test('a corrupt entry reads as nothing', () async {
      await prefs.setString(
        'family_remote_dashboard_cache_v1:$_guardian',
        '{broken',
      );

      expect(cache.read(_guardian), isNull);
    });
  });
}

_MockProfile _profile({MemorizationPath path = MemorizationPath.adult}) {
  final profile = _MockProfile();
  final now = DateTime.utc(2026, 10, 1);
  when(() => profile.loadProfile()).thenAnswer(
    (_) async => MemorizationProfileModel(
      schemaVersion: 1,
      selectedPath: path,
      guardianLinkStatus: GuardianLinkStatus.none,
      guardianOnboardingStatus: GuardianOnboardingStatus.completed,
      isParentGuardian: false,
      createdAt: now,
      updatedAt: now,
    ),
  );
  return profile;
}
