import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_preferences_store.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:talia_quran/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:talia_quran/features/azkar/presentation/cubits/azkar_cubit.dart';
import 'package:talia_quran/features/azkar/presentation/pages/azkar_category_page.dart';
import 'package:talia_quran/features/azkar/presentation/widgets/font_scale_selector_sheet.dart';

void main() {
  late SharedPreferences prefs;
  late AzkarPreferencesStore prefsStore;

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    prefsStore = AzkarPreferencesStore(prefs);
    getIt.registerSingleton<SharedPreferences>(prefs);
    getIt.registerSingleton<AzkarPreferencesStore>(prefsStore);
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

  const testZikr1 = Zikr(
    id: 'zikr-1',
    text: 'الذكر الأول المعتمد',
    transliteration: '',
    translation: '',
    totalCount: 2,
    category: AzkarCategory.morning,
    reference: 'رواه مسلم',
    citation: 'Muslim 1234',
    sourceType: 'hadith',
    tier: DuaTier.essential,
    reviewStatus: ContentReviewStatus.approved,
    datasetVersion: 'v1-reviewed-1',
  );

  const testZikr2 = Zikr(
    id: 'zikr-2',
    text: 'الذكر الثاني المعتمد',
    transliteration: '',
    translation: '',
    totalCount: 1,
    category: AzkarCategory.morning,
    reference: 'رواه البخاري',
    citation: 'Bukhari 5678',
    sourceType: 'hadith',
    tier: DuaTier.essential,
    reviewStatus: ContentReviewStatus.approved,
    datasetVersion: 'v1-reviewed-1',
  );

  void registerCubitWith(List<Zikr> items) {
    final repo = _FakeRepo(items);
    getIt.registerFactory<AzkarCubit>(
      () => AzkarCubit(GetAzkarUsecase(repo), prefs),
    );
  }

  testWidgets('tapping reading card increments counter', (tester) async {
    registerCubitWith([testZikr1, testZikr2]);

    await tester.pumpWidget(
      buildApp(const AzkarCategoryPage(category: 'morning')),
    );
    await tester.pumpAndSettle();

    // Verify initial count is 0 / 2
    expect(find.text('0'), findsOneWidget);
    expect(find.text('الذكر الأول المعتمد'), findsOneWidget);

    // Tap the reading card text directly
    await tester.tap(find.text('الذكر الأول المعتمد'));
    await tester.pump();

    // Count should be incremented to 1
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets(
    'when auto-advance is disabled, completing a zikr does not move to next page',
    (tester) async {
      await prefsStore.setAutoAdvance(false);
      registerCubitWith([testZikr1, testZikr2]);

      await tester.pumpWidget(
        buildApp(const AzkarCategoryPage(category: 'morning')),
      );
      await tester.pumpAndSettle();

      // Tap card twice to complete testZikr1 (totalCount is 2)
      await tester.tap(find.text('الذكر الأول المعتمد'));
      await tester.pump();
      await tester.tap(find.text('الذكر الأول المعتمد'));
      await tester.pump();

      // Wait past auto-advance delay
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Should still be on testZikr1
      expect(find.text('الذكر الأول المعتمد'), findsOneWidget);
    },
  );

  testWidgets(
    'when auto-advance is enabled, completing a zikr advances to next zikr',
    (tester) async {
      await prefsStore.setAutoAdvance(true);
      registerCubitWith([testZikr1, testZikr2]);

      await tester.pumpWidget(
        buildApp(const AzkarCategoryPage(category: 'morning')),
      );
      await tester.pumpAndSettle();

      expect(find.text('الذكر الأول المعتمد'), findsOneWidget);

      // Tap card twice to complete testZikr1
      await tester.tap(find.text('الذكر الأول المعتمد'));
      await tester.pump();
      await tester.tap(find.text('الذكر الأول المعتمد'));
      await tester.pump();

      // Settle the delay and page transition animation
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should have advanced to testZikr2
      expect(find.text('الذكر الثاني المعتمد'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping font button opens FontScaleSelectorSheet and selecting scale persists',
    (tester) async {
      registerCubitWith([testZikr1]);

      await tester.pumpWidget(
        buildApp(const AzkarCategoryPage(category: 'morning')),
      );
      await tester.pumpAndSettle();

      // Tap font size icon button
      await tester.tap(find.byIcon(Icons.format_size_rounded));
      await tester.pumpAndSettle();

      // Font scale bottom sheet is open
      expect(find.byType(FontScaleSelectorSheet), findsOneWidget);
      expect(find.text('حجم خط الأذكار'), findsOneWidget);
      expect(find.text('كبير'), findsOneWidget);

      // Tap "كبير" (1.25x)
      await tester.tap(find.text('كبير'));
      await tester.pumpAndSettle();

      expect(prefsStore.getFontScale(), 1.25);
    },
  );
}

class _FakeRepo implements AzkarRepository {
  const _FakeRepo(this.items);
  final List<Zikr> items;

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      Right(items);
}
