import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/surah_names.dart';
import '../../../../core/memorization/similar_ayah/similar_ayah_attempt_authority.dart';
import '../../../../core/memorization/learning_launch_context.dart';
import '../../../../core/memorization/similar_ayah/similar_ayah_attempt_service.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/confusion_pair.dart';
import '../../domain/entities/similar_ayah_reference_pair.dart';
import '../../domain/repositories/similar_ayah_browsing_source.dart';

typedef SimilarAyahAuthorityCapture = SimilarAyahAttemptAuthority Function();

final class SimilarAyahTrainerPassage extends Equatable {
  const SimilarAyahTrainerPassage({required this.ayah, this.previous});

  final Ayah ayah;
  final Ayah? previous;

  @override
  List<Object?> get props => [ayah, previous];
}

final class SimilarAyahTrainerState extends Equatable {
  const SimilarAyahTrainerState({
    this.pairs = const [],
    this.related = const [],
    this.browsing = const [],
    this.selected,
    this.target,
    this.other,
    this.loading = false,
    this.available = true,
    this.gated = false,
    this.failed = false,
    this.revealTarget = false,
    this.practiceMode = false,
    this.indexUnavailable = false,
  });

  /// The reviewed similar-ayah list is not approved (or unreadable): an
  /// eligible adult sees that, not an eligibility message.
  final bool indexUnavailable;

  final List<ConfusionPair> pairs;
  final SimilarAyahReferencePair? selected;
  final List<SimilarAyahReferencePair> related;
  final List<SimilarAyahReferencePair> browsing;
  final SimilarAyahTrainerPassage? target;
  final SimilarAyahTrainerPassage? other;
  final bool loading;
  final bool available;
  final bool gated;
  final bool failed;
  final bool revealTarget;
  final bool practiceMode;

  SimilarAyahTrainerState copyWith({
    List<ConfusionPair>? pairs,
    SimilarAyahReferencePair? selected,
    List<SimilarAyahReferencePair>? related,
    List<SimilarAyahReferencePair>? browsing,
    bool clearSelection = false,
    SimilarAyahTrainerPassage? target,
    SimilarAyahTrainerPassage? other,
    bool clearPassages = false,
    bool? loading,
    bool? available,
    bool? gated,
    bool? failed,
    bool? revealTarget,
    bool? practiceMode,
  }) => SimilarAyahTrainerState(
    pairs: pairs ?? this.pairs,
    related: related ?? this.related,
    browsing: browsing ?? this.browsing,
    selected: clearSelection ? null : selected ?? this.selected,
    target: clearPassages ? null : target ?? this.target,
    other: clearPassages ? null : other ?? this.other,
    loading: loading ?? this.loading,
    available: available ?? this.available,
    gated: gated ?? this.gated,
    failed: failed ?? this.failed,
    revealTarget: revealTarget ?? this.revealTarget,
    practiceMode: practiceMode ?? this.practiceMode,
  );

  @override
  List<Object?> get props => [
    pairs,
    related,
    browsing,
    selected,
    target,
    other,
    loading,
    available,
    gated,
    failed,
    revealTarget,
    practiceMode,
    indexUnavailable,
  ];
}

/// Read-only, adult-only historical pair practice. It never assesses recitation.
final class SimilarAyahTrainerCubit extends Cubit<SimilarAyahTrainerState> {
  SimilarAyahTrainerCubit({
    required this._readPairs,
    required this._quran,
    required this._captureAuthority,
    required Stream<void> accountChanges,
    required this._readAdultEligibility,
    required this._isEnabled,
    this._candidateSource,
  }) : super(const SimilarAyahTrainerState()) {
    _changes = accountChanges.listen(_onAccountChange);
  }

  final Future<List<ConfusionPair>> Function() _readPairs;
  final QuranRepository _quran;
  final SimilarAyahAuthorityCapture _captureAuthority;
  final Future<bool> Function() _readAdultEligibility;
  final bool Function() _isEnabled;
  final SimilarAyahCandidateSource? _candidateSource;
  late final StreamSubscription<void> _changes;
  SimilarAyahAttemptAuthority? _authority;
  int _generation = 0;
  AyahReference? _relatedTarget;

