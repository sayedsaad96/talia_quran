part of 'track_selection_cubit.dart';

@immutable
abstract class TrackSelectionState extends Equatable {
  const TrackSelectionState();
  @override
  List<Object?> get props => [];
}

class TrackSelectionInitial extends TrackSelectionState {
  const TrackSelectionInitial();
}

class TrackSelectionSaving extends TrackSelectionState {
  const TrackSelectionSaving();
}

class TrackSelectionLoaded extends TrackSelectionState {
  const TrackSelectionLoaded({required this.profile});
  final MemorizationProfile profile;

  MemorizationTrack? get track => profile.legacyTrack;
  bool get hasTrack => profile.hasSelectedPath;
  bool get needsPathSelection => !profile.hasSelectedPath;
  bool get needsGuardianOnboarding => profile.needsGuardianOnboarding;

  @override
  List<Object?> get props => [profile];
}

class TrackSelectionNeedsPath extends TrackSelectionState {
  const TrackSelectionNeedsPath();
}

class TrackSelectionAdultReady extends TrackSelectionState {
  const TrackSelectionAdultReady({required this.profile});
  final MemorizationProfile profile;

  @override
  List<Object?> get props => [profile];
}

class TrackSelectionGuardianOnboardingRequired extends TrackSelectionState {
  const TrackSelectionGuardianOnboardingRequired({required this.profile});
  final MemorizationProfile profile;

  @override
  List<Object?> get props => [profile];
}

class TrackSelectionChildReady extends TrackSelectionState {
  const TrackSelectionChildReady({required this.profile});
  final MemorizationProfile profile;

  @override
  List<Object?> get props => [profile];
}

class TrackSelectionLegacyLoaded extends TrackSelectionState {
  const TrackSelectionLegacyLoaded({required this.track});
  final MemorizationTrack? track;

  bool get hasTrack => track != null;

  @override
  List<Object?> get props => [track];
}

class TrackSelectionError extends TrackSelectionState {
  const TrackSelectionError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
