import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/core/services/reader_repeat_plan.dart';
import 'package:talia_quran/core/services/sleep_timer.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

import 'quran_continuous_player_service_test.dart';

class RecordingPlayer extends ControlledAudioPlayer {
  final List<LoopMode> loopModes = [];
  final List<double> speeds = [];
  final List<double> volumes = [];
  List<AudioSource> lastSources = const [];
  List<AudioSource> sources = [];
  final List<(int, int)> removedRanges = [];
  final List<String> calls = [];
  bool failRemove = false;

  @override
  Future<void> removeAudioSourceRange(int start, int end) async {
    calls.add('remove');
    if (failRemove) throw StateError('remove failed');
    removedRanges.add((start, end));
    sources = sources.sublist(0, start) + sources.sublist(end);
  }

  @override
  Future<void> addAudioSources(List<AudioSource> audioSources) async {
    sources = [...sources, ...audioSources];
  }

  @override
  Future<void> setLoopMode(LoopMode mode) async {
    calls.add('loop:${mode.name}');
    loopModes.add(mode);
  }

  @override
  Future<void> setSpeed(double speed) async => speeds.add(speed);

  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> sources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) {
    lastSources = sources;
    this.sources = List<AudioSource>.of(sources);
    return super.setAudioSources(
      sources,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
    );
  }
}

