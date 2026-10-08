import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/daily_reading_log_service.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/services/activity_event_recorder.dart';
import '../../../../features/home/domain/entities/activity_event.dart';
import '../../../../features/memorization_plus/data/datasources/kids_streak_store.dart';
import '../../../../features/progress/domain/usecases/save_read_page_usecase.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/repositories/quran_repository.dart';

abstract class QuranPageState extends Equatable {
  const QuranPageState();
  @override
  List<Object?> get props => [];
}

class QuranPageInitial extends QuranPageState {}

class QuranPageLoading extends QuranPageState {}

class QuranPageLoaded extends QuranPageState {
  const QuranPageLoaded(
    this.detail, {
    this.isReadConfirmed = false,
    this.readConfirmationError,
  });
  final QuranPageDetail detail;
  final bool isReadConfirmed;
  final String? readConfirmationError;
  @override
  List<Object?> get props => [detail, isReadConfirmed, readConfirmationError];
}

class QuranPageError extends QuranPageState {
  const QuranPageError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class QuranPageCubit extends Cubit<QuranPageState> {
  QuranPageCubit(
    this._repository,
    this._saveReadPage,
    this._streakService, [
    this._readingLog,
    this._activityRecorder,
    this._kidsStreak,
  ]) : super(QuranPageInitial());

  final QuranRepository _repository;
  final SaveReadPageUsecase _saveReadPage;
  final StreakService _streakService;
  final DailyReadingLogService? _readingLog;
  final ActivityEventRecorder? _activityRecorder;
  final KidsStreakStore? _kidsStreak;

  Future<void> loadPage(int pageNumber) async {
    emit(QuranPageLoading());
    final result = await _repository.getQuranPage(pageNumber);
    result.fold(
      (failure) => emit(QuranPageError(failure.message)),
      (detail) => emit(QuranPageLoaded(detail)),
    );
  }

  /// Confirms a page read in the ordinary Quran-reading journey.
  ///
  /// Khatmah progress is owned by [KhatmahCubit]. Its reader records only the
  /// streak here; it must not enter the rest of this generic pipeline, because
  /// generic read pages feed the daily-wird state and reading metrics.
  Future<bool> confirmRead(
    int pageNumber, {
    bool recordOrdinaryReading = true,
  }) async {
    final current = state;
    if (current is! QuranPageLoaded) return false;
    if (current.isReadConfirmed) return true;

    if (!recordOrdinaryReading) {
      // Khatmah reading is real reading for the streak, but it must stay
      // separate from free reading: no read-page stats, reading log, or
      // daily-wird progress — those belong to the ordinary journey.
      try {
        await _streakService.recordActivity();
      } catch (_) {
        // Streak recording is supplementary and must not invalidate reading.
      }
      if (_isShowing(pageNumber)) {
        emit(
          QuranPageLoaded(
            current.detail,
            isReadConfirmed: true,
            readConfirmationError: current.readConfirmationError,
          ),
        );
      }
      return true;
    }

    final saveResult = await _saveReadPage(pageNumber);
    final failure = saveResult.fold((failure) => failure, (_) => null);
    if (failure != null) {
      if (_isShowing(pageNumber)) {
        emit(
          QuranPageLoaded(
            current.detail,
            readConfirmationError: failure.message,
          ),
        );
      }
      return false;
    }

    try {
      await _streakService.recordActivity();
    } catch (_) {
      // Streak recording is supplementary and must not invalidate reading.
    }
    try {
      await _readingLog?.recordPage(pageNumber);
    } catch (_) {}
    try {
      final surahId = current.detail.surahs.isEmpty
          ? null
          : current.detail.surahs.first.id;
      final ayahs = current.detail.ayahs;
      await _activityRecorder?.record(
        ActivityEvent(
          occurredAt: DateTime.now(),
          kind: ActivityEventKind.reading,
          idempotencyKey:
              'reading|${ActivityEventRecorder.dayKey(DateTime.now())}|$pageNumber',
          surahId: surahId,
          startAyah: ayahs.isEmpty ? null : ayahs.first.numberInSurah,
          endAyah: ayahs.isEmpty ? null : ayahs.last.numberInSurah,
          pageNumber: pageNumber,
        ),
      );
    } catch (_) {}
    if (_isShowing(pageNumber)) {
      emit(QuranPageLoaded(current.detail, isReadConfirmed: true));
    }
    return true;
  }

  /// Confirms a page read in the kids reader. Kids reading belongs to the
  /// kids track only: its own streak and kids-tagged activity. The primary
  /// learner's read pages, reading log, streak and daily wird stay untouched.
  Future<bool> confirmKidsRead(int pageNumber) async {
    final current = state;
    if (current is! QuranPageLoaded ||
        current.detail.pageNumber != pageNumber) {
      return false;
    }
    if (current.isReadConfirmed) return true;

    try {
      await _kidsStreak?.recordActivity();
    } catch (_) {
      // Streak recording is supplementary and must not invalidate reading.
    }
    try {
      final now = DateTime.now();
      final ayahs = current.detail.ayahs;
      await _activityRecorder?.record(
        ActivityEvent(
          occurredAt: now,
          kind: ActivityEventKind.reading,
          idempotencyKey:
              'reading|kids|${ActivityEventRecorder.dayKey(now)}|$pageNumber',
          surahId: current.detail.surahs.isEmpty
              ? null
              : current.detail.surahs.first.id,
          startAyah: ayahs.isEmpty ? null : ayahs.first.numberInSurah,
          endAyah: ayahs.isEmpty ? null : ayahs.last.numberInSurah,
          pageNumber: pageNumber,
          isKids: true,
        ),
      );
    } catch (_) {}
    if (_isShowing(pageNumber)) {
      emit(QuranPageLoaded(current.detail, isReadConfirmed: true));
    }
    return true;
  }

  /// A confirmation finishes after several awaits; by then the reader may
  /// have loaded the next page. Emitting the old page's state would replace
  /// it and cancel that page's read timer, so its read would never count.
  bool _isShowing(int pageNumber) {
    final latest = state;
    return !isClosed &&
        latest is QuranPageLoaded &&
        latest.detail.pageNumber == pageNumber;
  }
}
