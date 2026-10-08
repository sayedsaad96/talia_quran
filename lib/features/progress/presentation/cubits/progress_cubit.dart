import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../../../core/services/xp_service.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../../home/domain/usecases/get_activity_heatmap_usecase.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../domain/entities/progress_entities.dart';
import '../../domain/usecases/get_progress_usecase.dart';

part 'progress_state.dart';

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit(
    this._getProgress,
    this._pathResolver,
    this._progressEvents, [
    this._getHeatmap,
    this._xpService,
  ]) : super(const ProgressInitial()) {
    _pathChangesSub = _pathResolver.changes.listen((_) {
      if (!isClosed) {
        _scheduleReload();
      }
    });
    _progressChangesSub = _progressEvents.changes.listen(_onProgressChanged);
  }

  final GetProgressUsecase _getProgress;
  final MemorizationPathResolver _pathResolver;
  final ProgressEventsBus _progressEvents;
  final GetActivityHeatmapUsecase? _getHeatmap;
  final XpService? _xpService;
  late final StreamSubscription<void> _pathChangesSub;
  late final StreamSubscription<ProgressChangedReason> _progressChangesSub;
  Timer? _reloadDebounce;

  /// Incremented on every load so a slow, older load can never overwrite
  /// the result of a newer one.
  int _loadGeneration = 0;

  void _onProgressChanged(ProgressChangedReason reason) {
    if (!ProgressEventsBus.affectsProgressTab(reason)) {
      // XP-only changes skip the full reload but must not leave the XP
      // card stale.
      if (reason == ProgressChangedReason.xp) unawaited(refreshXp());
      return;
    }
    _scheduleReload();
  }

  void _scheduleReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!isClosed) {
        unawaited(load());
      }
    });
  }

  /// Loads progress. The skeleton is shown only on the first load; later
  /// reloads (progress events, pull-to-refresh, retry after data exists)
  /// swap the data in place so scroll position and open UI survive.
  Future<void> load() async {
    final generation = ++_loadGeneration;
    if (state is! ProgressLoaded) emit(const ProgressLoading());

    final profileFuture = _pathResolver.currentProfile();
    final heatmapFuture = _loadHeatmap();
    final xpFuture = _loadXp();
    final result = await _getProgress();
    final profile = await _safe(profileFuture, null, 'profile');
    final heatmap = await heatmapFuture;
    final totalXp = await xpFuture;
    if (isClosed || generation != _loadGeneration) return;

    result.fold(
      (f) {
        // Keep showing the last good data rather than replacing it with an
        // error screen on a background refresh.
        if (state is ProgressLoaded) return;
        emit(ProgressError(f.message));
      },
      (progress) => emit(
        ProgressLoaded(
          progress: progress,
          selectedPath: profile?.selectedPath,
          activityCountsByDay: heatmap?.countsByDay ?? const {},
          activityStartDate: heatmap?.startDate,
          totalXp: totalXp,
          xpLevelProgress: _xpLevelProgress(totalXp),
        ),
      ),
    );
  }

  /// Pull-to-refresh entry point.
  Future<void> refresh() => load();

  /// Updates only the XP numbers without recomputing the whole page.
  Future<void> refreshXp() async {
    final current = state;
    if (current is! ProgressLoaded || _xpService == null) return;
    final totalXp = await _loadXp();
    final latest = state;
    if (isClosed || latest is! ProgressLoaded) return;
    emit(
      latest.copyWith(
        totalXp: totalXp,
        xpLevelProgress: _xpLevelProgress(totalXp),
      ),
    );
  }

  // Heatmap and XP are secondary: a failure there must not block the page.
  Future<ActivityHeatmapData?> _loadHeatmap() async {
    final getHeatmap = _getHeatmap;
    if (getHeatmap == null) return null;
    return _safe(getHeatmap(), null, 'heatmap');
  }

  Future<int> _loadXp() async {
    final xpService = _xpService;
    if (xpService == null) return 0;
    return _safe(xpService.getTotalXp(), 0, 'xp');
  }

  double _xpLevelProgress(int totalXp) {
    final xpService = _xpService;
    if (xpService == null) return 0;
    try {
      return xpService.progressToNextLevel(totalXp);
    } catch (_) {
      return 0;
    }
  }

  Future<T> _safe<T>(Future<T> future, T fallback, String what) async {
    try {
      return await future;
    } catch (e, st) {
      TaliaLogger.w('ProgressCubit: $what failed to load', e, st);
      return fallback;
    }
  }

  @override
  Future<void> close() async {
    _reloadDebounce?.cancel();
    await _pathChangesSub.cancel();
    await _progressChangesSub.cancel();
    return super.close();
  }
}
