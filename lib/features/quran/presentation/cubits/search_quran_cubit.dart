import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/repositories/quran_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

abstract class SearchQuranState extends Equatable {
  const SearchQuranState();
  @override
  List<Object?> get props => [];
}

class SearchQuranInitial extends SearchQuranState {
  const SearchQuranInitial();
}

class SearchQuranLoading extends SearchQuranState {
  const SearchQuranLoading();
}

class SearchQuranLoaded extends SearchQuranState {
  const SearchQuranLoaded({required this.results, required this.query});
  final List<Ayah> results;
  final String query;

  @override
  List<Object?> get props => [results, query];
}

class SearchQuranError extends SearchQuranState {
  const SearchQuranError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class SearchQuranCubit extends Cubit<SearchQuranState> {
  SearchQuranCubit(this._repository) : super(const SearchQuranInitial());

  final QuranRepository _repository;
  Timer? _debounce;

  /// Debounced search — waits 400ms after the user stops typing.
  void search(String query) {
    _debounce?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      emit(const SearchQuranInitial());
      return;
    }

    // Show loading immediately for UX feedback
    emit(const SearchQuranLoading());

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final result = await _repository.searchAyahs(trimmed);
      result.fold(
        (failure) => emit(SearchQuranError(failure.message)),
        (ayahs) => emit(SearchQuranLoaded(results: ayahs, query: trimmed)),
      );
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    emit(const SearchQuranInitial());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
