import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

part 'track_selection_state.dart';

class TrackSelectionCubit extends Cubit<TrackSelectionState> {
  TrackSelectionCubit(this._repository) : super(const TrackSelectionInitial());
  final MemorizationPlusRepository _repository;

  void load() {
    final result = _repository.getSelectedTrack();
    result.fold(
      (f) => emit(TrackSelectionLoaded(track: null)),
      (track) => emit(TrackSelectionLoaded(track: track)),
    );
  }

  Future<void> selectTrack(MemorizationTrack track) async {
    final result = await _repository.saveSelectedTrack(track);
    result.fold(
      (_) {},
      (_) => emit(TrackSelectionLoaded(track: track)),
    );
  }
}
