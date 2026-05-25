import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/app_failure.dart';
import '../../../hifz/data/datasources/hifz_local_datasource.dart';
import '../../../hifz/domain/entities/hifz_entities.dart';
import '../../domain/entities/progress_entities.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_local_datasource.dart';

import '../../../../features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import '../../../quran/data/datasources/quran_local_datasource.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(
    this._progressDs,
    this._hifzDs,
    this._memPlusDs,
    this._quranDs,
  );
  final ProgressLocalDatasource _progressDs;
  final HifzLocalDatasource _hifzDs;
  final MemorizationPlusLocalDatasource _memPlusDs;
  final QuranLocalDatasource _quranDs;

  @override
  Future<Either<Failure, OverallProgress>> getOverallProgress() async {
    try {
      final allProgress = await _hifzDs.getAllProgress();

      // Memorized ayahs count
      final memorizedAyahs = allProgress
          .where((p) => p.status == AyahStatus.memorized)
          .length;

      // Learning ayahs
      final learningAyahs = allProgress
          .where((p) => p.status == AyahStatus.learning)
          .length;

      // Review ayahs
      final reviewAyahs = allProgress
          .where((p) => p.status == AyahStatus.review)
          .length;

      final surahs = await _quranDs.getSurahs();
      final surahAyahCounts = {
        for (final surah in surahs) surah.id: surah.ayahCount,
      };

      // Count memorized surahs only when every ayah in the surah is recorded as memorized.
      final bySurah = <int, List<dynamic>>{};
      for (final p in allProgress) {
        bySurah.putIfAbsent(p.surahId, () => []).add(p);
      }

      final memorizedSurahs = bySurah.entries.where((entry) {
        final totalAyahs = surahAyahCounts[entry.key];
        if (totalAyahs == null || entry.value.length < totalAyahs) {
          return false;
        }
        return entry.value.every((a) => a.status == AyahStatus.memorized);
      }).length;

      // Read pages & reading stats
      final readPages = _progressDs.getReadPages();
      final readPagesCount = readPages.length;

      // Calculate read-only stats: pages read means those ayahs were read
      // Reading juz = pages read / 20 (each juz ~20 pages)
      final readJuz = (readPagesCount / 20).floor().clamp(
        0,
        AppConstants.totalJuz,
      );

      // Reading stats are derived from pages explicitly confirmed as read.
      final readAyahKeys = <String>{};
      final readSurahIds = <int>{};

      for (final page in readPages) {
        try {
          final ayahs = await _quranDs.getAyahsByPage(page);
          for (final ayah in ayahs) {
            readAyahKeys.add('${ayah.surahId}_${ayah.numberInSurah}');
            readSurahIds.add(ayah.surahId);
          }
        } catch (_) {
          // Ignore a stale page entry rather than failing the whole progress page.
        }
      }

      final readSurahs = readSurahIds.length;
      final readAyahs = readAyahKeys.length;

      // BUG-6 FIX: Accurate memorizedJuz — check each juz individually
      // instead of dividing total memorized ayahs by average juz size.
      final memorizedKeys = allProgress
          .where((p) => p.status == AyahStatus.memorized)
          .map((p) => '${p.surahId}_${p.ayahNumber}')
          .toSet();

      int memorizedJuz = 0;
      try {
        final ayahsByJuz = await _quranDs.getAyahsGroupedByJuz();
        for (int juz = 1; juz <= AppConstants.totalJuz; juz++) {
          final juzAyahs = ayahsByJuz[juz];
          if (juzAyahs != null &&
              juzAyahs.isNotEmpty &&
              juzAyahs.every(
                (a) =>
                    memorizedKeys.contains('${a.surahId}_${a.numberInSurah}'),
              )) {
            memorizedJuz++;
          }
        }
      } catch (_) {
        // Fallback to approximate calculation if juz data unavailable
        memorizedJuz =
            (memorizedAyahs / (AppConstants.totalAyahs / AppConstants.totalJuz))
                .floor()
                .clamp(0, AppConstants.totalJuz);
      }

      final streak = _progressDs.getStreakDays();
      final lastActive = _progressDs.getLastActiveDate();

      // Update streak using UTC-normalized today to avoid timezone boundary bugs.
      final today = DateTime.now().toUtc();
      final updatedStreak = _calculateStreak(streak, lastActive, today);
      if (updatedStreak != streak) {
        await _progressDs.saveStreak(updatedStreak, today);
      }

      final achievements = _buildAchievements(
        memorizedAyahs: memorizedAyahs,
        memorizedSurahs: memorizedSurahs,
        memorizedJuz: memorizedJuz,
        streak: updatedStreak,
        readPages: readPagesCount,
        readAyahs: readAyahs,
        learningAyahs: learningAyahs,
        reviewAyahs: reviewAyahs,
      );

      // Smart memorization system data
      final memPlusRecords = await _memPlusDs.getAllReviewRecords();
      final smartMemorizedAyahs = memPlusRecords
          .where((r) => r.strengthLevel >= 6)
          .length;
      final smartReviewAyahs = memPlusRecords
          .where((r) => r.strengthLevel < 6 && r.strengthLevel > 0)
          .length;

      final kidsProgress = await _memPlusDs.getKidsProgress();

      return Right(
        OverallProgress(
          memorizedAyahs: memorizedAyahs,
          totalAyahs: AppConstants.totalAyahs,
          memorizedSurahs: memorizedSurahs,
          totalSurahs: AppConstants.totalSurahs,
          memorizedJuz: memorizedJuz,
          totalJuz: AppConstants.totalJuz,
          readAyahs: readAyahs,
          readSurahs: readSurahs,
          readJuz: readJuz,
          learningAyahs: learningAyahs,
          reviewAyahs: reviewAyahs,
          streakDays: updatedStreak,
          lastActiveDate: lastActive,
          achievements: achievements,
          readPagesCount: readPagesCount,
          totalQuranPages: 604,
          smartMemorizedAyahs: smartMemorizedAyahs,
          smartReviewAyahs: smartReviewAyahs,
          kidsPoints: kidsProgress.totalPoints,
          kidsStars: kidsProgress.starsEarned,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveReadPage(int pageNumber) async {
    try {
      await _progressDs.saveReadPage(pageNumber);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateStreak() async {
    try {
      final streak = _progressDs.getStreakDays();
      final lastActive = _progressDs.getLastActiveDate();
      // UTC-normalized: consistent with getOverallProgress() and StreakService.
      final now = DateTime.now().toUtc();
      final updated = _calculateStreak(streak, lastActive, now);
      await _progressDs.saveStreak(updated, now);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  int _calculateStreak(int current, DateTime? lastActive, DateTime now) {
    if (lastActive == null) return 1;
    // Compare on UTC date components to avoid DST-ambiguous local midnight.
    final lastDate = DateTime.utc(
      lastActive.toUtc().year,
      lastActive.toUtc().month,
      lastActive.toUtc().day,
    );
    final nowDate = DateTime.utc(now.year, now.month, now.day);
    final diff = nowDate.difference(lastDate).inDays;
    if (diff == 0) return current; // Same day
    if (diff == 1) return current + 1; // Consecutive day
    return 1; // Streak broken
  }

  List<Achievement> _buildAchievements({
    required int memorizedAyahs,
    required int memorizedSurahs,
    required int memorizedJuz,
    required int streak,
    required int readPages,
    required int readAyahs,
    required int learningAyahs,
    required int reviewAyahs,
  }) {
    return [
      // ─── Reading Achievements ───────────────────────────────────────
      Achievement(
        id: 'first_page',
        titleKey: 'الصفحة الأولى',
        descriptionKey: 'اقرأ أول صفحة من القرآن',
        icon: '📖',
        isUnlocked: readPages >= 1,
        category: AchievementCategory.reading,
        currentValue: readPages.clamp(0, 1),
        targetValue: 1,
      ),
      Achievement(
        id: 'ten_pages',
        titleKey: '١٠ صفحات',
        descriptionKey: 'اقرأ ١٠ صفحات من القرآن',
        icon: '📚',
        isUnlocked: readPages >= 10,
        category: AchievementCategory.reading,
        currentValue: readPages.clamp(0, 10),
        targetValue: 10,
      ),
      Achievement(
        id: 'fifty_pages',
        titleKey: '٥٠ صفحة',
        descriptionKey: 'اقرأ ٥٠ صفحة من القرآن',
        icon: '🌟',
        isUnlocked: readPages >= 50,
        category: AchievementCategory.reading,
        currentValue: readPages.clamp(0, 50),
        targetValue: 50,
      ),
      Achievement(
        id: 'juz_read',
        titleKey: 'جزء كامل',
        descriptionKey: 'اقرأ جزءاً كاملاً (٢٠ صفحة)',
        icon: '✨',
        isUnlocked: readPages >= 20,
        category: AchievementCategory.reading,
        currentValue: readPages.clamp(0, 20),
        targetValue: 20,
      ),
      Achievement(
        id: 'five_juz_read',
        titleKey: '٥ أجزاء',
        descriptionKey: 'اقرأ ٥ أجزاء من القرآن',
        icon: '🌙',
        isUnlocked: readPages >= 100,
        category: AchievementCategory.reading,
        currentValue: readPages.clamp(0, 100),
        targetValue: 100,
      ),
      Achievement(
        id: 'half_quran_read',
        titleKey: 'نصف القرآن',
        descriptionKey: 'اقرأ نصف القرآن الكريم',
        icon: '🏆',
        isUnlocked: readPages >= 302,
        category: AchievementCategory.reading,
        currentValue: readPages.clamp(0, 302),
        targetValue: 302,
      ),
      Achievement(
        id: 'full_quran_read',
        titleKey: 'ختم القرآن',
        descriptionKey: 'اقرأ القرآن الكريم كاملاً',
        icon: '👑',
        isUnlocked: readPages >= 604,
        category: AchievementCategory.reading,
        currentValue: readPages.clamp(0, 604),
        targetValue: 604,
      ),

      // ─── Memorization Achievements ──────────────────────────────────
      Achievement(
        id: 'first_ayah',
        titleKey: 'أول آية',
        descriptionKey: 'احفظ أول آية من القرآن',
        icon: '⭐',
        isUnlocked: memorizedAyahs >= 1,
        category: AchievementCategory.memorization,
        currentValue: memorizedAyahs.clamp(0, 1),
        targetValue: 1,
      ),
      Achievement(
        id: 'ten_ayahs',
        titleKey: '١٠ آيات',
        descriptionKey: 'احفظ ١٠ آيات',
        icon: '🌟',
        isUnlocked: memorizedAyahs >= 10,
        category: AchievementCategory.memorization,
        currentValue: memorizedAyahs.clamp(0, 10),
        targetValue: 10,
      ),
      Achievement(
        id: 'fifty_ayahs',
        titleKey: '٥٠ آية',
        descriptionKey: 'احفظ ٥٠ آية',
        icon: '💫',
        isUnlocked: memorizedAyahs >= 50,
        category: AchievementCategory.memorization,
        currentValue: memorizedAyahs.clamp(0, 50),
        targetValue: 50,
      ),
      Achievement(
        id: 'hundred_ayahs',
        titleKey: '١٠٠ آية',
        descriptionKey: 'احفظ ١٠٠ آية',
        icon: '🔥',
        isUnlocked: memorizedAyahs >= 100,
        category: AchievementCategory.memorization,
        currentValue: memorizedAyahs.clamp(0, 100),
        targetValue: 100,
      ),
      Achievement(
        id: 'first_surah',
        titleKey: 'أول سورة',
        descriptionKey: 'احفظ سورة كاملة',
        icon: '📜',
        isUnlocked: memorizedSurahs >= 1,
        category: AchievementCategory.memorization,
        currentValue: memorizedSurahs.clamp(0, 1),
        targetValue: 1,
      ),
      Achievement(
        id: 'five_surahs',
        titleKey: '٥ سور',
        descriptionKey: 'احفظ ٥ سور كاملة',
        icon: '🎯',
        isUnlocked: memorizedSurahs >= 5,
        category: AchievementCategory.memorization,
        currentValue: memorizedSurahs.clamp(0, 5),
        targetValue: 5,
      ),
      Achievement(
        id: 'ten_surahs',
        titleKey: '١٠ سور',
        descriptionKey: 'احفظ ١٠ سور كاملة',
        icon: '🏅',
        isUnlocked: memorizedSurahs >= 10,
        category: AchievementCategory.memorization,
        currentValue: memorizedSurahs.clamp(0, 10),
        targetValue: 10,
      ),
      Achievement(
        id: 'juz_amma',
        titleKey: 'جزء عمّ',
        descriptionKey: 'احفظ ٥٦٤ آية (جزء عمّ)',
        icon: '🌙',
        isUnlocked: memorizedAyahs >= 564,
        category: AchievementCategory.memorization,
        currentValue: memorizedAyahs.clamp(0, 564),
        targetValue: 564,
      ),
      Achievement(
        id: 'one_juz_memorized',
        titleKey: 'جزء محفوظ',
        descriptionKey: 'احفظ جزءاً كاملاً',
        icon: '📗',
        isUnlocked: memorizedJuz >= 1,
        category: AchievementCategory.memorization,
        currentValue: memorizedJuz.clamp(0, 1),
        targetValue: 1,
      ),
      Achievement(
        id: 'five_juz_memorized',
        titleKey: '٥ أجزاء محفوظة',
        descriptionKey: 'احفظ ٥ أجزاء من القرآن',
        icon: '💎',
        isUnlocked: memorizedJuz >= 5,
        category: AchievementCategory.memorization,
        currentValue: memorizedJuz.clamp(0, 5),
        targetValue: 5,
      ),
      Achievement(
        id: 'ten_juz_memorized',
        titleKey: '١٠ أجزاء',
        descriptionKey: 'احفظ ١٠ أجزاء من القرآن',
        icon: '🎖️',
        isUnlocked: memorizedJuz >= 10,
        category: AchievementCategory.memorization,
        currentValue: memorizedJuz.clamp(0, 10),
        targetValue: 10,
      ),
      Achievement(
        id: 'half_quran_memorized',
        titleKey: 'نصف القرآن',
        descriptionKey: 'احفظ نصف القرآن الكريم',
        icon: '🏆',
        isUnlocked: memorizedJuz >= 15,
        category: AchievementCategory.memorization,
        currentValue: memorizedJuz.clamp(0, 15),
        targetValue: 15,
      ),
      Achievement(
        id: 'full_quran_memorized',
        titleKey: 'حافظ القرآن',
        descriptionKey: 'احفظ القرآن الكريم كاملاً',
        icon: '👑',
        isUnlocked: memorizedAyahs >= AppConstants.totalAyahs,
        category: AchievementCategory.memorization,
        currentValue: memorizedAyahs.clamp(0, AppConstants.totalAyahs),
        targetValue: AppConstants.totalAyahs,
      ),

      // ─── Streak Achievements ────────────────────────────────────────
      Achievement(
        id: 'three_day_streak',
        titleKey: '٣ أيام متتالية',
        descriptionKey: 'حافظ على ٣ أيام متتالية',
        icon: '🔥',
        isUnlocked: streak >= 3,
        category: AchievementCategory.streak,
        currentValue: streak.clamp(0, 3),
        targetValue: 3,
      ),
      Achievement(
        id: 'week_streak',
        titleKey: 'أسبوع كامل',
        descriptionKey: 'حافظ على ٧ أيام متتالية',
        icon: '💪',
        isUnlocked: streak >= 7,
        category: AchievementCategory.streak,
        currentValue: streak.clamp(0, 7),
        targetValue: 7,
      ),
      Achievement(
        id: 'two_week_streak',
        titleKey: 'أسبوعان',
        descriptionKey: 'حافظ على ١٤ يوماً متتالية',
        icon: '⚡',
        isUnlocked: streak >= 14,
        category: AchievementCategory.streak,
        currentValue: streak.clamp(0, 14),
        targetValue: 14,
      ),
      Achievement(
        id: 'month_streak',
        titleKey: 'شهر كامل',
        descriptionKey: 'حافظ على ٣٠ يوماً متتالية',
        icon: '💎',
        isUnlocked: streak >= 30,
        category: AchievementCategory.streak,
        currentValue: streak.clamp(0, 30),
        targetValue: 30,
      ),
      Achievement(
        id: 'ninety_day_streak',
        titleKey: '٩٠ يوماً',
        descriptionKey: 'حافظ على ٩٠ يوماً متتالية',
        icon: '🌟',
        isUnlocked: streak >= 90,
        category: AchievementCategory.streak,
        currentValue: streak.clamp(0, 90),
        targetValue: 90,
      ),
      Achievement(
        id: 'year_streak',
        titleKey: 'سنة كاملة',
        descriptionKey: 'حافظ على ٣٦٥ يوماً متتالياً',
        icon: '👑',
        isUnlocked: streak >= 365,
        category: AchievementCategory.streak,
        currentValue: streak.clamp(0, 365),
        targetValue: 365,
      ),
    ];
  }
}
