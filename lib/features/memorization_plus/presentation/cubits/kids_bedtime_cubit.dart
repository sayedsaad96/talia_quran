import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/quran_continuous_player_service.dart';
import '../../../../core/services/sleep_timer.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../domain/entities/kids_journey_path_definition.dart';
import '../../domain/entities/kids_session_log.dart';
import '../../domain/services/kids_adventure_regions.dart';

enum KidsBedtimeStatus { loading, empty, ready, error }

/// Timer choices offered to the child; the default is 15 minutes.
const kKidsBedtimeTimerChoices = [
  SleepTimerChoice.min15,
  SleepTimerChoice.min30,
  SleepTimerChoice.off,
];

class KidsBedtimeState extends Equatable {
  const KidsBedtimeState({
    this.status = KidsBedtimeStatus.loading,
    this.surahs = const [],
    this.selected = const {},
    this.timer = SleepTimerChoice.min15,
    this.playing = false,
  });

  final KidsBedtimeStatus status;

  /// Memorized surahs in the order of the child's current journey path.
  final List<Surah> surahs;
  final Set<int> selected;
  final SleepTimerChoice timer;
  final bool playing;

  /// Selected surah ids in list order.
  List<int> get queue => [
    for (final surah in surahs)
      if (selected.contains(surah.id)) surah.id,
  ];

  KidsBedtimeState copyWith({
    KidsBedtimeStatus? status,
    List<Surah>? surahs,
    Set<int>? selected,
    SleepTimerChoice? timer,
    bool? playing,
  }) => KidsBedtimeState(
    status: status ?? this.status,
    surahs: surahs ?? this.surahs,
    selected: selected ?? this.selected,
    timer: timer ?? this.timer,
    playing: playing ?? this.playing,
  );

  @override
  List<Object?> get props => [status, surahs, selected, timer, playing];
}

typedef KidsBedtimeQueuePlayer =
    Future<void> Function(List<int> surahIds, SleepTimerChoice sleep);

/// «استماع قبل النوم»: plays the child's memorized surahs back to back.
/// Listening only: it never writes points, rewards or session logs.
class KidsBedtimeCubit extends Cubit<KidsBedtimeState> {
  KidsBedtimeCubit({
    required this._sessionLogs,
    required this._surahs,
    required this._pathLoader,
    required this._play,
    required this._stop,
    this._playback,
  }) : super(const KidsBedtimeState()) {
    _playback?.addListener(_onPlayback);
  }

  final Future<List<KidsSessionLog>> Function() _sessionLogs;
  final Future<List<Surah>> Function() _surahs;
  final Future<KidsJourneyPathDefinition> Function() _pathLoader;
  final KidsBedtimeQueuePlayer _play;
  final Future<void> Function() _stop;
  final ValueListenable<ContinuousPlaybackState>? _playback;

  Future<void> load() async {
    emit(const KidsBedtimeState());
    try {
      final logs = await _sessionLogs();
      final surahs = await _surahs();
      var path = KidsJourneyPathDefinition.adventure;
      try {
        path = await _pathLoader();
      } catch (_) {
        path = KidsJourneyPathDefinition.adventure;
      }
      final memorized = kidsMemorizedSurahIds(logs, {
        for (final surah in surahs) surah.id: surah.ayahCount,
      });
      final byId = {for (final surah in surahs) surah.id: surah};
      final pathIds = path.surahIds;
      // Path order first; anything memorized on an earlier path follows.
      final ordered = <int>[
        for (final id in pathIds)
          if (memorized.contains(id)) id,
        ...(memorized.where((id) => !pathIds.contains(id)).toList()..sort()),
      ];
      final list = [
        for (final id in ordered)
          if (byId[id] != null) byId[id]!,
      ];
      if (isClosed) return;
      emit(
        KidsBedtimeState(
          status: list.isEmpty
              ? KidsBedtimeStatus.empty
              : KidsBedtimeStatus.ready,
          surahs: list,
          selected: {for (final surah in list) surah.id},
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(const KidsBedtimeState(status: KidsBedtimeStatus.error));
      }
    }
  }

  void toggleSurah(int surahId) {
    final selected = Set<int>.of(state.selected);
    if (!selected.remove(surahId)) selected.add(surahId);
    emit(state.copyWith(selected: selected));
  }

  void setTimer(SleepTimerChoice choice) {
    if (!kKidsBedtimeTimerChoices.contains(choice)) return;
    emit(state.copyWith(timer: choice));
  }

  /// The running [start], so [stop] can wait for it: a stop that lands while
  /// the playlist is still loading must not be overtaken by that load.
  Future<void>? _pendingStart;

  Future<void> start() {
    final queue = state.queue;
    if (queue.isEmpty || state.playing || _pendingStart != null) {
      return Future<void>.value();
    }
    final run = _start(queue);
    _pendingStart = run;
    return run.whenComplete(() {
      if (identical(_pendingStart, run)) _pendingStart = null;
    });
  }

  Future<void> _start(List<int> queue) async {
    emit(state.copyWith(playing: true));
    try {
      await _play(queue, state.timer);
      final playback = _playback?.value;
      if (playback != null && playback.isError && !isClosed) {
        emit(state.copyWith(playing: false));
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(playing: false));
    }
  }

  Future<void> stop() async {
    if (!isClosed) emit(state.copyWith(playing: false));
    final pending = _pendingStart;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {}
    }
    try {
      await _stop();
    } catch (_) {}
  }

  /// The timer ending (or anything else stopping the player) shows Start
  /// again.
  void _onPlayback() {
    final playback = _playback?.value;
    if (playback == null || isClosed || !state.playing) return;
    if (playback.isIdle || playback.isError) {
      emit(state.copyWith(playing: false));
    }
  }

  @override
  Future<void> close() {
    _playback?.removeListener(_onPlayback);
    return super.close();
  }
}
