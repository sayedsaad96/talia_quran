import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/navigation/kids_next_mission_resolver.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

part 'kids_journey_state.dart';

typedef KidsReviewRecordsLoader = Future<List<AyahReviewRecord>> Function();
typedef KidsResumeMissionLoader = Future<KidsNextMission?> Function();

class KidsJourneyCubit extends Cubit<KidsJourneyState> {
  KidsJourneyCubit(
    this._getJourney,
    this._getKidsProgress,
    this._quranRepository, {
    KidsReviewRecordsLoader? reviewRecordsLoader,
    KidsResumeMissionLoader? resumeMissionLoader,
    KidsNextMissionResolver missionResolver = const KidsNextMissionResolver(),
    bool v2Enabled = true,
  }) : _reviewRecordsLoader = reviewRecordsLoader,
       _resumeMissionLoader = resumeMissionLoader,
       _missionResolver = missionResolver,
       _v2Enabled = v2Enabled,
       super(const KidsJourneyInitial());

  final GetKidsJourneyUsecase _getJourney;
  final GetKidsProgressUsecase _getKidsProgress;
  final QuranRepository _quranRepository;
  final KidsReviewRecordsLoader? _reviewRecordsLoader;
  final KidsResumeMissionLoader? _resumeMissionLoader;
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
    final nextMission = _v2Enabled
        ? _missionResolver.resolve(
            activeSurahId: surahId,
            stages: stages,
            resumableMission: resumableMission,
            reviewRecords: reviewRecords,
            now: DateTime.now().toUtc(),
          )
        : _legacyMission(stages);

    emit(
      KidsJourneyLoaded(
        surahId: surahId,
        stages: stages,
        progress: progressResult.getOrElse(() => const KidsProgress.initial()),
        surahName: surahName,
        nextMission: nextMission,
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
}
