import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/kids_hifz_feature_flags.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/memorization_path_settings_sheet.dart';

class Repo extends Mock implements MemorizationPlusRepository {}

class Resolver extends Mock implements MemorizationPathResolver {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(KidsJourneyPathId.juzAmmaAdventure));
  late Repo repo;
  late SharedPreferences prefs;
  final child = MemorizationProfile.empty().copyWith(
    selectedPath: MemorizationPath.child,
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      KidsHifzFeatureFlags.quranJourneyKey: true,
    });
    prefs = await SharedPreferences.getInstance();
    repo = Repo();
    const owner = FixedRecordOwnerProvider('child');
    AccountDataBarrier.forPreferences(prefs).owner = owner;
    getIt.registerSingleton<SharedPreferences>(prefs);
    getIt.registerSingleton<RecordOwnerProvider>(owner);
    getIt.registerSingleton<MemorizationPlusRepository>(repo);
    getIt.registerSingleton<ParentAccessUsecase>(ParentAccessUsecase(repo));
    when(
      () => repo.getMemorizationProfile(),
    ).thenAnswer((_) async => Right(child));
    when(
      () => repo.getKidsJourneyPath(),
    ).thenAnswer((_) async => const Right(KidsJourneyPathDefinition.adventure));
  });
  tearDown(() async {
    await getIt.reset();
  });
  Widget app({Locale locale = const Locale('en'), double scale = 1}) =>
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showMemorizationPathSettingsSheet(context, isDark: false),
              child: const Text('open'),
            ),
          ),
        ),
      );
  testWidgets('child can see current choice and cancel without saving', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kids-change-journey')));
    await tester.pumpAndSettle();
    final group = tester.widget<RadioGroup<KidsJourneyPathId>>(
      find.byType(RadioGroup<KidsJourneyPathId>),
    );
    expect(group.groupValue, KidsJourneyPathId.juzAmmaAdventure);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.setKidsJourneyPath(any()));
  });
  testWidgets('flag off and adult hide the tile', (tester) async {
    await prefs.setBool(KidsHifzFeatureFlags.quranJourneyKey, false);
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kids-change-journey')), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await prefs.setBool(KidsHifzFeatureFlags.quranJourneyKey, true);
    when(() => repo.getMemorizationProfile()).thenAnswer(
      (_) async => Right(child.copyWith(selectedPath: MemorizationPath.adult)),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kids-change-journey')), findsNothing);
  });
  testWidgets('Arabic large text fits a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(locale: const Locale('ar'), scale: 2));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('kids-change-journey')),
    );
    await tester.tap(find.byKey(const ValueKey('kids-change-journey')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('link change during PIN creation prevents setting a PIN', (
    tester,
  ) async {
    when(
      () => repo.getParentSettings(),
    ).thenAnswer((_) async => const Right(ParentSettings()));
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kids-change-journey')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('kids_journey_path_quran_from_nas')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.byKey(const ValueKey('guardian-pin-create')),
      '1234',
    );
    await tester.enterText(
      find.byKey(const ValueKey('guardian-pin-create-confirm')),
      '1234',
    );
    when(() => repo.getMemorizationProfile()).thenAnswer(
      (_) async => Right(
        child.copyWith(
          guardianLinkStatus: GuardianLinkStatus.linked,
          guardianId: 'guardian',
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('guardian-pin-create-save')));
    await tester.pumpAndSettle();
    verifyNever(() => repo.setParentPin(any()));
    verifyNever(() => repo.setKidsJourneyPath(any()));
  });
  testWidgets('linked child without PIN cannot create one', (tester) async {
    when(() => repo.getMemorizationProfile()).thenAnswer(
      (_) async =>
          Right(child.copyWith(guardianLinkStatus: GuardianLinkStatus.linked)),
    );
    when(
      () => repo.getParentSettings(),
    ).thenAnswer((_) async => const Right(ParentSettings()));
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kids-change-journey')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('kids_journey_path_quran_from_nas')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('guardian-pin-create')), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    verifyNever(() => repo.setParentPin(any()));
  });
  testWidgets(
    'wrong PIN does not change path; correct PIN refreshes destination',
    (tester) async {
      final resolver = Resolver();
      getIt.registerSingleton<MemorizationPathResolver>(resolver);
      when(() => repo.getParentSettings()).thenAnswer(
        (_) async => const Right(ParentSettings(pinHash: 'secure-v2')),
      );
      when(
        () => repo.verifyParentPin('0000'),
      ).thenAnswer((_) async => const Right(false));
      when(
        () => repo.verifyParentPin('1234'),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => repo.setKidsJourneyPath(any()),
      ).thenAnswer((_) async => const Right(ParentSettings()));
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showMemorizationPathSettingsSheet(
                    context,
                    isDark: false,
                    replacementLocation: '/done',
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/done',
            builder: (_, _) => const Scaffold(body: Text('done')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('kids-change-journey')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('kids_journey_path_quran_from_nas')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField), '0000');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      verifyNever(() => repo.setKidsJourneyPath(any()));
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();
      verify(
        () => repo.setKidsJourneyPath(KidsJourneyPathId.quranFromNas),
      ).called(1);
      verify(() => resolver.notifyChanged()).called(1);
      expect(find.text('done'), findsOneWidget);
    },
  );
}
