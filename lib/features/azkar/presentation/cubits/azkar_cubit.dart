import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/azkar_entities.dart';
import '../../domain/usecases/get_azkar_usecase.dart';

part 'azkar_state.dart';

class AzkarCubit extends Cubit<AzkarState> {
  AzkarCubit(this._getAzkar, this._prefs) : super(const AzkarInitial());
  final GetAzkarUsecase _getAzkar;
  final SharedPreferences _prefs;

  static const _counterPrefix = 'azkar_counter_';
  static const _datePrefix = 'azkar_date_';

  Future<void> load(AzkarCategory category) async {
    emit(const AzkarLoading());
    final result = await _getAzkar(category);
    result.fold((f) => emit(AzkarError(f.message)), (azkar) {
      final savedDate = _prefs.getString('$_datePrefix${category.name}');
      final todayStr = _todayKey();
      final isToday = savedDate == todayStr;

      final sessions = azkar.map((z) {
        final savedCount = isToday
            ? (_prefs.getInt('$_counterPrefix${category.name}_${z.id}') ?? 0)
            : 0;
        final count = savedCount.clamp(0, z.totalCount);
        return ZikrSession(
          zikr: z,
          currentCount: count,
          isDone: count >= z.totalCount,
        );
      }).toList();

      // Update date stamp if starting fresh
      if (!isToday) {
        _prefs.setString('$_datePrefix${category.name}', todayStr);
      }

      final allDone = sessions.isNotEmpty && sessions.every((s) => s.isDone);
      emit(
        AzkarLoaded(
          category: category,
          sessions: sessions,
          currentIndex: 0,
          allDone: allDone,
        ),
      );
    });
  }

  void increment() async {
    final state = this.state;
    if (state is! AzkarLoaded) return;
    if (state.sessions.isEmpty) return;

    final sessions = List<ZikrSession>.from(state.sessions);
    final idx = state.currentIndex;

    if (sessions[idx].isDone) return;

    sessions[idx] = sessions[idx].increment();

    // Persist the updated counter
    final session = sessions[idx];
    await _prefs.setInt(
      '$_counterPrefix${state.category.name}_${session.zikr.id}',
      session.currentCount,
    );
    await _prefs.setString('$_datePrefix${state.category.name}', _todayKey());

    final allDone = sessions.every((s) => s.isDone);
    emit(state.copyWith(sessions: sessions, allDone: allDone));

    // Automatically navigate to the next unfinished zikr
    if (session.isDone && !allDone) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (isClosed) return;
      final latestState = this.state;
      if (latestState is AzkarLoaded && latestState.currentIndex == idx) {
        int nextIndex = latestState.sessions.indexWhere(
          (s) => !s.isDone,
          idx + 1,
        );
        if (nextIndex == -1) {
          nextIndex = latestState.sessions.indexWhere((s) => !s.isDone);
        }
        if (nextIndex != -1) {
          emit(latestState.copyWith(currentIndex: nextIndex));
        }
      }
    }
  }

  void reset() {
    final state = this.state;
    if (state is! AzkarLoaded) return;
    final sessions = state.sessions.map((s) => s.reset()).toList();

    // Clear persisted counters for this category
    for (final s in state.sessions) {
      _prefs.remove('$_counterPrefix${state.category.name}_${s.zikr.id}');
    }

    emit(state.copyWith(sessions: sessions, allDone: false));
  }

  Future<void> decrementCurrent() async {
    final state = this.state;
    if (state is! AzkarLoaded) return;
    if (state.sessions.isEmpty) return;

    final sessions = List<ZikrSession>.from(state.sessions);
    final idx = state.currentIndex;
    if (sessions[idx].currentCount <= 0) return;

    sessions[idx] = sessions[idx].decrement();
    final session = sessions[idx];
    await _prefs.setInt(
      '$_counterPrefix${state.category.name}_${session.zikr.id}',
      session.currentCount,
    );
    await _prefs.setString('$_datePrefix${state.category.name}', _todayKey());

    emit(state.copyWith(sessions: sessions, allDone: false));
  }

  void goTo(int index) {
    final state = this.state;
    if (state is! AzkarLoaded) return;
    if (index < 0 || index >= state.sessions.length) return;
    emit(state.copyWith(currentIndex: index));
  }

  void goNext() {
    final state = this.state;
    if (state is! AzkarLoaded) return;
    if (state.currentIndex < state.sessions.length - 1) {
      emit(state.copyWith(currentIndex: state.currentIndex + 1));
    }
  }

  void goNextUnfinished() {
    final state = this.state;
    if (state is! AzkarLoaded) return;

    int nextIndex = state.sessions.indexWhere(
      (s) => !s.isDone,
      state.currentIndex + 1,
    );
    if (nextIndex == -1) {
      nextIndex = state.sessions.indexWhere((s) => !s.isDone);
    }
    if (nextIndex != -1 && nextIndex != state.currentIndex) {
      emit(state.copyWith(currentIndex: nextIndex));
    } else if (state.currentIndex < state.sessions.length - 1) {
      emit(state.copyWith(currentIndex: state.currentIndex + 1));
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
