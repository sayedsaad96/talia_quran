import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../../../features/progress/domain/usecases/save_read_page_usecase.dart';

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
  const QuranPageLoaded(this.detail, {this.isReadConfirmed = false});
  @override
  List<Object?> get props => [detail, isReadConfirmed];
}
class QuranPageError extends QuranPageState {
  final String message;
  const QuranPageError(this.message);
  @override
  List<Object?> get props => [message];
}

class QuranPageCubit extends Cubit<QuranPageState> {
  QuranPageCubit(this._repository, this._saveReadPage) : super(QuranPageInitial());

  final QuranRepository _repository;
  final SaveReadPageUsecase _saveReadPage;

  Future<void> loadPage(int pageNumber) async {
    emit(QuranPageLoading());
    // No longer auto-saving reading progress here
    final result = await _repository.getQuranPage(pageNumber);
    result.fold(
      (f) => emit(QuranPageError(f.message)),
      (detail) => emit(QuranPageLoaded(detail)),
    );
  }

  /// Called after the user has spent enough time on the page
  /// to confirm they actually read it.
  Future<void> confirmRead(int pageNumber) async {
    await _saveReadPage(pageNumber);
    if (state is QuranPageLoaded) {
      final loaded = state as QuranPageLoaded;
      emit(QuranPageLoaded(loaded.detail, isReadConfirmed: true));
    }
  }
}
