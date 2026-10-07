import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_card.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_sheet.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SocialShareData Domain Model & Factories', () {
    test('defines fixed logical canvases for each social export format', () {
      expect(SocialShareFormat.square.exportLogicalSize, const Size(360, 360));
      expect(
        SocialShareFormat.portrait.exportLogicalSize,
        const Size(360, 450),
      );
      expect(SocialShareFormat.story.exportLogicalSize, const Size(360, 640));
    });

    test(
      'references only character assets that actually ship with the app',
      () {
        for (final category in SocialShareCategory.values) {
          expect(
            SocialShareData.defaultCharacterAssetFor(category),
            'assets/images/character/talia_hero.png',
            reason: '$category must resolve to the official master character',
          );
        }
      },
    );

    test('quranAyah factory keeps trusted verse text and reference only', () {
      const ayah = Ayah(
        number: 1,
        surahId: 1,
        text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        numberInSurah: 1,
        juz: 1,
      );

      final data = SocialShareData.quranAyah(
        ayah: ayah,
        surahName: 'الفاتحة',
        translation: 'In the name of Allah, the Entirely Merciful.',
      );

      expect(data.category, SocialShareCategory.quranAyah);
      expect(data.content, 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
      expect(data.title, 'الفاتحة');
      expect(data.surahName, 'الفاتحة');
      expect(data.ayahNumber, 1);
      // The raw ayah number must not leak as presentation copy; the
      // localized template composes the reference label.
      expect(data.subtitle, isNull);
      expect(data.translation, isNotNull);
      expect(data.showCharacter, isTrue);
    });

    test('achievement factory creates valid data from domain Achievement', () {
      const achievement = Achievement(
        id: 'first_page',
        titleKey: 'الصفحة الأولى',
        descriptionKey: 'اقرأ أول صفحة من القرآن',
        icon: '📖',
        isUnlocked: true,
        category: AchievementCategory.reading,
        currentValue: 1,
        targetValue: 1,
      );

      final data = SocialShareData.achievement(
        achievement: achievement,
        userName: 'سيد سعد',
      );

      expect(data.category, SocialShareCategory.achievement);
      expect(data.title, 'الصفحة الأولى');
      expect(data.content, 'اقرأ أول صفحة من القرآن');
      expect(data.userName, 'سيد سعد');
      expect(data.achievementUnlocked, isTrue);
      expect(data.showCharacter, isTrue);
    });

    test('dua factory creates valid data from domain Zikr', () {
      const zikr = Zikr(
        id: 'dua_1',
        text:
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
        transliteration: '',
        translation: '',
        totalCount: 1,
        category: AzkarCategory.duas,
        reference: 'صحيح مسلم',
      );

      final data = SocialShareData.dua(
        zikr: zikr,
        categoryTitle: 'أدعية نبوية',
        isDua: true,
      );

      expect(data.category, SocialShareCategory.dua);
      expect(data.title, 'أدعية نبوية');
      expect(data.subtitle, 'صحيح مسلم');
      expect(data.content, contains('اللَّهُمَّ إِنِّي أَسْأَلُكَ'));
    });

    test('memorization factory maps BOTH real user stats', () {
      final data = SocialShareData.memorization(
        ayahsCount: 120,
        surahsCount: 5,
        userName: 'سيد سعد',
      );

      expect(data.category, SocialShareCategory.memorization);
      expect(data.memorizedAyahsCount, 120);
      expect(data.memorizedSurahsCount, 5);
      expect(data.content, isEmpty);
    });

    test('streak factory creates valid streak data', () {
      final data = SocialShareData.streak(
        streakDays: 30,
        longestStreak: 45,
        userName: 'سيد سعد',
      );

      expect(data.category, SocialShareCategory.streak);
      expect(data.streakDays, 30);
      expect(data.targetValue, 45);
      expect(data.content, isEmpty);
    });

    test('progress factory creates valid multi-stat summary', () {
      final progress = OverallProgress(
        memorizedAyahs: 250,
        totalAyahs: 6236,
        memorizedSurahs: 12,
        totalSurahs: 114,
        memorizedJuz: 1,
        totalJuz: 30,
        readAyahs: 1500,
        readSurahs: 30,
        readJuz: 8,
        streakDays: 14,
        lastActiveDate: DateTime.now(),
        achievements: const [],
        readPagesCount: 85,
        totalQuranPages: 604,
        learningAyahs: 20,
        reviewAyahs: 15,
      );

      final data = SocialShareData.progress(
        progress: progress,
        userName: 'سيد سعد',
      );

      expect(data.category, SocialShareCategory.progress);
      expect(data.readPagesCount, 85);
      expect(data.memorizedAyahsCount, 250);
      expect(data.memorizedSurahsCount, 12);
      expect(data.streakDays, 14);
    });

    test('certificate factory keeps real award data, labels stay in copy', () {
      final award = CertificateAward(
        id: 'cert_juz_30',
        titleAr: 'شهادة إتمام حفظ جزء عم',
        type: CertificateType.juz,
        earnedAt: DateTime.utc(2026, 8, 16),
        juzNumber: 30,
      );

      final data = SocialShareData.certificate(
        award: award,
        userName: 'سيد سعد',
      );

      expect(data.category, SocialShareCategory.certificate);
      expect(data.content, award.titleAr);
      expect(data.verificationCode, award.verificationCode);
      // Presentation sentences are localized by the template, not baked in.
      expect(data.title, isNull);
      expect(data.subtitle, isNull);
    });

    test('toPlainShareText formats correctly with branding signature', () {
      const data = SocialShareData(
        content: 'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ',
        title: 'سورة الإسراء',
        subtitle: 'الآية رقم 9',
        category: SocialShareCategory.quranAyah,
      );

      final text = data.toPlainShareText();
      expect(text, contains('سورة الإسراء'));
      expect(text, contains('إِنَّ هَٰذَا الْقُرْآنَ'));
      expect(text, contains('الآية رقم 9'));
      expect(text, contains('ابدأ رحلة حفظك مع تالية'));
      expect(
        text,
        contains('https://play.google.com/store/apps/details?id=com.talia.quran'),
      );
    });

    test('toPlainShareText accepts a localized footer', () {
      const data = SocialShareData(
        content: 'My Quran progress',
        category: SocialShareCategory.progress,
      );

      final text = data.toPlainShareText(footer: '— Shared from Talia Quran');
      expect(text, contains('— Shared from Talia Quran'));
      expect(text, isNot(contains('تمت المشاركة')));
    });

    test('copyWith preserves every presentation field', () {
      const data = SocialShareData(
        content: 'x',
        category: SocialShareCategory.memorization,
        memorizedAyahsCount: 10,
        memorizedSurahsCount: 2,
      );
      final updated = data.copyWith(
        audience: SocialShareAudience.kids,
        showCharacter: true,
      );

      expect(updated.audience, SocialShareAudience.kids);
      expect(updated.showCharacter, isTrue);
      expect(updated.memorizedAyahsCount, 10);
      expect(updated.memorizedSurahsCount, 2);
    });
  });

  group('Share sheet chrome localization', () {
    Widget sheetHarness(SocialShareData data, Locale locale) {
      return MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: SocialShareSheet(data: data)),
      );
    }

    testWidgets('capture tree preserves locale outside the app hierarchy', (
      tester,
    ) async {
      late Widget captureTree;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              captureTree = buildSocialShareCaptureTree(
                context: context,
                child: Builder(
                  builder: (captureContext) =>
                      Text(Localizations.localeOf(captureContext).languageCode),
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(360, 450)),
            child: Material(child: captureTree),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('en'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('image capture rasterizes the fixed portrait canvas', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (buildContext) {
              context = buildContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final bytes = await tester.runAsync(
        () => captureSocialShareCardImage(
          context: context,
          data: const SocialShareData(
            content: 'My Quran progress',
            category: SocialShareCategory.progress,
          ),
          format: SocialShareFormat.portrait,
        ),
      );
      expect(bytes, isNotNull);
      final header = ByteData.view(bytes!.buffer, 16, 8);

      expect(header.getUint32(0), 1080);
      expect(header.getUint32(4), 1350);
      expect(bytes.length, greaterThan(1024));
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow preview scales the canonical export canvas', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const data = SocialShareData(
        content: 'رَبِّ زِدْنِي عِلْمًا',
        category: SocialShareCategory.dua,
      );
      await tester.pumpWidget(sheetHarness(data, const Locale('ar')));

      final canvas = tester.widget<SizedBox>(
        find.byKey(const ValueKey('social-share-card-canvas')),
      );
      expect(canvas.width, 360);
      expect(canvas.height, 450);
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('social-share-card-canvas')),
          matching: find.byType(FittedBox),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('English sheet shows English chrome only', (tester) async {
      const data = SocialShareData(
        content: 'My Quran progress',
        category: SocialShareCategory.progress,
      );

      await tester.pumpWidget(sheetHarness(data, const Locale('en')));

      expect(find.text('Share your card'), findsOneWidget);
      expect(find.text('Share as image 📸'), findsOneWidget);
      expect(find.text('Card style:'), findsOneWidget);
      expect(find.text('Square (1:1)'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Night'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Story (9:16)'), findsOneWidget);
      expect(find.text('Post (4:5)'), findsOneWidget);
      // No Arabic chrome may leak into the English share flow.
      expect(find.textContaining('مشاركة'), findsNothing);
      expect(find.textContaining('اختر'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic sheet shows Arabic chrome', (tester) async {
      const data = SocialShareData(
        content: 'حصاد التقدم',
        category: SocialShareCategory.progress,
      );

      await tester.pumpWidget(sheetHarness(data, const Locale('ar')));

      expect(find.text('مشاركة بطاقة سوشيال ميديا'), findsOneWidget);
      expect(find.text('اختر مظهر البطاقة:'), findsOneWidget);
      expect(find.text('مربع (1:1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('choosing a mood re-renders the preview palette', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final data = SocialShareData.streak(streakDays: 12);
      await tester.pumpWidget(sheetHarness(data, const Locale('ar')));

      ShareCardBackdrop backdrop() =>
          tester.widget<ShareCardBackdrop>(find.byType(ShareCardBackdrop).last);
      expect(backdrop().palette.id, SharePaletteId.forenoon);

      await tester.ensureVisible(find.byKey(const ValueKey('share-mood-day')));
      await tester.tap(find.byKey(const ValueKey('share-mood-day')));
      await tester.pumpAndSettle();
      expect(backdrop().palette.id, SharePaletteId.day);
    });
  });
}
