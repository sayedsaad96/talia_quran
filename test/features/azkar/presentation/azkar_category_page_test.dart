import 'package:dartz/dartz.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_preferences_store.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:talia_quran/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:talia_quran/features/azkar/presentation/cubits/azkar_cubit.dart';
import 'package:talia_quran/features/azkar/presentation/pages/azkar_category_page.dart';
import 'package:talia_quran/features/azkar/presentation/services/zikr_audio_service.dart';
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
    getIt.registerSingleton<ZikrAudioService>(ZikrAudioService());
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
    expect(find.text('٠'), findsOneWidget);
    expect(find.text('الذكر الأول المعتمد'), findsOneWidget);

    // Tap the reading card text directly
    await tester.tap(find.text('الذكر الأول المعتمد'));
    await tester.pump();

    // Count should be incremented to 1
    expect(find.text('١'), findsOneWidget);
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
      await tester.tap(find.byIcon(TaliaIcons.textSize));
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

  testWidgets('narrow screens move auto-advance and index into a menu', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    registerCubitWith([testZikr1, testZikr2]);

    await tester.pumpWidget(
      buildApp(const AzkarCategoryPage(category: 'morning')),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(TaliaIcons.listBulleted), findsNothing);
    expect(find.byIcon(TaliaIcons.refresh), findsNothing);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('فهرس الأذكار'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow menu toggles auto-advance', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    await prefsStore.setAutoAdvance(true);
    registerCubitWith([testZikr1]);

    await tester.pumpWidget(
      buildApp(const AzkarCategoryPage(category: 'morning')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الانتقال التلقائي مفعّل'));
    await tester.pumpAndSettle();

    expect(prefsStore.getAutoAdvance(), isFalse);
  });

  testWidgets('wide screens keep the separate buttons', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 800);
    addTearDown(tester.view.reset);
    registerCubitWith([testZikr1]);

    await tester.pumpWidget(
      buildApp(const AzkarCategoryPage(category: 'morning')),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(TaliaIcons.listBulleted), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });

  testWidgets('the completion screen can take back the last tap', (
    tester,
  ) async {
    registerCubitWith([testZikr2]); // totalCount 1
    await tester.pumpWidget(
      buildApp(const AzkarCategoryPage(category: 'morning')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('الذكر الثاني المعتمد'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('azkar-completion-morning')),
      findsOneWidget,
    );
    final undo = find.byKey(const ValueKey('azkar-completion-undo'));
    expect(undo, findsOneWidget);

    await tester.tap(undo);
    await tester.pumpAndSettle();

    expect(find.text('الذكر الثاني المعتمد'), findsOneWidget);
    expect(find.text('٠'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('azkar-completion-morning')),
      findsNothing,
    );
  });

  group('haptic feedback never blocks the action', () {
    // A platform haptic that never replies (slow device / engine hiccup,
    // and the default under test) must not hold up copy or undo.
    String? copied;

    setUp(() {
      copied = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) {
            if (call.method == 'HapticFeedback.vibrate') {
              return Completer<Object?>().future;
            }
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String?;
            }
            return Future<Object?>.value();
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('copy writes the zikr and confirms', (tester) async {
      registerCubitWith([testZikr1]);
      await tester.pumpWidget(
        buildApp(const AzkarCategoryPage(category: 'morning')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(TaliaIcons.copy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(copied, contains('الذكر الأول المعتمد'));
      expect(find.text('تم نسخ الذكر'), findsOneWidget);
    });

    testWidgets('undo restores the count and hides the undo button', (
      tester,
    ) async {
      registerCubitWith([testZikr1, testZikr2]);
      await tester.pumpWidget(
        buildApp(const AzkarCategoryPage(category: 'morning')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('الذكر الأول المعتمد'));
      await tester.pump();
      expect(find.text('١'), findsOneWidget);
      expect(find.byIcon(TaliaIcons.undo), findsOneWidget);

      await tester.tap(find.byIcon(TaliaIcons.undo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('٠'), findsOneWidget);
      expect(find.byIcon(TaliaIcons.undo), findsNothing);
    });
  });
}

class _FakeRepo implements AzkarRepository {
  const _FakeRepo(this.items);
  final List<Zikr> items;

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      Right(items);

  @override
  Future<Either<Failure, Map<AzkarCategory, List<Zikr>>>> getAllAzkar() async =>
      Right({for (final category in AzkarCategory.values) category: items});
}
