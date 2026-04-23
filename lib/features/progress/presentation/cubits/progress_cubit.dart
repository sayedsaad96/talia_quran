import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/progress_entities.dart';
import '../../domain/usecases/get_progress_usecase.dart';

part 'progress_state.dart';

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit(this._getProgress) : super(const ProgressInitial());
  final GetProgressUsecase _getProgress;

  Future<void> load() async {
    emit(const ProgressLoading());
    final result = await _getProgress();
    result.fold(
      (f) => emit(ProgressError(f.message)),
      (progress) => emit(ProgressLoaded(progress: progress)),
    );
  }
}
