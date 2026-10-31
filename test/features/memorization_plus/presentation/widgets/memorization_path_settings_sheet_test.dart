import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/application/guardian_session_controller.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/guardian_unlink_usecase.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/memorization_path_settings_sheet.dart';

class _MockMemorizationPlusRepository extends Mock
    implements MemorizationPlusRepository {}

class _MockUnlink extends Mock implements UnlinkGuardianUsecase {}

class _MockMemorizationPathResolver extends Mock
    implements MemorizationPathResolver {}

Widget _buildApp(
  _MockMemorizationPlusRepository repo,
  _MockMemorizationPathResolver resolver,
) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (ctx) {
              return ElevatedButton(
                onPressed: () =>
                    showMemorizationPathSettingsSheet(ctx, isDark: false),
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: '/memorization-plus',
        builder: (context, state) => const Scaffold(body: Text('Replaced')),
      ),
      GoRoute(
        path: '/memorization-plus/guardian-linking',
        builder: (context, state) =>
            const Scaffold(body: Text('Guardian linking page')),
      ),
      GoRoute(
        path: AppRoutes.familyDashboard,
        builder: (context, state) =>
            const Scaffold(body: Text('Family dashboard page')),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
  );
}

final _resetTile = find.ancestor(
  of: find.byIcon(TaliaIcons.replay),
  matching: find.byType(ListTile),
);
final _linkTile = find.widgetWithText(ListTile, 'Link guardian');

MemorizationProfile _child({bool linked = false}) =>
    MemorizationProfile.empty().copyWith(
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      selectedPath: MemorizationPath.child,
      guardianLinkStatus: linked
          ? GuardianLinkStatus.linked
          : GuardianLinkStatus.none,
      guardianOnboardingStatus: linked
          ? GuardianOnboardingStatus.completed
          : GuardianOnboardingStatus.skipped,
    );

/// Opens the bottom sheet, taps the Reset tile, and confirms via the dialog.
Future<void> _openSheetAndConfirmReset(WidgetTester tester) async {
  await tester.tap(find.text('Open Sheet'));
  await tester.pumpAndSettle();

  expect(_resetTile, findsOneWidget);
  await tester.tap(_resetTile);
  await tester.pumpAndSettle();

  // Tap the warning FilledButton inside the confirmation AlertDialog.
  final arabicBtn = find.widgetWithText(FilledButton, 'إعادة الضبط');
  final btn = arabicBtn.evaluate().isNotEmpty
      ? arabicBtn
      : find.widgetWithText(FilledButton, 'Reset');
  await tester.tap(btn);
  await tester.pumpAndSettle();
}

