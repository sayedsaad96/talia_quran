import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
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

  @override
  Future<void> setLoopMode(LoopMode mode) async => loopModes.add(mode);

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
    'setRepeat(perAyah 3) rebuilds the queue from the current ayah',
    () async {
      await service.playPage(2);
      player.advanceToIndex(1);
      await Future<void>.delayed(Duration.zero);
      expect(service.state.currentAyahNumber, 1);
      expect(service.state.currentSurahId, 2);

      await service.setRepeat(const ReaderRepeatSettings(perAyah: 3));
      await Future<void>.delayed(Duration.zero);

      // Current ayah (s2:1) and the one after it, three times each.
      expect(player.lastSources.length, 6);
      expect(service.state.currentSurahId, 2);
      expect(service.state.currentAyahNumber, 1);
      player.advanceToIndex(4);
      await Future<void>.delayed(Duration.zero);
      expect(service.state.currentAyahNumber, 2);
      expect(service.state.repeat.perAyah, 3);
    },
  );

  test('nextAyah with repeats jumps to the next distinct ayah', () async {
    await service.setRepeat(const ReaderRepeatSettings(perAyah: 3));
    await service.playPage(2);
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

  test('endOfSurah stops after the last ayah of the current surah', () async {
    await service.playPage(2); // s1:7, s2:1, s2:2 -> choice made on surah 1
    await service.setSleepTimer(SleepTimerChoice.endOfSurah);
    expect(service.state.sleepChoice, SleepTimerChoice.endOfSurah);

    player.advanceToIndex(1); // first ayah of the next surah
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(service.state.isIdle, isTrue);
    expect(service.state.sleepChoice, SleepTimerChoice.off);
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
}
