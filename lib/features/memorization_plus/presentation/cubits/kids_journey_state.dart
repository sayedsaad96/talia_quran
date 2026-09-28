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

  KidsJourneyStage? get currentStage {
    for (final stage in stages) {
      if (stage.status == KidsJourneyStageStatus.needsReview) return stage;
    }
    for (final stage in stages) {
      if (stage.status == KidsJourneyStageStatus.current) return stage;
    }
    return null;
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
  ];
}
