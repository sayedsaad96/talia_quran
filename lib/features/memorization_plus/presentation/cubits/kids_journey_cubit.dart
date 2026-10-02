import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/navigation/kids_next_mission_resolver.dart';
import '../../domain/services/kids_adventure_regions.dart';
import '../../domain/services/kids_daily_budget.dart';
import '../../domain/services/kids_daily_missions.dart';
import '../../domain/services/kids_return_policy.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

part 'kids_journey_state.dart';

typedef KidsReviewRecordsLoader = Future<List<AyahReviewRecord>> Function();
typedef KidsResumeMissionLoader = Future<KidsNextMission?> Function();

/// Reads the local kids session log for today's mission budget.
/// Optional: when unavailable (or throwing) the budget is not enforced.
typedef KidsJourneySessionLogsLoader = Future<List<KidsSessionLog>?> Function();

/// Today's confirmed Mushaf pages for the reading mission. When absent (or
/// throwing) the reading mission is omitted.
typedef KidsReadingPagesLoader = Future<Set<int>> Function();

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
    KidsReadingPagesLoader? readingPagesLoader,
    KidsJourneyPolicyLoader? policyLoader,
    KidsNextMissionResolver missionResolver = const KidsNextMissionResolver(),
    bool v2Enabled = true,
  }) : _reviewRecordsLoader = reviewRecordsLoader,
       _resumeMissionLoader = resumeMissionLoader,
       _sessionLogsLoader = sessionLogsLoader,
       _readingPagesLoader = readingPagesLoader,
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
  final KidsReadingPagesLoader? _readingPagesLoader;
  final KidsJourneyPolicyLoader? _policyLoader;
  final KidsNextMissionResolver _missionResolver;
  final bool _v2Enabled;

  /// Loads [surahId]'s journey. With [followFrontier] (the kids home) a
  /// fully memorized surah hands over to the surah where the journey really
  /// continues, so the home map, Mushaf and card move on with the child
  /// instead of staying on the surah the route was opened with (K20). The
  /// map keeps the surah it was opened for.
  Future<void> load({required int surahId, bool followFrontier = false}) async {
    emit(const KidsJourneyLoading());
    var activeSurahId = surahId;
    var journeyResult = await _getJourney(
      GetKidsJourneyParams(surahId: surahId),
    );
    if (followFrontier && _v2Enabled) {
      final frontier = (await _missionResolver.findContinuation(
        activeSurahId: surahId,
        stages: journeyResult.getOrElse(() => const <KidsJourneyStage>[]),
        loadStages: _loadStages,
      ))?.mission;
      if (frontier != null && frontier.surahId != surahId) {
        final frontierResult = await _getJourney(
          GetKidsJourneyParams(surahId: frontier.surahId),
        );
        if (frontierResult.isRight()) {
          activeSurahId = frontier.surahId;
          journeyResult = frontierResult;
        }
      }
    }
    final progressResult = await _getKidsProgress();

    final failure =
        journeyResult.fold((f) => f, (_) => null) ??
        progressResult.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(KidsJourneyError(failure.message));
      return;
    }

    // Fetch surah name — gracefully falls back to null on failure
    final surahName = await _surahName(activeSurahId);

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
    final logs = await _loadSessionLogs();
    final budget = _v2Enabled
        ? await _loadDailyBudget(logs)
        : KidsDailyBudget.unlimited;
    final continuation = _v2Enabled
        ? await _missionResolver.findContinuation(
            activeSurahId: activeSurahId,
            stages: stages,
            loadStages: _loadStages,
          )
        : null;
    final now = DateTime.now().toUtc();
    KidsNextMission? resolveWith(KidsDailyBudget budget) =>
        _missionResolver.resolve(
          activeSurahId: activeSurahId,
          stages: stages,
          resumableMission: resumableMission,
          reviewRecords: reviewRecords,
          now: now,
          budget: budget,
          continuation: continuation,
        );
    final nextMission = _v2Enabled
        ? resolveWith(budget)
        : _legacyMission(stages);
    final missionSurahId = nextMission?.surahId;
    final dailyGoalCap = _missionResolver.dailyGoalCap(
      mission: nextMission,
      budget: budget,
      resolveWith: resolveWith,
    );
    final dailyMissions = followFrontier
        ? await _resolveDailyMissions(
            learning: nextMission,
            dayGoalReached: dailyGoalCap != null,
            logs: logs ?? const <KidsSessionLog>[],
          )
        : const <KidsDailyMission>[];

    emit(
      KidsJourneyLoaded(
        surahId: activeSurahId,
        stages: stages,
        progress: progressResult.getOrElse(() => const KidsProgress.initial()),
        surahName: surahName,
        nextMission: nextMission,
        dailyGoalCap: dailyGoalCap,
        dailyMissions: dailyMissions,
        currentRegion: await _currentRegion(activeSurahId, logs),
        missionSurahName:
            missionSurahId == null || missionSurahId == activeSurahId
            ? null
            : await _surahName(missionSurahId),
        isReturningAfterBreak: kidsIsReturningAfterBreak(
          progressResult.fold((_) => null, (p) => p.lastSessionAt),
          DateTime.now(),
        ),
      ),
    );
  }

  /// A surah's display name, or null — a label never blocks the journey.
  Future<String?> _surahName(int surahId) async {
    try {
      final result = await _quranRepository.getSurahDetail(surahId);
      return result.fold<String?>((_) => null, (detail) => detail.surah.nameAr);
    } catch (_) {
      return null;
    }
  }

  /// Region progress for [surahId]. Null off the kids path or when the logs or
  /// the surah list cannot be read: a label never blocks the journey.
  Future<KidsRegionProgress?> _currentRegion(
    int surahId,
    List<KidsSessionLog>? logs,
  ) async {
    if (logs == null) return null;
    try {
      final region = kidsRegionOf(surahId);
      final surahs = (await _quranRepository.getSurahs()).fold<List<Surah>?>(
        (_) => null,
        (list) => list,
      );
      if (surahs == null) return null;
      final memorized = kidsMemorizedSurahIds(logs, {
        for (final surah in surahs) surah.id: surah.ayahCount,
      });
      return kidsRegionProgress(memorized).firstWhere(
        (progress) => progress.region.id == region.id,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<KidsJourneyStage>?> _loadStages(int surahId) async {
    final result = await _getJourney(GetKidsJourneyParams(surahId: surahId));
    return result.fold((_) => null, (stages) => stages);
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

  Future<List<KidsSessionLog>?> _loadSessionLogs() async {
    try {
      return await _sessionLogsLoader?.call();
    } catch (_) {
      return null;
    }
  }

  /// «مهماتي اليوم». Reading needs a working pages loader; without one (or on
  /// a read error) that card is omitted rather than shown wrongly.
  Future<List<KidsDailyMission>> _resolveDailyMissions({
    required KidsNextMission? learning,
    required bool dayGoalReached,
    required List<KidsSessionLog> logs,
  }) async {
    Set<int>? pages;
    try {
      pages = await _readingPagesLoader?.call();
    } catch (_) {
      pages = null;
    }
    final missions = resolveKidsDailyMissions(
      now: DateTime.now(),
      learning: learning,
      dayGoalReached: dayGoalReached,
      logs: logs,
      pagesReadToday: pages ?? const <int>{},
    );
    if (pages != null) return missions;
    return missions
        .where((m) => m.kind != KidsDailyMissionKind.reading)
        .toList(growable: false);
  }

  /// Today's age-band budget from the local session log. Each part fails
  /// open independently so a storage glitch can never lock a child out of
  /// their mission pipeline.
  Future<KidsDailyBudget> _loadDailyBudget(List<KidsSessionLog>? logs) async {
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
