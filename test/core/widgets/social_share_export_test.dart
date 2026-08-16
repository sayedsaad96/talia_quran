import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_card.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

/// Export QA harness: renders share cards on the exact production export
/// canvas with the real Arabic fonts and rasterizes them at the production
/// 3x pixel ratio, verifying actual PNG pixel dimensions and writing the
/// images to build/share_qa/ for manual visual inspection.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final outputDir = Directory('build/share_qa');
  // Asset bytes preloaded outside the fake-async zone; the channel handler
  // must never perform real IO while the fake clock is in control.
  final Map<String, Uint8List> assetCache = {};

  Future<void> primeAssets() async {
    for (final path in [
      'assets/images/logo_icon_padded.png',
      'assets/images/character/Talia_Master_Character.png',
    ]) {
      final file = File(path);
      if (await file.exists()) {
        assetCache[path] = await file.readAsBytes();
      }
    }
  }

  setUpAll(() async {
    await _loadRealFonts();
    await primeAssets();
    // Serve real asset bytes (logo, character) so the QA PNGs show the true
    // branding instead of fallback icons.  Pure in-memory lookups only.
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      // The asset manifest is consulted before any AssetImage resolves;
      // hand it a valid empty manifest (no resolution variants).
      if (key.startsWith('AssetManifest')) {
        return const StandardMessageCodec().encodeMessage(<Object?, Object?>{});
      }
      final bytes = assetCache[key];
      if (bytes == null) return null;
      return ByteData.view(bytes.buffer);
    });
  });

  Future<void> captureAndVerify(
    WidgetTester tester, {
    required String caseName,
    required SocialShareData data,
    required SocialShareTheme theme,
    required SocialShareFormat format,
    Locale locale = const Locale('ar'),
  }) async {
    final logical = format.exportLogicalSize;
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: logical.width,
              height: logical.height,
              child: SocialShareCard(
                data: data,
                theme: theme,
                format: format,
                width: logical.width,
              ),
            ),
          ),
        ),
      ),
    ));
    // Bounded pumps: a settle loop can hang forever if an image stream
    // never completes in the test environment.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull, reason: '$caseName layout error');

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    // Engine rasterization/encoding is real async work; it must run inside
    // runAsync or the fake-async test zone never observes completion.
    final rawBytes = await tester.runAsync(() async {
      // Same ratio the production exporter uses in SocialShareSheet.
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final result = byteData?.buffer.asUint8List();
      image.dispose();
      return result;
    });
    expect(rawBytes, isNotNull, reason: '$caseName produced no PNG');
    final bytes = rawBytes!;

    // PNG IHDR: width at bytes 16-19, height at 20-23 (big-endian).
    final header = ByteData.view(bytes.buffer, 16, 8);
    final width = header.getUint32(0);
    final height = header.getUint32(4);
    expect(width, 1080, reason: '$caseName width must be exactly 1080px');
    switch (format) {
      case SocialShareFormat.portrait:
        expect(height, 1350, reason: '$caseName must export 1080x1350');
      case SocialShareFormat.square:
        expect(height, 1080, reason: '$caseName must export 1080x1080');
      case SocialShareFormat.story:
        expect(height, 1920, reason: '$caseName must export 1080x1920');
    }

    await tester.runAsync(() async {
      await outputDir.create(recursive: true);
      final file = File('${outputDir.path}/$caseName.png');
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('QA PNG written: ${file.path} (${width}x$height)');
    });
  }

  testWidgets('VISUAL QA MATRIX - 16 representative export cases', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const ayatAlKursi =
        'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ '
        'لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۚ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ '
        'يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ '
        'وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضِ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ';

    const achievementAr = Achievement(
      id: 'juz_read',
      titleKey: 'قارئ جزء كامل',
      descriptionKey: 'قرأت جزءاً كاملاً من القرآن الكريم بفضل الله وتوفيقه',
      icon: '📖',
      isUnlocked: true,
      category: AchievementCategory.reading,
      currentValue: 20,
      targetValue: 20,
    );

    final progressStats = OverallProgress(
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

    // CASE 1 — Achievement, Arabic, portrait.
    await captureAndVerify(
      tester,
      caseName: '01_achievement_ar',
      data: SocialShareData.achievement(
        achievement: achievementAr,
        userName: 'سيد سعد',
      ),
      theme: SocialShareTheme.emeraldDark,
      format: SocialShareFormat.portrait,
    );

    // CASE 2 — Achievement, English, portrait.
    await captureAndVerify(
      tester,
      caseName: '02_achievement_en',
      locale: const Locale('en'),
      data: const SocialShareData(
        content: 'You completed reading a full Juz of the Holy Quran',
        title: 'Full Juz Reader',
        achievementIcon: '📖',
        achievementUnlocked: true,
        currentValue: 20,
        targetValue: 20,
        userName: 'Sayed',
        category: SocialShareCategory.achievement,
      ),
      theme: SocialShareTheme.emeraldDark,
      format: SocialShareFormat.portrait,
    );

    // CASE 3 — Quran verse, Arabic, portrait (typography-first parchment).
    await captureAndVerify(
      tester,
      caseName: '03_quran_verse_ar',
      data: SocialShareData.quranAyah(
        ayah: const Ayah(
          number: 9,
          surahId: 17,
          text: 'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ وَيُبَشِّرُ الْمُؤْمِنِينَ',
          numberInSurah: 9,
        ),
        surahName: 'الإسراء',
      ),
      theme: SocialShareTheme.parchmentGold,
      format: SocialShareFormat.portrait,
    );

    // CASE 4 — Quran verse, English locale with translation, square.
    await captureAndVerify(
      tester,
      caseName: '04_quran_verse_en',
      locale: const Locale('en'),
      data: SocialShareData.quranAyah(
        ayah: const Ayah(
          number: 9,
          surahId: 17,
          text: 'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ',
          numberInSurah: 9,
        ),
        surahName: 'Al-Isra',
        translation: 'Indeed, this Quran guides to that which is most suitable.',
      ),
      theme: SocialShareTheme.dawnLight,
      format: SocialShareFormat.square,
    );

    // CASE 5 — Dua, Arabic, portrait (calm dawn).
    await captureAndVerify(
      tester,
      caseName: '05_dua_ar',
      data: SocialShareData.dua(
        zikr: const Zikr(
          id: 'd1',
          text: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
          transliteration: '',
          translation: '',
          totalCount: 1,
          category: AzkarCategory.duas,
          reference: 'سورة البقرة: ٢٠١',
        ),
        categoryTitle: 'دعاء قرآني',
        isDua: true,
      ),
      theme: SocialShareTheme.dawnLight,
      format: SocialShareFormat.portrait,
    );

    // CASE 6 — Memorization, Arabic, portrait with both real stats.
    await captureAndVerify(
      tester,
      caseName: '06_memorization_ar',
      data: SocialShareData.memorization(
        ayahsCount: 250,
        surahsCount: 12,
        userName: 'سيد سعد',
      ),
      theme: SocialShareTheme.emeraldDark,
      format: SocialShareFormat.portrait,
    );

    // CASE 7 — Streak, Arabic, portrait.
    await captureAndVerify(
      tester,
      caseName: '07_streak_ar',
      data: SocialShareData.streak(
        streakDays: 45,
        longestStreak: 45,
        userName: 'سيد سعد',
      ),
      theme: SocialShareTheme.midnightGold,
      format: SocialShareFormat.portrait,
    );

    // CASE 8 — Progress, Arabic, portrait.
    await captureAndVerify(
      tester,
      caseName: '08_progress_ar',
      data: SocialShareData.progress(progress: progressStats, userName: 'سيد سعد'),
      theme: SocialShareTheme.dawnLight,
      format: SocialShareFormat.portrait,
    );

    // CASE 9 — Kids achievement share (character + playful layer).
    await captureAndVerify(
      tester,
      caseName: '09_kids_achievement',
      data: SocialShareData.achievement(
        achievement: achievementAr,
        userName: 'أحمد',
      ).copyWith(audience: SocialShareAudience.kids, showCharacter: true),
      theme: SocialShareTheme.parchmentGold,
      format: SocialShareFormat.portrait,
    );

    // CASE 10 — Adult achievement share (refined, no character).
    await captureAndVerify(
      tester,
      caseName: '10_adult_achievement',
      data: SocialShareData.achievement(
        achievement: achievementAr,
        userName: 'سيد سعد',
      ),
      theme: SocialShareTheme.emeraldDark,
      format: SocialShareFormat.portrait,
    );

    // CASE 11 — Long Quran text (Ayat Al-Kursi), portrait.
    await captureAndVerify(
      tester,
      caseName: '11_long_verse',
      data: SocialShareData.quranAyah(
        ayah: const Ayah(
          number: 255,
          surahId: 2,
          text: ayatAlKursi,
          numberInSurah: 255,
        ),
        surahName: 'البقرة',
      ),
      theme: SocialShareTheme.parchmentGold,
      format: SocialShareFormat.portrait,
    );

    // CASE 12 — Long achievement title, portrait.
    await captureAndVerify(
      tester,
      caseName: '12_long_title',
      data: SocialShareData.achievement(
        achievement: const Achievement(
          id: 'full_quran_read',
          titleKey: 'إنجاز إتمام قراءة القرآن الكريم كاملاً من الغلاف إلى الغلاف',
          descriptionKey:
              'قرأت جميع صفحات القرآن الكريم بفضل الله وتوفيقه، واستمريت في رحلتك حتى أتممت الختمة كاملة',
          icon: '📖',
          isUnlocked: true,
          category: AchievementCategory.milestone,
          currentValue: 604,
          targetValue: 604,
        ),
        userName: 'سيد سعد',
      ),
      theme: SocialShareTheme.emeraldDark,
      format: SocialShareFormat.portrait,
    );

    // CASE 13 — Long user name, portrait.
    await captureAndVerify(
      tester,
      caseName: '13_long_name',
      data: SocialShareData.streak(
        streakDays: 7,
        longestStreak: 21,
        userName: 'عبد الرحمن بن خالد المهدي القرشي الهاشمي الطالبي',
      ),
      theme: SocialShareTheme.tealTwilight,
      format: SocialShareFormat.portrait,
    );

    // CASE 14 — Square export 1080x1080.
    await captureAndVerify(
      tester,
      caseName: '14_square_1080',
      data: SocialShareData.quranAyah(
        ayah: const Ayah(
          number: 255,
          surahId: 2,
          text: ayatAlKursi,
          numberInSurah: 255,
        ),
        surahName: 'البقرة',
      ),
      theme: SocialShareTheme.emeraldDark,
      format: SocialShareFormat.square,
    );

    // CASE 15 — Portrait export 1080x1350 (already used above; explicit case).
    await captureAndVerify(
      tester,
      caseName: '15_portrait_1080',
      data: SocialShareData.dua(
        zikr: const Zikr(
          id: 'z1',
          text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ',
          transliteration: '',
          translation: '',
          totalCount: 100,
          category: AzkarCategory.general,
          reference: 'صحيح البخاري',
        ),
        isDua: false,
      ),
      theme: SocialShareTheme.dawnLight,
      format: SocialShareFormat.portrait,
    );

    // CASE 16 — Story export 1080x1920.
    await captureAndVerify(
      tester,
      caseName: '16_story_1080',
      data: SocialShareData.progress(progress: progressStats, userName: 'سيد سعد'),
      theme: SocialShareTheme.tealTwilight,
      format: SocialShareFormat.story,
    );
  });
}

/// Registers the real bundled fonts so exported PNGs show true Arabic
/// typography instead of the test-only fallback font.
Future<void> _loadRealFonts() async {  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final data = await File(path).readAsBytes();
      loader.addFont(Future.value(ByteData.view(data.buffer)));
    }
    await loader.load();
  }

  await load('Amiri', [
    'assets/fonts/Amiri/Amiri-Regular.ttf',
    'assets/fonts/Amiri/Amiri-Bold.ttf',
  ]);
  await load('Noto_Naskh_Arabic', [
    'assets/fonts/Noto_Naskh_Arabic/NotoNaskhArabic-Regular.ttf',
    'assets/fonts/Noto_Naskh_Arabic/NotoNaskhArabic-Bold.ttf',
  ]);
}
