import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_completion_store.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_preferences_store.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_time_context.dart';
import 'package:talia_quran/features/azkar/presentation/pages/azkar_page.dart';
import 'package:talia_quran/features/azkar/presentation/widgets/free_tasbeeh_sheet.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
    getIt.registerSingleton<AzkarCompletionStore>(AzkarCompletionStore(prefs));
    getIt.registerSingleton<AzkarPreferencesStore>(AzkarPreferencesStore(prefs));
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

  const morningZikr = Zikr(
    id: 'm-1',
    text: 'ذكر صباح',
    transliteration: '',
    translation: '',
    totalCount: 1,
    category: AzkarCategory.morning,
    reviewStatus: ContentReviewStatus.approved,
    datasetVersion: 'v1',
  );

  const eveningZikr = Zikr(
    id: 'e-1',
    text: 'ذكر مساء',
    transliteration: '',
    translation: '',
    totalCount: 1,
    category: AzkarCategory.evening,
    reviewStatus: ContentReviewStatus.approved,
    datasetVersion: 'v1',
  );

  testWidgets('shows safe under review state when no approved records exist', (tester) async {
    final repo = _FakeRepo(const {});
    getIt.registerSingleton<AzkarRepository>(repo);

    await tester.pumpWidget(buildApp(const AzkarPage()));
    await tester.pumpAndSettle();

    expect(find.text('الأذكار'), findsOneWidget);
    expect(find.byKey(const ValueKey('azkar-content-under-review')), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsNothing);
    expect(find.text('أذكار المساء'), findsNothing);
  });

  testWidgets('morning time context displays morning Hero card', (tester) async {
    final repo = _FakeRepo({
      AzkarCategory.morning: [morningZikr],
      AzkarCategory.evening: [eveningZikr],
    });
    getIt.registerSingleton<AzkarRepository>(repo);

    // Explicit morning time (09:00)
    await tester.pumpWidget(
      buildApp(AzkarPage(currentTime: DateTime(2026, 9, 10, 9, 0))),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('azkar-hero-card')), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('مسبحة حرة'), findsOneWidget);
  });

  testWidgets('evening time context displays evening Hero card', (tester) async {
    final repo = _FakeRepo({
      AzkarCategory.morning: [morningZikr],
      AzkarCategory.evening: [eveningZikr],
    });
    getIt.registerSingleton<AzkarRepository>(repo);

    // Explicit evening time (18:00)
    await tester.pumpWidget(
      buildApp(AzkarPage(currentTime: DateTime(2026, 9, 10, 18, 0))),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('azkar-hero-card')), findsOneWidget);
    expect(find.text('أذكار المساء'), findsOneWidget);
    expect(find.text('مسبحة حرة'), findsOneWidget);
  });

  testWidgets('tapping free tasbeeh card opens FreeTasbeehSheet', (tester) async {
    final repo = _FakeRepo({
      AzkarCategory.morning: [morningZikr],
    });
    getIt.registerSingleton<AzkarRepository>(repo);

    await tester.pumpWidget(buildApp(const AzkarPage()));
    await tester.pumpAndSettle();

    final tasbeehCard = find.byKey(const ValueKey('azkar-card-tasbeeh'));
    expect(tasbeehCard, findsOneWidget);

    await tester.tap(tasbeehCard);
    await tester.pumpAndSettle();

    expect(find.byType(FreeTasbeehSheet), findsOneWidget);
    expect(find.text('مسبحة حرة'), findsWidgets);
  });
}

class _FakeRepo implements AzkarRepository {
  const _FakeRepo(this.records);
  final Map<AzkarCategory, List<Zikr>> records;

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      Right(records[category] ?? const []);
}
