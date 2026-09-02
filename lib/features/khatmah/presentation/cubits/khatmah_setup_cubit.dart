import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';
import '../../domain/entities/khatmah_dedication.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';
import '../../domain/usecases/create_khatmah_usecase.dart';

// ─── States ──────────────────────────────────────────────────────────────────
abstract class KhatmahSetupState extends Equatable {
  const KhatmahSetupState();

  @override
  List<Object?> get props => [];
}

class KhatmahSetupIdle extends KhatmahSetupState {
  const KhatmahSetupIdle();
}

class KhatmahSetupSaving extends KhatmahSetupState {
  const KhatmahSetupSaving();
}

class KhatmahSetupDone extends KhatmahSetupState {
  const KhatmahSetupDone(this.plan);

  final KhatmahPlan plan;

  @override
  List<Object?> get props => [plan];
}

class KhatmahSetupError extends KhatmahSetupState {
  const KhatmahSetupError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────
class KhatmahSetupCubit extends Cubit<KhatmahSetupState> {
  KhatmahSetupCubit(
    this._createKhatmah, {
    Uuid? uuid,
  })  : _uuid = uuid ?? const Uuid(),
        super(const KhatmahSetupIdle());

  final CreateKhatmahUsecase _createKhatmah;
  final Uuid _uuid;

  Future<void> createPlan({
    required int pagesPerDay,
    KhatmahDedication dedication = const KhatmahDedication(),
  }) async {
    emit(const KhatmahSetupSaving());
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final days = KhatmahSchedulingEngine.calculateDaysFromPages(
        KhatmahSchedulingEngine.totalPages,
        pagesPerDay,
      );
      final endDate = KhatmahSchedulingEngine.calculateEndDate(today, days);

      final title = dedication.isDedicated &&
              dedication.recipientName != null &&
              dedication.recipientName!.trim().isNotEmpty
          ? dedication.recipientName!.trim()
          : 'Khatmah';

      final plan = KhatmahPlan(
        id: _uuid.v4(),
        title: title,
        targetPagesPerDay: pagesPerDay,
        targetDays: days,
        startDate: today,
        expectedEndDate: endDate,
        dedication: dedication,
      );

      await _createKhatmah(plan);
      emit(KhatmahSetupDone(plan));
    } catch (e) {
      emit(KhatmahSetupError(e.toString()));
    }
  }
}
