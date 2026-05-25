import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

part 'track_selection_state.dart';

class TrackSelectionCubit extends Cubit<TrackSelectionState> {
  TrackSelectionCubit(this._repository) : super(const TrackSelectionInitial());
  final MemorizationPlusRepository _repository;

  Future<void> load() async {
    final result = await _repository.getMemorizationProfile();
    result.fold((f) => emit(TrackSelectionError(f.message)), _emitProfileState);
  }

  Future<void> selectTrack(MemorizationTrack track) async {
    final path = track == MemorizationTrack.kids
        ? MemorizationPath.child
        : MemorizationPath.adult;
    await selectPath(path);
  }

  Future<void> selectPath(MemorizationPath path) async {
    emit(const TrackSelectionSaving());
    final result = await _repository.selectMemorizationPath(path);
    result.fold((f) => emit(TrackSelectionError(f.message)), _emitProfileState);
  }

  Future<void> refreshChildGuardianLink() async {
    final result = await _repository.refreshChildGuardianLink();
    result.fold((f) => emit(TrackSelectionError(f.message)), _emitProfileState);
  }

  void _emitProfileState(MemorizationProfile profile) {
    emit(TrackSelectionLoaded(profile: profile));
    if (!profile.hasSelectedPath) {
      emit(const TrackSelectionNeedsPath());
    } else if (profile.isAdult) {
      emit(TrackSelectionAdultReady(profile: profile));
    } else if (profile.needsGuardianOnboarding) {
      emit(TrackSelectionGuardianOnboardingRequired(profile: profile));
    } else {
      emit(TrackSelectionChildReady(profile: profile));
    }
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

