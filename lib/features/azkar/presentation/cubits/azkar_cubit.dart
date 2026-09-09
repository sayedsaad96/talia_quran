import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/azkar_completion_store.dart';
import '../../domain/entities/azkar_entities.dart';
import '../../domain/usecases/get_azkar_usecase.dart';

part 'azkar_state.dart';

class AzkarCubit extends Cubit<AzkarState> {
  AzkarCubit(this._getAzkar, SharedPreferences prefs, [AzkarCompletionStore? store])
    : _store = store ?? AzkarCompletionStore(prefs),
      super(const AzkarInitial());
  final GetAzkarUsecase _getAzkar;
  final AzkarCompletionStore _store;
  Future<void> _mutationTail = Future<void>.value();

  Future<void> load(AzkarCategory category) async {
    emit(const AzkarLoading());
    final result = await _getAzkar(category);
    await result.fold<Future<void>>((f) async {
      if (!isClosed) emit(AzkarError(f.message));
    }, (azkar) async {
      await _store.prepareForToday(category);
      if (isClosed) return;

      final sessions = azkar.map((z) {
        final savedCount = _store.countFor(category, z.id);
        final count = savedCount.clamp(0, z.totalCount);
        return ZikrSession(
          zikr: z,
          currentCount: count,
          isDone: count >= z.totalCount,
        );
      }).toList();

      final allDone = sessions.isNotEmpty && sessions.every((s) => s.isDone);
      if (allDone) {
        await _store.setAllDone(category, true);
      }
      if (isClosed) return;
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

  /// Queues taps so each one observes the count produced by the previous tap.
  Future<void> increment() => _enqueueMutation(_increment);

  Future<void> _enqueueMutation(Future<void> Function() operation) {
    final result = _mutationTail.then((_) => operation());
    _mutationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> _increment() async {
    final state = this.state;
    if (state is! AzkarLoaded) return;
    if (state.sessions.isEmpty) return;

    // A page can stay open across midnight. Rebuild it from the new day's
    // cleared state before applying this tap, so yesterday's count is never
    // added to today's first count.
    if (!_store.isToday(state.category)) {
      await load(state.category);
      if (isClosed || this.state is! AzkarLoaded) return;
      return _increment();
    }

    final sessions = List<ZikrSession>.from(state.sessions);
    final idx = state.currentIndex;

    if (sessions[idx].isDone) return;

    sessions[idx] = sessions[idx].increment();

    final session = sessions[idx];
    await _store.setCount(
      category: state.category,
      zikrId: session.zikr.id,
      count: session.currentCount,
    );

    final allDone = sessions.every((s) => s.isDone);
    if (allDone) {
      await _store.setAllDone(state.category, true);
    }
    emit(state.copyWith(sessions: sessions, allDone: allDone));

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

  Future<void> reset() => _enqueueMutation(_reset);

  Future<void> _reset() async {
    final state = this.state;
    if (state is! AzkarLoaded) return;
    final sessions = state.sessions.map((s) => s.reset()).toList();

    await _store.clearCategory(state.category);
    if (isClosed) return;

    emit(state.copyWith(sessions: sessions, allDone: false));
  }

  Future<void> decrementCurrent() => _enqueueMutation(_decrementCurrent);

  Future<void> _decrementCurrent() async {
    final state = this.state;
    if (state is! AzkarLoaded) return;
    if (state.sessions.isEmpty) return;

    if (!_store.isToday(state.category)) {
      await load(state.category);
      return;
    }

    final sessions = List<ZikrSession>.from(state.sessions);
    final idx = state.currentIndex;
    if (sessions[idx].currentCount <= 0) return;

    sessions[idx] = sessions[idx].decrement();
    final session = sessions[idx];
    await _store.setCount(
      category: state.category,
      zikrId: session.zikr.id,
      count: session.currentCount,
    );
    await _store.setAllDone(state.category, false);

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
}
