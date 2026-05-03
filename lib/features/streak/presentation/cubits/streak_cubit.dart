import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/streak_result.dart';
import '../../../../core/services/streak_service.dart';

part 'streak_state.dart';

class StreakCubit extends Cubit<StreakState> {
  StreakCubit(this._streakService) : super(const StreakInitial());

  final StreakService _streakService;

  Future<void> loadStreak() async {
    try {
      final entity = await _streakService.getStreak();
      emit(StreakLoaded(streak: entity));
    } catch (e) {
      emit(StreakError(e.toString()));
    }
  }

  Future<StreakResult> recordActivity() async {
    try {
      final result = await _streakService.recordActivity();
      if (result.isNewActivity) {
        final entity = await _streakService.getStreak();
        emit(StreakLoaded(streak: entity));
      }
      return result;
    } catch (e) {
      emit(StreakError(e.toString()));
      return const StreakResult.sameDay();
    }
  }

  Future<void> useFreeze() async {
    await _streakService.useFreeze();
    await loadStreak();
  }
}
