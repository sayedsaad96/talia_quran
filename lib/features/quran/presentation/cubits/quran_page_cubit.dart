import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/streak_service.dart';
import '../../../../features/progress/domain/usecases/save_read_page_usecase.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/repositories/quran_repository.dart';

abstract class QuranPageState extends Equatable {
  const QuranPageState();
  @override
  List<Object?> get props => [];
}

class QuranPageInitial extends QuranPageState {}

class QuranPageLoading extends QuranPageState {}

class QuranPageLoaded extends QuranPageState {
  const QuranPageLoaded(
    this.detail, {
    this.isReadConfirmed = false,
    this.readConfirmationError,
  });
  final QuranPageDetail detail;
  final bool isReadConfirmed;
  final String? readConfirmationError;
  @override
  List<Object?> get props => [detail, isReadConfirmed, readConfirmationError];
}

class QuranPageError extends QuranPageState {
  const QuranPageError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class QuranPageCubit extends Cubit<QuranPageState> {
  QuranPageCubit(this._repository, this._saveReadPage, this._streakService)
    : super(QuranPageInitial());

  final QuranRepository _repository;
  final SaveReadPageUsecase _saveReadPage;
  final StreakService _streakService;

  Future<void> loadPage(int pageNumber) async {
    emit(QuranPageLoading());
    final result = await _repository.getQuranPage(pageNumber);
    result.fold(
      (failure) => emit(QuranPageError(failure.message)),
      (detail) => emit(QuranPageLoaded(detail)),
    );
  }

  /// Confirms ordinary Quran reading. Khatmah progress is intentionally owned
  /// by KhatmahCubit after this method returns true.
  Future<bool> confirmRead(int pageNumber) async {
    final current = state;
    if (current is! QuranPageLoaded) return false;
    if (current.isReadConfirmed) return true;

    final saveResult = await _saveReadPage(pageNumber);
    final failure = saveResult.fold((failure) => failure, (_) => null);
    if (failure != null) {
      emit(
        QuranPageLoaded(current.detail, readConfirmationError: failure.message),
      );
      return false;
    }

    try {
      await _streakService.recordActivity();
    } catch (_) {
      // Streak recording is supplementary and must not invalidate reading.
    }
    emit(QuranPageLoaded(current.detail, isReadConfirmed: true));
    return true;
  }
}
