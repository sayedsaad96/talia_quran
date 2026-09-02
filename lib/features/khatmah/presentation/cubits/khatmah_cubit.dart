import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';
import '../../domain/usecases/complete_khatmah_usecase.dart';
import '../../domain/usecases/delete_khatmah_usecase.dart';
import '../../domain/usecases/get_active_khatmah_usecase.dart';
import '../../domain/usecases/pause_resume_khatmah_usecase.dart';
import '../../domain/usecases/update_khatmah_progress_usecase.dart';

// ─── States ──────────────────────────────────────────────────────────────────
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

class KhatmahWirdCompleted extends KhatmahState {
  const KhatmahWirdCompleted({required this.plan});

  final KhatmahPlan plan;

  @override
  List<Object?> get props => [plan];
}

class KhatmahCompleted extends KhatmahState {
  const KhatmahCompleted({required this.plan});

  final KhatmahPlan plan;

  @override
  List<Object?> get props => [plan];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────
class KhatmahCubit extends Cubit<KhatmahState> {
  KhatmahCubit(
    this._getActive,
    this._updateProgress,
    this._complete,
    this._pauseResume,
    this._deleteKhatmah,
  ) : super(const KhatmahInitial());

  final GetActiveKhatmahUsecase _getActive;
  final UpdateKhatmahProgressUsecase _updateProgress;
  final CompleteKhatmahUsecase _complete;
  final PauseResumeKhatmahUsecase _pauseResume;
  final DeleteKhatmahUsecase _deleteKhatmah;

  Future<void> load() async {
    emit(const KhatmahLoading());
    final plan = await _getActive();
    if (plan == null || plan.status != KhatmahStatus.active) {
      emit(const KhatmahNoActivePlan());
      return;
    }
    _emitActive(plan);
  }

  Future<void> advancePage(int pageNumber) async {
    final current = state;
    if (current is! KhatmahActive) return;

    final updated = await _updateProgress(current.plan, pageNumber);

    if (updated.currentPage >= KhatmahSchedulingEngine.totalPages) {
      await _complete(updated);
      emit(KhatmahCompleted(
        plan: updated.copyWith(status: KhatmahStatus.completed),
      ));
      return;
    }

    if (pageNumber >= current.wirdEndPage) {
      emit(KhatmahWirdCompleted(plan: updated));
      return;
    }

    _emitActive(updated);
  }

  Future<void> pause() async {
    final current = state;
    if (current is! KhatmahActive) return;
    await _pauseResume.pause(current.plan);
    emit(const KhatmahNoActivePlan());
  }

  Future<void> resume() async {
    final plan = await _getActive();
    if (plan != null && plan.status == KhatmahStatus.paused) {
      final resumed = await _pauseResume.resume(plan);
      _emitActive(resumed);
      return;
    }
    await load();
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
    emit(KhatmahActive(
      plan: plan,
      wirdStartPage: wird.startPage,
      wirdEndPage: wird.endPage,
    ));
  }
}
