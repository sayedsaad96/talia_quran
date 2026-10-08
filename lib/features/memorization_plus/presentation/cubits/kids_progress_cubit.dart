import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../domain/services/kids_progress_snapshot.dart';

sealed class KidsProgressState extends Equatable {
  const KidsProgressState();

  @override
  List<Object?> get props => [];
}

final class KidsProgressLoading extends KidsProgressState {
  const KidsProgressLoading();
}

final class KidsProgressLoaded extends KidsProgressState {
  const KidsProgressLoaded(this.snapshot);

  final KidsProgressSnapshot snapshot;

  @override
  List<Object?> get props => [snapshot];
}

final class KidsProgressError extends KidsProgressState {
  const KidsProgressError();
}

/// The kids "تقدّمي" page. Reloads when kids progress or activity changes,
/// so a session or a read page shows without reopening the page.
class KidsProgressCubit extends Cubit<KidsProgressState> {
  KidsProgressCubit(this._loadSnapshot, ProgressEventsBus progressEvents)
    : super(const KidsProgressLoading()) {
    _changes = progressEvents.changes.listen((reason) {
      if (reason == ProgressChangedReason.kidsProgress ||
          reason == ProgressChangedReason.activityFeed ||
          reason == ProgressChangedReason.certificate ||
          reason == ProgressChangedReason.cloudPull) {
        _scheduleReload();
      }
    });
  }

  final Future<KidsProgressSnapshot> Function() _loadSnapshot;
  late final StreamSubscription<ProgressChangedReason> _changes;
  Timer? _reloadDebounce;
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    try {
      final snapshot = await _loadSnapshot();
      if (isClosed || generation != _generation) return;
      emit(KidsProgressLoaded(snapshot));
    } catch (error, stack) {
      TaliaLogger.w('Kids progress failed to load', error, stack);
      if (isClosed || generation != _generation) return;
      // A background reload keeps the last good page.
      if (state is! KidsProgressLoaded) emit(const KidsProgressError());
    }
  }

  void _scheduleReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!isClosed) unawaited(load());
    });
  }

  @override
  Future<void> close() async {
    _reloadDebounce?.cancel();
    await _changes.cancel();
    return super.close();
  }
}
