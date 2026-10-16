import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/memorization/strength_band.dart';
import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../services/strength_overlay_source.dart';

class StrengthOverlayState extends Equatable {
  const StrengthOverlayState({this.enabled = false, this.revision = 0});

  final bool enabled;

  /// Bumped whenever the loaded records change so the reader rebuilds.
  final int revision;

  StrengthOverlayState copyWith({bool? enabled, int? revision}) =>
      StrengthOverlayState(
        enabled: enabled ?? this.enabled,
        revision: revision ?? this.revision,
      );

  @override
  List<Object?> get props => [enabled, revision];
}

/// Memorization-strength overlay of the adult reader. Adult records only.
class StrengthOverlayCubit extends Cubit<StrengthOverlayState> {
  StrengthOverlayCubit({
    required this._repository,
    required ProgressEventsBus events,
    required this._source,
    required this._prefs,
    DateTime Function()? clock,
    this._currentOwnerId,
  }) : _clock = clock ?? DateTime.now,
       super(const StrengthOverlayState()) {
    _sub = events.changes.listen((reason) {
      if (reason == ProgressChangedReason.reviewRecord ||
          reason == ProgressChangedReason.cloudPull) {
        unawaited(_reload());
      }
    });
  }

  static const prefsKey = 'reader_strength_overlay_on';

  final MemorizationPlusRepository _repository;
  final StrengthOverlaySource _source;
  final SharedPreferences _prefs;
  final DateTime Function() _clock;
  final String Function()? _currentOwnerId;
  late final StreamSubscription<ProgressChangedReason> _sub;

  String? _loadedOwner;
  bool _reloading = false;
  bool _rerun = false;

  /// The latest explicit [setEnabled] request; the last request always wins,
  /// even over a reload that was already in flight.
  bool? _requested;

  String? _owner() {
    try {
      return _currentOwnerId?.call();
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    final on = _prefs.getBool(prefsKey) ?? false;
    if (on) {
      await _reload(enable: true);
    }
  }

  Future<void> setEnabled(bool on) async {
    await _prefs.setBool(prefsKey, on);
    _requested = on;
    if (on) {
      await _reload(enable: true);
    } else {
      _source.clear();
      _loadedOwner = null;
      if (!isClosed) {
        emit(state.copyWith(enabled: false, revision: state.revision + 1));
      }
    }
  }

  Map<({int surah, int ayah}), StrengthBand> bandsForPage(int page) {
    if (!state.enabled) return const {};
    if (_loadedOwner != _owner()) {
      // Another account is active: never show the previous owner's data.
      _source.clear();
      unawaited(_reload());
      return const {};
    }
    return _source.bandsForPage(page, _clock());
  }

  Future<void> _reload({bool enable = false}) async {
    if (isClosed) return;
    if (_reloading) {
      _rerun = true;
      return;
    }
    if (!enable && !state.enabled) return;
    _reloading = true;
    try {
      final owner = _owner();
      final result = await _repository.getAllReviewRecords(
        scope: ReviewRecordReadScope.adult,
      );
      if (isClosed) return;
      if (_requested == false) return; // switched off while loading
      // A failed read keeps the previous bands and does not emit, so a
      // rebuild-triggered retry can never loop.
      final records = result.fold((_) => null, (r) => r);
      if (records == null) {
        if (enable && !state.enabled) emit(state.copyWith(enabled: true));
        return;
      }
      _source.setRecords(records);
      _loadedOwner = owner;
      emit(
        state.copyWith(
          enabled: _requested ?? (enable ? true : state.enabled),
          revision: state.revision + 1,
        ),
      );
    } catch (_) {
      // Overlay is decorative; keep the previous bands on failure.
    } finally {
      _reloading = false;
      if (_rerun && !isClosed) {
        _rerun = false;
        if (_requested != false) unawaited(_reload(enable: _requested == true));
      }
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
