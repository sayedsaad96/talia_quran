import '../../features/memorization_plus/domain/entities/custom_memorization_plan.dart';
import '../../features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../features/progress/data/datasources/progress_local_datasource.dart';
import '../../features/quran/domain/usecases/get_surahs_usecase.dart';
import 'app_session_service.dart';

/// Resolves today's personal wird page from the user's own reading journey.
///
/// This usecase is intentionally isolated from the Khatmah feature.
/// The daily wird is an independent daily habit that runs regardless of whether
/// the user has an active khatmah plan. Neither should affect the other.
class GetDailyWirdUsecase {
  const GetDailyWirdUsecase({
    required this.sessionService,
    required this.getCustomPlan,
    required this.readPages,
    required this.getSurahs,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const lastPage = 604;

  final AppSessionService sessionService;
  final GetCustomPlanUsecase getCustomPlan;
  final ProgressLocalDatasource readPages;
  final GetSurahsUsecase getSurahs;
  final DateTime Function() _now;

  Future<int> call() async {
    final today = _now();

    // 1. If today's wird target was already decided, reuse it.
    final savedTarget = sessionService.getDailyWirdTarget(today);
    if (savedTarget != null) return savedTarget;

    // 2. Compute from the user's own wird progress.
    final candidate = await _resolveOrdinaryTarget();
    try {
      await sessionService.saveDailyWirdTarget(candidate, today);
    } catch (_) {
      // Persistence may be temporarily blocked during an account transition.
      // The calculated target is still safe to use for this render.
    }
    return candidate;
  }

  Future<int> _resolveOrdinaryTarget() async {
    // 2a. If the user completed a wird before, continue from the next page.
    final lastCompleted = sessionService.getDailyWirdLastCompletedPage();
    if (lastCompleted != null) {
      return _clamp(lastCompleted + 1);
    }

    // 2b. If a custom memorization plan is active, start from its surah.
    final planResult = await getCustomPlan();
    final customPlan = planResult.fold((_) => null, (plan) => plan);
    if (customPlan is CustomMemorizationPlan) {
      final surahsResult = await getSurahs();
      final surahs = surahsResult.fold((_) => const [], (list) => list);
      for (final surah in surahs) {
        if (surah.id == customPlan.startSurahId) {
          return _clamp(surah.page);
        }
      }
    }

    // 2c. Continue from the highest page the user has ever read.
    final pages = readPages.getReadPages();
    if (pages.isNotEmpty) {
      var highest = pages.first;
      for (final page in pages) {
        if (page > highest) highest = page;
      }
      return _clamp(highest + 1);
    }

    // 2d. New user — start from the beginning.
    return 1;
  }

  int _clamp(int page) {
    if (page < 1) return 1;
    if (page > lastPage) return lastPage;
    return page;
  }
}
