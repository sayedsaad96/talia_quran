import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/streak_result.dart';
import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/utils/talia_logger.dart';

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
    } catch (e, s) {
      TaliaLogger.e('loadStreak failed', e, s);
      if (!isClosed) {
        emit(const StreakError(CubitMessageCodes.errorUnknown));
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
    } catch (e, s) {
      TaliaLogger.e('recordActivity failed', e, s);
      if (!isClosed) {
        emit(const StreakError(CubitMessageCodes.errorUnknown));
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
