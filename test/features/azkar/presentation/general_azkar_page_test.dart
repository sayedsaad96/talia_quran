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
import 'package:talia_quran/features/azkar/presentation/pages/general_azkar_page.dart';

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

  const testDua1 = Zikr(
    id: 'dua-1',
    text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى',
    transliteration: '',
    translation: '',
    totalCount: 1,
    category: AzkarCategory.duas,
    subcategory: 'أدعية نبوية',
    reference: 'رواه مسلم',
    citation: 'Muslim 2725',
    sourceType: 'hadith',
    tier: DuaTier.essential,
    reviewStatus: ContentReviewStatus.approved,
    datasetVersion: 'v1-reviewed-1',
  );

  const testDua2 = Zikr(
    id: 'dua-2',
    text: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً',
    transliteration: '',
    translation: '',
    totalCount: 1,
    category: AzkarCategory.duas,
    subcategory: 'أدعية قرآنية',
    reference: 'سورة البقرة: 201',
    citation: 'Quran 2:201',
    sourceType: 'quran',
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

  testWidgets(
    'search matches query normalized for Arabic diacritics and letter variants',
    (tester) async {
      registerCubitWith([testDua1, testDua2]);

      await tester.pumpWidget(
        buildApp(const GeneralAzkarPage(category: AzkarCategory.duas)),
      );
      await tester.pumpAndSettle();

      expect(find.text('اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى'), findsOneWidget);
      expect(find.text('رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً'), findsOneWidget);

      // Search without diacritics / plain alef: "اللهم" should match testDua1
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'اللهم اني اسالك');
      await tester.pumpAndSettle();

      expect(find.text('اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى'), findsOneWidget);
      expect(find.text('رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً'), findsNothing);
    },
  );

  testWidgets('tapping bookmark adds and removes ID from favorites store', (tester) async {
    registerCubitWith([testDua1]);

    await tester.pumpWidget(
      buildApp(const GeneralAzkarPage(category: AzkarCategory.duas)),
    );
    await tester.pumpAndSettle();

    expect(prefsStore.isFavorite('dua-1'), isFalse);

    // Tap bookmark icon button on dua card
    final bookmarkButton = find.byKey(const ValueKey('bookmark-dua-1'));
    expect(bookmarkButton, findsOneWidget);
    await tester.tap(bookmarkButton);
    await tester.pumpAndSettle();

    expect(prefsStore.isFavorite('dua-1'), isTrue);

    // Tap again to remove
    await tester.tap(bookmarkButton);
    await tester.pumpAndSettle();

    expect(prefsStore.isFavorite('dua-1'), isFalse);
  });

  testWidgets('selecting favorites tab displays only favorited Duas', (tester) async {
    await prefsStore.toggleFavorite('dua-2');
    registerCubitWith([testDua1, testDua2]);

    await tester.pumpWidget(
      buildApp(const GeneralAzkarPage(category: AzkarCategory.duas)),
    );
    await tester.pumpAndSettle();

    // Both visible initially
    expect(find.text('اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى'), findsOneWidget);
    expect(find.text('رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً'), findsOneWidget);

    // Select favorites tab
    final favoritesChip = find.text('المفضلة');
    expect(favoritesChip, findsOneWidget);
    await tester.tap(favoritesChip);
    await tester.pumpAndSettle();

    // Only testDua2 should be visible
    expect(find.text('اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى'), findsNothing);
    expect(find.text('رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً'), findsOneWidget);
  });

  testWidgets('empty search results shows empty state with clear button', (tester) async {
    registerCubitWith([testDua1]);

    await tester.pumpWidget(
      buildApp(const GeneralAzkarPage(category: AzkarCategory.duas)),
    );
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'نص غير موجود اطلاقا');
    await tester.pumpAndSettle();

    expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);

    // Tap clear button in empty state or search bar
    final clearButton = find.byKey(const ValueKey('clear-search-button'));
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(find.text('اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى'), findsOneWidget);
  });
}

class _FakeRepo implements AzkarRepository {
  const _FakeRepo(this.items);
  final List<Zikr> items;

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      Right(items);
}
