import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:talia_quran/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:talia_quran/features/azkar/presentation/cubits/azkar_cubit.dart';
import 'package:talia_quran/features/azkar/presentation/pages/azkar_category_page.dart';
import 'package:talia_quran/features/azkar/presentation/pages/azkar_page.dart';
import 'package:talia_quran/features/azkar/presentation/pages/general_azkar_page.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => getIt.reset());

  testWidgets('keeps the Azkar feature visible with a safe review state', (
    tester,
  ) async {
    _registerRepository(const _FakeAzkarRepository());

    await tester.pumpWidget(_localizedApp(const AzkarPage()));
    await tester.pumpAndSettle();

    expect(find.text('الأذكار'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('azkar-content-under-review')),
      findsOneWidget,
    );
    expect(find.text('أذكار الصباح'), findsNothing);
    expect(find.text('أذكار المساء'), findsNothing);
  });

  testWidgets('shows only categories that contain approved records', (
    tester,
  ) async {
    _registerRepository(
      const _FakeAzkarRepository({
        AzkarCategory.morning: [_approvedMorningZikr],
      }),
    );

    await tester.pumpWidget(_localizedApp(const AzkarPage()));
    await tester.pumpAndSettle();

    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('أذكار المساء'), findsNothing);
    expect(find.text('أذكار عامة'), findsNothing);
    expect(find.text('الأدعية'), findsNothing);
  });

  testWidgets('never presents a grade for a record that is not approved', (
    tester,
  ) async {
    const repository = _FakeAzkarRepository({
      AzkarCategory.morning: [_pendingGradedMorningZikr],
    });
    _registerRepository(repository);
    final preferences = await SharedPreferences.getInstance();
    getIt.registerFactory<AzkarCubit>(
      () => AzkarCubit(GetAzkarUsecase(repository), preferences),
    );

    await tester.pumpWidget(
      _localizedApp(const AzkarCategoryPage(category: 'morning')),
    );
    await tester.pumpAndSettle();

    expect(find.text('صحيح'), findsNothing);
  });

  testWidgets('copying approved Azkar preserves its exact release text', (
    tester,
  ) async {
    const sacredText = '  نَصٌّ مُعْتَمَدٌ\n';
    const citation = '  القرآن 2:201  ';
    const zikr = Zikr(
      id: 'approved-copy-001',
      text: sacredText,
      transliteration: '',
      translation: '',
      totalCount: 1,
      category: AzkarCategory.morning,
      reference: citation,
      citation: citation,
      sourceType: 'quran',
      tier: DuaTier.essential,
      reviewStatus: ContentReviewStatus.approved,
      datasetVersion: 'v1-reviewed-1',
    );
    final copiedTexts = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedTexts.add(
              (call.arguments as Map<Object?, Object?>)['text']! as String,
            );
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    const repository = _FakeAzkarRepository({
      AzkarCategory.morning: [zikr],
    });
    _registerRepository(repository);
    final preferences = await SharedPreferences.getInstance();
    getIt.registerFactory<AzkarCubit>(
      () => AzkarCubit(GetAzkarUsecase(repository), preferences),
    );

    await tester.pumpWidget(
      _localizedApp(const AzkarCategoryPage(category: 'morning')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.copy_rounded));
    await tester.pump();

    expect(copiedTexts, [
      '$sacredText\n\n$citation\n\nتمت المشاركة من تطبيق تالية للقرآن',
    ]);
  });

  for (final pageCase in <({String name, Widget page})>[
    (
      name: 'counter category',
      page: const AzkarCategoryPage(category: 'morning'),
    ),
    (name: 'general category', page: const GeneralAzkarPage()),
  ]) {
    testWidgets('direct ${pageCase.name} route shows the safe review state', (
      tester,
    ) async {
      const repository = _FakeAzkarRepository();
      _registerRepository(repository);
      final preferences = await SharedPreferences.getInstance();
      getIt.registerFactory<AzkarCubit>(
        () => AzkarCubit(GetAzkarUsecase(repository), preferences),
      );

      await tester.pumpWidget(_localizedApp(pageCase.page));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('azkar-content-under-review')),
        findsOneWidget,
      );
      expect(find.text('تم بحمد الله'), findsNothing);
    });
  }
}

void _registerRepository(AzkarRepository repository) {
  getIt.registerSingleton<AzkarRepository>(repository);
}

Widget _localizedApp(Widget home) => MaterialApp(
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

class _FakeAzkarRepository implements AzkarRepository {
  const _FakeAzkarRepository([this.records = const {}]);

  final Map<AzkarCategory, List<Zikr>> records;

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      Right(records[category] ?? const []);
}

const _approvedMorningZikr = Zikr(
  id: 'morning-001',
  text: 'نص معتمد للاختبار',
  transliteration: '',
  translation: '',
  totalCount: 1,
  category: AzkarCategory.morning,
  citation: 'Quran 2:201',
  sourceType: 'quran',
  tier: DuaTier.essential,
  reviewStatus: ContentReviewStatus.approved,
  datasetVersion: 'v1-reviewed-1',
);

const _pendingGradedMorningZikr = Zikr(
  id: 'morning-pending',
  text: 'نص غير معتمد للاختبار',
  transliteration: '',
  translation: '',
  totalCount: 1,
  category: AzkarCategory.morning,
  citation: 'مرجع اختباري',
  sourceType: 'hadith',
  authenticityGrade: AuthenticityGrade.sahih,
  tier: DuaTier.essential,
  reviewStatus: ContentReviewStatus.pendingReview,
  datasetVersion: 'v1-candidate',
);
