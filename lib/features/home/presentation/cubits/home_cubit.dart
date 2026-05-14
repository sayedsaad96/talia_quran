import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../progress/domain/entities/progress_entities.dart';
import '../../../progress/domain/usecases/get_progress_usecase.dart';
import '../../../hifz/domain/usecases/get_hifz_progress_usecase.dart';
import '../../../hifz/domain/entities/hifz_entities.dart';
import '../../../quran/domain/usecases/get_surahs_usecase.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../../core/services/app_session_service.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetProgressUsecase _getProgress;
  final GetHifzProgressUsecase _getHifzProgress;
  final GetQuranPageUsecase _getQuranPage;
  final GetCustomPlanUsecase _getCustomPlan;
  final MemorizationPlusRepository _memorizationRepository;
  final AppSessionService _sessionService;

  HomeCubit(
    this._getProgress,
    this._getHifzProgress,
    this._getQuranPage,
    this._getCustomPlan,
    this._memorizationRepository,
    this._sessionService,
  ) : super(const HomeInitial());

  Future<void> load() async {
    emit(const HomeLoading());

    final progressResult = await _getProgress();
    final hifzResult = await _getHifzProgress();

    final now = DateTime.now();
    // Use date-based seed to ensure the random page stays the same for the whole day
    final today = DateTime(now.year, now.month, now.day);
    final random = Random(today.millisecondsSinceEpoch);
    final pageNumber = random.nextInt(604) + 1;
    final quranPageResult = await _getQuranPage(pageNumber);
    QuranPageDetail? dailyWirdDetail;
    quranPageResult.fold((l) => null, (r) => dailyWirdDetail = r);

    // Fetch custom plan
    CustomMemorizationPlan? customPlan;
    final planResult = await _getCustomPlan();
    planResult.fold((l) => null, (plan) => customPlan = plan);

    // Load last restorable location for "Continue Reading" chip
    final lastLocation = _sessionService.getLastRestorableLocation();

    // Load parent tracking preferences
    MemorizationTrack? selectedTrack;
    _memorizationRepository.getSelectedTrack().fold((_) {}, (t) => selectedTrack = t);
    bool isParentMode = false;
    _memorizationRepository.getIsParentMode().fold((_) {}, (m) => isParentMode = m);

    progressResult.fold((f) => emit(HomeError(f.message)), (progress) {
      final hifzProgress = hifzResult.getOrElse(() => []);
      emit(
        HomeLoaded(
          progress: progress,
          hifzSurahProgress: hifzProgress,
          greeting: _greeting(),
          dailyWirdPageDetail: dailyWirdDetail,
          customPlan: customPlan,
          selectedTrack: selectedTrack,
          isParentMode: isParentMode,
          lastRestorableLocation: lastLocation,
        ),
      );
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }
}
