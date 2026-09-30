import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/auth/domain/services/account_password_verifier.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/child_detail_page.dart';
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
    testWidgets('guidance-audio switch is hidden from the settings sheet', (
      tester,
    ) async {
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
    });

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

    testWidgets('dashboard renders multiple children in the grid', (
      tester,
    ) async {
      final usecases = _FakeUsecases();
      usecases.settings = const ParentSettings(pinHash: 'secure-v2');
      usecases.dashboard = _dashboardWithChildren([
        const FamilyChildEntry(
          childUserId: 'child-1',
          displayName: 'Ahmad',
          isLocal: true,
          localData: ParentDashboard(
            progress: KidsProgress.initial(),
            stages: [],
            logs: [],
            rewards: [],
            settings: ParentSettings(pinHash: 'secure-v2'),
          ),
        ),
        const FamilyChildEntry(
          childUserId: 'child-2',
          displayName: 'Fatima',
          isLocal: false,
        ),
        const FamilyChildEntry(
          childUserId: 'child-3',
          displayName: 'Yusuf',
          isLocal: false,
        ),
      ]);

      await tester.pumpWidget(_TestApp(cubit: _buildCubit(usecases)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1234');
      await tester.tap(find.text('Enter'));
      await tester.pumpAndSettle();

      // All three children must be visible in the grid.
      expect(find.text('Ahmad'), findsOneWidget);
      expect(find.text('Fatima'), findsOneWidget);
      expect(find.text('Yusuf'), findsOneWidget);
      // The add-child card still appears after the list.
      expect(find.text('Link New Child'), findsOneWidget);
    });

    testWidgets('empty state shows placeholder and link-child button', (
      tester,
    ) async {
      final usecases = _FakeUsecases();
      usecases.settings = const ParentSettings(pinHash: 'secure-v2');
      usecases.dashboard = const FamilyDashboard(
        children: [],
        settings: ParentSettings(pinHash: 'secure-v2'),
      );

      await tester.pumpWidget(_TestApp(cubit: _buildCubit(usecases)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1234');
      await tester.tap(find.text('Enter'));
      await tester.pumpAndSettle();

      // Empty-state title and CTA must be visible; no child cards.
      expect(find.text('No children linked yet'), findsOneWidget);
      expect(find.text('Link New Child'), findsWidgets);
    });
  });

  testWidgets('the add-child sheet explains where the code comes from', (
    tester,
  ) async {
    final usecases = _FakeUsecases()
      ..settings = const ParentSettings(pinHash: 'secure-v2')
      ..dashboard = _dashboard();

    await tester.pumpWidget(_TestApp(cubit: _buildCubit(usecases)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '1234');
    await tester.tap(find.text('Enter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Link New Child'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "On your child's device: open the kids track → tap ⚙ → "
        '“Link guardian”, then scan the code shown or type it here.',
      ),
      findsOneWidget,
    );
    expect(find.text('Scan QR'), findsOneWidget);
  });

  group('linking errors', () {
    Future<void> submitManualCode(WidgetTester tester, String code) async {
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1234');
      await tester.tap(find.text('Enter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Link New Child').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enter linking code'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        code,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a child with another guardian gets an actionable message', (
      tester,
    ) async {
      final usecases = _FakeUsecases()
        ..settings = const ParentSettings(pinHash: 'secure-v2')
        ..acceptResult = const Left(
          ServerFailure(CubitMessageCodes.guardianChildHasGuardian),
        );

      await tester.pumpWidget(_TestApp(cubit: _buildCubit(usecases)));
      await submitManualCode(tester, 'A1B2C3D4E5F6');

      expect(
        find.text(
          'This child is already linked to another guardian. '
          'The current link must be removed first.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('@guardian'), findsNothing);
    });

    testWidgets('a generic server failure is shown as readable text', (
      tester,
    ) async {
      final usecases = _FakeUsecases()
        ..settings = const ParentSettings(pinHash: 'secure-v2')
        ..acceptResult = const Left(ServerFailure());

      await tester.pumpWidget(_TestApp(cubit: _buildCubit(usecases)));
      await submitManualCode(tester, 'A1B2C3D4E5F6');

      expect(find.textContaining('@error'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('guardian PIN reset', () {
    testWidgets('locked screen offers no reset without account recovery', (
      tester,
    ) async {
      final usecases = _FakeUsecases()
        ..settings = const ParentSettings(pinHash: 'secure-v2');

      await tester.pumpWidget(_TestApp(cubit: _buildCubit(usecases)));
      await tester.pumpAndSettle();

      expect(find.text('Forgot the code?'), findsNothing);
      expect(
        find.text('Reset on this device — a new code will be required'),
        findsNothing,
      );
      expect(usecases.resetCount, 0);
    });

    testWidgets('forgotten PIN with a wrong account password stays locked', (
      tester,
    ) async {
      final usecases = _FakeUsecases()
        ..settings = const ParentSettings(pinHash: 'secure-v2');
      final verifier = _FakeVerifier(AccountPasswordCheck.incorrect);

      await tester.pumpWidget(
        _TestApp(cubit: _buildCubit(usecases, verifier: verifier)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot the code?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('parent@example.com'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'guess',
      );
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(verifier.checkedPasswords, ['guess']);
      expect(usecases.resetCount, 0);
      expect(find.text('Incorrect account password'), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);
    });

    testWidgets('forgotten PIN with the account password asks for a new PIN', (
      tester,
    ) async {
      final usecases = _FakeUsecases()
        ..settings = const ParentSettings(pinHash: 'secure-v2');

      await tester.pumpWidget(
        _TestApp(
          cubit: _buildCubit(
            usecases,
            verifier: _FakeVerifier(AccountPasswordCheck.verified),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '99');
      await tester.tap(find.text('Forgot the code?'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'secret',
      );
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(usecases.resetCount, 1);
      // The create-PIN gate asks for confirmation and starts empty.
      expect(find.byType(TextField), findsNWidgets(2));
      final pinField = tester.widget<TextField>(find.byType(TextField).first);
      expect(pinField.controller!.text, isEmpty);
    });

    testWidgets('changing the PIN from settings needs confirmation', (
      tester,
    ) async {
      final usecases = _FakeUsecases()
        ..settings = const ParentSettings(pinHash: 'secure-v2')
        ..dashboard = _dashboard();

      await tester.pumpWidget(_TestApp(cubit: _buildCubit(usecases)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1234');
      await tester.tap(find.text('Enter'));
      await tester.pumpAndSettle();

      Future<void> tapChangePin() async {
        await tester.tap(find.byIcon(Icons.settings_rounded));
        await tester.pumpAndSettle();
        final button = find.widgetWithText(
          OutlinedButton,
          'Change guardian code',
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      await tapChangePin();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(usecases.resetCount, 0);

      await tapChangePin();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(usecases.resetCount, 1);
    });
  });

  group('child detail route', () {
    Future<void> openChild(WidgetTester tester, String name) async {
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1234');
      await tester.tap(find.text('Enter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }

    Future<void> submitDialogText(WidgetTester tester, String text) async {
      final field = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, text);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'adds a reward for a remote child through the dashboard cubit',
      (tester) async {
        final usecases = _FakeUsecases()
          ..settings = const ParentSettings(pinHash: 'secure-v2')
          ..dashboard = _dashboardWithChildren([
            const FamilyChildEntry(
              childUserId: 'child-2',
              displayName: 'Fatima',
              isLocal: false,
            ),
          ]);

        await tester.pumpWidget(_RouterTestApp(cubit: _buildCubit(usecases)));
        await openChild(tester, 'Fatima');
        expect(find.byType(ChildDetailPage), findsOneWidget);

        await tester.tap(find.byIcon(Icons.card_giftcard_rounded));
        await tester.pumpAndSettle();
        await submitDialogText(tester, 'Ice cream');

        expect(tester.takeException(), isNull);
        expect(usecases.remoteRewards, ['child-2:Ice cream']);
      },
    );

    testWidgets('renaming the local child updates the open detail page', (
      tester,
    ) async {
      final usecases = _FakeUsecases()
        ..settings = const ParentSettings(pinHash: 'secure-v2')
        ..dashboard = _dashboard();

      await tester.pumpWidget(_RouterTestApp(cubit: _buildCubit(usecases)));
      await openChild(tester, 'Talia');

      final editButton = find.byIcon(Icons.edit_rounded);
      await tester.scrollUntilVisible(
        editButton,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(editButton);
      await tester.pumpAndSettle();
      await submitDialogText(tester, 'Maryam');

      expect(tester.takeException(), isNull);
      expect(usecases.settings.localChildNickname, 'Maryam');
      expect(find.byType(ChildDetailPage), findsOneWidget);
      expect(find.textContaining('Maryam'), findsWidgets);
      expect(find.textContaining('Talia'), findsNothing);
    });

    testWidgets('shows a linked child age and edits name and age', (
      tester,
    ) async {
      final usecases = _FakeUsecases()
        ..settings = const ParentSettings(pinHash: 'secure-v2')
        ..dashboard = _dashboardWithChildren([
          const FamilyChildEntry(
            childUserId: 'child-2',
            displayName: 'Fatima',
            isLocal: false,
            childAge: 7,
          ),
        ]);

      await tester.pumpWidget(_RouterTestApp(cubit: _buildCubit(usecases)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1234');
      await tester.tap(find.text('Enter'));
      await tester.pumpAndSettle();
      // The grid card shows the age next to the name.
      expect(find.text('7 years old'), findsOneWidget);

      await tester.tap(find.text('Fatima'));
      await tester.pumpAndSettle();
      final editButton = find.text('Edit name and age');
      await tester.scrollUntilVisible(
        editButton,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      final nameField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      // Blank name is refused inside the dialog.
      await tester.enterText(nameField, '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a name of 1 to 50 characters.'), findsOneWidget);
      expect(usecases.identityUpdates, isEmpty);

      await tester.enterText(nameField, '  Fatima   Zahra ');
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('9 years old').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(usecases.identityUpdates, ['child-2:Fatima Zahra:9']);
      expect(find.textContaining('Fatima Zahra'), findsWidgets);
      expect(find.text('9 years old'), findsOneWidget);
      expect(
        find.text(
          "Saved. The child's device shows the change after its next sync.",
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'a push without the dashboard cubit falls back to the PIN gate',
      (tester) async {
        final usecases = _FakeUsecases()
          ..settings = const ParentSettings(pinHash: 'secure-v2');
        final cubit = _buildCubit(usecases);
        getIt.registerFactory<FamilyDashboardCubit>(() => cubit);

        await tester.pumpWidget(
          _localizedApp(
            home: ChildDetailPage.forRoute(
              const FamilyChildEntry(
                childUserId: 'child-2',
                displayName: 'Fatima',
                isLocal: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ChildDetailPage), findsNothing);
        expect(find.text('Enter'), findsOneWidget);
      },
    );
  });
}

FamilyDashboardCubit _buildCubit(
  _FakeUsecases usecases, {
  AccountPasswordVerifier? verifier,
}) => FamilyDashboardCubit(
  usecases.parentAccess,
  usecases.remoteLink,
  usecases.familyDashboard,
  accountVerifier: verifier,
);

class _FakeVerifier implements AccountPasswordVerifier {
  _FakeVerifier(this.result);

  final AccountPasswordCheck result;
  final checkedPasswords = <String>[];

  @override
  String? get currentEmail => 'parent@example.com';

  @override
  Future<AccountPasswordCheck> verify(String password) async {
    checkedPasswords.add(password);
    return result;
  }
}

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

FamilyDashboard _dashboardWithChildren(List<FamilyChildEntry> children) {
  return FamilyDashboard(
    settings: const ParentSettings(pinHash: 'secure-v2'),
    children: children,
  );
}

class _FakeUsecases {
  ParentSettings settings = const ParentSettings();
  FamilyDashboard dashboard = const FamilyDashboard(
    children: [],
    settings: ParentSettings(),
  );
  int resetCount = 0;
  final remoteRewards = <String>[];
  final identityUpdates = <String>[];
  Either<Failure, void> acceptResult = const Right(null);

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
    _owner.resetCount++;
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

  final _FakeUsecases _owner;

  @override
  Future<Either<Failure, void>> acceptChildLinkToken(String token) async =>
      _owner.acceptResult;

  @override
  Future<Either<Failure, void>> removeChild(String childUserId) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> updateChildIdentity({
    required String childUserId,
    required String nickname,
    required int age,
  }) async {
    _owner.identityUpdates.add('$childUserId:$nickname:$age');
    _owner.dashboard = FamilyDashboard(
      settings: _owner.dashboard.settings,
      children: [
        for (final child in _owner.dashboard.children)
          child.childUserId == childUserId
              ? FamilyChildEntry(
                  childUserId: childUserId,
                  displayName: nickname,
                  isLocal: false,
                  childAge: age,
                )
              : child,
      ],
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<ParentReward>>> saveRemoteReward({
    required String childUserId,
    required String title,
  }) async {
    _owner.remoteRewards.add('$childUserId:$title');
    return const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFamilyDashboard implements GetFamilyDashboardUsecase {
  _FakeFamilyDashboard(this._owner);

  final _FakeUsecases _owner;

  @override
  Future<Either<Failure, FamilyDashboard>> call() async {
    // Mirrors MemorizationFamilyService: the local child's name comes from
    // the saved parent settings.
    final nickname = _owner.settings.localChildNickname;
    final dashboard = _owner.dashboard;
    return Right(
      FamilyDashboard(
        settings: dashboard.settings,
        children: [
          for (final child in dashboard.children)
            child.isLocal && nickname != null
                ? FamilyChildEntry(
                    childUserId: child.childUserId,
                    displayName: nickname,
                    isLocal: true,
                    localData: child.localData,
                  )
                : child,
        ],
      ),
    );
  }

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
    return _localizedApp(home: const FamilyDashboardPage());
  }
}

Widget _localizedApp({Widget? home, GoRouter? router}) {
  const delegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  final theme = ThemeData(splashFactory: NoSplash.splashFactory);
  if (router != null) {
    return MaterialApp.router(
      locale: const Locale('en'),
      theme: theme,
      localizationsDelegates: delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
  return MaterialApp(
    locale: const Locale('en'),
    theme: theme,
    localizationsDelegates: delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

/// Pushes the child detail through a real go_router route built by the same
/// [ChildDetailPage.forRoute] the app router uses, so the page runs outside
/// the dashboard's widget subtree exactly as in production.
class _RouterTestApp extends StatefulWidget {
  const _RouterTestApp({required this.cubit});

  final FamilyDashboardCubit cubit;

  @override
  State<_RouterTestApp> createState() => _RouterTestAppState();
}

class _RouterTestAppState extends State<_RouterTestApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    getIt.registerFactory<FamilyDashboardCubit>(() => widget.cubit);
    _router = GoRouter(
      initialLocation: AppRoutes.familyDashboard,
      routes: [
        GoRoute(
          path: AppRoutes.familyDashboard,
          builder: (_, _) => const FamilyDashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.childDetail,
          builder: (_, state) => ChildDetailPage.forRoute(state.extra),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _localizedApp(router: _router);
}
