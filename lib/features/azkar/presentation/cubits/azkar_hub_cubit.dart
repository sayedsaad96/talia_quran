import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/azkar_completion_store.dart';
import '../../data/datasources/azkar_preferences_store.dart';
import '../../data/datasources/smart_wird_progress_store.dart';
import '../../domain/entities/azkar_entities.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../../domain/services/azkar_time_context.dart';

enum AzkarHubStatus { loading, ready, error }

class AzkarHubState extends Equatable {
  const AzkarHubState({
    required this.status,
    this.counts = const {},
    this.completion = const {},
    this.tasbeehTally = 0,
    this.period = AzkarPeriod.morning,
    this.smartWirdCompletedToday = false,
    this.smartWirdSessionCountToday = 0,
    this.error,
  });

  final AzkarHubStatus status;

  /// Approved record count per category.
  final Map<AzkarCategory, int> counts;

  /// Whether each category's daily wird is complete, computed live from the
  /// shared completion store — the single source of truth shared with Home.
  final Map<AzkarCategory, bool> completion;

  final int tasbeehTally;
  final AzkarPeriod period;

  /// Whether the smart wird was completed at least once today.
  final bool smartWirdCompletedToday;

  /// How many smart-wird sessions were completed today.
  final int smartWirdSessionCountToday;

  final String? error;

  bool get allEmpty => counts.values.every((count) => count == 0);

  AzkarHubState copyWith({
    AzkarHubStatus? status,
    Map<AzkarCategory, int>? counts,
    Map<AzkarCategory, bool>? completion,
    int? tasbeehTally,
    AzkarPeriod? period,
    bool? smartWirdCompletedToday,
    int? smartWirdSessionCountToday,
    String? error,
  }) =>
      AzkarHubState(
        status: status ?? this.status,
        counts: counts ?? this.counts,
        completion: completion ?? this.completion,
        tasbeehTally: tasbeehTally ?? this.tasbeehTally,
        period: period ?? this.period,
        smartWirdCompletedToday:
            smartWirdCompletedToday ?? this.smartWirdCompletedToday,
        smartWirdSessionCountToday:
            smartWirdSessionCountToday ?? this.smartWirdSessionCountToday,
        error: error,
      );

  @override
  List<Object?> get props => [
        status,
        counts,
        completion,
        tasbeehTally,
        period,
        smartWirdCompletedToday,
        smartWirdSessionCountToday,
        error,
      ];
}

/// Single source of truth for the Azkar Hub: loads counts and live completion
/// state through the repository instead of presentation-level data access.
class AzkarHubCubit extends Cubit<AzkarHubState> {
  AzkarHubCubit(
    this._repository,
    this._completionStore,
    this._prefsStore, {
    DateTime Function()? now,
    SmartWirdProgressStore? smartWirdStore,
  })  : _now = now ?? DateTime.now,
        _smartWirdStore = smartWirdStore,
        super(const AzkarHubState(status: AzkarHubStatus.loading));

  final AzkarRepository _repository;
  final AzkarCompletionStore _completionStore;
  final AzkarPreferencesStore _prefsStore;
  final SmartWirdProgressStore? _smartWirdStore;
  final DateTime Function() _now;

  Future<void> load([DateTime? nowOverride]) async {
    final now = nowOverride ?? _now();
    emit(state.copyWith(status: AzkarHubStatus.loading, error: null));
    final result = await _repository.getAllAzkar();
    if (isClosed) return;
    var failed = false;
    var failureMessage = '';
    final corpus = <AzkarCategory, List<Zikr>>{};
    result.fold(
      (failure) {
        failed = true;
        failureMessage = failure.message;
      },
      (data) => corpus.addAll(data),
    );
    if (failed) {
      emit(state.copyWith(status: AzkarHubStatus.error, error: failureMessage));
      return;
    }

    final counts = <AzkarCategory, int>{
      for (final entry in corpus.entries) entry.key: entry.value.length,
    };
    final completion = <AzkarCategory, bool>{
      for (final entry in corpus.entries)
        entry.key: _completionStore.isCompleteFromSessions(
          category: entry.key,
          items: entry.value,
          date: now,
        ),
    };

    // Smart-wird live state: completions logged today by the progress store.
    var smartCompletedToday = false;
    var smartSessionCount = 0;
    final smartStore = _smartWirdStore;
    if (smartStore != null) {
      final todayPrefix = _dayPrefix(now);
      smartSessionCount = smartStore
          .completionHistory()
          .where((time) => _dayPrefix(time) == todayPrefix)
          .length;
      smartCompletedToday = smartSessionCount > 0;
    }

    emit(
      state.copyWith(
        status: AzkarHubStatus.ready,
        counts: counts,
        completion: completion,
        tasbeehTally: _prefsStore.getTasbeehTally(now),
        period: AzkarTimeContext.resolvePeriod(now),
        smartWirdCompletedToday: smartCompletedToday,
        smartWirdSessionCountToday: smartSessionCount,
      ),
    );
  }

  String _dayPrefix(DateTime time) =>
      '${time.year}-${time.month}-${time.day}';

  /// Re-reads the daily tasbeeh tally after the sheet reports activity.
  void refreshTasbeehTally() {
    if (isClosed) return;
    emit(
      state.copyWith(tasbeehTally: _prefsStore.getTasbeehTally(_now())),
    );
  }
}
