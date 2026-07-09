import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/streak_result.dart';
import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../../../core/services/streak_service.dart';

part 'streak_state.dart';

class StreakCubit extends Cubit<StreakState> {
  StreakCubit(this._streakService, this._progressEvents)
    : super(const StreakInitial()) {
    _progressChangesSub = _progressEvents.changes.listen((reason) {
      if (reason == ProgressChangedReason.streak ||
          reason == ProgressChangedReason.cloudPull) {
        if (!isClosed) {
          unawaited(loadStreak());
        }
      }
    });
  }

  final StreakService _streakService;
  final ProgressEventsBus _progressEvents;
  late final StreamSubscription<ProgressChangedReason> _progressChangesSub;

  Future<void> loadStreak() async {
    try {
      final entity = await _streakService.getStreak();
      if (!isClosed) {
        emit(StreakLoaded(streak: entity));
      }
    } catch (e) {
      if (!isClosed) {
        emit(StreakError(e.toString()));
      }
    }
  }

  Future<StreakResult> recordActivity() async {
    try {
      final result = await _streakService.recordActivity();
      if (result.isNewActivity) {
        final entity = await _streakService.getStreak();
        if (!isClosed) {
          emit(StreakLoaded(streak: entity));
        }
      }
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(StreakError(e.toString()));
      }
      return const StreakResult.sameDay();
    }
  }

  Future<void> useFreeze() async {
    await _streakService.useFreeze();
    await loadStreak();
  }

  @override
  Future<void> close() async {
    await _progressChangesSub.cancel();
    return super.close();
  }
}
