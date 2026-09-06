import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../domain/entities/progress_entities.dart';
import '../../domain/usecases/get_progress_usecase.dart';

part 'progress_state.dart';

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit(
    this._getProgress,
    this._pathResolver,
    this._progressEvents,
  ) : super(const ProgressInitial()) {
    _pathChangesSub = _pathResolver.changes.listen((_) {
      if (!isClosed) {
        _scheduleReload();
      }
    });
    _progressChangesSub = _progressEvents.changes.listen(_onProgressChanged);
  }

  final GetProgressUsecase _getProgress;
  final MemorizationPathResolver _pathResolver;
  final ProgressEventsBus _progressEvents;
  late final StreamSubscription<void> _pathChangesSub;
  late final StreamSubscription<ProgressChangedReason> _progressChangesSub;
  Timer? _reloadDebounce;

  void _onProgressChanged(ProgressChangedReason reason) {
    if (!ProgressEventsBus.affectsProgressTab(reason)) return;
    _scheduleReload();
  }

  void _scheduleReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!isClosed) {
        unawaited(load());
      }
    });
  }

  Future<void> load() async {
    emit(const ProgressLoading());
    final profileFuture = _pathResolver.currentProfile();
    final result = await _getProgress();
    final profile = await profileFuture;
    result.fold(
      (f) => emit(ProgressError(f.message)),
      (progress) => emit(
        ProgressLoaded(
          progress: progress,
          selectedPath: profile?.selectedPath,
          isKids: _pathResolver.isKids(profile),
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    _reloadDebounce?.cancel();
    await _pathChangesSub.cancel();
    await _progressChangesSub.cancel();
    return super.close();
  }
}