  Future<void> load() async {
    _relatedTarget = null;
    final request = ++_generation;
    final authority = _capture();
    if (authority == null || !_isEnabled()) return _gate();
    emit(
      state.copyWith(
        loading: true,
        failed: false,
        gated: false,
        available: true,
      ),
    );
    try {
      final adult = await _readAdultEligibility();
      if (!_valid(authority, request) || !_isEnabled()) return;
      if (!adult) return _gate();
      final pairs = await _readPairs();
      if (!_valid(authority, request)) return;
      final source = _candidateSource;
      final browsing = source is SimilarAyahBrowsingSource
          ? await (source as SimilarAyahBrowsingSource).loadBrowsingPairs()
          : <SimilarAyahReferencePair>[];
      if (!_valid(authority, request)) return;
      if (browsing == null && pairs.isEmpty) {
        emit(const SimilarAyahTrainerState(indexUnavailable: true));
        return;
      }
      emit(
        state.copyWith(
          pairs: List.unmodifiable(pairs),
          browsing: List.unmodifiable(browsing ?? const []),
          loading: false,
          failed: false,
        ),
      );
    } catch (_) {
      if (_valid(authority, request)) {
        emit(state.copyWith(loading: false, failed: true));
      }
    }
  }

  Future<void> loadRelated(AyahReference target) async {
    _relatedTarget = target;
    final request = ++_generation;
    final authority = _capture();
    if (authority == null || !_isEnabled()) return _gate();
    emit(const SimilarAyahTrainerState(loading: true));
    try {
      final adult = await _readAdultEligibility();
      if (!_valid(authority, request)) return;
      if (!adult) return _gate();
      final source = _candidateSource;
      if (source is SimilarAyahBrowsingSource) {
        final all = await (source as SimilarAyahBrowsingSource)
            .loadBrowsingPairs();
        if (!_valid(authority, request)) return;
        if (all == null) {
          emit(const SimilarAyahTrainerState(indexUnavailable: true));
          return;
        }
        final related = <SimilarAyahReferencePair>[];
        for (final pair in all) {
          if (pair.targetSurahId == target.surahId &&
              pair.targetAyahNumber == target.ayahNumber) {
            related.add(pair);
          } else if (pair.otherSurahId == target.surahId &&
              pair.otherAyahNumber == target.ayahNumber) {
            related.add(
              SimilarAyahReferencePair(
                targetSurahId: target.surahId,
                targetAyahNumber: target.ayahNumber,
                otherSurahId: pair.targetSurahId,
                otherAyahNumber: pair.targetAyahNumber,
              ),
            );
          }
        }
        emit(SimilarAyahTrainerState(related: List.unmodifiable(related)));
        return;
      }
      final candidates = await _candidateSource?.loadCandidates(
        '${target.surahId}:${target.ayahNumber}',
      );
      if (!_valid(authority, request)) return;
      if (candidates == null) {
        emit(const SimilarAyahTrainerState(indexUnavailable: true));
        return;
      }
      final related = candidates
          .map((candidate) {
            final parts = candidate.key.split(':');
            if (parts.length != 2) throw const FormatException();
            final choice = SimilarAyahReferencePair(
              targetSurahId: target.surahId,
              targetAyahNumber: target.ayahNumber,
              otherSurahId: int.parse(parts[0]),
              otherAyahNumber: int.parse(parts[1]),
            );
            if (!_validPair(choice) ||
                candidate.key !=
                    '${choice.otherSurahId}:${choice.otherAyahNumber}') {
              throw const FormatException();
            }
            return choice;
          })
          .toList(growable: false);
      emit(SimilarAyahTrainerState(related: List.unmodifiable(related)));
    } catch (_) {
      if (_valid(authority, request)) {
        emit(const SimilarAyahTrainerState(failed: true));
      }
    }
  }

  Future<void> choose(ConfusionPair pair) => chooseReference(
    SimilarAyahReferencePair(
      targetSurahId: pair.targetSurahId,
      targetAyahNumber: pair.targetAyahNumber,
      otherSurahId: pair.otherSurahId,
      otherAyahNumber: pair.otherAyahNumber,
    ),
  );

  Future<void> retry() {
    final selected = state.selected;
    final relatedTarget = _relatedTarget;
    if (selected != null) return chooseReference(selected);
    return relatedTarget == null ? load() : loadRelated(relatedTarget);
  }

  Future<void> chooseReference(SimilarAyahReferencePair pair) async {
    final request = ++_generation;
    final authority = _authority ?? _capture();
    if (authority == null || !_isEnabled()) return _gate();
    if (!_validPair(pair)) {
      emit(state.copyWith(selected: pair, failed: true, clearPassages: true));
      return;
    }
    emit(
      state.copyWith(
        selected: pair,
        loading: true,
        clearPassages: true,
        failed: false,
        revealTarget: false,
        practiceMode: false,
      ),
    );
    try {
      final adult = await _readAdultEligibility();
      if (!_valid(authority, request) || !_isEnabled()) return;
      if (!adult) return _gate();
      final passages = await _loadPassages(pair, authority, request);
      if (!_valid(authority, request)) return;
      if (passages == null) {
        emit(state.copyWith(loading: false, failed: true));
        return;
      }
      emit(
        state.copyWith(target: passages.$1, other: passages.$2, loading: false),
      );
    } catch (_) {
      if (_valid(authority, request)) {
        emit(state.copyWith(loading: false, failed: true));
      }
    }
  }

