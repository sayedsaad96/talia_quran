import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

sealed class MemorizationTabState extends Equatable {
  const MemorizationTabState();
  @override
  List<Object?> get props => [];
}

class MemorizationTabLoading extends MemorizationTabState {
  const MemorizationTabLoading();
}

class MemorizationTabLoaded extends MemorizationTabState {
  const MemorizationTabLoaded(this.showPlan);
  final bool showPlan;
  @override
  List<Object?> get props => [showPlan];
}

class MemorizationTabError extends MemorizationTabState {
  const MemorizationTabError();
}

class MemorizationTabCubit extends Cubit<MemorizationTabState> {
  MemorizationTabCubit(
    this._repository,
    ProgressEventsBus events,
    MemorizationPathResolver resolver,
  ) : super(const MemorizationTabLoading()) {
    _events = events.changes.listen((reason) {
      if (reason == ProgressChangedReason.dailyPlan ||
          reason == ProgressChangedReason.cloudPull) {
        _schedule();
      }
    });
    _paths = resolver.changes.listen((_) => _schedule());
  }
  final MemorizationPlusRepository _repository;
  late final StreamSubscription<ProgressChangedReason> _events;
  late final StreamSubscription<void> _paths;
  Timer? _timer;
  int _generation = 0;
  Future<void> load() async {
    if (isClosed) return;
    final generation = ++_generation;
    final profileResult = await _repository.getMemorizationProfile();
    if (isClosed || generation != _generation) return;
    final profile = profileResult.fold((_) => null, (value) => value);
    if (profile == null) {
      emit(const MemorizationTabError());
      return;
    }
    if (!profile.isAdult) {
      _emit(false);
      return;
    }
    final planResult = await _repository.getCustomPlan();
    if (isClosed || generation != _generation) return;
    planResult.fold(
      (_) => emit(const MemorizationTabError()),
      (plan) => _emit(
        plan?.isActive == true && plan?.targetUser == PlanTargetUser.adult,
      ),
    );
  }

  void _emit(bool showPlan) {
    if (state is! MemorizationTabLoaded ||
        (state as MemorizationTabLoaded).showPlan != showPlan) {
      emit(MemorizationTabLoaded(showPlan));
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 250), () {
      if (!isClosed) unawaited(load());
    });
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _events.cancel();
    await _paths.cancel();
    return super.close();
  }
}
