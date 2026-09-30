import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/usecases/get_surahs_usecase.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/memorization/surah_memorization_status.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';

part 'surah_list_state.dart';

class SurahListCubit extends Cubit<SurahListState> {
  SurahListCubit(
    this._getSurahsUsecase, {
    MemorizationPlusRepository? memorizationRepository,
  }) : _memorizationRepository = memorizationRepository,
       super(const SurahListInitial());
  final GetSurahsUsecase _getSurahsUsecase;

  /// Source of the per-surah memorization badges (N17). Optional: without
  /// it the list simply shows no badges.
  final MemorizationPlusRepository? _memorizationRepository;

  List<Surah> _allSurahs = [];

  Future<void> loadSurahs() async {
    emit(const SurahListLoading());
    final result = await _getSurahsUsecase();
    result.fold((f) => emit(SurahListError(f.message)), (surahs) {
      _allSurahs = surahs;
      emit(SurahListLoaded(surahs: surahs, filtered: surahs));
    });
    if (state is SurahListLoaded) await _loadMemorizationStatus();
  }

  /// Badges load after the list so a slow or failing read never blocks it.
  Future<void> _loadMemorizationStatus() async {
    final repository = _memorizationRepository;
    if (repository == null) return;
    try {
      final result = await repository.getAllReviewRecords(
        scope: ReviewRecordReadScope.adult,
      );
      final records = result.fold((_) => null, (records) => records);
      final current = state;
      if (records == null || isClosed || current is! SurahListLoaded) return;
      emit(
        current.copyWith(
          selectedJuz: current.selectedJuz,
          memorizationStatus: SurahMemorizationStatus.fromRecords(
            records,
            ayahCounts: {for (final s in _allSurahs) s.id: s.ayahCount},
          ),
        ),
      );
    } catch (_) {
      // Badges are optional decoration; the list stays usable without them.
    }
  }

  void search(String query) {
    final current = state;
    if (current is! SurahListLoaded) return;
    if (query.trim().isEmpty) {
      emit(current.copyWith(filtered: _allSurahs, query: ''));
      return;
    }
    final qRaw = query.trim().toLowerCase();
    final qNormalized = ArabicNormalizer.normalize(query.trim());

    final filtered = _allSurahs.where((s) {
      final surahNameNormalized = ArabicNormalizer.normalize(s.nameAr);
      final matchAr =
          qNormalized.isNotEmpty && surahNameNormalized.contains(qNormalized);

      return matchAr ||
          s.nameAr.contains(qRaw) ||
          s.nameEn.toLowerCase().contains(qRaw) ||
          s.id.toString() == qRaw;
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
