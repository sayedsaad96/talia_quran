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
  const KidsProgressLoaded(this.snapshot, {this.childName});

  final KidsProgressSnapshot snapshot;
  final String? childName;

  @override
  List<Object?> get props => [snapshot, childName];
}

final class KidsProgressError extends KidsProgressState {
  const KidsProgressError();
}

/// The kids "تقدّمي" page. Reloads when kids progress or activity changes,
/// so a session or a read page shows without reopening the page.
class KidsProgressCubit extends Cubit<KidsProgressState> {
  KidsProgressCubit(
    this._loadSnapshot,
    ProgressEventsBus progressEvents, {
    Future<String?> Function()? childNameLoader,
  }) : _loadChildName = childNameLoader,
       super(const KidsProgressLoading()) {
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
  final Future<String?> Function()? _loadChildName;
  late final StreamSubscription<ProgressChangedReason> _changes;
  Timer? _reloadDebounce;
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    try {
      final snapshot = await _loadSnapshot();
      final childName = await _loadChildNameSafely();
      if (isClosed || generation != _generation) return;
      emit(KidsProgressLoaded(snapshot, childName: childName));
    } catch (error, stack) {
      TaliaLogger.w('Kids progress failed to load', error, stack);
      if (isClosed || generation != _generation) return;
      // A background reload keeps the last good page.
      if (state is! KidsProgressLoaded) emit(const KidsProgressError());
    }
  }

  Future<String?> _loadChildNameSafely() async {
    try {
      final childName = await _loadChildName?.call();
      final trimmed = childName?.trim();
      return trimmed == null || trimmed.isEmpty ? null : trimmed;
    } catch (error, stack) {
      // A name only personalizes certificates. Progress remains usable and the
      // page supplies its non-adult localized child fallback on this failure.
      TaliaLogger.w('Kids progress child name failed to load', error, stack);
      return null;
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
