import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/memorization/review_record_filters.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../data/datasources/kids_quran_map_celebration_store.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/kids_journey_path_definition.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../domain/services/kids_surah_house_summary_builder.dart';

sealed class KidsQuranJourneyState extends Equatable {
  const KidsQuranJourneyState();

  @override
  List<Object?> get props => [];
}

final class KidsQuranJourneyLoading extends KidsQuranJourneyState {
  const KidsQuranJourneyLoading();
}

final class KidsQuranJourneyError extends KidsQuranJourneyState {
  const KidsQuranJourneyError();
}

final class KidsQuranJourneyLoaded extends KidsQuranJourneyState {
  const KidsQuranJourneyLoaded({
    required this.houses,
    required this.currentSurahId,
    required this.surahNames,
    this.celebratedSurahIds = const {},
  });

  final List<KidsSurahHouse> houses;
  final int currentSurahId;

  /// Canonical Arabic surah names (`Surah.nameAr`) by surah id. Non-Arabic
  /// locales use the localized canonical name table in the UI.
  final Map<int, String> surahNames;

  /// Surahs completed since the child's last visit to the map, to light up
  /// once. Empty when no celebration store is available.
  final Set<int> celebratedSurahIds;

  @override
  List<Object?> get props => [
    houses,
    currentSurahId,
    surahNames,
    celebratedSurahIds,
  ];
}

/// Loads the whole-Quran journey map: one house per surah of the selected path.
class KidsQuranJourneyCubit extends Cubit<KidsQuranJourneyState> {
  KidsQuranJourneyCubit(
    this._repository,
    this._quranRepository, {
    KidsQuranMapCelebrationStore? celebrationStore,
    DateTime Function()? clock,
  }) : _celebrationStore = celebrationStore,
       _clock = clock ?? DateTime.now,
       super(const KidsQuranJourneyLoading());

  final MemorizationPlusRepository _repository;
  final QuranRepository _quranRepository;
  final KidsQuranMapCelebrationStore? _celebrationStore;
  final DateTime Function() _clock;

  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    try {
      final path = (await _repository.getKidsJourneyPath()).getOrElse(
        () => KidsJourneyPathDefinition.adventure,
      );
      final surahsResult = await _quranRepository.getSurahs();
      final surahs = surahsResult.fold((_) => null, (value) => value);
      if (surahs == null) {
        _emit(generation, const KidsQuranJourneyError());
        return;
      }
      final logs = (await _repository.getKidsSessionLogs()).getOrElse(
        () => const <KidsSessionLog>[],
      );
      final records =
          (await _repository.getAllReviewRecords(
                scope: ReviewRecordReadScope.kids,
              ))
              .getOrElse(() => const <AyahReviewRecord>[])
              .where(ReviewRecordFilters.isKidsSource)
              .toList();
      final settings = (await _repository.getParentSettings()).fold(
        (_) => const ParentSettings(),
        (value) => value,
      );
      final profile = (await _repository.getMemorizationProfile()).fold(
        (_) => null,
        (value) => value,
      );
      final defaultStageSize =
          sanitizeKidsAyahsPerHouse(settings.kidsAyahsPerHouse) ??
          KidsSessionPolicy.forChildAge(profile?.childAge).journeyStageSize;

      final houses = buildKidsSurahHouses(
        path: path,
        surahs: surahs,
        logs: logs,
        kidsRecords: records,
        frozenSizes: settings.kidsHouseSizesBySurah,
        wholeSurahIds: settings.kidsWholeSurahIds,
        defaultStageSize: defaultStageSize,
        now: _clock(),
      );
      final celebratedSurahIds = _celebrationStore == null
          ? const <int>{}
          : await _celebrationStore.takeNewlyCompleted(houses);
      _emit(
        generation,
        KidsQuranJourneyLoaded(
          houses: houses,
          currentSurahId: currentKidsSurahHouse(
            houses,
            logs,
            startingSurahId: settings.startingSurahId,
          ),
          surahNames: {for (final s in surahs) s.id: s.nameAr},
          celebratedSurahIds: celebratedSurahIds,
        ),
      );
    } catch (error, stackTrace) {
      TaliaLogger.e('KidsQuranJourneyCubit.load', error, stackTrace);
      _emit(generation, const KidsQuranJourneyError());
    }
  }

  void _emit(int generation, KidsQuranJourneyState next) {
    if (isClosed || generation != _generation) return;
    emit(next);
  }
}
