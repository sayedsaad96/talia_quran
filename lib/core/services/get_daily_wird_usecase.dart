import '../../features/khatmah/domain/entities/khatmah_plan.dart';
import '../../features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import '../../features/memorization_plus/domain/entities/custom_memorization_plan.dart';
import '../../features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../features/progress/data/datasources/progress_local_datasource.dart';
import '../../features/quran/domain/usecases/get_surahs_usecase.dart';
import 'app_session_service.dart';

/// Resolves today's personal wird page from the user's own journey.
class GetDailyWirdUsecase {
  const GetDailyWirdUsecase({
    required this.sessionService,
    required this.getCustomPlan,
    required this.readPages,
    required this.getSurahs,
    this.getActiveKhatmah,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const lastPage = 604;

  final GetActiveKhatmahUsecase? getActiveKhatmah;
  final AppSessionService sessionService;
  final GetCustomPlanUsecase getCustomPlan;
  final ProgressLocalDatasource readPages;
  final GetSurahsUsecase getSurahs;
  final DateTime Function() _now;

  Future<int> call() async {
    final today = _now();
    try {
      final plan = await getActiveKhatmah?.call();
      if (plan != null && plan.status == KhatmahStatus.active) {
        return _clamp(plan.dailyTargetFor(today).startPage);
      }
    } catch (_) {}

    final savedTarget = sessionService.getDailyWirdTarget(today);
    if (savedTarget != null) return savedTarget;

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

    final pages = readPages.getReadPages();
    if (pages.isNotEmpty) {
      var highest = pages.first;
      for (final page in pages) {
        if (page > highest) highest = page;
      }
      return _clamp(highest + 1);
    }

    return 1;
  }

  int _clamp(int page) {
    if (page < 1) return 1;
    if (page > lastPage) return lastPage;
    return page;
  }
}
