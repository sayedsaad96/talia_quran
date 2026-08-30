import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/memorization/progress_metrics.dart';
import '../../../../core/memorization/progress_metrics_service.dart';
import '../../../../core/memorization/quran_structure_maps.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../../../core/services/streak_reader.dart';
import '../../domain/entities/progress_entities.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_local_datasource.dart';

import '../../../../features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../quran/data/datasources/quran_local_datasource.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(
    this._progressDs,
    this._memPlusDs,
    this._quranDs,
    this._streakReader,
    this._progressEvents, [
    this._metrics = const ProgressMetricsService(),
  ]);
  final ProgressLocalDatasource _progressDs;
  final MemorizationPlusLocalDatasource _memPlusDs;
  final QuranLocalDatasource _quranDs;
  final StreakReader _streakReader;
  final ProgressEventsBus _progressEvents;
  final ProgressMetricsService _metrics;

  @override
  Future<Either<Failure, OverallProgress>> getOverallProgress() async {
    try {
      final profile = await _memPlusDs.getMemorizationProfile();
      final isChild = profile.selectedPath == MemorizationPath.child;
      final reviewScope = isChild
          ? ReviewRecordReadScope.kids
          : ReviewRecordReadScope.adult;
      final progressAudience = isChild
          ? ProgressAudience.kids
          : ProgressAudience.adult;

      final memPlusRecords = await _memPlusDs.getAllReviewRecords(
        scope: reviewScope,
      );

      final structure = await QuranStructureMaps.load(_quranDs);
      final surahAyahCounts = structure.surahAyahCounts;
      final ayahKeysByJuz = structure.ayahKeysByJuz;
      final readPages = _progressDs.getReadPages();
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
          // Ignore a stale page entry rather than failing the whole page.
        }
      }

      final streakEntity = await _streakReader.getStreak();

      // Single source of truth for every progress number.
      final metrics = _metrics.calculate(
        records: memPlusRecords,
        now: DateTime.now().toUtc(),
        audience: progressAudience,
        surahAyahCounts: surahAyahCounts,
        ayahKeysByJuz: ayahKeysByJuz,
        totalAyahs: AppConstants.totalAyahs,
        totalSurahs: AppConstants.totalSurahs,
        totalJuz: AppConstants.totalJuz,
        readPagesCount: readPages.length,
        totalQuranPages: 604,
        readAyahKeys: readAyahKeys,
        readSurahIds: readSurahIds,
        streakDays: streakEntity.currentStreak,
      );

      final achievements = _buildAchievements(
        memorizedAyahs: metrics.memorizedAyahs,
        memorizedSurahs: metrics.memorizedSurahs,
        memorizedJuz: metrics.memorizedJuz,
        streak: metrics.streakDays,
        readPages: metrics.readPagesCount,
        readAyahs: metrics.readAyahs,
        learningAyahs: metrics.learningAyahs,
        reviewAyahs: metrics.dueReviews,
      );

      final kidsProgress = await _memPlusDs.getKidsProgress();

      return Right(
        OverallProgress(
          memorizedAyahs: metrics.memorizedAyahs,
          startedAyahs: metrics.startedAyahs,
          reviewedAyahsTotal: metrics.totalReviewEvents,
          overdueReviews: metrics.overdueReviews,
          lastReviewedAt: metrics.lastReviewedAt,
          lastMemorizedSurahId: metrics.lastMemorizedSurahId,
          lastMemorizedAyahNumber: metrics.lastMemorizedAyahNumber,
          totalAyahs: AppConstants.totalAyahs,
          memorizedSurahs: metrics.memorizedSurahs,
          totalSurahs: AppConstants.totalSurahs,
          memorizedJuz: metrics.memorizedJuz,
          totalJuz: AppConstants.totalJuz,
          readAyahs: metrics.readAyahs,
          readSurahs: metrics.readSurahs,
          readJuz: metrics.readJuz,
          learningAyahs: metrics.learningAyahs,
          reviewAyahs: metrics.dueReviews,
          streakDays: metrics.streakDays,
          lastActiveDate: streakEntity.lastActivityDate,
          achievements: achievements,
          readPagesCount: metrics.readPagesCount,
          totalQuranPages: metrics.totalQuranPages,
          kidsPoints: kidsProgress.totalPoints,
          kidsStars: kidsProgress.starsEarned,
        ),
      );
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, void>> saveReadPage(int pageNumber) async {
    try {
      await _progressDs.saveReadPage(pageNumber);
      _progressEvents.notify(ProgressChangedReason.readPage);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
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
