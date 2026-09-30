import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/memorization_path_settings_sheet.dart';

class _MockMemorizationPlusRepository extends Mock
    implements MemorizationPlusRepository {}

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
}
