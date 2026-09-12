import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/constants/xp_constants.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_achievement_sheet.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/xp/domain/entities/xp_gain_result.dart';

class FakeXpService implements XpService {
  @override
  XpLevel getCurrentLevel(int xp) => const XpLevel(
        name: 'طالب',
        minXp: 100,
        icon: '📚',
        colorHex: 0xFF3B82F6,
      );

  @override
  double progressToNextLevel(int xp) => 0.5;

  @override
  Future<int> getTotalXp() async => 200;

  @override
  Future<XpGainResult> addXp(String eventKey) async => const XpGainResult.zero();
}

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<XpService>(FakeXpService());
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget createHarness({
    required OverallProgress progress,
    required int totalXp,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: const Locale('ar'),
      home: Scaffold(
        body: HomeAchievementSheet(
          progress: progress,
          totalXp: totalXp,
          isKids: false,
        ),
      ),
    );
  }

  testWidgets('renders level, total XP, and achievements list', (tester) async {
    const progress = OverallProgress(
      memorizedAyahs: 10,
      totalAyahs: 6236,
      memorizedSurahs: 1,
      totalSurahs: 114,
      memorizedJuz: 0,
      totalJuz: 30,
      readAyahs: 50,
      readSurahs: 2,
      readJuz: 1,
      streakDays: 3,
      lastActiveDate: null,
      achievements: [
        Achievement(
          id: 'first_page',
          titleKey: 'achievementTitleFirstPage',
          descriptionKey: 'achievementDescFirstPage',
          icon: 'book',
          currentValue: 1,
          targetValue: 1,
          isUnlocked: true,
          category: AchievementCategory.reading,
        ),
      ],
      readPagesCount: 15,
      totalQuranPages: 604,
      learningAyahs: 0,
      reviewAyahs: 0,
      kidsPoints: 0,
      kidsStars: 0,
    );

    await tester.pumpWidget(createHarness(progress: progress, totalXp: 200));
    await tester.pumpAndSettle();

    expect(find.text('إنجازاتك ومستواك'), findsOneWidget);
    expect(find.text('طالب'), findsOneWidget);
    expect(find.textContaining('200'), findsOneWidget);
    expect(find.text('الصفحة الأولى'), findsOneWidget);
  });
}
