import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/family_dashboard_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('FamilyDashboardPage', () {
    testWidgets(
      'guidance-audio switch is hidden from the settings sheet',
      (tester) async {
        final usecases = _FakeUsecases();
        usecases.settings = const ParentSettings(
          pinHash: 'secure-v2',
          sessionGoalMinutes: 6,
          guidanceAudioEnabled: true,
        );
        usecases.dashboard = _dashboard();

        await tester.pumpWidget(
          // ignore: prefer_const_constructors
          _TestApp(cubit: _buildCubit(usecases)),
        );
        // Initial load → PIN gate
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, '1234');
        await tester.tap(find.text('Enter'));
        await tester.pumpAndSettle();

        // Open the settings sheet.
        await tester.tap(find.byIcon(Icons.settings_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Guide voice'), findsNothing);
        // The other kid settings stay visible.
        expect(find.text('Target session length'), findsOneWidget);
      },
    );

    testWidgets('dashboard shows the family summary and children grid', (
      tester,
    ) async {
      final usecases = _FakeUsecases();
      usecases.settings = const ParentSettings(pinHash: 'secure-v2');
      usecases.dashboard = _dashboard();

      await tester.pumpWidget(
        // ignore: prefer_const_constructors
        _TestApp(cubit: _buildCubit(usecases)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1234');
      await tester.tap(find.text('Enter'));
      await tester.pumpAndSettle();

      expect(find.text('Talia'), findsOneWidget);
      expect(find.text('Link New Child'), findsOneWidget);
    });
  });
}

FamilyDashboardCubit _buildCubit(_FakeUsecases usecases) =>
    FamilyDashboardCubit(
      usecases.parentAccess,
      usecases.remoteLink,
      usecases.familyDashboard,
    );

FamilyDashboard _dashboard() {
  return const FamilyDashboard(
    settings: ParentSettings(pinHash: 'secure-v2'),
    children: [
      FamilyChildEntry(
        childUserId: 'local-child',
        displayName: 'Talia',
        isLocal: true,
        localData: ParentDashboard(
          progress: KidsProgress.initial(),
          stages: [],
          logs: [],
          rewards: [],
          settings: ParentSettings(pinHash: 'secure-v2'),
        ),
      ),
    ],
  );
}

class _FakeUsecases {
  ParentSettings settings = const ParentSettings();
  FamilyDashboard dashboard = const FamilyDashboard(
    children: [],
    settings: ParentSettings(),
  );

  late final parentAccess = _FakeParentAccess(this);
  late final remoteLink = _FakeRemoteLink(this);
  late final familyDashboard = _FakeFamilyDashboard(this);
}

class _FakeParentAccess implements ParentAccessUsecase {
  _FakeParentAccess(this._owner);

  final _FakeUsecases _owner;

  @override
  Future<Either<Failure, ParentSettings>> getSettings() async =>
      Right(_owner.settings);

  @override
  Future<Either<Failure, void>> setPin(String pin) async {
    _owner.settings = const ParentSettings(pinHash: 'secure-v2');
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String pin) async =>
      Right(pin == '1234');

  @override
  Future<Either<Failure, void>> saveSettings(ParentSettings settings) async {
    _owner.settings = settings;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> reset() async {
    _owner.settings = const ParentSettings();
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<ParentReward>>> saveReward(String title) async =>
      const Right([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemoteLink implements ParentRemoteLinkUsecase {
  _FakeRemoteLink(this._owner);

  // Kept for parity with the other fakes; only reachable via the initializer.
  // ignore: unused_field
  final _FakeUsecases _owner;

  @override
  Future<Either<Failure, void>> acceptChildLinkToken(String token) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> removeChild(String childUserId) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<ParentReward>>> saveRemoteReward({
    required String childUserId,
    required String title,
  }) async => const Right([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFamilyDashboard implements GetFamilyDashboardUsecase {
  _FakeFamilyDashboard(this._owner);

  final _FakeUsecases _owner;

  @override
  Future<Either<Failure, FamilyDashboard>> call() async =>
      Right(_owner.dashboard);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.cubit});

  final FamilyDashboardCubit cubit;

  @override
  Widget build(BuildContext context) {
    // The page builds its own cubit via getIt, so register the factory here
    // (same pattern as guardian_linking_page_test.dart).
    // ignore: prefer_const_constructors
    getIt.registerFactory<FamilyDashboardCubit>(() => cubit);
    return MaterialApp(
      locale: const Locale('en'),
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const FamilyDashboardPage(),
    );
  }
}
