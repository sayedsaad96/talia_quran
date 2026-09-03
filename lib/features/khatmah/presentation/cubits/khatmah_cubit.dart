import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/khatmah_history_entry.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_reading_result.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';
import '../../domain/usecases/delete_khatmah_usecase.dart';
import '../../domain/usecases/get_active_khatmah_usecase.dart';
import '../../domain/usecases/pause_resume_khatmah_usecase.dart';
import '../../domain/usecases/record_khatmah_reading_usecase.dart';
import '../../domain/usecases/update_khatmah_schedule_usecase.dart';

abstract class KhatmahState extends Equatable {
  const KhatmahState();

  @override
  List<Object?> get props => [];
}

class KhatmahInitial extends KhatmahState {
  const KhatmahInitial();
}

class KhatmahLoading extends KhatmahState {
  const KhatmahLoading();
}

class KhatmahNoActivePlan extends KhatmahState {
  const KhatmahNoActivePlan();
}

class KhatmahActive extends KhatmahState {
  const KhatmahActive({
    required this.plan,
    required this.wirdStartPage,
    required this.wirdEndPage,
  });

  final KhatmahPlan plan;
  final int wirdStartPage;
  final int wirdEndPage;

  @override
  List<Object?> get props => [plan, wirdStartPage, wirdEndPage];
}

class KhatmahPaused extends KhatmahState {
  const KhatmahPaused({required this.plan});

  final KhatmahPlan plan;

  @override
  List<Object?> get props => [plan];
}

class KhatmahWirdCompleted extends KhatmahState {
  const KhatmahWirdCompleted({required this.plan});

  final KhatmahPlan plan;

  @override
  List<Object?> get props => [plan];
}

class KhatmahProgressFailure extends KhatmahState {
  const KhatmahProgressFailure({
    required this.plan,
    required this.pageNumber,
    required this.source,
    required this.error,
  });

  final KhatmahPlan? plan;
  final int pageNumber;
  final KhatmahReadingSource source;
  final Object error;

  @override
  List<Object?> get props => [plan, pageNumber, source, error];
}

class KhatmahCompleted extends KhatmahState {
  const KhatmahCompleted({
    required this.plan,
    required this.historyEntry,
    this.newlyCompletedPages = const {},
  });

  final KhatmahPlan plan;
  final KhatmahHistoryEntry historyEntry;
  final Set<int> newlyCompletedPages;

  @override
  List<Object?> get props => [plan, historyEntry, newlyCompletedPages];
}

class _RecordRequestKey {
  const _RecordRequestKey(this.source, this.pageNumber);

  final KhatmahReadingSource source;
  final int pageNumber;

  @override
  bool operator ==(Object other) =>
      other is _RecordRequestKey &&
      other.source == source &&
      other.pageNumber == pageNumber;

  @override
  int get hashCode => Object.hash(source, pageNumber);
}

class _RecordRequest {
  _RecordRequest(this.source, this.pageNumber)
    : key = _RecordRequestKey(source, pageNumber);

  final KhatmahReadingSource source;
  final int pageNumber;
  final _RecordRequestKey key;
  final Completer<void> completer = Completer<void>();
}

class KhatmahCubit extends Cubit<KhatmahState> {
  KhatmahCubit(
    this._getActive,
    this._recordReading,
    this._pauseResume,
    this._deleteKhatmah, [
    this._updateSchedule,
  ]) : super(const KhatmahInitial());

  final GetActiveKhatmahUsecase _getActive;
  final RecordKhatmahReadingUsecase _recordReading;
  final PauseResumeKhatmahUsecase _pauseResume;
  final DeleteKhatmahUsecase _deleteKhatmah;

  // Retained only for the existing scheduling-adjustment controls. Reader
  // progress must use RecordKhatmahReadingUsecase through the methods below.
  final UpdateKhatmahScheduleUsecase? _updateSchedule;
  KhatmahPlan? _lastKnownPlan;
  final List<_RecordRequest> _recordQueue = [];
  final Map<_RecordRequestKey, Completer<void>> _pendingRecordRequests = {};
  bool _isDrainingRecords = false;

  Future<void> load() async {
    emit(const KhatmahLoading());
    try {
      final plan = await _getActive();
      if (plan == null || plan.status == KhatmahStatus.completed) {
        _lastKnownPlan = null;
        emit(const KhatmahNoActivePlan());
      } else if (plan.status == KhatmahStatus.paused) {
        _lastKnownPlan = plan;
        emit(KhatmahPaused(plan: plan));
      } else {
        _lastKnownPlan = plan;
        _emitActive(plan);
      }
    } catch (error) {
      emit(
        KhatmahProgressFailure(
          plan: _lastKnownPlan,
          pageNumber: 0,
          source: KhatmahReadingSource.digital,
          error: error,
        ),
      );
    }
  }

  Future<void> recordDigitalPage(int pageNumber) =>
      _recordCurrent(pageNumber, KhatmahReadingSource.digital);

  Future<void> recordPhysicalThroughPage(int pageNumber) =>
      _recordCurrent(pageNumber, KhatmahReadingSource.physical);

  /// Legacy dashboard entry point. A physical logger records an explicit range,
  /// never a fabricated cursor jump.
  Future<void> advancePage(int pageNumber) =>
      recordPhysicalThroughPage(pageNumber);

  Future<void> retryLastProgress() async {
    final current = state;
    if (current is KhatmahProgressFailure &&
        current.plan != null &&
        current.pageNumber > 0) {
      await _recordCurrent(current.pageNumber, current.source);
    }
  }

