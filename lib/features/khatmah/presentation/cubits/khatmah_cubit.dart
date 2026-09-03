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
  const _RecordRequestKey(this.planId, this.source, this.pageNumber);

  final String planId;
  final KhatmahReadingSource source;
  final int pageNumber;

  @override
  bool operator ==(Object other) =>
      other is _RecordRequestKey &&
      other.planId == planId &&
      other.source == source &&
      other.pageNumber == pageNumber;

  @override
  int get hashCode => Object.hash(planId, source, pageNumber);
}

class _RecordRequest {
  _RecordRequest(String planId, this.source, this.pageNumber)
    : key = _RecordRequestKey(planId, source, pageNumber);

  final KhatmahReadingSource source;
  final int pageNumber;
  final _RecordRequestKey key;
  final Completer<void> completer = Completer<void>();
}

class _FailedRecordRequest {
  _FailedRecordRequest(this.request, this.error);

  final _RecordRequest request;
  final Object error;
}

class KhatmahCubit extends Cubit<KhatmahState> {
  KhatmahCubit(
    this._getActive,
    this._recordReading,
    this._pauseResume,
    this._deleteKhatmah, {
    UpdateKhatmahScheduleUsecase? updateSchedule,
    Duration shutdownTimeout = const Duration(seconds: 2),
  }) : _updateSchedule = updateSchedule,
       _shutdownTimeout = shutdownTimeout,
       super(const KhatmahInitial());

  final GetActiveKhatmahUsecase _getActive;
  final RecordKhatmahReadingUsecase _recordReading;
  final PauseResumeKhatmahUsecase _pauseResume;
  final DeleteKhatmahUsecase _deleteKhatmah;

  // Retained only for the existing scheduling-adjustment controls. Reader
  // progress must use RecordKhatmahReadingUsecase through the methods below.
  final UpdateKhatmahScheduleUsecase? _updateSchedule;
  final Duration _shutdownTimeout;
  KhatmahPlan? _lastKnownPlan;
  final Map<_RecordRequestKey, Completer<void>> _pendingRecordRequests = {};
  final Map<_RecordRequestKey, _FailedRecordRequest> _failedRecordRequests = {};
  Future<void> _recordTail = Future<void>.value();
  Future<void>? _closeFuture;
  bool _closing = false;

  @override
  Future<void> close() {
    final existing = _closeFuture;
    if (existing != null) return existing;

    _closing = true;
    final acceptedTail = _recordTail
        .timeout(_shutdownTimeout)
        .then<void>(
          (_) {},
          onError: (Object _, StackTrace _) {
            // Timeout or an unexpected tail error must not block final closure.
          },
        );
    final closing = acceptedTail.then((_) => super.close());
    _closeFuture = closing;
    return closing;
  }

