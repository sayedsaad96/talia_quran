import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/usecases/get_surahs_usecase.dart';
import '../../domain/hifz_unlock_rules.dart';
import '../../domain/entities/hifz_entities.dart';
import '../../domain/usecases/get_hifz_progress_usecase.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';

part 'hifz_state.dart';

class HifzCubit extends Cubit<HifzState> {
  HifzCubit(
    this._getSurahs,
    this._getProgress,
    this._getPath,
    this._savePath,
    this._memorizationRepository,
    this._pathResolver,
  ) : super(const HifzInitial());

  final GetSurahsUsecase _getSurahs;
  final GetHifzProgressUsecase _getProgress;
  final GetHifzPathUsecase _getPath;
  final SaveHifzPathUsecase _savePath;
  final MemorizationPlusRepository _memorizationRepository;
  final MemorizationPathResolver _pathResolver;

  Future<void> load() async {
    emit(const HifzLoading());
    final surahsResult = await _getSurahs();
    final progressResult = await _getProgress();
    final pathResult = await _getPath();
    final profileResult = await _memorizationRepository
        .getMemorizationProfile();

    surahsResult.fold((f) => emit(HifzError(f.message)), (surahs) {
      progressResult.fold((f) => emit(HifzError(f.message)), (progress) {
        pathResult.fold((f) => emit(HifzError(f.message)), (path) {
          final profile = profileResult.fold((_) => null, (profile) => profile);
          final effectivePath = profile?.hifzPathValue ?? path;
          final progressMap = {for (final p in progress) p.surahId: p};
          final sortedSurahs = sortSurahsForHifzPath(
            surahs: surahs,
            path: effectivePath,
          );
          final unlockedSurahIds = buildUnlockedSurahIds(
            orderedSurahs: sortedSurahs,
            progressMap: progressMap,
          );

          emit(
            HifzLoaded(
              surahs: sortedSurahs,
              progressMap: progressMap,
              selectedPath: effectivePath,
              unlockedSurahIds: unlockedSurahIds,
            ),
          );
        });
      });
    });
  }

  Future<void> selectPath(String path) async {
    final currentState = state;
    if (currentState is HifzLoaded) {
      final saveResult = await _savePath(path);
      final failure = saveResult.fold((f) => f, (_) => null);
      if (failure != null) {
        emit(HifzError(failure.message));
        return;
      }

      final sortedSurahs = sortSurahsForHifzPath(
        surahs: currentState.surahs,
        path: path,
      );
      final unlockedSurahIds = buildUnlockedSurahIds(
        orderedSurahs: sortedSurahs,
        progressMap: currentState.progressMap,
      );

      emit(
        HifzLoaded(
          surahs: sortedSurahs,
          progressMap: currentState.progressMap,
          selectedPath: path,
          unlockedSurahIds: unlockedSurahIds,
        ),
      );
      final memPath = path == 'backward'
          ? MemorizationPath.child
          : MemorizationPath.adult;
      final pathResult = await _memorizationRepository.selectMemorizationPath(
        memPath,
      );
      pathResult.fold((_) => null, (_) => _pathResolver.notifyChanged());
    }
  }
}
