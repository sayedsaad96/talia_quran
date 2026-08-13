import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/memorization/surah_path_ordering.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/usecases/get_surahs_usecase.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

part 'practice_surah_state.dart';

/// Loads the adult practice-by-surah list from Memorization Plus identity.
class PracticeSurahCubit extends Cubit<PracticeSurahState> {
  PracticeSurahCubit(
    this._getSurahs,
    this._memorizationRepository,
  ) : super(const PracticeSurahInitial());

  final GetSurahsUsecase _getSurahs;
  final MemorizationPlusRepository _memorizationRepository;

  Future<void> load() async {
    emit(const PracticeSurahLoading());
    final surahsResult = await _getSurahs();
    final profileResult = await _memorizationRepository.getMemorizationProfile();

    surahsResult.fold((f) => emit(PracticeSurahError(f.message)), (surahs) {
      final profile = profileResult.fold((_) => null, (profile) => profile);
      final effectivePath = profile?.hifzPathValue;
      final sortedSurahs = sortSurahsForPracticePath(
        surahs: surahs,
        path: effectivePath,
      );

      emit(
        PracticeSurahLoaded(
          surahs: sortedSurahs,
          selectedPath: effectivePath,
        ),
      );
    });
  }
}