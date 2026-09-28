import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/navigation/kids_next_mission_resolver.dart';
import '../../domain/services/kids_daily_budget.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

part 'kids_journey_state.dart';

typedef KidsReviewRecordsLoader = Future<List<AyahReviewRecord>> Function();
typedef KidsResumeMissionLoader = Future<KidsNextMission?> Function();

/// Reads the local kids session log for today's mission budget.
/// Optional: when unavailable (or throwing) the budget is not enforced.
typedef KidsJourneySessionLogsLoader = Future<List<KidsSessionLog>?> Function();

/// Loads the age-band policy that owns the daily mission caps.
typedef KidsJourneyPolicyLoader = Future<KidsSessionPolicy> Function();

class KidsJourneyCubit extends Cubit<KidsJourneyState> {
  KidsJourneyCubit(
    this._getJourney,
    this._getKidsProgress,
    this._quranRepository, {
    KidsReviewRecordsLoader? reviewRecordsLoader,
    KidsResumeMissionLoader? resumeMissionLoader,
    KidsJourneySessionLogsLoader? sessionLogsLoader,
    KidsJourneyPolicyLoader? policyLoader,
    KidsNextMissionResolver missionResolver = const KidsNextMissionResolver(),
    bool v2Enabled = true,
  }) : _reviewRecordsLoader = reviewRecordsLoader,
       _resumeMissionLoader = resumeMissionLoader,
       _sessionLogsLoader = sessionLogsLoader,
       _policyLoader = policyLoader,
       _missionResolver = missionResolver,
       _v2Enabled = v2Enabled,
       super(const KidsJourneyInitial());

  final GetKidsJourneyUsecase _getJourney;
  final GetKidsProgressUsecase _getKidsProgress;
  final QuranRepository _quranRepository;
  final KidsReviewRecordsLoader? _reviewRecordsLoader;
  final KidsResumeMissionLoader? _resumeMissionLoader;
  final KidsJourneySessionLogsLoader? _sessionLogsLoader;
  final KidsJourneyPolicyLoader? _policyLoader;
  final KidsNextMissionResolver _missionResolver;
  final bool _v2Enabled;

  Future<void> load({required int surahId}) async {
    emit(const KidsJourneyLoading());
    final journeyResult = await _getJourney(
      GetKidsJourneyParams(surahId: surahId),
    );
    final progressResult = await _getKidsProgress();

    final failure =
        journeyResult.fold((f) => f, (_) => null) ??
        progressResult.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(KidsJourneyError(failure.message));
      return;
    }

    // Fetch surah name — gracefully falls back to null on failure
    String? surahName;
    final surahResult = await _quranRepository.getSurahDetail(surahId);
    surahResult.fold((_) => null, (detail) => surahName = detail.surah.nameAr);

    final stages = journeyResult.getOrElse(() => const <KidsJourneyStage>[]);
    var reviewRecords = const <AyahReviewRecord>[];
    try {
      reviewRecords = await _reviewRecordsLoader?.call() ?? const [];
    } catch (_) {
      // Mission resolution still falls back to the journey when SRS is unreadable.
    }
    KidsNextMission? resumableMission;
    if (_v2Enabled) {
      try {
        resumableMission = await _resumeMissionLoader?.call();
      } catch (_) {
        // A corrupt or unavailable resume row must not block today's mission.
      }
    }
    final budget = _v2Enabled
        ? await _loadDailyBudget()
        : KidsDailyBudget.unlimited;
    final nextMission = _v2Enabled
        ? _missionResolver.resolve(
            activeSurahId: surahId,
            stages: stages,
            resumableMission: resumableMission,
            reviewRecords: reviewRecords,
            now: DateTime.now().toUtc(),
            budget: budget,
          )
        : _legacyMission(stages);

    emit(
      KidsJourneyLoaded(
        surahId: surahId,
        stages: stages,
        progress: progressResult.getOrElse(() => const KidsProgress.initial()),
        surahName: surahName,
        nextMission: nextMission,
        dailyGoalCap: nextMission == null && budget.newAyahLimitReached
            ? budget.maxNewAyahsPerDay
            : null,
      ),
    );
  }

  static KidsNextMission? _legacyMission(List<KidsJourneyStage> stages) {
    for (final stage in stages) {
      if (stage.status == KidsJourneyStageStatus.current) {
        return KidsNextMission(
          type: KidsMissionType.newMemorization,
          surahId: stage.surahId,
          ayahNumbers: [stage.nextAyahToStart],
        );
      }
    }
    return null;
  }

  /// Today's age-band budget from the local session log. Each part fails
  /// open independently so a storage glitch can never lock a child out of
  /// their mission pipeline.
  Future<KidsDailyBudget> _loadDailyBudget() async {
    List<KidsSessionLog>? logs;
    try {
      logs = await _sessionLogsLoader?.call();
    } catch (_) {
      logs = null;
    }
    KidsSessionPolicy? policy;
    try {
      policy = await _policyLoader?.call();
    } catch (_) {
      policy = null;
    }
    if (logs == null) return KidsDailyBudget.unlimited;
    return KidsDailyBudget.fromLogs(
      logs: logs,
      policy: policy,
      now: DateTime.now(),
    );
  }
}