  Future<void> _recordCurrent(
    int pageNumber,
    KhatmahReadingSource source,
  ) async {
    final plan = _recordingPlan;
    if (plan == null) return;

    final key = _RecordRequestKey(source, pageNumber);
    final pending = _pendingRecordRequests[key];
    if (pending != null) return pending.future;

    final request = _RecordRequest(source, pageNumber);
    _pendingRecordRequests[key] = request.completer;
    _recordQueue.add(request);
    unawaited(_drainRecordQueue());
    return request.completer.future;
  }

  KhatmahPlan? get _recordingPlan {
    final plan = switch (state) {
      final KhatmahActive current => current.plan,
      final KhatmahWirdCompleted current => current.plan,
      final KhatmahProgressFailure current => current.plan,
      _ => _lastKnownPlan,
    };
    return plan?.status == KhatmahStatus.active ? plan : null;
  }

  Future<void> _drainRecordQueue() async {
    if (_isDrainingRecords) return;
    _isDrainingRecords = true;
    try {
      while (_recordQueue.isNotEmpty) {
        final request = _recordQueue.removeAt(0);
        try {
          final plan = _recordingPlan;
          if (plan != null) {
            try {
              final result = await _recordReading(
                plan,
                request.pageNumber,
                source: request.source,
              );
              _lastKnownPlan = result.plan;
              _emitReadingResult(result);
            } catch (error) {
              emit(
                KhatmahProgressFailure(
                  plan: _lastKnownPlan,
                  pageNumber: request.pageNumber,
                  source: request.source,
                  error: error,
                ),
              );
            }
          }
        } finally {
          _pendingRecordRequests.remove(request.key);
          if (!request.completer.isCompleted) request.completer.complete();
        }
      }
    } finally {
      _isDrainingRecords = false;
      if (_recordQueue.isNotEmpty) unawaited(_drainRecordQueue());
    }
  }

  void _emitReadingResult(KhatmahReadingResult result) {
    final history = result.historyEntry;
    if (history != null) {
      emit(
        KhatmahCompleted(
          plan: result.plan,
          historyEntry: history,
          newlyCompletedPages: result.newlyCompletedPages,
        ),
      );
      _lastKnownPlan = null;
      return;
    }
    final wird = KhatmahSchedulingEngine.todaysWird(
      result.plan.currentPage,
      result.plan.targetPagesPerDay,
    );
    if (result.plan.currentPage >= wird.endPage) {
      emit(KhatmahWirdCompleted(plan: result.plan));
    } else {
      _emitActive(result.plan);
    }
  }

  Future<void> pause() async {
    final current = state;
    if (current is! KhatmahActive) return;
    try {
      final paused = await _pauseResume.pause(current.plan);
      _lastKnownPlan = paused;
      emit(KhatmahPaused(plan: paused));
    } catch (error) {
      emit(
        KhatmahProgressFailure(
          plan: _lastKnownPlan,
          pageNumber: 0,
          source: KhatmahReadingSource.digital,
          error: error,
        ),
      );
    }
  }

  Future<void> resume() async {
    try {
      final plan = await _getActive();
      if (plan != null && plan.status == KhatmahStatus.paused) {
        final resumed = await _pauseResume.resume(plan);
        _lastKnownPlan = resumed;
        _emitActive(resumed);
      } else {
        await load();
      }
    } catch (error) {
      emit(
        KhatmahProgressFailure(
          plan: _lastKnownPlan,
          pageNumber: 0,
          source: KhatmahReadingSource.digital,
          error: error,
        ),
      );
    }
  }

  Future<void> calmAdjustment() => _adjustSchedule((plan) {
    final days = KhatmahSchedulingEngine.calculateDaysFromPages(
      plan.remainingPages,
      plan.targetPagesPerDay,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return plan.copyWith(
      targetDays: days,
      expectedEndDate: KhatmahSchedulingEngine.calculateEndDate(today, days),
    );
  });

  Future<void> mildCompensation([int extraPages = 1]) => _adjustSchedule((
    plan,
  ) {
    final target = plan.targetPagesPerDay + extraPages;
    final days = KhatmahSchedulingEngine.calculateDaysFromPages(
      plan.remainingPages,
      target,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return plan.copyWith(
      targetPagesPerDay: target,
      targetDays: days,
      expectedEndDate: KhatmahSchedulingEngine.calculateEndDate(today, days),
    );
  });

  Future<void> _adjustSchedule(
    KhatmahPlan Function(KhatmahPlan) transform,
  ) async {
    final current = state;
    if (current is! KhatmahActive || _updateSchedule == null) return;
    final adjusted = transform(current.plan);
    try {
      final updated = await _updateSchedule(
        planId: current.plan.id,
        targetPagesPerDay: adjusted.targetPagesPerDay,
        targetDays: adjusted.targetDays,
        expectedEndDate: adjusted.expectedEndDate,
      );
      _lastKnownPlan = updated;
      _emitActive(updated);
    } catch (error) {
      emit(
        KhatmahProgressFailure(
          plan: _lastKnownPlan,
          pageNumber: 0,
          source: KhatmahReadingSource.digital,
          error: error,
        ),
      );
    }
  }

  Future<void> abandonPlan() async {
    try {
      await _deleteKhatmah();
      _lastKnownPlan = null;
      emit(const KhatmahNoActivePlan());
    } catch (error) {
      emit(
        KhatmahProgressFailure(
          plan: _lastKnownPlan,
          pageNumber: 0,
          source: KhatmahReadingSource.digital,
          error: error,
        ),
      );
    }
  }

  void _emitActive(KhatmahPlan plan) {
    final wird = KhatmahSchedulingEngine.todaysWird(
      plan.currentPage,
      plan.targetPagesPerDay,
    );
    emit(
      KhatmahActive(
        plan: plan,
        wirdStartPage: wird.startPage,
        wirdEndPage: wird.endPage,
      ),
    );
  }
}
