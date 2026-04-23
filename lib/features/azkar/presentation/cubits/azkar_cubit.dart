import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/azkar_entities.dart';
import '../../domain/usecases/get_azkar_usecase.dart';

part 'azkar_state.dart';

class AzkarCubit extends Cubit<AzkarState> {
  AzkarCubit(this._getAzkar) : super(const AzkarInitial());
  final GetAzkarUsecase _getAzkar;

  Future<void> load(AzkarCategory category) async {
    emit(const AzkarLoading());
    final result = await _getAzkar(category);
    result.fold(
      (f) => emit(AzkarError(f.message)),
      (azkar) {
        final sessions = azkar
            .map((z) => ZikrSession(zikr: z, currentCount: 0, isDone: false))
            .toList();
        emit(AzkarLoaded(
          category: category,
          sessions: sessions,
          currentIndex: 0,
        ));
      },
    );
  }

  void increment() {
    final state = this.state;
    if (state is! AzkarLoaded) return;

    final sessions = List<ZikrSession>.from(state.sessions);
    final idx = state.currentIndex;
    sessions[idx] = sessions[idx].increment();

    final allDone = sessions.every((s) => s.isDone);
    emit(state.copyWith(sessions: sessions, allDone: allDone));
  }

  void reset() {
    final state = this.state;
    if (state is! AzkarLoaded) return;
    final sessions =
        state.sessions.map((s) => s.reset()).toList();
    emit(state.copyWith(sessions: sessions, allDone: false));
  }

  void goTo(int index) {
    final state = this.state;
    if (state is! AzkarLoaded) return;
    emit(state.copyWith(currentIndex: index));
  }

  void goNext() {
    final state = this.state;
    if (state is! AzkarLoaded) return;
    if (state.currentIndex < state.sessions.length - 1) {
      emit(state.copyWith(currentIndex: state.currentIndex + 1));
    }
  }
}
