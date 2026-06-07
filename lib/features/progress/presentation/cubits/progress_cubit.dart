import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../domain/entities/progress_entities.dart';
import '../../domain/usecases/get_progress_usecase.dart';

part 'progress_state.dart';

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit(this._getProgress, this._pathResolver)
    : super(const ProgressInitial()) {
    _pathChangesSub = _pathResolver.changes.listen((_) {
      if (!isClosed) {
        unawaited(load());
      }
    });
  }

  final GetProgressUsecase _getProgress;
  final MemorizationPathResolver _pathResolver;
  late final StreamSubscription<void> _pathChangesSub;

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
    await _pathChangesSub.cancel();
    return super.close();
  }
}
