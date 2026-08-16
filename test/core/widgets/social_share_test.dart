import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_card.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SocialShareData Domain Model & Factories', () {
    test('defines fixed logical canvases for each social export format', () {
      expect(
        SocialShareFormat.square.exportLogicalSize,
        const Size(360, 360),
      );
      expect(
        SocialShareFormat.portrait.exportLogicalSize,
        const Size(360, 450),
      );
      expect(
        SocialShareFormat.story.exportLogicalSize,
        const Size(360, 640),
      );
    });

    test('uses the official transparent Talia character for social cards', () {
      expect(
        SocialShareData.defaultCharacterAssetFor(
          SocialShareCategory.achievement,
        ),
        'assets/images/character/Talia_Master_Character.png',
      );
    });

    test('quranAyah factory creates valid data from domain Ayah', () {
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
        translation: 'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
      );

      expect(data.category, SocialShareCategory.quranAyah);
      expect(data.content, 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
      expect(data.title, 'الفاتحة');
      expect(data.subtitle, '1');
      expect(data.surahName, 'الفاتحة');
      expect(data.ayahNumber, 1);
      expect(data.translation, isNotNull);
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
      expect(data.showCharacter, isTrue);
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

    test('memorization factory creates valid milestone data', () {
      final data = SocialShareData.memorization(
        ayahsCount: 120,
        surahsCount: 5,
        userName: 'سيد سعد',
      );

      expect(data.category, SocialShareCategory.memorization);
      expect(data.memorizedAyahsCount, 120);
      expect(data.subtitle, isNull);
      expect(data.content, isEmpty);
      expect(data.showCharacter, isTrue);
    });

    test('streak factory creates valid streak data', () {
      final data = SocialShareData.streak(
        streakDays: 30,
        longestStreak: 45,
        userName: 'سيد سعد',
      );

      expect(data.category, SocialShareCategory.streak);
      expect(data.streakDays, 30);
      expect(data.subtitle, isNull);
      expect(data.targetValue, 45);
      expect(data.content, isEmpty);
      expect(data.showCharacter, isTrue);
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
      expect(data.streakDays, 14);
    });

    test('certificate factory creates valid award data', () {
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
      expect(data.verificationCode, award.verificationCode);
      expect(data.subtitle, contains(award.verificationCode));
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
  });

  group('Template Resolution & Widget Rendering', () {
    Widget buildTestHarness(
      Widget child, {
      Size size = const Size(800, 1000),
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

    testWidgets('Case 1: Achievement card renders without errors', (tester) async {
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
      expect(tester.takeException(), isNull);
    });

    testWidgets('Case 2: Quran verse card renders authentic verse text', (tester) async {
      const ayah = Ayah(
        number: 9,
        surahId: 17,
        text: 'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ وَيُبَشِّرُ الْمُؤْمِنِينَ',
        numberInSurah: 9,
      );

      final data = SocialShareData.quranAyah(
        ayah: ayah,
        surahName: 'الإسراء',
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

      expect(find.text('﴿ بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيمِ ﴾'), findsOneWidget);
      expect(find.text('سورة الإسراء'), findsOneWidget);
      expect(find.text('الآية 9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Case 3: Dua & Dhikr card renders reference', (tester) async {
      const zikr = Zikr(
        id: 'dua_1',
        text: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
        transliteration: '',
        translation: '',
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
      expect(tester.takeException(), isNull);
    });

    testWidgets('Case 4: Memorization card renders stats and level', (tester) async {
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
            theme: SocialShareTheme.royalGradient,
            format: SocialShareFormat.portrait,
          ),
        ),
      );

      expect(find.text('150'), findsOneWidget);
      expect(find.text('آية محفوظة'), findsOneWidget);
      expect(find.text('6'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Case 5: Streak card renders streak counter', (tester) async {
      final data = SocialShareData.streak(
        streakDays: 45,
        longestStreak: 45,
        userName: 'سيد',
      );

      await tester.pumpWidget(
        buildTestHarness(
          SocialShareCard(
            data: data,
            theme: SocialShareTheme.parchmentGold,
            format: SocialShareFormat.portrait,
          ),
        ),
      );

      expect(find.text('45'), findsOneWidget);
      expect(find.text('أيام متواصلة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Case 6: Very long Quran verse does not overflow across all formats', (tester) async {
      const longAyahText =
          'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ '
          'لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۚ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ '
          'يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ '
          'وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ';

      const ayah = Ayah(
        number: 255,
        surahId: 2,
        text: longAyahText,
        numberInSurah: 255,
      );

      final data = SocialShareData.quranAyah(
        ayah: ayah,
        surahName: 'البقرة',
      );

      for (final fmt in SocialShareFormat.values) {
        await tester.pumpWidget(
          buildTestHarness(
            SocialShareCard(
              data: data,
              theme: SocialShareTheme.emeraldDark,
              format: fmt,
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'Failed on format: $fmt');
      }
    });

    testWidgets('Case 7: English localization and empty optional fields render safely', (tester) async {
      const data = SocialShareData(
        content: 'Completed the first milestone of the Holy Quran!',
        title: 'New Milestone',
        subtitle: 'Chapter Al-Baqarah',
        category: SocialShareCategory.achievement,
        userName: 'Sayed',
      );

      await tester.pumpWidget(
        buildTestHarness(
          const SocialShareCard(
            data: data,
            theme: SocialShareTheme.emeraldDark,
            format: SocialShareFormat.square,
          ),
          locale: const Locale('en'),
        ),
      );

      expect(find.text('New Milestone'), findsOneWidget);
      expect(find.text('Completed the first milestone of the Holy Quran!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('Contextual character pose assets are mapped correctly for all categories', () {
      expect(
        SocialShareData.defaultCharacterAssetFor(SocialShareCategory.quranAyah),
        'assets/images/character/talia_reading.jpg',
      );
      expect(
        SocialShareData.defaultCharacterAssetFor(SocialShareCategory.dua),
        'assets/images/character/talia_praying.jpg',
      );
      expect(
        SocialShareData.defaultCharacterAssetFor(SocialShareCategory.azkar),
        'assets/images/character/talia_praying.jpg',
      );
      expect(
        SocialShareData.defaultCharacterAssetFor(SocialShareCategory.achievement),
        'assets/images/character/talia_celebrating.jpg',
      );
      expect(
        SocialShareData.defaultCharacterAssetFor(SocialShareCategory.memorization),
        'assets/images/character/talia_memorizing.jpg',
      );
      expect(
        SocialShareData.defaultCharacterAssetFor(SocialShareCategory.streak),
        'assets/images/character/talia_streak.jpg',
      );
      expect(
        SocialShareData.defaultCharacterAssetFor(SocialShareCategory.progress),
        'assets/images/character/talia_celebrating.jpg',
      );
      expect(
        SocialShareData.defaultCharacterAssetFor(SocialShareCategory.certificate),
        'assets/images/character/talia_memorizing.jpg',
      );
    });
  });
}
