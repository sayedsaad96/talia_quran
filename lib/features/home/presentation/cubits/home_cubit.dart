import 'dart:async';
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../progress/domain/entities/progress_entities.dart';
import '../../../progress/domain/usecases/get_progress_usecase.dart';
import '../../../hifz/domain/usecases/get_hifz_progress_usecase.dart';
import '../../../hifz/domain/entities/hifz_entities.dart';
import '../../../quran/domain/usecases/get_surahs_usecase.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/memorization/smart_coach_recommendation.dart';
import '../../../../core/memorization/usecases/get_smart_coach_recommendation_usecase.dart';
import '../../../../core/services/app_session_service.dart';
import '../../domain/usecases/get_activity_heatmap_usecase.dart';
import '../../../../core/journey/unified_journey_action.dart';
import '../../../../core/journey/unified_journey_engine.dart';
import '../../../../core/journey/unified_journey_input.dart';
import '../../../memorization_plus/domain/services/memorization_insights_aggregator.dart';
import '../../../../core/utils/talia_logger.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetProgressUsecase _getProgress;
  final GetHifzProgressUsecase _getHifzProgress;
  final GetQuranPageUsecase _getQuranPage;
  final GetCustomPlanUsecase _getCustomPlan;
  final MemorizationPlusRepository _memorizationRepository;
  final AppSessionService _sessionService;
  final GetActivityHeatmapUsecase _getHeatmap;
  final MemorizationPathResolver _pathResolver;
  final GetSmartCoachRecommendationUsecase _getCoachRecommendation;
  final UnifiedJourneyEngine _journeyEngine;
  final SharedPreferences _prefs;
  late final StreamSubscription<void> _pathChangesSub;

  HomeCubit(
    this._getProgress,
    this._getHifzProgress,
    this._getQuranPage,
    this._getCustomPlan,
    this._memorizationRepository,
    this._sessionService,
    this._getHeatmap,
    this._pathResolver,
    this._getCoachRecommendation,
    this._journeyEngine,
    this._prefs,
  ) : super(const HomeInitial()) {
    _pathChangesSub = _pathResolver.changes.listen((_) {
      if (!isClosed) {
        unawaited(load());
      }
    });
  }

  Future<void> load() async {
    emit(const HomeLoading());

    final now = DateTime.now();
    // Use date-based seed to ensure the random page stays the same for the whole day
    final today = DateTime(now.year, now.month, now.day);
    final random = Random(today.millisecondsSinceEpoch);
    final pageNumber = random.nextInt(604) + 1;

    final progressFuture = _getProgress();
    final hifzFuture = _getHifzProgress();
    final quranPageFuture = _getQuranPage(pageNumber);
    final planFuture = _getCustomPlan();
    final heatmapFuture = _getHeatmap();
    final coachFuture = _getCoachRecommendation();

    final progressResult = await progressFuture;
    final hifzResult = await hifzFuture;
    final quranPageResult = await quranPageFuture;
    QuranPageDetail? dailyWirdDetail;
    quranPageResult.fold((l) => null, (r) => dailyWirdDetail = r);

    CustomMemorizationPlan? customPlan;
    final planResult = await planFuture;
    planResult.fold((l) => null, (plan) => customPlan = plan);
    final heatmap = await heatmapFuture;
    SmartCoachRecommendation? coachRecommendation;
    final coachResult = await coachFuture;
    coachResult.fold((_) => null, (r) => coachRecommendation = r);

    // Load last restorable location for "Continue Reading" chip
    final lastLocation = _sessionService.getLastRestorableLocation();

    // T-03 FIX: Load the authoritative memorization profile async instead of
    // the legacy synchronous getSelectedTrack() / getIsParentMode() reads.
    // This ensures HomeCubit always reflects the latest path configuration.
    final profileResult = await _memorizationRepository
        .getMemorizationProfile();
    final profile = profileResult.fold((_) => null, (p) => p);
    final selectedTrack = profile?.selectedPath == MemorizationPath.child
        ? MemorizationTrack.kids
        : profile?.selectedPath == MemorizationPath.adult
        ? MemorizationTrack.adults
        : null;
    final isParentMode = profile?.isParentGuardian ?? false;
    final isKids = profile?.isChild ?? false;

    // P1-05 FIX: Guard against emitting after the cubit was closed during the
    // 7 awaits above. Emitting on a closed cubit throws a StateError.
    if (isClosed) return;
    // Sprint C: Unified Journey Hero Action Evaluation
    UnifiedJourneyAction? heroAction;
    try {
      heroAction = await _evaluateUnifiedAction(
        lastLocation: lastLocation,
        coachRecommendation: coachRecommendation,
        customPlan: customPlan,
        dailyWirdDetail: dailyWirdDetail,
        isKids: isKids,
      );
    } catch (e, s) {
      TaliaLogger.w('Failed to evaluate hero action', e, s);
      // Swallow errors to ensure Home still loads even if engine fails
    }

    if (isClosed) return;
    progressResult.fold((f) => emit(HomeError(f.message)), (progress) {
      final hifzProgress = hifzResult.getOrElse(() => []);
      emit(
        HomeLoaded(
          progress: progress,
          hifzSurahProgress: hifzProgress,
          greeting: _greeting(),
          dailyWirdPageDetail: dailyWirdDetail,
          customPlan: customPlan,
          selectedTrack: selectedTrack,
          isParentMode: isParentMode,
          isKids: isKids,
          lastRestorableLocation: lastLocation,
          activityCountsByDay: heatmap.countsByDay,
          activityStartDate: heatmap.startDate,
          coachRecommendation: coachRecommendation,
          heroAction: heroAction,
        ),
      );
    });
  }

  Future<UnifiedJourneyAction?> _evaluateUnifiedAction({
    required String? lastLocation,
    required SmartCoachRecommendation? coachRecommendation,
    required CustomMemorizationPlan? customPlan,
    required QuranPageDetail? dailyWirdDetail,
    required bool isKids,
  }) async {
    try {
      final isEnabled = _prefs.getBool('unified_journey_enabled') ?? true;
      if (!isEnabled) {
        return null;
      }

      final recordsResult = await _memorizationRepository.getAllReviewRecords();
      final records = recordsResult.getOrElse(() => []);
      
      const aggregator = MemorizationInsightsAggregator();
      final insights = aggregator.generate(records, DateTime.now());
      
      const adaptiveUsecase = AdaptiveRecommendationsUsecase();
      final adaptiveReport = adaptiveUsecase.generate(insights);
      
      final criticals = adaptiveReport.recommendations
          .where((r) => (r.priority == RecommendationPriority.critical || r.priority == RecommendationPriority.high) && r.type != RecommendationType.reviewBacklog)
          .toList();
      final backlogs = adaptiveReport.recommendations
          .where((r) => r.type == RecommendationType.reviewBacklog)
          .toList();

      final input = UnifiedJourneyInput(
        lastRestorableLocation: lastLocation,
        hasCriticalLearningAlert: criticals.isNotEmpty,
        learningAlertTitle: criticals.isNotEmpty ? criticals.first.title : null,
        learningAlertDescription: criticals.isNotEmpty ? criticals.first.description : null,
        hasReviewBacklog: backlogs.isNotEmpty,
        overdueAyahs: insights.dueAyahs,
        hasSmartPlan: coachRecommendation != null || customPlan != null,
        isSmartPlanReview: coachRecommendation != null &&
            (coachRecommendation.kind == SmartCoachRecommendationKind.reviewDueNear ||
                coachRecommendation.kind == SmartCoachRecommendationKind.reviewDueFar ||
                coachRecommendation.kind == SmartCoachRecommendationKind.memorizedReviewDue ||
                coachRecommendation.kind == SmartCoachRecommendationKind.reviewWeakAyah ||
                coachRecommendation.kind == SmartCoachRecommendationKind.hifzReviewDue),
        smartPlanTitle: customPlan != null ? 'Custom Plan' : 'Smart Coach',
        smartPlanRoute: coachRecommendation?.route ?? (customPlan != null ? '/memorization' : null),
        hasDailyWird: dailyWirdDetail != null,
        dailyWirdPageNumber: dailyWirdDetail?.pageNumber,
        isKids: isKids,
        userGoal: _prefs.getString('user_primary_goal'),
      );

      final unifiedAction = _journeyEngine.evaluate(input);
      return unifiedAction;
    } catch (e, s) {
      TaliaLogger.w('Failed to evaluate UnifiedJourneyEngine input', e, s);
      // Swallow errors in shadow mode
      return null;
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  @override
  Future<void> close() async {
    await _pathChangesSub.cancel();
    return super.close();
  }
}
