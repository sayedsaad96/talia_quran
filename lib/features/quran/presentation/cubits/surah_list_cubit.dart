import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/usecases/get_surahs_usecase.dart';

part 'surah_list_state.dart';

class SurahListCubit extends Cubit<SurahListState> {
  SurahListCubit(this._getSurahsUsecase) : super(const SurahListInitial());
  final GetSurahsUsecase _getSurahsUsecase;

  List<Surah> _allSurahs = [];

  Future<void> loadSurahs() async {
    emit(const SurahListLoading());
    final result = await _getSurahsUsecase();
    result.fold((f) => emit(SurahListError(f.message)), (surahs) {
      _allSurahs = surahs;
      emit(SurahListLoaded(surahs: surahs, filtered: surahs));
    });
  }

  void search(String query) {
    final current = state;
    if (current is! SurahListLoaded) return;
    if (query.trim().isEmpty) {
      emit(current.copyWith(filtered: _allSurahs, query: ''));
      return;
    }
    final q = query.trim().toLowerCase();
    final filtered = _allSurahs.where((s) {
      return s.nameAr.contains(q) ||
          s.nameEn.toLowerCase().contains(q) ||
          s.id.toString() == q;
    }).toList();
    emit(current.copyWith(filtered: filtered, query: query));
  }

  void filterByJuz(int? juz) {
    final current = state;
    if (current is! SurahListLoaded) return;
    if (juz == null) {
      emit(current.copyWith(filtered: _allSurahs, selectedJuz: null));
      return;
    }
    final filtered = _allSurahs.where((s) => s.juz == juz).toList();
    emit(current.copyWith(filtered: filtered, selectedJuz: juz));
  }
}
