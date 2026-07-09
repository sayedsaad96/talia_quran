import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/usecases/get_surahs_usecase.dart';
import '../../domain/hifz_unlock_rules.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';

part 'hifz_state.dart';

class HifzCubit extends Cubit<HifzState> {
  HifzCubit(
    this._getSurahs,
    this._memorizationRepository,
    this._pathResolver,
  ) : super(const HifzInitial());

  final GetSurahsUsecase _getSurahs;
  final MemorizationPlusRepository _memorizationRepository;
  final MemorizationPathResolver _pathResolver;

  Future<void> load() async {
    emit(const HifzLoading());
    final surahsResult = await _getSurahs();
    final profileResult = await _memorizationRepository
        .getMemorizationProfile();

    surahsResult.fold((f) => emit(HifzError(f.message)), (surahs) {
      final profile = profileResult.fold((_) => null, (profile) => profile);
      final effectivePath = profile?.hifzPathValue;
      final sortedSurahs = sortSurahsForHifzPath(
        surahs: surahs,
        path: effectivePath,
      );

      emit(
        HifzLoaded(
          surahs: sortedSurahs,
          selectedPath: effectivePath,
        ),
      );
    });
  }

  Future<void> selectPath(String path) async {
    final currentState = state;
    if (currentState is HifzLoaded) {
      final sortedSurahs = sortSurahsForHifzPath(
        surahs: currentState.surahs,
        path: path,
      );

      final memPath = path == 'backward'
          ? MemorizationPath.child
          : MemorizationPath.adult;
      final pathResult = await _memorizationRepository.selectMemorizationPath(
        memPath,
      );
      pathResult.fold((failure) => emit(HifzError(failure.message)), (_) {
        emit(HifzLoaded(surahs: sortedSurahs, selectedPath: path));
        _pathResolver.notifyChanged();
      });
    }
  }
}
