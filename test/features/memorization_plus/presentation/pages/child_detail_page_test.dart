import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_child_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_home_mission.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/child_detail_page.dart';

const _settings = ParentSettings(pinHash: 'hash');

KidsHomeMission _mission(String id, KidsHomeMissionStatus status) =>
    KidsHomeMission(
      id: id,
      title: 'mission $id',
      status: status,
      createdAt: DateTime.utc(2026, 10, 1),
    );

FamilyChildEntry _remoteChild(
  List<KidsHomeMission> missions, {
  KidsChildPolicy? policy,
}) => FamilyChildEntry(
      childUserId: 'c1',
      displayName: 'Fatima',
      isLocal: false,
      remoteSummary: RemoteChildSummary(
        childUserId: 'c1',
        displayName: 'Fatima',
        progress: const KidsProgress.initial(),
        logs: const [],
        rewards: const [],
        homeMissions: missions,
        policy: policy,
      ),
    );

FamilyChildEntry _localChild(List<KidsHomeMission> missions) =>
    FamilyChildEntry(
      childUserId: 'local-child',
      displayName: 'Talia',
      isLocal: true,
      localData: ParentDashboard(
        progress: const KidsProgress.initial(),
        stages: const [],
        logs: const [],
        rewards: const [],
        settings: _settings,
        homeMissions: missions,
      ),
    );

class _Repo implements MemorizationPlusRepository {
  _Repo(this.child);

  FamilyChildEntry child;
  final remoteCreates = <String>[];
  final remoteAcks = <String>[];
  final localAdds = <String>[];
  final localAcks = <String>[];
  final remotePolicies = <String>[];

  @override
  Future<Either<Failure, KidsChildPolicy>> saveRemoteChildPolicy({
    required String childUserId,
    required KidsChildPolicy policy,
  }) async {
    remotePolicies.add(
      '$childUserId:v${policy.version}:${policy.reduceMotion}:'
      '${policy.maxDailySuggestions}:${policy.homeMissionsEnabled}',
    );
    return Right(policy);
  }

  @override
  Future<Either<Failure, ParentSettings>> getParentSettings() async =>
      const Right(_settings);

  @override
  Future<Either<Failure, bool>> verifyParentPin(String pin) async =>
      const Right(true);

  @override
  Future<Either<Failure, FamilyDashboard>> getFamilyDashboard() async =>
      Right(FamilyDashboard(children: [child], settings: _settings));

  @override
  Future<Either<Failure, List<KidsHomeMission>>> createRemoteHomeMission({
    required String childUserId,
    required String title,
  }) async {
    remoteCreates.add('$childUserId:$title');
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<KidsHomeMission>>> acknowledgeRemoteHomeMission(
    String missionId,
  ) async {
    remoteAcks.add(missionId);
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<KidsHomeMission>>> addLocalHomeMission(
    String title,
  ) async {
    localAdds.add(title);
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<KidsHomeMission>>> acknowledgeLocalHomeMission(
    String id,
  ) async {
    localAcks.add(id);
    return const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_Repo> _pump(
  WidgetTester tester,
  FamilyChildEntry child, {
  Locale locale = const Locale('en'),
}) async {
  final repo = _Repo(child);
  final cubit = FamilyDashboardCubit(
    ParentAccessUsecase(repo),
    ParentRemoteLinkUsecase(repo),
    GetFamilyDashboardUsecase(repo),
  );
  addTearDown(cubit.close);
  await cubit.load();
  await cubit.unlock('1234');
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<FamilyDashboardCubit>.value(
        value: cubit,
        child: ChildDetailPage(child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  testWidgets('shows status chips and acknowledge only on reported rows', (
    tester,
  ) async {
    await _pump(
      tester,
      _remoteChild([
        _mission('1', KidsHomeMissionStatus.assigned),
        _mission('2', KidsHomeMissionStatus.reported),
        _mission('3', KidsHomeMissionStatus.acknowledged),
      ]),
    );
    await _scrollTo(tester, find.text('Home missions').first);

    expect(find.text('Waiting for child'), findsOneWidget);
    expect(find.text("Child says it's done"), findsOneWidget);
    expect(find.text('Seen by guardian'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-mission-ack-1')), findsNothing);
    expect(find.byKey(const ValueKey('home-mission-ack-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-mission-ack-3')), findsNothing);
  });

  testWidgets('acknowledging a remote mission calls the remote API', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      _remoteChild([_mission('2', KidsHomeMissionStatus.reported)]),
    );
    final ack = find.byKey(const ValueKey('home-mission-ack-2'));
    await _scrollTo(tester, ack);
    await tester.tap(ack);
    await tester.pumpAndSettle();

    expect(repo.remoteAcks, ['2']);
    expect(repo.localAcks, isEmpty);
  });

  testWidgets('a local child acknowledges through the local API', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      _localChild([_mission('9', KidsHomeMissionStatus.reported)]),
    );
    final ack = find.byKey(const ValueKey('home-mission-ack-9'));
    await _scrollTo(tester, ack);
    await tester.tap(ack);
    await tester.pumpAndSettle();

    expect(repo.localAcks, ['9']);
  });

  testWidgets('a suggestion chip fills the field and saves remotely', (
    tester,
  ) async {
    final repo = await _pump(tester, _remoteChild(const []));
    final add = find.byKey(const ValueKey('child-detail-add-home-mission'));
    await _scrollTo(tester, add);
    await tester.tap(add);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tidy your room'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repo.remoteCreates, ['c1:Tidy your room']);
  });

  testWidgets('free text mission for the local child uses the local API', (
    tester,
  ) async {
    final repo = await _pump(tester, _localChild(const []));
    final add = find.byKey(const ValueKey('child-detail-add-home-mission'));
    await _scrollTo(tester, add);
    await tester.tap(add);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Water the plants');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repo.localAdds, ['Water the plants']);
  });

  testWidgets('renders in Arabic without layout exceptions', (tester) async {
    await _pump(
      tester,
      _remoteChild([_mission('2', KidsHomeMissionStatus.reported)]),
      locale: const Locale('ar'),
    );
    await _scrollTo(tester, find.text('المهمات المنزلية').first);

    expect(find.text('اطّلعت'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a remote child edits its policy with the summary version', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      _remoteChild(
        const [],
        policy: const KidsChildPolicy(maxDailySuggestions: 2, version: 5),
      ),
    );
    final reduceMotion = find.byKey(const ValueKey('kids-policy-reduce-motion'));
    await _scrollTo(tester, reduceMotion);
    await tester.ensureVisible(reduceMotion);
    await tester.pumpAndSettle();
    expect(find.text('Reduce motion'), findsOneWidget);
    expect(find.text('Missions per day'), findsOneWidget);
    await tester.tap(reduceMotion);
    await tester.pumpAndSettle();

    expect(repo.remotePolicies, ['c1:v5:true:2:true']);
  });

  testWidgets('a remote child without a policy row edits from version 0', (
    tester,
  ) async {
    final repo = await _pump(tester, _remoteChild(const []));
    final homeMissions = find.byKey(
      const ValueKey('kids-policy-home-missions'),
    );
    await _scrollTo(tester, homeMissions);
    await tester.ensureVisible(homeMissions);
    await tester.pumpAndSettle();
    await tester.tap(homeMissions);
    await tester.pumpAndSettle();

    expect(repo.remotePolicies, ['c1:v0:false:3:false']);
  });
}
