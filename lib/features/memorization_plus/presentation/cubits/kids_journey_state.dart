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
    this.qrPayload,
    this.message,
    this.isCreatingLink = false,
  });

  final int surahId;
  final List<KidsJourneyStage> stages;
  final KidsProgress progress;
  final String? qrPayload;
  final String? message;
  final bool isCreatingLink;

  KidsJourneyStage? get currentStage {
    for (final stage in stages) {
      if (stage.status == KidsJourneyStageStatus.current) return stage;
    }
    return stages.isEmpty ? null : stages.last;
  }

  KidsJourneyLoaded copyWith({
    List<KidsJourneyStage>? stages,
    KidsProgress? progress,
    String? qrPayload,
    bool clearQrPayload = false,
    String? message,
    bool clearMessage = false,
    bool? isCreatingLink,
  }) => KidsJourneyLoaded(
    surahId: surahId,
    stages: stages ?? this.stages,
    progress: progress ?? this.progress,
    qrPayload: clearQrPayload ? null : (qrPayload ?? this.qrPayload),
    message: clearMessage ? null : (message ?? this.message),
    isCreatingLink: isCreatingLink ?? this.isCreatingLink,
  );

  @override
  List<Object?> get props => [
    surahId,
    stages,
    progress,
    qrPayload,
    message,
    isCreatingLink,
  ];
}
