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
  bool _isRecording = false;

  Future<void> load() async {
    emit(const KhatmahLoading());
    try {
      final plan = await _getActive();
      _lastKnownPlan = plan ?? _lastKnownPlan;
      if (plan == null || plan.status == KhatmahStatus.completed) {
        emit(const KhatmahNoActivePlan());
      } else if (plan.status == KhatmahStatus.paused) {
        emit(KhatmahPaused(plan: plan));
      } else {
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
      await _record(current.plan!, current.pageNumber, current.source);
    }
  }

  Future<void> _recordCurrent(
    int pageNumber,
    KhatmahReadingSource source,
  ) async {
    final plan = switch (state) {
      final KhatmahActive current => current.plan,
      final KhatmahWirdCompleted current => current.plan,
      final KhatmahPaused _ => null,
      final KhatmahProgressFailure current => current.plan,
      _ => null,
    };
    if (plan != null) {
      await _record(plan, pageNumber, source);
    }
  }

  Future<void> _record(
    KhatmahPlan plan,
    int pageNumber,
    KhatmahReadingSource source,
  ) async {
    if (_isRecording) return;
    _isRecording = true;
    try {
      final result = await _recordReading(plan, pageNumber, source: source);
      _lastKnownPlan = result.plan;
      _emitReadingResult(result);
    } catch (error) {
      emit(
        KhatmahProgressFailure(
          plan: plan,
          pageNumber: pageNumber,
          source: source,
          error: error,
        ),
      );
    } finally {
      _isRecording = false;
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
      emit(KhatmahPaused(plan: paused));
    } catch (error) {
      emit(
        KhatmahProgressFailure(
          plan: current.plan,
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
        _emitActive(await _pauseResume.resume(plan));
      } else {
        await load();
      }
    } catch (error) {
      final plan = state is KhatmahPaused
          ? (state as KhatmahPaused).plan
          : _lastKnownPlan;
      emit(
        KhatmahProgressFailure(
          plan: plan,
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
      await _updateSchedule(
        planId: current.plan.id,
        targetPagesPerDay: adjusted.targetPagesPerDay,
        targetDays: adjusted.targetDays,
        expectedEndDate: adjusted.expectedEndDate,
      );
      _emitActive(adjusted);
    } catch (error) {
      emit(
        KhatmahProgressFailure(
          plan: current.plan,
          pageNumber: 0,
          source: KhatmahReadingSource.digital,
          error: error,
        ),
      );
    }
  }

  Future<void> abandonPlan() async {
    await _deleteKhatmah();
    emit(const KhatmahNoActivePlan());
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