  Future<void> load() async {
    _emitIfOpen(const KhatmahLoading());
    try {
      final plan = await _getActive();
      if (plan == null || plan.status == KhatmahStatus.completed) {
        _failedRecordRequests.clear();
        _lastKnownPlan = null;
        _emitIfOpen(const KhatmahNoActivePlan());
      } else if (plan.status == KhatmahStatus.paused) {
        _discardFailuresOutsidePlan(plan.id);
        _lastKnownPlan = plan;
        _emitIfOpen(KhatmahPaused(plan: plan));
      } else {
        _discardFailuresOutsidePlan(plan.id);
        _lastKnownPlan = plan;
        _emitActive(plan);
      }
    } catch (error) {
      _emitIfOpen(
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
    final plan = _recordingPlan;
    if (plan == null) return;
    final failures = _failedRecordRequests.values.where(
      (failed) => failed.request.key.planId == plan.id,
    );
    final failed = failures.isEmpty ? null : failures.last;
    if (failed != null) {
      await _recordCurrent(failed.request.pageNumber, failed.request.source);
    }
  }

  Future<void> _recordCurrent(int pageNumber, KhatmahReadingSource source) {
    if (_closing || isClosed) return Future<void>.value();
    final plan = _recordingPlan;
    if (plan == null) return Future<void>.value();

    final key = _RecordRequestKey(plan.id, source, pageNumber);
    final pending = _pendingRecordRequests[key];
    if (pending != null) return pending.future;

    final request = _RecordRequest(plan.id, source, pageNumber);
    _pendingRecordRequests[key] = request.completer;
    _recordTail = _recordTail.then((_) => _executeRecord(request));
    return request.completer.future;
  }

  KhatmahPlan? get _recordingPlan {
    final plan =
        _lastKnownPlan ??
        switch (state) {
          final KhatmahActive current => current.plan,
          final KhatmahWirdCompleted current => current.plan,
          final KhatmahProgressFailure current => current.plan,
          _ => null,
        };
    return plan?.status == KhatmahStatus.active ? plan : null;
  }

  Future<void> _executeRecord(_RecordRequest request) async {
    try {
      final plan = _recordingPlan;
      if (plan == null || plan.id != request.key.planId) return;

      final result = await _recordReading(
        plan,
        request.pageNumber,
        source: request.source,
      );
      final latestPlan = _recordingPlan;
      if (latestPlan == null || latestPlan.id != request.key.planId) return;

      _lastKnownPlan = result.plan;
      _pruneCoveredFailures(result.plan);
      if (result.completed) {
        _clearFailuresForPlan(result.plan.id);
        _emitReadingResult(result);
        return;
      }

      _emitReadingResult(result);
      _emitOutstandingFailure(result.plan);
    } catch (error) {
      final plan = _recordingPlan;
      if (plan != null && plan.id == request.key.planId) {
        _rememberFailure(request, error);
        _emitOutstandingFailure(plan);
      }
    } finally {
      final pending = _pendingRecordRequests[request.key];
      if (identical(pending, request.completer)) {
        _pendingRecordRequests.remove(request.key);
      }
      if (!request.completer.isCompleted) request.completer.complete();
    }
  }

  void _rememberFailure(_RecordRequest request, Object error) {
    _failedRecordRequests[request.key] = _FailedRecordRequest(request, error);
  }

  void _pruneCoveredFailures(KhatmahPlan plan) {
    _failedRecordRequests.removeWhere(
      (key, _) =>
          key.planId == plan.id && plan.completedPages.contains(key.pageNumber),
    );
  }

  void _clearFailuresForPlan(String planId) {
    _failedRecordRequests.removeWhere((key, _) => key.planId == planId);
  }

  void _discardFailuresOutsidePlan(String planId) {
    _failedRecordRequests.removeWhere((key, _) => key.planId != planId);
  }

  void _emitOutstandingFailure(KhatmahPlan? plan) {
    if (plan == null) return;
    final failures = _failedRecordRequests.values.where(
      (failed) => failed.request.key.planId == plan.id,
    );
    if (failures.isEmpty) return;
    final failed = failures.last;
    _emitIfOpen(
      KhatmahProgressFailure(
        plan: plan,
        pageNumber: failed.request.pageNumber,
        source: failed.request.source,
        error: failed.error,
      ),
    );
  }

  void _emitReadingResult(KhatmahReadingResult result) {
    final history = result.historyEntry;
    if (history != null) {
      _emitIfOpen(
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
      _emitIfOpen(KhatmahWirdCompleted(plan: result.plan));
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
      _emitIfOpen(KhatmahPaused(plan: paused));
    } catch (error) {
      _emitIfOpen(
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
      _emitIfOpen(
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
      _emitIfOpen(
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
      _failedRecordRequests.clear();
      _lastKnownPlan = null;
      _emitIfOpen(const KhatmahNoActivePlan());
    } catch (error) {
      _emitIfOpen(
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
    _emitIfOpen(
      KhatmahActive(
        plan: plan,
        wirdStartPage: wird.startPage,
        wirdEndPage: wird.endPage,
      ),
    );
  }

  void _emitIfOpen(KhatmahState next) {
    if (!_closing && !isClosed) emit(next);
  }
}
