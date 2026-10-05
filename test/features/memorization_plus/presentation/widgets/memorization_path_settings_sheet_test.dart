import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/application/guardian_session_controller.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/parent_pin_recovery_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/guardian_unlink_usecase.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/parent_pin_recovery_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/memorization_path_settings_sheet.dart';

class _MockMemorizationPlusRepository extends Mock
    implements MemorizationPlusRepository {}

class _MockRecovery extends Mock implements ParentPinRecoveryUsecase {}

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
  of: find.byIcon(Icons.restart_alt_rounded),
  matching: find.byType(ListTile),
);
final _linkTile = find.widgetWithText(ListTile, 'Link guardian');

MemorizationProfile _child({bool linked = false}) =>
    MemorizationProfile.empty().copyWith(
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

  setUp(() {
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
  });

  tearDown(() {
    if (getIt.isRegistered<MemorizationPlusRepository>()) {
      getIt.unregister<MemorizationPlusRepository>();
    }
    if (getIt.isRegistered<MemorizationPathResolver>()) {
      getIt.unregister<MemorizationPathResolver>();
    }
  });

  testWidgets(
    'Guardian PIN dialog opens when guardian is linked, validates, and '
    'resets path without controller disposal exception',
    (tester) async {
      // Child path + guardian LINKED → PIN verification is required.
      when(() => mockRepository.getMemorizationProfile()).thenAnswer(
        (_) async => Right(
          MemorizationProfile.empty().copyWith(
            selectedPath: MemorizationPath.child,
            guardianLinkStatus: GuardianLinkStatus.linked,
          ),
        ),
      );
      when(
        () => mockRepository.verifyParentPin('1234'),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => mockRepository.resetMemorizationIdentity(),
      ).thenAnswer((_) async => Right(MemorizationProfile.empty()));
      when(() => mockPathResolver.notifyChanged()).thenReturn(null);

      await tester.pumpWidget(_buildApp(mockRepository, mockPathResolver));

      await _openSheetAndConfirmReset(tester);

      // Guardian PIN dialog must appear.
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();

      final pinBtn = find.widgetWithText(FilledButton, 'إعادة الضبط');
      final fallback = pinBtn.evaluate().isNotEmpty
          ? pinBtn
          : find.widgetWithText(FilledButton, 'Reset');
      await tester.tap(fallback);
      await tester.pumpAndSettle();

      verify(() => mockRepository.verifyParentPin('1234')).called(1);
      verify(() => mockRepository.resetMemorizationIdentity()).called(1);
    },
  );

  testWidgets(
    'First-time child profile without linked guardian resets path directly '
    'without showing the guardian PIN dialog',
    (tester) async {
      // Child path + guardian NOT linked → no PIN required.
      when(() => mockRepository.getMemorizationProfile()).thenAnswer(
        (_) async => Right(
          MemorizationProfile.empty().copyWith(
            selectedPath: MemorizationPath.child,
            // guardianLinkStatus defaults to GuardianLinkStatus.none
          ),
        ),
      );
      // A profile that never set a parent PIN.
      when(
        () => mockRepository.getParentSettings(),
      ).thenAnswer((_) async => const Right(ParentSettings()));
      when(
        () => mockRepository.resetMemorizationIdentity(),
      ).thenAnswer((_) async => Right(MemorizationProfile.empty()));
      when(() => mockPathResolver.notifyChanged()).thenReturn(null);

      await tester.pumpWidget(_buildApp(mockRepository, mockPathResolver));

      await _openSheetAndConfirmReset(tester);

      // PIN dialog must NOT appear — no TextField on screen.
      expect(find.byType(TextField), findsNothing);

      // Identity reset must still fire.
      verify(() => mockRepository.resetMemorizationIdentity()).called(1);
      // verifyParentPin must never be called.
      verifyNever(() => mockRepository.verifyParentPin(any()));
    },
  );

  testWidgets(
    'an unlinked child with a parent PIN on this device cannot leave the '
    'kids track without it',
    (tester) async {
      when(() => mockRepository.getMemorizationProfile()).thenAnswer(
        (_) async => Right(
          MemorizationProfile.empty().copyWith(
            selectedPath: MemorizationPath.child,
          ),
        ),
      );
      when(() => mockRepository.getParentSettings()).thenAnswer(
        (_) async => const Right(ParentSettings(pinHash: 'secure-v2')),
      );
      when(
        () => mockRepository.verifyParentPin(any()),
      ).thenAnswer((_) async => const Right(false));
      when(() => mockPathResolver.notifyChanged()).thenReturn(null);

      await tester.pumpWidget(_buildApp(mockRepository, mockPathResolver));
      await _openSheetAndConfirmReset(tester);

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), '0000');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.verifyParentPin('0000')).called(1);
      verifyNever(() => mockRepository.resetMemorizationIdentity());
    },
  );

  testWidgets('a linked child is warned that the link goes, and stays put '
      'when it cannot be revoked', (tester) async {
    when(
      () => mockRepository.getMemorizationProfile(),
    ).thenAnswer((_) async => Right(_child(linked: true)));
    when(
      () => mockRepository.verifyParentPin('1234'),
    ).thenAnswer((_) async => const Right(true));
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
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("Couldn't remove the guardian link"),
      findsOneWidget,
    );
    expect(find.text('Replaced'), findsNothing);
    verifyNever(() => mockPathResolver.notifyChanged());
  });

  group('forgotten PIN', () {
    late _MockRecovery recovery;

    setUp(() {
      recovery = _MockRecovery();
      getIt.registerSingleton<ParentPinRecoveryUsecase>(recovery);
      when(
        () => mockRepository.resetMemorizationIdentity(),
      ).thenAnswer((_) async => Right(MemorizationProfile.empty()));
      when(() => mockPathResolver.notifyChanged()).thenReturn(null);
    });

    tearDown(() => getIt.unregister<ParentPinRecoveryUsecase>());

    Future<void> openPinDialog(WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(mockRepository, mockPathResolver));
      await _openSheetAndConfirmReset(tester);
    }

    testWidgets('a linked child recovers through the guardian and the reset '
        'goes ahead', (tester) async {
      when(
        () => mockRepository.getMemorizationProfile(),
      ).thenAnswer((_) async => Right(_child(linked: true)));
      when(() => recovery.request()).thenAnswer(
        (_) async => Right(
          PinRecoveryChallenge(id: 'c-1', expiresAt: DateTime.utc(2030)),
        ),
      );
      when(
        () => recovery.complete(
          challengeId: 'c-1',
          code: 'ABCDEF123456',
          newPin: '2468',
        ),
      ).thenAnswer((_) async => const Right(true));
      await openPinDialog(tester);

      await tester.tap(find.byKey(const ValueKey('guardian-pin-forgot')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('pin-recovery-code')),
        'ABCDEF123456',
      );
      await tester.enterText(
        find.byKey(const ValueKey('pin-recovery-new-pin')),
        '2468',
      );
      await tester.tap(find.byKey(const ValueKey('pin-recovery-submit')));
      await tester.pumpAndSettle();

      verify(() => mockRepository.resetMemorizationIdentity()).called(1);
      verifyNever(() => mockRepository.verifyParentPin(any()));
    });

    testWidgets('an unlinked child has no recovery to offer', (tester) async {
      when(
        () => mockRepository.getMemorizationProfile(),
      ).thenAnswer((_) async => Right(_child()));
      when(() => mockRepository.getParentSettings()).thenAnswer(
        (_) async => const Right(ParentSettings(pinHash: 'secure-v2')),
      );
      await openPinDialog(tester);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const ValueKey('guardian-pin-forgot')), findsNothing);
    });
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

    testWidgets('asks for the parent PIN, then opens guardian linking', (
      tester,
    ) async {
      when(
        () => mockRepository.getMemorizationProfile(),
      ).thenAnswer((_) async => Right(_child()));
      when(() => mockRepository.getParentSettings()).thenAnswer(
        (_) async => const Right(ParentSettings(pinHash: 'secure-v2')),
      );
      when(
        () => mockRepository.verifyParentPin('1234'),
      ).thenAnswer((_) async => const Right(true));

      await openSheet(tester);
      await tester.tap(_linkTile);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.reopenGuardianLinking()).called(1);
      expect(find.text('Guardian linking page'), findsOneWidget);
    });

    testWidgets('a wrong PIN keeps linking closed', (tester) async {
      when(
        () => mockRepository.getMemorizationProfile(),
      ).thenAnswer((_) async => Right(_child()));
      when(() => mockRepository.getParentSettings()).thenAnswer(
        (_) async => const Right(ParentSettings(pinHash: 'secure-v2')),
      );
      when(
        () => mockRepository.verifyParentPin('0000'),
      ).thenAnswer((_) async => const Right(false));

      await openSheet(tester);
      await tester.tap(_linkTile);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0000');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepository.reopenGuardianLinking());
      expect(find.text('Guardian linking page'), findsNothing);
    });

    testWidgets('a profile that never had a PIN is not locked out', (
      tester,
    ) async {
      when(
        () => mockRepository.getMemorizationProfile(),
      ).thenAnswer((_) async => Right(_child()));
      when(
        () => mockRepository.getParentSettings(),
      ).thenAnswer((_) async => const Right(ParentSettings()));

      await openSheet(tester);
      await tester.tap(_linkTile);
      await tester.pumpAndSettle();

      verifyNever(() => mockRepository.verifyParentPin(any()));
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

    testWidgets('is hidden when no PIN was ever set', (tester) async {
      when(
        () => mockRepository.getParentSettings(),
      ).thenAnswer((_) async => const Right(ParentSettings()));
      await openSheetFor(tester, _child());

      expect(guardianTile, findsNothing);
    });
  });
}