  void revealTarget() {
    if (_canInteract() && state.target != null && state.available) {
      emit(state.copyWith(revealTarget: true));
    }
  }

  void startPractice() {
    if (_canInteract() && state.target != null) {
      emit(state.copyWith(practiceMode: true, revealTarget: false));
    }
  }

  void exitPractice() {
    if (_canInteract()) emit(state.copyWith(practiceMode: false));
  }

  void showPairs() {
    if (!_canInteract()) return;
    _generation++;
    emit(
      state.copyWith(
        clearSelection: true,
        clearPassages: true,
        loading: false,
        failed: false,
        practiceMode: false,
        revealTarget: false,
      ),
    );
  }

  bool _canInteract() {
    final authority = _authority;
    return authority != null && _valid(authority, _generation);
  }

  bool _validPair(SimilarAyahReferencePair pair) =>
      pair.targetSurahId >= 1 &&
      pair.targetSurahId <= 114 &&
      pair.otherSurahId >= 1 &&
      pair.otherSurahId <= 114 &&
      pair.targetAyahNumber >= 1 &&
      pair.otherAyahNumber >= 1 &&
      pair.targetAyahNumber <= SurahNames.ayahCount(pair.targetSurahId) &&
      pair.otherAyahNumber <= SurahNames.ayahCount(pair.otherSurahId) &&
      (pair.targetSurahId != pair.otherSurahId ||
          pair.targetAyahNumber != pair.otherAyahNumber);

  SimilarAyahAttemptAuthority? _capture() {
    try {
      final authority = _captureAuthority();
      authority.check();
      _authority = authority;
      return authority;
    } catch (_) {
      _invalidate();
      return null;
    }
  }

  Future<(SimilarAyahTrainerPassage, SimilarAyahTrainerPassage)?> _loadPassages(
    SimilarAyahReferencePair pair,
    SimilarAyahAttemptAuthority authority,
    int request,
  ) async {
    final ids = {pair.targetSurahId, pair.otherSurahId};
    final details = <int, SurahDetail>{};
    for (final id in ids) {
      final result = await _quran.getSurahDetail(id);
      if (!_valid(authority, request)) return null;
      final detail = result.fold((_) => null, (value) => value);
      if (detail == null || detail.surah.id != id) return null;
      details[id] = detail;
    }
    final target = _passage(
      details[pair.targetSurahId]!,
      pair.targetAyahNumber,
    );
    final other = _passage(details[pair.otherSurahId]!, pair.otherAyahNumber);
    return target == null || other == null ? null : (target, other);
  }

  SimilarAyahTrainerPassage? _passage(SurahDetail detail, int number) {
    if (number < 1 || number > SurahNames.ayahCount(detail.surah.id)) {
      return null;
    }
    final matches = detail.ayahs
        .where((ayah) => ayah.numberInSurah == number)
        .toList();
    if (matches.length != 1 || matches.single.surahId != detail.surah.id) {
      return null;
    }
    final prior = detail.ayahs
        .where((ayah) => ayah.numberInSurah == number - 1)
        .toList();
    final previous =
        number > 1 &&
            prior.length == 1 &&
            prior.single.surahId == detail.surah.id
        ? prior.single
        : null;
    if (number > 1 && previous == null) return null;
    return SimilarAyahTrainerPassage(ayah: matches.single, previous: previous);
  }

  bool _valid(SimilarAyahAttemptAuthority authority, int request) {
    if (isClosed ||
        request != _generation ||
        !identical(_authority, authority)) {
      return false;
    }
    try {
      authority.check();
      if (!_isEnabled()) {
        _gate();
        return false;
      }
      return true;
    } catch (_) {
      _invalidate();
      return false;
    }
  }

  void _onAccountChange(void _) {
    final authority = _authority;
    if (authority == null) return;
    try {
      authority.check();
    } catch (_) {
      _invalidate();
    }
  }

  void _gate() {
    if (!isClosed) {
      emit(const SimilarAyahTrainerState(available: false, gated: true));
    }
  }

  void _invalidate() {
    _generation++;
    _authority = null;
    if (!isClosed) emit(const SimilarAyahTrainerState(available: false));
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
