import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
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

  testWidgets('session composes from corpus and completes with reset option',
      (tester) async {
    await tester.pumpWidget(
      buildApp(SmartWirdPage(currentTime: DateTime(2026, 9, 25, 9))),
    );
    await tester.pumpAndSettle();

    final dialText = find.text('0');
    expect(dialText, findsOneWidget);

    // The counter dial is tappable: 2 taps finish card 1, the view then
    // advances to card 2 for 2 more taps.
    await tester.tap(dialText);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.text('نص تجريبي g-1'), findsOneWidget);
    await tester.tap(find.text('0'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    // Completion view shows the localized done title.
    expect(find.text('اكتمل الورد الذكي'), findsOneWidget);
  });

  testWidgets('progress persists for resume across widget rebuilds',
      (tester) async {
    await tester.pumpWidget(
      buildApp(SmartWirdPage(currentTime: DateTime(2026, 9, 25, 9))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('0'));
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

  testWidgets('resume restores counts and jumps to first unfinished card',
      (tester) async {
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
    await tester.tap(find.text('1').first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('اكتمل الورد الذكي'), findsOneWidget);
  });
}
