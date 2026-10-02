part of 'kids_journey_cubit.dart';

@immutable
abstract class KidsJourneyState extends Equatable {
  const KidsJourneyState();

  @override
  List<Object?> get props => [];
}

class KidsJourneyInitial extends KidsJourneyState {
  const KidsJourneyInitial();
}

class KidsJourneyLoading extends KidsJourneyState {
  const KidsJourneyLoading();
}

class KidsJourneyError extends KidsJourneyState {
  const KidsJourneyError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class KidsJourneyLoaded extends KidsJourneyState {
  const KidsJourneyLoaded({
    required this.surahId,
    required this.stages,
    required this.progress,
    this.surahName,
    this.nextMission,
    this.qrPayload,
    this.message,
    this.isCreatingLink = false,
    this.dailyGoalCap,
    this.missionSurahName,
    this.isReturningAfterBreak = false,
    this.dailyMissions = const [],
    this.currentRegion,
  });

  final int surahId;
  final List<KidsJourneyStage> stages;
  final KidsProgress progress;
  final String? surahName;
  final KidsNextMission? nextMission;
  final String? qrPayload;
  final String? message;
  final bool isCreatingLink;

  /// Today's new-ayah quota when it is used up and nothing else is pending;
  /// null otherwise. Home then shows the "day complete" card instead of a
  /// mission the session gate would refuse (N3).
  final int? dailyGoalCap;

  bool get dailyGoalReached => dailyGoalCap != null;

  /// Name of [nextMission]'s surah when it is not [surahId] (a due review
  /// elsewhere), so the card never shows a bare surah number (K20).
  final String? missionSurahName;

  /// K33 — back after three or more days: home greets the child warmly.
  final bool isReturningAfterBreak;

  /// «مهماتي اليوم»: learning, then reading. Only the kids home computes it.
  final List<KidsDailyMission> dailyMissions;

  /// Region progress of [surahId]; null when off the kids path or unreadable.
  final KidsRegionProgress? currentRegion;

  KidsJourneyStage? get currentStage {
    for (final stage in stages) {
      if (stage.status == KidsJourneyStageStatus.needsReview) return stage;
    }
    for (final stage in stages) {
      if (stage.status == KidsJourneyStageStatus.current) return stage;
    }
    return null;
  }

  /// The stage the mission card describes: the one [nextMission] actually
  /// opens. Once the review budget is spent a "needs review" stage may still
  /// be [currentStage] while the mission is new memorization in a later
  /// stage (K19). A mission in another surah has no stage here.
  KidsJourneyStage? get missionStage {
    final mission = nextMission;
    if (mission == null) return currentStage;
    for (final stage in stages) {
      if (stage.surahId == mission.surahId &&
          mission.startAyah >= stage.startAyah &&
          mission.startAyah <= stage.endAyah) {
        return stage;
      }
    }
    return mission.surahId == surahId ? currentStage : null;
  }

  KidsJourneyLoaded copyWith({
    List<KidsJourneyStage>? stages,
    KidsProgress? progress,
    String? surahName,
    bool clearSurahName = false,
    KidsNextMission? nextMission,
    bool clearNextMission = false,
    String? qrPayload,
    bool clearQrPayload = false,
    String? message,
    bool clearMessage = false,
    bool? isCreatingLink,
    int? dailyGoalCap,
    bool clearDailyGoalCap = false,
    String? missionSurahName,
    bool? isReturningAfterBreak,
    List<KidsDailyMission>? dailyMissions,
    KidsRegionProgress? currentRegion,
    bool clearCurrentRegion = false,
  }) => KidsJourneyLoaded(
    surahId: surahId,
    stages: stages ?? this.stages,
    progress: progress ?? this.progress,
    surahName: clearSurahName ? null : (surahName ?? this.surahName),
    nextMission: clearNextMission ? null : (nextMission ?? this.nextMission),
    qrPayload: clearQrPayload ? null : (qrPayload ?? this.qrPayload),
    message: clearMessage ? null : (message ?? this.message),
    isCreatingLink: isCreatingLink ?? this.isCreatingLink,
    dailyGoalCap: clearDailyGoalCap
        ? null
        : (dailyGoalCap ?? this.dailyGoalCap),
    missionSurahName: missionSurahName ?? this.missionSurahName,
    isReturningAfterBreak: isReturningAfterBreak ?? this.isReturningAfterBreak,
    dailyMissions: dailyMissions ?? this.dailyMissions,
    currentRegion: clearCurrentRegion
        ? null
        : (currentRegion ?? this.currentRegion),
  );

  @override
  List<Object?> get props => [
    surahId,
    stages,
    progress,
    surahName,
    nextMission,
    qrPayload,
    message,
    isCreatingLink,
    dailyGoalCap,
    missionSurahName,
    isReturningAfterBreak,
    dailyMissions,
    currentRegion,
  ];
}