Ayah _ayah(int surah, int n, int global) => Ayah(
  number: global,
  surahId: surah,
  text: 'x',
  numberInSurah: n,
  juz: 1,
  page: 2,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranContinuousPlayerService service;
  late FakeQuranRepository repository;
  late RecordingPlayer player;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = FakeQuranRepository();
    repository.pageDetails[2] = QuranPageDetail(
      pageNumber: 2,
      surahs: const [],
      ayahs: [_ayah(1, 7, 7), _ayah(2, 1, 8), _ayah(2, 2, 9)],
    );
    player = RecordingPlayer();
    service = QuranContinuousPlayerService(
      quranRepository: repository,
      reciterService: QuranReciterService(prefs),
      player: player,
    );
  });

  tearDown(() async {
    service.dispose();
    await player.closeControllers();
  });

  test(
    'default settings keep the queue, loop off and no speed calls',
    () async {
      await service.playPage(1);
      expect(player.lastSources.length, 2);
      expect(player.loopModes, isEmpty);
      expect(player.speeds, isEmpty);
      expect(service.state.repeat.isDefault, isTrue);
    },
  );

  test(
    'setRepeat(perAyah 3) rebuilds the whole range and resumes at the '
    'current ayah',
    () async {
      await service.playPage(2);
      player.advanceToIndex(1);
      await Future<void>.delayed(Duration.zero);
      expect(service.state.currentAyahNumber, 1);
      expect(service.state.currentSurahId, 2);

      await service.setRepeat(const ReaderRepeatSettings(perAyah: 3));
      await Future<void>.delayed(Duration.zero);

      // All three ayahs, three times each; playback resumes at s2:1.
      expect(player.lastSources.length, 9);
      expect(service.state.currentSurahId, 2);
      expect(service.state.currentAyahNumber, 1);
      player.advanceToIndex(6);
      await Future<void>.delayed(Duration.zero);
      expect(service.state.currentAyahNumber, 2);
      expect(service.state.repeat.perAyah, 3);
    },
  );

  test('a passage repeat chosen mid-range replays the whole range', () async {
    await service.playPage(2);
    player.advanceToIndex(1);
    await Future<void>.delayed(Duration.zero);

    await service.setRepeat(const ReaderRepeatSettings(rangeTimes: 2));
    await Future<void>.delayed(Duration.zero);

    expect(player.lastSources.length, 6);
    expect(service.state.currentSurahId, 2);
    expect(service.state.currentAyahNumber, 1);
    // The second pass starts again at the first ayah of the range.
    player.advanceToIndex(3);
    await Future<void>.delayed(Duration.zero);
    expect(service.state.currentSurahId, 1);
    expect(service.state.currentAyahNumber, 7);
  });

  test('endOfSurah with passage repeats stops at the end of the current '
      'pass', () async {
    repository.pageDetails[3] = QuranPageDetail(
      pageNumber: 3,
      surahs: const [],
      ayahs: [_ayah(2, 3, 10), _ayah(2, 4, 11)],
    );
    await service.playPage(3);
    await service.setRepeat(const ReaderRepeatSettings(rangeTimes: 3));
    await Future<void>.delayed(Duration.zero);
    expect(player.lastSources.length, 6);

    await service.setSleepTimer(SleepTimerChoice.endOfSurah);
    // One surah across all passes: only the first pass (2 items) is kept.
    expect(player.sources.length, 2);
  });

  test('nextAyah with repeats jumps to the next distinct ayah', () async {
    await service.setRepeat(const ReaderRepeatSettings(perAyah: 3));
    await service.playPage(2, applyReaderSettings: true);
    expect(player.lastSources.length, 9);
    expect(service.state.hasPrevious, isFalse);

    await service.nextAyah();
    await Future<void>.delayed(Duration.zero);
    expect(service.state.currentSurahId, 2);
    expect(service.state.currentAyahNumber, 1);

    await service.previousAyah();
    await Future<void>.delayed(Duration.zero);
    expect(service.state.currentSurahId, 1);
    expect(service.state.currentAyahNumber, 7);
  });

  test('rangeTimes 0 sets LoopMode.all; back to 1 sets LoopMode.off', () async {
    await service.playPage(1);
    await service.setRepeat(const ReaderRepeatSettings(rangeTimes: 0));
    await Future<void>.delayed(Duration.zero);
    expect(player.loopModes.last, LoopMode.all);
    expect(player.lastSources.length, 2);

    await service.setRepeat(const ReaderRepeatSettings());
    await Future<void>.delayed(Duration.zero);
    expect(player.loopModes.last, LoopMode.off);
  });

  test('speed change applies the normalized speed without a rebuild', () async {
    await service.playPage(1);
    final sources = player.lastSources;
    await service.setRepeat(const ReaderRepeatSettings(speed: 1.25));
    expect(player.speeds.last, 1.25);
    expect(identical(player.lastSources, sources), isTrue);
    await service.setRepeat(const ReaderRepeatSettings(speed: 0.9));
    expect(player.speeds.last, 1.0);
  });

  test(
    'endOfSurah truncates the playlist and ends after the last ayah',
    () async {
      await service.playPage(2); // s1:7, s2:1, s2:2 -> choice made on surah 1
      await service.setSleepTimer(SleepTimerChoice.endOfSurah);
      expect(service.state.sleepChoice, SleepTimerChoice.endOfSurah);
      expect(player.sources.length, 1);
      expect(player.removedRanges, [(1, 3)]);

      player.finishCurrentTrack();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(service.state.isIdle, isTrue);
      expect(service.state.sleepChoice, SleepTimerChoice.off);
    },
  );

  test('previous while endOfSurah is active does not stop playback', () async {
    await service.playPage(2);
    player.advanceToIndex(1);
    await Future<void>.delayed(Duration.zero);
    await service.setSleepTimer(SleepTimerChoice.endOfSurah);
    await service.previousAyah();
    await Future<void>.delayed(Duration.zero);
    expect(service.state.isIdle, isFalse);
    expect(service.state.currentSurahId, 1);
    expect(service.state.sleepChoice, SleepTimerChoice.endOfSurah);
  });

  test(
    'a new play call re-anchors endOfSurah to the surah that starts',
    () async {
      await service.playPage(2);
      await service.setSleepTimer(SleepTimerChoice.endOfSurah); // anchored: s1
      await service.playPage(
        2,
        startAyahIndex: 1,
        applyReaderSettings: true,
      ); // now anchored: s2
      expect(service.state.sleepChoice, SleepTimerChoice.endOfSurah);
      expect(player.sources.length, 3);
      player.advanceToIndex(2);
      await Future<void>.delayed(Duration.zero);
      expect(service.state.isIdle, isFalse);
      expect(service.state.currentAyahNumber, 2);
    },
  );

  test(
    'choosing off after endOfSurah restores the tail and loop mode',
    () async {
      await service.setRepeat(const ReaderRepeatSettings(rangeTimes: 0));
      await service.playPage(2, applyReaderSettings: true);
      expect(player.loopModes.last, LoopMode.all);
      await service.setSleepTimer(SleepTimerChoice.endOfSurah);
      expect(player.sources.length, 1);
      expect(player.loopModes.last, LoopMode.off);

      await service.setSleepTimer(SleepTimerChoice.off);
      expect(player.sources.length, 3);
      expect(service.state.hasNext, isTrue);
      expect(player.loopModes.last, LoopMode.all);
    },
  );

  test('changeReciter keeps the endOfSurah tail so Off restores it', () async {
    await service.playPage(2); // s1:7, s2:1, s2:2
    await service.setSleepTimer(SleepTimerChoice.endOfSurah);
    expect(player.sources.length, 1);

    await service.changeReciter(QuranReciter.abdulbasit);
    expect(player.lastSources.length, 1);

    await service.setSleepTimer(SleepTimerChoice.off);
    expect(player.sources.length, 3);
  });

  test('changeReciter keeps a paused session paused', () async {
    await service.playPage(1);
    await service.pause();
    final plays = player.playCallCount;
    await service.changeReciter(QuranReciter.abdulbasit);
    expect(player.playCallCount, plays);
    expect(service.state.status, PlaybackStatus.paused);
  });

  test(
    'endOfSurah immediately followed by Off ends with the full list',
    () async {
      await service.playPage(2);
      final first = service.setSleepTimer(SleepTimerChoice.endOfSurah);
      final second = service.setSleepTimer(SleepTimerChoice.off);
      await Future.wait([first, second]);
      expect(service.state.sleepChoice, SleepTimerChoice.off);
      expect(player.sources.length, 3);
      expect(service.state.hasNext, isTrue);
    },
  );

  test('repeat change while paused does not call play()', () async {
    await service.playPage(1);
    await service.pause();
    final plays = player.playCallCount;
    await service.setRepeat(const ReaderRepeatSettings(perAyah: 2));
    expect(player.playCallCount, plays);
    expect(service.state.status, PlaybackStatus.paused);
    expect(player.lastSources.length, 4);
  });

  test('endOfSurah keeps playing inside the same surah', () async {
    await service.playPage(2);
    player.advanceToIndex(1);
    await Future<void>.delayed(Duration.zero);
    await service.setSleepTimer(SleepTimerChoice.endOfSurah);
    player.advanceToIndex(2);
    await Future<void>.delayed(Duration.zero);
    expect(service.state.isIdle, isFalse);
    expect(service.state.currentAyahNumber, 2);
  });

  test('sleep timer choice and repeat reset when playback stops', () async {
    await service.playPage(1);
    await service.setSleepTimer(SleepTimerChoice.min15);
    await service.setRepeat(const ReaderRepeatSettings(perAyah: 2, speed: 1.5));
    expect(service.state.sleepChoice, SleepTimerChoice.min15);

    await service.stop();
    expect(service.state.sleepChoice, SleepTimerChoice.off);
    expect(service.state.repeat.isDefault, isTrue);
    expect(player.loopModes.last, LoopMode.off);
    expect(player.speeds.last, 1.0);
  });

  test('a fresh playSurah loading state already reports hasNext', () async {
    final loadingStates = <ContinuousPlaybackState>[];
    service.stateNotifier.addListener(() {
      if (service.state.isLoading) loadingStates.add(service.state);
    });
    await service.playSurah(1);
    expect(loadingStates, isNotEmpty);
    expect(loadingStates.last.hasNext, isTrue);
    expect(loadingStates.last.hasPrevious, isFalse);
  });

  test('endOfSurah turns the loop off before removing the tail', () async {
    await service.setRepeat(const ReaderRepeatSettings(rangeTimes: 0));
    await service.playPage(2, applyReaderSettings: true);
    player.calls.clear();
    await service.setSleepTimer(SleepTimerChoice.endOfSurah);
    expect(player.calls.take(2), ['loop:off', 'remove']);
  });

  test('a failed tail removal restores the loop mode', () async {
    await service.setRepeat(const ReaderRepeatSettings(rangeTimes: 0));
    await service.playPage(2, applyReaderSettings: true);
    player.failRemove = true;
    await service.setSleepTimer(SleepTimerChoice.endOfSurah);
    expect(player.loopModes.last, LoopMode.all);
    expect(player.sources.length, 3);
  });

  test(
    'repeat, speed and sleep apply only to playback from the reader',
    () async {
      await service.setRepeat(
        const ReaderRepeatSettings(perAyah: 3, speed: 1.5),
      );
      await service.playPage(2, applyReaderSettings: true);
      expect(player.lastSources.length, 9);
      expect(player.speeds.last, 1.5);
      await service.setSleepTimer(SleepTimerChoice.endOfSurah);

      player.speeds.clear();
      await service.playPage(2); // another surface: no reader settings
      expect(player.lastSources.length, 3);
      expect(service.state.repeat.isDefault, isTrue);
      expect(service.state.sleepChoice, SleepTimerChoice.off);
      expect(player.speeds.every((s) => s == 1.0), isTrue);
      expect(player.loopModes.last, LoopMode.off);
    },
  );

  group('playAyahRange', () {
    setUp(() {
      repository.surahDetails[5] = SurahDetail(
        surah: const Surah(
          id: 5,
          nameAr: 'x',
          nameEn: 'x',
          type: 'medinan',
          ayahCount: 6,
          juz: 1,
          page: 2,
        ),
        ayahs: [for (var n = 1; n <= 6; n++) _ayah(5, n, 100 + n)],
      );
    });

    test('plays exactly the range with perAyah and rangeTimes', () async {
      await service.setRepeat(
        const ReaderRepeatSettings(perAyah: 2, rangeTimes: 2),
      );
      expect(await service.playAyahRange(5, 2, 4), isTrue);
      await Future<void>.delayed(Duration.zero);

      // 3 ayahs x 2 each x 2 passes.
      expect(player.lastSources.length, 12);
      expect(service.state.currentSurahId, 5);
      expect(service.state.currentAyahNumber, 2);
      expect(service.state.repeat.perAyah, 2);
      player.advanceToIndex(6); // second pass, first ayah
      await Future<void>.delayed(Duration.zero);
      expect(service.state.currentAyahNumber, 2);
      player.advanceToIndex(11);
      await Future<void>.delayed(Duration.zero);
      expect(service.state.currentAyahNumber, 4);
    });

    test('rangeTimes 0 loops the range', () async {
      await service.setRepeat(const ReaderRepeatSettings(rangeTimes: 0));
      await service.playAyahRange(5, 3, 4);
      expect(player.lastSources.length, 2);
      expect(player.loopModes.last, LoopMode.all);
    });

    test('end is clamped to the surah ayah count', () async {
      expect(await service.playAyahRange(5, 5, 50), isTrue);
      expect(player.lastSources.length, 2);
    });

    test('invalid ranges are rejected and leave playback untouched', () async {
      await service.playPage(1);
      final before = player.lastSources.length;
      expect(await service.playAyahRange(5, 4, 2), isFalse);
      expect(await service.playAyahRange(5, 0, 2), isFalse);
      expect(await service.playAyahRange(5, 7, 9), isFalse);
      expect(await service.playAyahRange(99, 1, 2), isFalse);
      expect(player.lastSources.length, before);
      expect(service.state.hasActiveAudio, isTrue);
      expect(service.state.currentSurahId, 1);
    });

    test('setRepeat afterwards rebuilds only the range', () async {
      await service.playAyahRange(5, 2, 3);
      await service.setRepeat(const ReaderRepeatSettings(perAyah: 3));
      await Future<void>.delayed(Duration.zero);
      expect(player.lastSources.length, 6);
      expect(service.state.currentAyahNumber, 2);
    });

    test('endOfSurah keeps the range to the end of the pass', () async {
      await service.setRepeat(const ReaderRepeatSettings(rangeTimes: 3));
      await service.playAyahRange(5, 1, 2);
      await service.setSleepTimer(SleepTimerChoice.endOfSurah);
      expect(player.sources.length, 2);
    });
  });
}
