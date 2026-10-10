import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../domain/entities/plan_details.dart';
import '../../domain/usecases/get_plan_details_usecase.dart';

sealed class PlanDetailsState extends Equatable {
  const PlanDetailsState();
  @override
  List<Object?> get props => [];
}

class PlanDetailsLoading extends PlanDetailsState {
  const PlanDetailsLoading();
}

class PlanDetailsEmpty extends PlanDetailsState {
  const PlanDetailsEmpty();
}

class PlanDetailsLoaded extends PlanDetailsState {
  const PlanDetailsLoaded(this.details);
  final PlanDetails details;
  @override
  List<Object?> get props => [details];
}

class PlanDetailsError extends PlanDetailsState {
  const PlanDetailsError();
}

class PlanDetailsCubit extends Cubit<PlanDetailsState> {
  PlanDetailsCubit(this._getDetails, ProgressEventsBus events)
    : super(const PlanDetailsLoading()) {
    _subscription = events.changes.listen((reason) {
      if (reason == ProgressChangedReason.reviewRecord ||
          reason == ProgressChangedReason.dailyPlan ||
          reason == ProgressChangedReason.cloudPull) {
        _scheduleLoad();
      }
    });
  }
  final GetPlanDetailsUseCase _getDetails;
  late final StreamSubscription<ProgressChangedReason> _subscription;
  Timer? _debounce;
  int _generation = 0;

  Future<void> load() async {
    if (isClosed) return;
    final generation = ++_generation;
    if (state is! PlanDetailsLoaded) emit(const PlanDetailsLoading());
    final result = await _getDetails();
    if (isClosed || generation != _generation) return;
    result.fold((_) => emit(const PlanDetailsError()), (details) {
      emit(
        details == null ? const PlanDetailsEmpty() : PlanDetailsLoaded(details),
      );
    });
  }

  Future<String?> sessionLocation() async {
    await load();
    final current = state;
    if (current is! PlanDetailsLoaded || !current.details.canStartSession) {
      return null;
    }
    try {
      return await _getDetails.sessionLocation();
    } catch (error, stack) {
      TaliaLogger.e('Plan details: session location failed', error, stack);
      if (!isClosed) emit(const PlanDetailsError());
      return null;
    }
  }

  void _scheduleLoad() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!isClosed) unawaited(load());
    });
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await _subscription.cancel();
    return super.close();
  }
}
