import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/usecases/get_surahs_usecase.dart';
import '../../domain/entities/hifz_entities.dart';
import '../../domain/usecases/get_hifz_progress_usecase.dart';

part 'hifz_state.dart';

class HifzCubit extends Cubit<HifzState> {
  HifzCubit(
    this._getSurahs,
    this._getProgress,
    this._getPath,
    this._savePath,
  ) : super(const HifzInitial());

  final GetSurahsUsecase _getSurahs;
  final GetHifzProgressUsecase _getProgress;
  final GetHifzPathUsecase _getPath;
  final SaveHifzPathUsecase _savePath;

  Future<void> load() async {
    emit(const HifzLoading());
    final surahsResult = await _getSurahs();
    final progressResult = await _getProgress();
    final pathResult = await _getPath();

    surahsResult.fold(
      (f) => emit(HifzError(f.message)),
      (surahs) {
        progressResult.fold(
          (f) => emit(HifzError(f.message)),
          (progress) {
             pathResult.fold(
              (f) => emit(HifzError(f.message)),
              (path) {
                final progressMap = {
                  for (final p in progress) p.surahId: p,
                };
                
                // Sort according to path
                var sortedSurahs = List<Surah>.from(surahs);
                if (path == 'backward') {
                  sortedSurahs.sort((a, b) => b.id.compareTo(a.id));
                } else if (path == 'forward') {
                   sortedSurahs.sort((a, b) => a.id.compareTo(b.id)); // keep original basically
                }

                emit(HifzLoaded(
                  surahs: sortedSurahs, 
                  progressMap: progressMap,
                  selectedPath: path,
                ));
              }
             );
          },
        );
      },
    );
  }

  Future<void> selectPath(String path) async {
    final currentState = state;
    if (currentState is HifzLoaded) {
      await _savePath(path);
      
      var sortedSurahs = List<Surah>.from(currentState.surahs);
      if (path == 'backward') {
        sortedSurahs.sort((a, b) => b.id.compareTo(a.id));
      } else if (path == 'forward') {
        sortedSurahs.sort((a, b) => a.id.compareTo(b.id));
      }

      emit(HifzLoaded(
        surahs: sortedSurahs,
        progressMap: currentState.progressMap,
        selectedPath: path,
      ));
    }
  }
}
