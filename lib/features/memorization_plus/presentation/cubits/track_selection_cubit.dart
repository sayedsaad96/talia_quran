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
      (f) => emit(TrackSelectionError(f.message)),
      (track) => emit(TrackSelectionLoaded(track: track)),
    );
  }

  Future<void> selectTrack(MemorizationTrack track) async {
    final result = await _repository.saveSelectedTrack(track);
    result.fold(
      (f) => emit(TrackSelectionError(f.message)),
      (_) => emit(TrackSelectionLoaded(track: track)),
    );
  }

  /// BUG-9 FIX: get the last reviewed surahId so navigation can resume from
  /// where the user left off instead of always starting from surah 1.
  Future<int> getLastActiveSurahId() async {
    final result = await _repository.getAllReviewRecords();
    final records = result.fold((_) => <AyahReviewRecord>[], (r) => r);
    if (records.isEmpty) return 1;
    // Find the surah with the most recent review (using correct field name)
    final sorted = [...records]
      ..sort((a, b) => b.lastReviewedAt.compareTo(a.lastReviewedAt));
    return sorted.first.surahId;
  }
}
