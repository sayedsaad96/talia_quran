part of 'track_selection_cubit.dart';

abstract class TrackSelectionState extends Equatable {
  const TrackSelectionState();
  @override
  List<Object?> get props => [];
}

class TrackSelectionInitial extends TrackSelectionState {
  const TrackSelectionInitial();
}

class TrackSelectionLoaded extends TrackSelectionState {
  const TrackSelectionLoaded({required this.track});
  final MemorizationTrack? track;

  bool get hasTrack => track != null;

  @override
  List<Object?> get props => [track];
}