void main() {
  late _MockMemorizationPlusRepository mockRepository;
  late _MockMemorizationPathResolver mockPathResolver;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const owner = FixedRecordOwnerProvider('child');
    AccountDataBarrier.forPreferences(prefs).owner = owner;
    getIt.registerSingleton<SharedPreferences>(prefs);
    getIt.registerSingleton<RecordOwnerProvider>(owner);
    mockRepository = _MockMemorizationPlusRepository();
    mockPathResolver = _MockMemorizationPathResolver();

    if (getIt.isRegistered<MemorizationPlusRepository>()) {
      getIt.unregister<MemorizationPlusRepository>();
    }
    if (getIt.isRegistered<MemorizationPathResolver>()) {
      getIt.unregister<MemorizationPathResolver>();
    }

    getIt.registerSingleton<MemorizationPlusRepository>(mockRepository);
    getIt.registerSingleton<MemorizationPathResolver>(mockPathResolver);
    // Guardian actions read the parent settings first; by default a PIN
    // exists. Tests about a device without a PIN override this.
    when(() => mockRepository.getParentSettings()).thenAnswer(
      (_) async => const Right(ParentSettings(pinHash: 'secure-v2')),
    );
  });

  tearDown(() {
    getIt.unregister<SharedPreferences>();
    getIt.unregister<RecordOwnerProvider>();
    if (getIt.isRegistered<MemorizationPlusRepository>()) {
      getIt.unregister<MemorizationPlusRepository>();
    }
    if (getIt.isRegistered<MemorizationPathResolver>()) {
      getIt.unregister<MemorizationPathResolver>();
    }
  });

  for (final scenario in [
    (name: 'unlinked child without a PIN', linked: false, pin: false),
    (name: 'unlinked child with a PIN', linked: false, pin: true),
    (name: 'linked child without a PIN', linked: true, pin: false),
    (name: 'linked child with a PIN', linked: true, pin: true),
  ]) {
    testWidgets('${scenario.name} can reset without a PIN', (tester) async {
      when(
        () => mockRepository.getMemorizationProfile(),
      ).thenAnswer((_) async => Right(_child(linked: scenario.linked)));
      when(() => mockRepository.getParentSettings()).thenAnswer(
        (_) async =>
            Right(ParentSettings(pinHash: scenario.pin ? 'secure-v2' : null)),
      );
      when(
        () => mockRepository.resetMemorizationIdentity(),
      ).thenAnswer((_) async => Right(MemorizationProfile.empty()));
      when(() => mockPathResolver.notifyChanged()).thenReturn(null);
      await tester.pumpWidget(_buildApp(mockRepository, mockPathResolver));
      await _openSheetAndConfirmReset(tester);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Replaced'), findsOneWidget);
      verify(() => mockRepository.resetMemorizationIdentity()).called(1);
      verifyNever(() => mockRepository.setParentPin(any()));
      verifyNever(() => mockRepository.verifyParentPin(any()));
    });
  }

  testWidgets('cancelling reset keeps the current path', (tester) async {
    when(
      () => mockRepository.getMemorizationProfile(),
    ).thenAnswer((_) async => Right(_child()));
    await tester.pumpWidget(_buildApp(mockRepository, mockPathResolver));
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
    await tester.tap(_resetTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Replaced'), findsNothing);
    verifyNever(() => mockRepository.resetMemorizationIdentity());
  });

  testWidgets('a failed guardian unlink keeps the current path', (
    tester,
  ) async {
    when(
      () => mockRepository.getMemorizationProfile(),
    ).thenAnswer((_) async => Right(_child(linked: true)));
    when(() => mockRepository.resetMemorizationIdentity()).thenAnswer(
      (_) async => const Left(
        NetworkFailure(CubitMessageCodes.guardianUnlinkBeforePathChangeFailed),
      ),
    );
    await tester.pumpWidget(_buildApp(mockRepository, mockPathResolver));
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
    await tester.tap(_resetTile);
    await tester.pumpAndSettle();
    expect(find.textContaining('removes the link'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining("Couldn't remove the guardian link"),
      findsOneWidget,
    );
    expect(find.text('Replaced'), findsNothing);
    verifyNever(() => mockPathResolver.notifyChanged());
  });

  group('unlink guardian tile', () {
    late _MockUnlink unlink;
    final unlinkTile = find.byKey(const ValueKey('kids-unlink-guardian'));

    setUp(() {
      unlink = _MockUnlink();
      getIt.registerSingleton<UnlinkGuardianUsecase>(unlink);
      when(() => mockPathResolver.notifyChanged()).thenReturn(null);
    });

    tearDown(() => getIt.unregister<UnlinkGuardianUsecase>());

    Future<void> confirmAndEnterPin(WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(mockRepository, mockPathResolver));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();
      await tester.tap(unlinkTile);
      await tester.pumpAndSettle();
      expect(find.textContaining('Gifts you received stay'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('kids-unlink-guardian-confirm')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.widgetWithText(FilledButton, 'Remove link'));
      await tester.pumpAndSettle();
    }

    setUp(() {
      when(
        () => mockRepository.getMemorizationProfile(),
      ).thenAnswer((_) async => Right(_child(linked: true)));
      when(
        () => mockRepository.verifyParentPin('1234'),
      ).thenAnswer((_) async => const Right(true));
    });

    for (final mode in ['missing', 'configured', 'unreadable']) {
      testWidgets('linked child may skip PIN while unlinking: $mode', (
        tester,
      ) async {
        when(() => mockRepository.getParentSettings()).thenAnswer(
          (_) async => mode == 'unreadable'
              ? const Left(CacheFailure('unavailable'))
              : Right(
                  ParentSettings(
                    pinHash: mode == 'configured' ? 'secure-v2' : null,
                  ),
                ),
        );
        when(
          () => unlink(),
        ).thenAnswer((_) async => Right(MemorizationProfile.empty()));
        await tester.pumpWidget(_buildApp(mockRepository, mockPathResolver));
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();
        await tester.tap(unlinkTile);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('kids-unlink-guardian-confirm')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('guardian-pin-skip')));
        await tester.pumpAndSettle();
        verify(() => unlink()).called(1);
        verifyNever(() => mockRepository.setParentPin(any()));
        verifyNever(() => mockRepository.verifyParentPin(any()));
      });
    }

    testWidgets('only a linked child sees it', (tester) async {
      when(
        () => mockRepository.getMemorizationProfile(),
      ).thenAnswer((_) async => Right(_child()));
      when(
        () => mockRepository.getParentSettings(),
      ).thenAnswer((_) async => const Right(ParentSettings()));
      await tester.pumpWidget(_buildApp(mockRepository, mockPathResolver));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(unlinkTile, findsNothing);
    });

    testWidgets('unlinks after the confirmation and the PIN', (tester) async {
      when(
        () => unlink(),
      ).thenAnswer((_) async => Right(MemorizationProfile.empty()));

      await confirmAndEnterPin(tester);

      verify(() => mockRepository.verifyParentPin('1234')).called(1);
      verify(() => unlink()).called(1);
      verify(() => mockPathResolver.notifyChanged()).called(1);
      expect(find.text('Guardian link removed'), findsOneWidget);
    });

    testWidgets('a failure says nothing changed', (tester) async {
      when(() => unlink()).thenAnswer(
        (_) async =>
            const Left(NetworkFailure(CubitMessageCodes.guardianUnlinkFailed)),
      );

      await confirmAndEnterPin(tester);

      expect(find.textContaining('nothing changed'), findsOneWidget);
      verifyNever(() => mockPathResolver.notifyChanged());
    });

    testWidgets('a wrong PIN never reaches the server', (tester) async {
      when(
        () => mockRepository.verifyParentPin('1234'),
      ).thenAnswer((_) async => const Right(false));

      await confirmAndEnterPin(tester);

      verifyNever(() => unlink());
    });
  });

  group('link guardian tile', () {
    setUp(() {
      when(() => mockPathResolver.notifyChanged()).thenReturn(null);
      when(
        () => mockRepository.reopenGuardianLinking(),
      ).thenAnswer((_) async => Right(_child()));
    });

    Future<void> openSheet(WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(mockRepository, mockPathResolver));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();
    }

    testWidgets('is hidden for an adult and for a linked child', (
      tester,
    ) async {
      for (final profile in [
        MemorizationProfile.empty().copyWith(
          selectedPath: MemorizationPath.adult,
        ),
        _child(linked: true),
      ]) {
        when(
          () => mockRepository.getMemorizationProfile(),
        ).thenAnswer((_) async => Right(profile));
        await openSheet(tester);
        expect(_linkTile, findsNothing);
        expect(_resetTile, findsOneWidget);
        Navigator.of(tester.element(_resetTile)).pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('opens linking without a PIN prompt', (tester) async {
      when(
        () => mockRepository.getMemorizationProfile(),
      ).thenAnswer((_) async => Right(_child()));
      await openSheet(tester);
      await tester.tap(_linkTile);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      verify(() => mockRepository.reopenGuardianLinking()).called(1);
      expect(find.text('Guardian linking page'), findsOneWidget);
    });
  });

  group('guardian area tile', () {
    final guardianTile = find.byKey(const ValueKey('kids-open-guardian-area'));
    late GuardianSessionController session;

    setUp(() {
      session = GuardianSessionController();
      getIt.registerSingleton<GuardianSessionController>(session);
      when(() => mockRepository.getParentSettings()).thenAnswer(
        (_) async => const Right(ParentSettings(pinHash: 'secure-v2')),
      );
    });

    tearDown(() async {
      session.end();
      await getIt.unregister<GuardianSessionController>();
      session.dispose();
    });

    Future<void> openSheetFor(
      WidgetTester tester,
      MemorizationProfile profile,
    ) async {
      when(
        () => mockRepository.getMemorizationProfile(),
      ).thenAnswer((_) async => Right(profile));
      await tester.pumpWidget(_buildApp(mockRepository, mockPathResolver));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();
    }

    for (final hasPin in [false, true]) {
      testWidgets('guardian area skip works when PIN configured: $hasPin', (
        tester,
      ) async {
        when(() => mockRepository.getParentSettings()).thenAnswer(
          (_) async =>
              Right(ParentSettings(pinHash: hasPin ? 'configured' : null)),
        );
        await openSheetFor(tester, _child());
        await tester.tap(guardianTile);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('guardian-pin-skip')));
        await tester.pumpAndSettle();
        expect(session.isActive, isTrue);
        verifyNever(() => mockRepository.setParentPin(any()));
        verifyNever(() => mockRepository.verifyParentPin(any()));
        session.end();
      });
    }

    testWidgets('the right PIN opens a guardian session on the dashboard', (
      tester,
    ) async {
      when(
        () => mockRepository.verifyParentPin('1234'),
      ).thenAnswer((_) async => const Right(true));
      await openSheetFor(tester, _child());

      await tester.tap(guardianTile);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();

      expect(session.isActive, isTrue);
      expect(session.returnLocation, '/');
      expect(find.text('Family dashboard page'), findsOneWidget);
      session.end();
    });

    testWidgets('a wrong PIN starts nothing', (tester) async {
      when(
        () => mockRepository.verifyParentPin('0000'),
      ).thenAnswer((_) async => const Right(false));
      await openSheetFor(tester, _child());

      await tester.tap(guardianTile);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0000');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(session.isActive, isFalse);
      expect(find.text('Family dashboard page'), findsNothing);
    });

    testWidgets('is hidden for a linked child', (tester) async {
      await openSheetFor(tester, _child(linked: true));

      expect(guardianTile, findsNothing);
    });

    testWidgets('without a PIN the guardian creates one, then enters', (
      tester,
    ) async {
      when(
        () => mockRepository.getParentSettings(),
      ).thenAnswer((_) async => const Right(ParentSettings()));
      when(
        () => mockRepository.setParentPin('2468'),
      ).thenAnswer((_) async => const Right(null));
      await openSheetFor(tester, _child());

      await tester.tap(guardianTile);
      await tester.pumpAndSettle();
      expect(session.isActive, isFalse);
      await _createGuardianPin(tester, '2468');

      expect(session.isActive, isTrue);
      expect(find.text('Family dashboard page'), findsOneWidget);
      session.end();
    });

    testWidgets('a PIN created meanwhile is never replaced', (tester) async {
      // No PIN when the sheet and the dialog open; one exists by the time
      // the stale dialog saves (another dialog from a double tap set it).
      var reads = 0;
      when(() => mockRepository.getParentSettings()).thenAnswer((_) async {
        reads += 1;
        return reads <= 1
            ? const Right(ParentSettings())
            : const Right(ParentSettings(pinHash: 'secure-v2'));
      });
      await openSheetFor(tester, _child());

      await tester.tap(guardianTile);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('guardian-pin-create')),
        '9999',
      );
      await tester.enterText(
        find.byKey(const ValueKey('guardian-pin-create-confirm')),
        '9999',
      );
      await tester.tap(find.byKey(const ValueKey('guardian-pin-create-save')));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepository.setParentPin(any()));
      expect(session.isActive, isFalse);
      expect(find.text('Family dashboard page'), findsNothing);
    });

    testWidgets('mismatched PINs save nothing and open nothing', (
      tester,
    ) async {
      when(
        () => mockRepository.getParentSettings(),
      ).thenAnswer((_) async => const Right(ParentSettings()));
      await openSheetFor(tester, _child());

      await tester.tap(guardianTile);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('guardian-pin-create')),
        '1111',
      );
      await tester.enterText(
        find.byKey(const ValueKey('guardian-pin-create-confirm')),
        '2222',
      );
      await tester.tap(find.byKey(const ValueKey('guardian-pin-create-save')));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepository.setParentPin(any()));
      expect(session.isActive, isFalse);
    });
  });
}

/// Fills and saves the create-guardian-PIN dialog.
Future<void> _createGuardianPin(WidgetTester tester, String pin) async {
  expect(find.byKey(const ValueKey('guardian-pin-create')), findsOneWidget);
  await tester.enterText(
    find.byKey(const ValueKey('guardian-pin-create')),
    pin,
  );
  await tester.enterText(
    find.byKey(const ValueKey('guardian-pin-create-confirm')),
    pin,
  );
  await tester.tap(find.byKey(const ValueKey('guardian-pin-create-save')));
  await tester.pumpAndSettle();
}
