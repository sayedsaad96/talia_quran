import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/audio_resume_store.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/core/services/reader_repeat_plan.dart';
import 'package:talia_quran/core/services/sleep_timer.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

import 'quran_continuous_player_repeat_test.dart';
import 'quran_continuous_player_service_test.dart';

Ayah _ayah(int surah, int n, int global) => Ayah(
  number: global,
  surahId: surah,
  text: 'x',
  numberInSurah: n,
  juz: 30,
  page: 604,
);

SurahDetail _surah(int id, int count, int firstGlobal) => SurahDetail(
  surah: Surah(
    id: id,
    nameAr: 's$id',
    nameEn: 's$id',
    type: 'meccan',
    ayahCount: count,
    juz: 30,
    page: 604,
  ),
  ayahs: [for (var n = 1; n <= count; n++) _ayah(id, n, firstGlobal + n - 1)],
);

List<String> _ids(List<AudioSource> sources) => [
  for (final s in sources) ((s as UriAudioSource).tag as MediaItem).id,
];

/// Holds setAudioSources until the test releases [gate].
class _GatedPlayer extends RecordingPlayer {
  Completer<void>? gate;
  final reached = Completer<void>();

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> sources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    if (!reached.isCompleted) reached.complete();
    await gate?.future;
    return super.setAudioSources(
      sources,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranContinuousPlayerService service;
  late FakeQuranRepository repository;
  late RecordingPlayer player;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = FakeQuranRepository();
    repository.surahDetails[113] = _surah(113, 5, 6222);
    repository.surahDetails[114] = _surah(114, 6, 6231);
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

  test('playSurahQueue queues every ayah of 114 then 113 in order', () async {
    await service.playSurahQueue([114, 113]);
    expect(_ids(player.lastSources), [
      for (var n = 1; n <= 6; n++) '114_$n',
      for (var n = 1; n <= 5; n++) '113_$n',
    ]);
    expect(service.state.isPlaying, isTrue);
    expect(service.state.currentSurahId, 114);
    expect(service.state.currentAyahNumber, 1);
  });

  test('playSurahQueue drops reader repeat/speed and never sets a speed '
      'other than 1.0', () async {
    await service.setRepeat(
      const ReaderRepeatSettings(perAyah: 3, rangeTimes: 0, speed: 1.5),
    );
    await service.playSurah(1, applyReaderSettings: true);
    player.speeds.clear();
    player.loopModes.clear();

    await service.playSurahQueue([114, 113], sleep: SleepTimerChoice.min15);
    expect(player.lastSources.length, 11);
    expect(service.state.repeat.isDefault, isTrue);
    expect(player.speeds.every((s) => s == 1.0), isTrue);
    expect(player.loopModes.every((m) => m == LoopMode.off), isTrue);
  });

  test('playSurahQueue from a clean player calls no setSpeed', () async {
    await service.playSurahQueue([114, 113], sleep: SleepTimerChoice.min30);
    expect(player.speeds, isEmpty);
    expect(player.loopModes, isEmpty);
  });

  test('playSurahQueue applies the sleep timer', () async {
    await service.playSurahQueue([114, 113], sleep: SleepTimerChoice.min15);
    expect(service.state.sleepChoice, SleepTimerChoice.min15);
    expect(service.sleepChoice, SleepTimerChoice.min15);
  });

  test('endOfSurah keeps the whole queue and ends after the last ayah of '
      'the last surah', () async {
    await service.playSurahQueue([
      114,
      113,
    ], sleep: SleepTimerChoice.endOfSurah);
    expect(service.state.sleepChoice, SleepTimerChoice.endOfSurah);
    expect(player.removedRanges, isEmpty);
    expect(player.sources.length, 11);
    expect(_ids(player.sources).last, '113_5');

    player.advanceToIndex(6); // first ayah of 113: still playing
    await Future<void>.delayed(Duration.zero);
    expect(service.state.isIdle, isFalse);
    expect(service.state.currentSurahId, 113);

    player.advanceToIndex(10);
    await Future<void>.delayed(Duration.zero);
    expect(service.state.currentAyahNumber, 5);
    player.finishCurrentTrack();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(service.state.isIdle, isTrue);
  });

  test('a later reader playSurah does not inherit the bedtime timer', () async {
    await service.playSurahQueue([114, 113], sleep: SleepTimerChoice.min15);
    await service.playSurah(114, applyReaderSettings: true);
    expect(service.state.sleepChoice, SleepTimerChoice.off);
    expect(player.lastSources.length, 6);
  });

  test(
    'a later reader playSurah does not inherit queue-wide endOfSurah',
    () async {
      await service.playSurahQueue([
        114,
        113,
      ], sleep: SleepTimerChoice.endOfSurah);
      await service.playSurah(114, applyReaderSettings: true);
      expect(service.state.sleepChoice, SleepTimerChoice.off);
    },
  );

  test('reader endOfSurah still cuts after the current surah', () async {
    repository.pageDetails[604] = QuranPageDetail(
      pageNumber: 604,
      surahs: const [],
      ayahs: [_ayah(113, 5, 6226), _ayah(114, 1, 6231), _ayah(114, 2, 6232)],
    );
    await service.playPage(604, applyReaderSettings: true);
    await service.setSleepTimer(SleepTimerChoice.endOfSurah);
    expect(player.removedRanges, [(1, 3)]);
  });

  group('leaving a queue session', () {
    setUp(() {
      repository.pageDetails[604] = QuranPageDetail(
        pageNumber: 604,
        surahs: const [],
        ayahs: [_ayah(113, 5, 6226), _ayah(114, 1, 6231), _ayah(114, 2, 6232)],
      );
    });

    test('a reader page after a queue cuts endOfSurah at the surah', () async {
      await service.playSurahQueue([114, 113]);
      await service.playPage(604, applyReaderSettings: true);
      await service.setSleepTimer(SleepTimerChoice.endOfSurah);
      expect(player.removedRanges, [(1, 3)]);
    });

    test('stop then a reader page cuts endOfSurah at the surah', () async {
      await service.playSurahQueue([114, 113]);
      await service.stop();
      await service.playPage(604, applyReaderSettings: true);
      await service.setSleepTimer(SleepTimerChoice.endOfSurah);
      expect(player.removedRanges, [(1, 3)]);
    });
  });

  group('audio resume position', () {
    test(
      'a queue session never saves; a reader playSurah still does',
      () async {
        final store = AudioResumeStore(prefs)..attach(service);
        addTearDown(store.detach);

        expect(service.state.isSurahQueue, isFalse);
        await service.playSurahQueue([114, 113]);
        expect(service.state.isSurahQueue, isTrue);
        player.advanceToIndex(7);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(prefs.getString('audio_resume_position'), isNull);

        await service.playSurah(114, applyReaderSettings: true);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(service.state.isSurahQueue, isFalse);
        expect(prefs.getString('audio_resume_position'), isNotNull);
        expect(store.position?.surahId, 114);
      },
    );
  });

  test('stop while the queue playlist is loading prevents playback', () async {
    final gated = _GatedPlayer()..gate = Completer<void>();
    final gatedService = QuranContinuousPlayerService(
      quranRepository: repository,
      reciterService: QuranReciterService(prefs),
      player: gated,
    );
    addTearDown(() async {
      gatedService.dispose();
      await gated.closeControllers();
    });

    final playing = gatedService.playSurahQueue([
      114,
      113,
    ], sleep: SleepTimerChoice.min15);
    await gated.reached.future;
    await gatedService.stop();
    gated.gate!.complete();
    await playing;
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(gated.playCallCount, 0);
    expect(gatedService.state.isIdle, isTrue);
    expect(gatedService.state.sleepChoice, SleepTimerChoice.off);
  });

  test('playSurahQueue with nothing loadable reports an error', () async {
    await service.playSurahQueue([999]);
    expect(service.state.isError, isTrue);
  });
}
