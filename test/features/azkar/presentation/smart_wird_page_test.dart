import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/azkar/data/datasources/smart_wird_progress_store.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_time_context.dart';
import 'package:talia_quran/features/azkar/domain/usecases/compose_smart_wird_usecase.dart';
import 'package:talia_quran/features/azkar/presentation/pages/smart_wird_page.dart';
import 'package:talia_quran/features/azkar/presentation/services/zikr_audio_service.dart';

class _StubRepo implements AzkarRepository {
  const _StubRepo(this.corpus);

  final Map<AzkarCategory, List<Zikr>> corpus;

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      Right(corpus[category] ?? const []);

  @override
  Future<Either<Failure, Map<AzkarCategory, List<Zikr>>>> getAllAzkar() async =>
      Right(corpus);
}

Zikr _zikr(String id, AzkarCategory category) => Zikr(
  id: id,
  text: 'نص تجريبي $id',
  transliteration: '',
  translation: '',
  totalCount: 2,
  category: category,
);

void main() {
  late SharedPreferences prefs;

  final corpus = {
    AzkarCategory.morning: [_zikr('m-1', AzkarCategory.morning)],
    AzkarCategory.general: [_zikr('g-1', AzkarCategory.general)],
  };

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
    getIt.registerSingleton<AzkarRepository>(_StubRepo(corpus));
    getIt.registerSingleton<ZikrAudioService>(ZikrAudioService());
    getIt.registerSingleton<SmartWirdProgressStore>(
      SmartWirdProgressStore(prefs),
    );
    getIt.registerSingleton<ComposeSmartWirdUsecase>(
      ComposeSmartWirdUsecase(getIt<AzkarRepository>()),
    );
    // XpService requires Isar and is intentionally not registered here:
    // the page treats XP as a bonus and fails closed without it.
  });

  tearDown(() => getIt.reset());

  Widget buildApp(Widget home) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }

  testWidgets('session composes from corpus and completes with reset option', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(SmartWirdPage(currentTime: DateTime(2026, 9, 25, 9))),
    );
    await tester.pumpAndSettle();

    final dialText = find.text('٠');
    expect(dialText, findsOneWidget);

    // The counter dial is tappable: 2 taps finish card 1, the view then
    // advances to card 2 for 2 more taps.
    await tester.tap(dialText);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('١'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.text('نص تجريبي g-1'), findsOneWidget);
    await tester.tap(find.text('٠'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('١'));
    await tester.pumpAndSettle();

    // Completion view shows the localized done title.
    expect(find.text('اكتمل الورد الذكي'), findsOneWidget);
  });

  testWidgets('progress persists for resume across widget rebuilds', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(SmartWirdPage(currentTime: DateTime(2026, 9, 25, 9))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('٠'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    final store = SmartWirdProgressStore(prefs);
    final saved = store.activeSession(DateTime(2026, 9, 25));
    expect(saved, isNotNull);
    expect(saved!.counts, isNotEmpty);
  });

  testWidgets('resume restores counts and jumps to first unfinished card', (
    tester,
  ) async {
    // Pre-seed a partial session under the same injected clock key the page
    // will read (2026-9-25).
    final store = SmartWirdProgressStore(prefs);
    await store.saveActiveSession(
      SmartWirdSession(
        dayPart: AzkarDayPart.afterFajr,
        counts: {'m-1': 2, 'g-1': 1},
        updatedAt: DateTime(2026, 9, 25, 9),
      ),
      DateTime(2026, 9, 25, 9),
    );

    await tester.pumpWidget(
      buildApp(SmartWirdPage(currentTime: DateTime(2026, 9, 25, 9))),
    );
    await tester.pumpAndSettle();

    // The session resumes on card 2 (g-1) with count 1: one more tap on the
    // visible counter completes the whole wird.
    await tester.tap(find.text('١').first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('اكتمل الورد الذكي'), findsOneWidget);
  });

  testWidgets(
    'resume survives crossing a day-part boundary inside the same period',
    (tester) async {
      // Saved at 09:00 (afterFajr). The page reopens at 10:30 (morning day
      // part) but it is still the morning period, so progress must restore.
      final store = SmartWirdProgressStore(prefs);
      await store.saveActiveSession(
        SmartWirdSession(
          dayPart: AzkarDayPart.afterFajr,
          period: AzkarPeriod.morning,
          counts: {'m-1': 2, 'g-1': 1},
          updatedAt: DateTime(2026, 9, 25, 9),
        ),
        DateTime(2026, 9, 25, 10, 30),
      );

      await tester.pumpWidget(
        buildApp(SmartWirdPage(currentTime: DateTime(2026, 9, 25, 10, 30))),
      );
      await tester.pumpAndSettle();

      // Restored on card 2 with count 1: one tap completes the wird.
      await tester.tap(find.text('١').first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('اكتمل الورد الذكي'), findsOneWidget);
    },
  );

  testWidgets(
    'evening progress saved after midnight does not resume the next evening',
    (tester) async {
      // 01:00 belongs to the previous evening. Opening the evening wird at
      // 17:00 the same calendar day must start fresh, not restore its counts.
      final store = SmartWirdProgressStore(prefs);
      await store.saveActiveSession(
        SmartWirdSession(
          dayPart: AzkarDayPart.night,
          period: AzkarPeriod.evening,
          counts: {'g-1': 1},
          updatedAt: DateTime(2026, 9, 25, 1),
        ),
        DateTime(2026, 9, 25, 17),
      );

      await tester.pumpWidget(
        buildApp(SmartWirdPage(currentTime: DateTime(2026, 9, 25, 17))),
      );
      await tester.pumpAndSettle();

      // Fresh start: one tap on the 0/2 card does not finish the wird.
      await tester.tap(find.text('٠'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('اكتمل الورد الذكي'), findsNothing);
    },
  );

  testWidgets('tapping a row in the index moves to that card', (tester) async {
    await tester.pumpWidget(
      buildApp(SmartWirdPage(currentTime: DateTime(2026, 9, 25, 9))),
    );
    await tester.pumpAndSettle();

    // Card 1 (m-1) is showing; card 2 (g-1) has not been built yet.
    expect(find.text('نص تجريبي g-1'), findsNothing);

    await tester.tap(find.byIcon(TaliaIcons.listBulleted));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('نص تجريبي g-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('نص تجريبي g-1'), findsOneWidget);
  });
}
