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
          body: Builder(builder: (ctx) {
            return ElevatedButton(
              onPressed: () =>
                  showMemorizationPathSettingsSheet(ctx, isDark: false),
              child: const Text('Open Sheet'),
            );
          }),
        ),
      ),
      GoRoute(
        path: '/memorization-plus',
        builder: (context, state) =>
            const Scaffold(body: Text('Replaced')),
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
  );
}

/// Opens the bottom sheet, taps the Reset tile, and confirms via the dialog.
Future<void> _openSheetAndConfirmReset(WidgetTester tester) async {
  await tester.tap(find.text('Open Sheet'));
  await tester.pumpAndSettle();

  expect(find.byType(ListTile), findsOneWidget);
  await tester.tap(find.byType(ListTile));
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
      when(() => mockRepository.verifyParentPin('1234'))
          .thenAnswer((_) async => const Right(true));
      when(() => mockRepository.resetMemorizationIdentity())
          .thenAnswer((_) async => Right(MemorizationProfile.empty()));
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
      when(() => mockRepository.resetMemorizationIdentity())
          .thenAnswer((_) async => Right(MemorizationProfile.empty()));
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
}
