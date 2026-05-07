import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../../../features/progress/domain/usecases/save_read_page_usecase.dart';
import '../../../../core/services/streak_service.dart';

abstract class QuranPageState extends Equatable {
  const QuranPageState();
  @override
  List<Object?> get props => [];
}

class QuranPageInitial extends QuranPageState {}

class QuranPageLoading extends QuranPageState {}

class QuranPageLoaded extends QuranPageState {
  final QuranPageDetail detail;
  final bool isReadConfirmed;
  final String? readConfirmationError;
  const QuranPageLoaded(
    this.detail, {
    this.isReadConfirmed = false,
    this.readConfirmationError,
  });
  @override
  List<Object?> get props => [detail, isReadConfirmed, readConfirmationError];
}

class QuranPageError extends QuranPageState {
  final String message;
  const QuranPageError(this.message);
  @override
  List<Object?> get props => [message];
}

class QuranPageCubit extends Cubit<QuranPageState> {
  // BUG-NEW-001 FIX: Added StreakService so reading also updates the streak
  QuranPageCubit(this._repository, this._saveReadPage, this._streakService)
    : super(QuranPageInitial());

  final QuranRepository _repository;
  final SaveReadPageUsecase _saveReadPage;
  final StreakService _streakService; // BUG-NEW-001 FIX

  Future<void> loadPage(int pageNumber) async {
    emit(QuranPageLoading());
    final result = await _repository.getQuranPage(pageNumber);
    result.fold(
      (f) => emit(QuranPageError(f.message)),
      (detail) => emit(QuranPageLoaded(detail)),
    );
  }

  /// Called after the user has spent enough time on the page
  /// to confirm they actually read it.
  Future<void> confirmRead(int pageNumber) async {
    if (state is! QuranPageLoaded) return;
    final loaded = state as QuranPageLoaded;
    if (loaded.isReadConfirmed) return;

    final saveResult = await _saveReadPage(pageNumber);
    final failure = saveResult.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(
        QuranPageLoaded(loaded.detail, readConfirmationError: failure.message),
      );
      return;
    }

    // BUG-NEW-001 FIX: Record activity in the unified StreakService (Isar-based)
    // so that reading the Quran counts towards the streak, not just Hifz sessions.
    try {
      await _streakService.recordActivity();
    } catch (_) {
      // Non-critical — don't crash the page if streak update fails
    }

    emit(QuranPageLoaded(loaded.detail, isReadConfirmed: true));
  }
}
