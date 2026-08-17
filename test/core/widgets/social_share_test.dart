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

  /// Matches the Talia companion image; templates tag it with a stable key
  /// so assertions hold regardless of provider wrapping (ResizeImage) or
  /// whether assets load in the test environment.
  final Finder characterImage = find.byKey(const ValueKey('share-character-image'));

  group('SocialShareData Domain Model & Factories', () {
    test('defines fixed logical canvases for each social export format', () {
      expect(SocialShareFormat.square.exportLogicalSize, const Size(360, 360));
      expect(SocialShareFormat.portrait.exportLogicalSize, const Size(360, 450));
      expect(SocialShareFormat.story.exportLogicalSize, const Size(360, 640));
    });

    test('references only character assets that actually ship with the app', () {
      for (final category in SocialShareCategory.values) {
        expect(
          SocialShareData.defaultCharacterAssetFor(category),
          'assets/images/character/Talia_Master_Character.png',
          reason: '$category must resolve to the official master character',
        );
      }
    });

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
      expect(data.showCharacter, isFalse);
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
      // Adults are the safe default: the audience resolver opts kids in.
      expect(data.showCharacter, isFalse);
    });

    test('dua factory creates valid data from domain Zikr', () {
      const zikr = Zikr(
        id: 'dua_1',
        text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
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
      expect(text, contains('تمت المشاركة عبر تطبيق تالية للقرآن الكريم'));
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

  group('Theme system', () {
    test('default theme is content-driven per category and audience', () {
      expect(
        SocialShareThemeType.defaultFor(SocialShareCategory.quranAyah),
        SocialShareThemeType.parchmentGold,
      );
      expect(
        SocialShareThemeType.defaultFor(SocialShareCategory.azkar),
        SocialShareThemeType.dawnLight,
      );
      expect(
        SocialShareThemeType.defaultFor(SocialShareCategory.achievement),
        SocialShareThemeType.emeraldDark,
      );
      expect(
        SocialShareThemeType.defaultFor(
          SocialShareCategory.achievement,
          audience: SocialShareAudience.kids,
        ),
        SocialShareThemeType.parchmentGold,
      );
      expect(
        SocialShareThemeType.defaultFor(SocialShareCategory.streak),
        SocialShareThemeType.midnightGold,
      );
    });

    test('every palette exposes localized display names', () {
      for (final type in SocialShareThemeType.values) {
        expect(type.nameAr, isNotEmpty);
        expect(type.nameEn, isNotEmpty);
        expect(type.nameAr, isNot(type.nameEn));
      }
    });
  });

  group('Template Resolution & Widget Rendering', () {
    Widget buildTestHarness(
      Widget child, {
      Size size = const Size(360, 450),
      Locale locale = const Locale('ar'),
    }) {
      return MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('premium shell exposes its arch and parchment sharing footer',
        (tester) async {
      const data = SocialShareData(
        content: 'A real milestone from the user journey',
        title: 'First Quran milestone',
        category: SocialShareCategory.achievement,
      );

      await tester.pumpWidget(
        buildTestHarness(
          const SocialShareCard(
            data: data,
            theme: SocialShareTheme.emeraldDark,
            format: SocialShareFormat.portrait,
          ),
          size: const Size(360, 450),
        ),
      );

      expect(find.byKey(const ValueKey('islamic-hero-arch')), findsOneWidget);
      expect(find.byKey(const ValueKey('share-parchment-footer')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('kids achievement composes the official character inside the hero arch',
        (tester) async {
      const data = SocialShareData(
        content: 'A real milestone from the user journey',
        title: 'First Quran milestone',
        category: SocialShareCategory.achievement,
        audience: SocialShareAudience.kids,
        showCharacter: true,
      );

      await tester.pumpWidget(
        buildTestHarness(
          const SocialShareCard(
            data: data,
            theme: SocialShareTheme.emeraldDark,
            format: SocialShareFormat.portrait,
          ),
          size: const Size(360, 450),
        ),
      );

      expect(find.byKey(const ValueKey('share-hero-character')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 1: Achievement card (Arabic) renders real data', (tester) async {
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
        userName: 'سيد',
      );

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.emeraldDark,
            format: SocialShareFormat.portrait,
          ),
        ),
      );

      expect(find.text('الصفحة الأولى'), findsOneWidget);
      expect(find.text('اقرأ أول صفحة من القرآن'), findsOneWidget);
      expect(find.text('تالية'), findsOneWidget);
      expect(find.text('إنجاز جديد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 2: Achievement card (English) is fully localized', (tester) async {
      const achievement = Achievement(
        id: 'ten_pages',
        titleKey: 'Ten pages read',
        descriptionKey: 'You read ten pages of the Holy Quran',
        icon: '📖',
        isUnlocked: true,
        category: AchievementCategory.reading,
        currentValue: 10,
        targetValue: 10,
      );

      final data = SocialShareData.achievement(
        achievement: achievement,
        userName: 'Sayed',
      );

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.emeraldDark,
            format: SocialShareFormat.portrait,
          ),
          locale: const Locale('en'),
        ),
      );

      expect(find.text('Ten pages read'), findsOneWidget);
      expect(find.text('Talia'), findsOneWidget);
      expect(find.text('New achievement'), findsOneWidget);
      expect(find.text("Sayed's Quran journey"), findsOneWidget);
      expect(find.text('Shared from Talia Quran'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 3: Quran verse card (Arabic) shows trusted text only', (tester) async {
      const ayah = Ayah(
        number: 9,
        surahId: 17,
        text: 'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ وَيُبَشِّرُ الْمُؤْمِنِينَ',
        numberInSurah: 9,
      );

      final data = SocialShareData.quranAyah(ayah: ayah, surahName: 'الإسراء');

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.parchmentGold,
            format: SocialShareFormat.portrait,
          ),
        ),
      );

      // Verse text rendered verbatim from the domain entity.
      expect(
        find.text('﴿ إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ وَيُبَشِّرُ الْمُؤْمِنِينَ ﴾'),
        findsOneWidget,
      );
      expect(find.text('سورة الإسراء'), findsOneWidget);
      expect(find.text('الآية 9'), findsOneWidget);
      // No Quran wording may be composed inside presentation code.
      expect(find.textContaining('بِسْمِ اللهِ الرَّحْمٰنِ'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 4: Quran verse card (English) shows translation', (tester) async {
      const ayah = Ayah(
        number: 9,
        surahId: 17,
        text: 'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ',
        numberInSurah: 9,
      );

      final data = SocialShareData.quranAyah(
        ayah: ayah,
        surahName: 'Al-Isra',
        translation: 'Indeed, this Quran guides to that which is most suitable',
      );

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.dawnLight,
            format: SocialShareFormat.portrait,
          ),
          locale: const Locale('en'),
        ),
      );

      expect(find.text('Surah Al-Isra'), findsOneWidget);
      expect(find.text('Ayah 9'), findsOneWidget);
      expect(find.textContaining('Indeed, this Quran guides'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 4b: Arabic verse card hides English translation', (tester) async {
      const ayah = Ayah(
        number: 9,
        surahId: 17,
        text: 'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ',
        numberInSurah: 9,
      );

      final data = SocialShareData.quranAyah(
        ayah: ayah,
        surahName: 'الإسراء',
        translation: 'Indeed, this Quran guides to that which is most suitable',
      );

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.dawnLight,
            format: SocialShareFormat.portrait,
          ),
        ),
      );

      expect(find.textContaining('Indeed, this Quran'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 5: Dua card (Arabic) renders reference, hides translation', (tester) async {
      const zikr = Zikr(
        id: 'dua_1',
        text: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
        transliteration: '',
        translation: 'Our Lord, give us good in this world',
        totalCount: 1,
        category: AzkarCategory.duas,
        reference: 'سورة البقرة: ٢٠١',
      );

      final data = SocialShareData.dua(
        zikr: zikr,
        categoryTitle: 'دعاء قرآني',
        isDua: true,
      );

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.dawnLight,
            format: SocialShareFormat.portrait,
          ),
        ),
      );

      expect(find.text('دعاء قرآني'), findsOneWidget);
      expect(find.text('سورة البقرة: ٢٠١'), findsOneWidget);
      expect(find.text('دعاء'), findsOneWidget);
      expect(find.textContaining('Our Lord'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 6: Memorization card renders BOTH real stats', (tester) async {
      final data = SocialShareData.memorization(
        ayahsCount: 150,
        surahsCount: 6,
        milestoneTitle: 'إنجاز في مسيرة الحفظ',
        userName: 'سيد سعد',
      );

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.emeraldDark,
            format: SocialShareFormat.portrait,
          ),
        ),
      );

      expect(find.text('150'), findsOneWidget);
      expect(find.text('آية محفوظة'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('سورة مكتملة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 7: Streak card renders counter and record context', (tester) async {
      final data = SocialShareData.streak(
        streakDays: 45,
        longestStreak: 45,
        userName: 'سيد',
      );

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.midnightGold,
            format: SocialShareFormat.portrait,
          ),
        ),
      );

      expect(find.text('45'), findsOneWidget);
      expect(find.text('أيام متواصلة'), findsOneWidget);
      expect(find.text('رقم قياسي جديد! 🎉'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 7b: Streak below record shows longest streak', (tester) async {
      final data = SocialShareData.streak(
        streakDays: 30,
        longestStreak: 45,
        userName: 'سيد',
      );

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.midnightGold,
            format: SocialShareFormat.portrait,
          ),
        ),
      );

      expect(find.text('أطول سلسلة: 45 يوم'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 8: Progress card renders all three stats', (tester) async {
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

      final data = SocialShareData.progress(progress: progress, userName: 'سيد');

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.dawnLight,
            format: SocialShareFormat.portrait,
          ),
        ),
      );

      expect(find.text('85'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('صفحات مقروءة'), findsOneWidget);
      expect(find.text('آيات محفوظة'), findsOneWidget);
      expect(find.text('أيام متتالية'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 8b: Certificate share card renders award + code', (tester) async {
      final award = CertificateAward(
        id: 'cert_juz_30',
        titleAr: 'شهادة إتمام حفظ جزء عم',
        type: CertificateType.juz,
        earnedAt: DateTime.utc(2026, 8, 16),
        juzNumber: 30,
      );

      final data = SocialShareData.certificate(award: award, userName: 'سيد');

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.parchmentGold,
            format: SocialShareFormat.portrait,
          ),
        ),
      );

      // The headline and the header badge both legitimately show this.
      expect(find.text('شهادة إتمام ومواظبة'), findsWidgets);
      expect(find.textContaining('حصلت بحمد الله على شهادة إتمام حفظ جزء عم'), findsOneWidget);
      expect(find.textContaining(award.verificationCode), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 9: Kids share shows kids identity and companion', (tester) async {
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
        userName: 'سيد',
      ).copyWith(audience: SocialShareAudience.kids, showCharacter: true);

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.parchmentGold,
            format: SocialShareFormat.portrait,
          ),
        ),
      );

      expect(find.text('رحلة الأبطال الصغار'), findsOneWidget);
      expect(find.textContaining('أحسنت! استمر يا بطل'), findsOneWidget);
      expect(characterImage, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 10: Adult share stays refined without kids layer', (tester) async {
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
        userName: 'سيد',
      );

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.emeraldDark,
            format: SocialShareFormat.portrait,
          ),
        ),
      );

      expect(find.text('رفيقك في رحلة القرآن'), findsOneWidget);
      expect(find.text('رحلة الأبطال الصغار'), findsNothing);
      expect(characterImage, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CASE 11: Very long Quran verse never overflows in any format', (tester) async {
      const longAyahText =
          'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ '
          'لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۚ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ '
          'يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ '
          'وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضِ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ';

      const ayah = Ayah(
        number: 255,
        surahId: 2,
        text: longAyahText,
        numberInSurah: 255,
      );

      final data = SocialShareData.quranAyah(ayah: ayah, surahName: 'البقرة');

      for (final fmt in SocialShareFormat.values) {
        await tester.pumpWidget(
          buildTestHarness(
            SocialShareCard(
              data: data,
              theme: SocialShareTheme.emeraldDark,
              format: fmt,
            ),
            size: fmt.exportLogicalSize,
          ),
        );
        // The full verse must be present — the export canvas may not clip.
        expect(find.textContaining('وَهُوَ الْعَلِيُّ الْعَظِيمُ'), findsOneWidget,
            reason: 'Verse tail missing on format: $fmt');
        expect(tester.takeException(), isNull, reason: 'Failed on format: $fmt');
      }
    });

    testWidgets('CASE 12: Long achievement title and description adapt', (tester) async {
      const achievement = Achievement(
        id: 'full_quran_read',
        titleKey: 'إنجاز إتمام قراءة القرآن الكريم كاملاً من الغلاف إلى الغلاف',
        descriptionKey:
            'قرأت جميع صفحات القرآن الكريم بفضل الله وتوفيقه، واستمريت في رحلتك حتى أتممت الختمة كاملة بصفحاتها الست مئة والأربعة',
        icon: '📖',
        isUnlocked: true,
        category: AchievementCategory.milestone,
        currentValue: 604,
        targetValue: 604,
      );

      final data = SocialShareData.achievement(
        achievement: achievement,
        userName: 'سيد سعد',
      );

      for (final fmt in SocialShareFormat.values) {
        await tester.pumpWidget(
          buildTestHarness(
            SocialShareCard(
              data: data,
              theme: SocialShareTheme.emeraldDark,
              format: fmt,
            ),
            size: fmt.exportLogicalSize,
          ),
        );
        expect(find.textContaining('من الغلاف إلى الغلاف'), findsOneWidget);
        expect(find.textContaining('الختمة كاملة'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Failed on format: $fmt');
      }
    });

    testWidgets('CASE 13: Long user name does not break the footer', (tester) async {
      final data = SocialShareData.streak(
        streakDays: 7,
        longestStreak: 21,
        userName: 'عبد الرحمن بن خالد المهدي القرشي الهاشمي الطالبي',
      );

      for (final fmt in SocialShareFormat.values) {
        await tester.pumpWidget(
          buildTestHarness(
            SocialShareCard(
              data: data,
              theme: SocialShareTheme.midnightGold,
              format: fmt,
            ),
            size: fmt.exportLogicalSize,
          ),
        );
        expect(find.textContaining('الطالبي'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Failed on format: $fmt');
      }
    });

    testWidgets('CASE 14-16: All export formats render every category safely', (tester) async {
      final datasets = <SocialShareData>[
        SocialShareData.achievement(
          achievement: const Achievement(
            id: 'ten_pages',
            titleKey: 'عشر صفحات',
            descriptionKey: 'قرأت عشر صفحات',
            icon: '📖',
            isUnlocked: true,
            category: AchievementCategory.reading,
            currentValue: 10,
            targetValue: 10,
          ),
        ),
        SocialShareData.quranAyah(
          ayah: const Ayah(
            number: 1,
            surahId: 1,
            text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            numberInSurah: 1,
          ),
          surahName: 'الفاتحة',
        ),
        SocialShareData.dua(
          zikr: const Zikr(
            id: 'z1',
            text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
            transliteration: '',
            translation: '',
            totalCount: 100,
            category: AzkarCategory.general,
            reference: 'صحيح البخاري',
          ),
          isDua: false,
        ),
        SocialShareData.memorization(ayahsCount: 60, surahsCount: 3),
        SocialShareData.streak(streakDays: 7, longestStreak: 14),
        SocialShareData.progress(
          progress: OverallProgress(
            memorizedAyahs: 60,
            totalAyahs: 6236,
            memorizedSurahs: 3,
            totalSurahs: 114,
            memorizedJuz: 0,
            totalJuz: 30,
            readAyahs: 400,
            readSurahs: 12,
            readJuz: 1,
            streakDays: 7,
            lastActiveDate: DateTime.now(),
            achievements: const [],
            readPagesCount: 32,
            totalQuranPages: 604,
            learningAyahs: 5,
            reviewAyahs: 4,
          ),
        ),
      ];

      for (final data in datasets) {
        for (final fmt in SocialShareFormat.values) {
          await tester.pumpWidget(
            buildTestHarness(
              SocialShareCard(
                data: data,
                theme: SocialShareTheme.tealTwilight,
                format: fmt,
              ),
              size: fmt.exportLogicalSize,
            ),
          );
          expect(tester.takeException(), isNull,
              reason: 'Failed: ${data.category} on $fmt');
        }
      }
    });

    testWidgets('English localization renders safely with empty optional fields', (tester) async {
      const data = SocialShareData(
        content: 'Completed the first milestone of the Holy Quran!',
        title: 'New Milestone',
        category: SocialShareCategory.achievement,
      );

      await tester.pumpWidget(
        buildTestHarness(
          const SocialShareCard(
            data: data,
            theme: SocialShareTheme.emeraldDark,
            format: SocialShareFormat.square,
          ),
          locale: const Locale('en'),
          size: const Size(360, 360),
        ),
      );

      expect(find.text('New Milestone'), findsOneWidget);
      expect(find.text('Completed the first milestone of the Holy Quran!'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
  });
}
