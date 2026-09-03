import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';
import '../../domain/entities/khatmah_dedication.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';
import '../../domain/usecases/create_khatmah_usecase.dart';
import '../../domain/usecases/delete_khatmah_usecase.dart';

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

class KhatmahSetupConflict extends KhatmahSetupState {
  const KhatmahSetupConflict(
    this.existingPlan, {
    this.isAbandoning = false,
    this.errorMessage,
  });

  final KhatmahPlan existingPlan;
  final bool isAbandoning;
  final String? errorMessage;

  KhatmahSetupConflict copyWith({bool? isAbandoning, String? errorMessage}) =>
      KhatmahSetupConflict(
        existingPlan,
        isAbandoning: isAbandoning ?? this.isAbandoning,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [existingPlan, isAbandoning, errorMessage];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────
class KhatmahSetupCubit extends Cubit<KhatmahSetupState> {
  KhatmahSetupCubit(
    this._createKhatmah, {
    DeleteKhatmahUsecase? deleteKhatmah,
    Uuid? uuid,
  }) : _deleteKhatmah = deleteKhatmah,
       _uuid = uuid ?? const Uuid(),
       super(const KhatmahSetupIdle());

  final CreateKhatmahUsecase _createKhatmah;
  final DeleteKhatmahUsecase? _deleteKhatmah;
  final Uuid _uuid;
  Future<void>? _abandonInFlight;

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

      final title =
          dedication.isDedicated &&
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
    } on KhatmahPlanAlreadyExistsException catch (e) {
      emit(KhatmahSetupConflict(e.existingPlan));
    } catch (e) {
      emit(KhatmahSetupError(e.toString()));
    }
  }

  /// Deletes a plan only after the UI has obtained explicit user confirmation.
  /// Returning to idle deliberately requires a separate, user-initiated retry
  /// to create the replacement plan.
  Future<void> abandonExistingPlan() {
    final conflict = state;
    if (conflict is! KhatmahSetupConflict ||
        conflict.isAbandoning ||
        _deleteKhatmah == null) {
      return _abandonInFlight ?? Future.value();
    }
    return _abandonInFlight ??= _abandon(conflict).whenComplete(() {
      _abandonInFlight = null;
    });
  }

  Future<void> _abandon(KhatmahSetupConflict conflict) async {
    emit(conflict.copyWith(isAbandoning: true));
    try {
      await _deleteKhatmah!(expectedPlanId: conflict.existingPlan.id);
      emit(const KhatmahSetupIdle());
    } catch (e) {
      emit(conflict.copyWith(errorMessage: e.toString()));
    }
  }
}
