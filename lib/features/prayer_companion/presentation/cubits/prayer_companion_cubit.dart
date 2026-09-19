import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/prayer_companion_controller.dart';
import '../../domain/entities/prayer_companion.dart';

/// States for a single in-sheet Companion action submission.
sealed class PrayerCompanionState extends Equatable {
  const PrayerCompanionState();

  @override
  List<Object?> get props => [];
}

class PrayerCompanionIdle extends PrayerCompanionState {
  const PrayerCompanionIdle();
}

class PrayerCompanionSubmitting extends PrayerCompanionState {
  const PrayerCompanionSubmitting();
}

class PrayerCompanionSuccess extends PrayerCompanionState {
  const PrayerCompanionSuccess(this.record);

  final PrayerCompanionRecord record;

  @override
  List<Object?> get props => [record];
}

class PrayerCompanionFailure extends PrayerCompanionState {
  const PrayerCompanionFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}

/// Sheet-scoped cubit that applies one explicit Companion command to the
/// current actionable occurrence.
///
/// Success is reported only after persistence succeeds — a failed write
/// always yields [PrayerCompanionFailure], never a fake confirmation.
class PrayerCompanionCubit extends Cubit<PrayerCompanionState> {
  PrayerCompanionCubit({
    required PrayerCompanionController controller,
    required PrayerOccurrence occurrence,
  }) : _controller = controller,
       _occurrence = occurrence,
       super(const PrayerCompanionIdle());

  final PrayerCompanionController _controller;
  final PrayerOccurrence _occurrence;

  Future<void> submit(PrayerCompanionCommand command) async {
    emit(const PrayerCompanionSubmitting());
    try {
      final record = await _controller.applyInApp(_occurrence, command);
      emit(PrayerCompanionSuccess(record));
    } catch (error) {
      emit(PrayerCompanionFailure(error));
    }
  }
}
