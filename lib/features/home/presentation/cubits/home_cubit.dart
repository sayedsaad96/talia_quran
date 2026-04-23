import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../progress/domain/entities/progress_entities.dart';
import '../../../progress/domain/usecases/get_progress_usecase.dart';
import '../../../hifz/domain/usecases/get_hifz_progress_usecase.dart';
import '../../../hifz/domain/entities/hifz_entities.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._getProgress, 
    this._getHifzProgress, 
    this._quranRepository,
    this._memorizationPlusRepository,
  ) : super(const HomeInitial());

  final GetProgressUsecase _getProgress;
  final GetHifzProgressUsecase _getHifzProgress;
  final QuranRepository _quranRepository;
  final MemorizationPlusRepository _memorizationPlusRepository;

  Future<void> load() async {
    emit(const HomeLoading());

    final progressResult = await _getProgress();
    final hifzResult = await _getHifzProgress();

    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final pageNumber = (dayOfYear % 604) + 1;
    final quranPageResult = await _quranRepository.getQuranPage(pageNumber);
    QuranPageDetail? dailyWirdDetail;
    quranPageResult.fold(
      (l) => null,
      (r) => dailyWirdDetail = r,
    );
    
    // Fetch custom plan
    CustomMemorizationPlan? customPlan;
    final planResult = await _memorizationPlusRepository.getCustomPlan();
    planResult.fold(
      (l) => null,
      (plan) => customPlan = plan,
    );

    progressResult.fold(
      (f) => emit(HomeError(f.message)),
      (progress) {
        final hifzProgress = hifzResult.getOrElse(() => []);
        emit(HomeLoaded(
          progress: progress,
          hifzSurahProgress: hifzProgress,
          greeting: _greeting(),
          dailyWirdPageDetail: dailyWirdDetail,
          customPlan: customPlan,
        ));
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }
}
