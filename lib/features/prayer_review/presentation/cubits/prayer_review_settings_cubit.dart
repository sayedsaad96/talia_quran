import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/prayer_review/prayer_review_lengths.dart';
import '../../../prayer_companion/domain/entities/prayer_companion.dart';
import '../../domain/entities/prayer_review_authority.dart';

final class PrayerReviewSettingsState {
  const PrayerReviewSettingsState._({
    required this.isLoading,
    required this.isReady,
    required this.isSaving,
    required this.saveFailed,
    required this.lengths,
  });

  const PrayerReviewSettingsState.hidden()
    : this._(
        isLoading: false,
        isReady: false,
        isSaving: false,
        saveFailed: false,
        lengths: const {},
      );

  final bool isLoading;
  final bool isReady;
  final bool isSaving;
  final bool saveFailed;
  final Map<PrayerKey, int> lengths;

  bool get isHidden => !isLoading && !isReady;

  PrayerReviewSettingsState copyWith({
    bool? isLoading,
    bool? isReady,
    bool? isSaving,
    bool? saveFailed,
    Map<PrayerKey, int>? lengths,
  }) => PrayerReviewSettingsState._(
    isLoading: isLoading ?? this.isLoading,
    isReady: isReady ?? this.isReady,
    isSaving: isSaving ?? this.isSaving,
    saveFailed: saveFailed ?? this.saveFailed,
    lengths: Map.unmodifiable(lengths ?? this.lengths),
  );
}

/// Owns account-safe prayer-review length settings. UI only renders its state.
final class PrayerReviewSettingsCubit extends Cubit<PrayerReviewSettingsState> {
  PrayerReviewSettingsCubit({
    required this._isEnabled,
    required this._captureAuthority,
    required this._readAdultEligibility,
    required this._readLength,
    required this._writeLength,
    required Stream<void> accountChanges,
  }) : super(const PrayerReviewSettingsState.hidden()) {
    _accountChanges = accountChanges.listen((_) => _wipe());
  }

  final bool Function() _isEnabled;
  final PrayerReviewAuthority Function() _captureAuthority;
  final Future<bool> Function() _readAdultEligibility;
  final int Function(String ownerId, PrayerKey prayer) _readLength;
  final Future<void> Function(
    String ownerId,
    PrayerKey prayer,
    int length,
    PrayerReviewAuthority authority,
  )
  _writeLength;
  late final StreamSubscription<void> _accountChanges;
  int _generation = 0;
  String? _readyOwnerId;

  Future<void> load() async {
    final generation = ++_generation;
    if (!_isEnabled()) return _hide(generation);
    try {
      final authority = _captureAuthority();
      authority.check();
      emit(state.copyWith(isLoading: true, isReady: false, saveFailed: false));
      final adult = await _readAdultEligibility();
      if (!_isCurrent(generation, authority)) return;
      if (!adult || !_isEnabled()) return _hide(generation);
      final lengths = <PrayerKey, int>{
        for (final prayer in PrayerKey.values)
          prayer: _readChecked(authority.ownerId, prayer),
      };
      if (!_isCurrent(generation, authority)) return;
      emit(
        PrayerReviewSettingsState._(
          isLoading: false,
          isReady: true,
          isSaving: false,
          saveFailed: false,
          lengths: Map.unmodifiable(lengths),
        ),
      );
      _readyOwnerId = authority.ownerId;
    } catch (_) {
      if (_isGeneration(generation)) _hide(generation);
    }
  }

  Future<void> changeLength(PrayerKey prayer, int length) async {
    if (!state.isReady ||
        state.isSaving ||
        !PrayerReviewLengths.validLengths.contains(length)) {
      return;
    }
    final generation = _generation;
    try {
      final authority = _captureAuthority();
      authority.check();
      if (_readyOwnerId != authority.ownerId) return _hide(generation);
      if (!_isEnabled()) return _hide(generation);
      emit(state.copyWith(isSaving: true, saveFailed: false));
      final adult = await _readAdultEligibility();
      if (!_isCurrent(generation, authority)) return;
      if (!adult) return _hide(generation);
      await _writeLength(authority.ownerId, prayer, length, authority);
      if (!_isCurrent(generation, authority)) return;
      final next = Map<PrayerKey, int>.from(state.lengths)..[prayer] = length;
      emit(state.copyWith(lengths: next, isSaving: false, saveFailed: false));
    } catch (_) {
      if (_isGeneration(generation)) {
        emit(state.copyWith(isSaving: false, saveFailed: true));
      }
    }
  }

  int _readChecked(String ownerId, PrayerKey prayer) {
    final value = _readLength(ownerId, prayer);
    if (!PrayerReviewLengths.validLengths.contains(value)) {
      throw const FormatException('Invalid prayer review length');
    }
    return value;
  }

  bool _isCurrent(int generation, PrayerReviewAuthority authority) {
    if (!_isGeneration(generation)) return false;
    authority.check();
    return _isEnabled();
  }

  bool _isGeneration(int generation) => !isClosed && generation == _generation;

  void _hide(int generation) {
    if (_isGeneration(generation)) {
      emit(const PrayerReviewSettingsState.hidden());
    }
  }

  void _wipe() {
    _generation++;
    _readyOwnerId = null;
    if (!isClosed) emit(const PrayerReviewSettingsState.hidden());
  }

  @override
  Future<void> close() {
    _generation++;
    _accountChanges.cancel();
    return super.close();
  }
}
