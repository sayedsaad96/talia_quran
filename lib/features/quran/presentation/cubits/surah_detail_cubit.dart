import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/usecases/get_surahs_usecase.dart';

part 'surah_detail_state.dart';

class SurahDetailCubit extends Cubit<SurahDetailState> {
  SurahDetailCubit(this._getDetailUsecase) : super(const SurahDetailInitial());
  final GetSurahDetailUsecase _getDetailUsecase;

  Future<void> loadSurah(int surahId) async {
    emit(const SurahDetailLoading());
    final result = await _getDetailUsecase(surahId);
    result.fold(
      (f) => emit(SurahDetailError(f.message)),
      (detail) => emit(SurahDetailLoaded(detail: detail)),
    );
  }
}
