import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

// ---------------------------------------------------------------------------
// Controlled AudioPlayer mock
// ---------------------------------------------------------------------------
/// A test double for [AudioPlayer] that uses just_audio's playlist API
/// (setAudioSources / currentIndexStream / playerStateStream).
class ControlledAudioPlayer extends Mock implements AudioPlayer {
  final _playerStateController = StreamController<PlayerState>.broadcast(
    sync: true,
  );
  final _currentIndexController = StreamController<int?>.broadcast(sync: true);

  int _currentIndex = 0;
  int _playCallCount = 0;

  /// Exposed so tests can assert how many times play() was called.
  int get playCallCount => _playCallCount;

  /// Simulates the engine finishing the current track and moving to the next.
  void finishCurrentTrack() {
    _playerStateController.add(
      PlayerState(true, ProcessingState.completed),
    );
  }

  Future<void> closeControllers() async {
    await stop();
    await _playerStateController.close();
    await _currentIndexController.close();
  }

  /// Simulates the engine advancing to [index] (e.g., gapless transition).
  void advanceToIndex(int index) {
    _currentIndex = index;
    _currentIndexController.add(index);
    _playerStateController.add(PlayerState(true, ProcessingState.ready));
  }

  // ── AudioPlayer overrides ──────────────────────────────────────────────────

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  Stream<int?> get currentIndexStream => _currentIndexController.stream;

  @override
  Future<void> play() async {
    _playCallCount++;
    _playerStateController.add(PlayerState(true, ProcessingState.ready));
  }

  @override
  Future<void> pause() async {
    _playerStateController.add(PlayerState(false, ProcessingState.ready));
  }

  @override
  Future<void> stop() async {
    _playerStateController.add(PlayerState(false, ProcessingState.idle));
  }

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> sources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    _currentIndex = initialIndex ?? 0;
    // Emit buffering → ready to simulate engine startup.
    _playerStateController.add(PlayerState(false, ProcessingState.buffering));
    _playerStateController.add(PlayerState(false, ProcessingState.ready));
    _currentIndexController.add(_currentIndex);
    return const Duration(seconds: 1);
  }

  @override
  Future<void> seekToNext() async {
    advanceToIndex(_currentIndex + 1);
  }

  @override
  Future<void> seekToPrevious() async {
    if (_currentIndex > 0) advanceToIndex(_currentIndex - 1);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    if (index != null) advanceToIndex(index);
  }

  @override
  Future<void> dispose() => stop();
}

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------
class FakeQuranRepository implements QuranRepository {
  final Map<int, SurahDetail> surahDetails = {
    1: const SurahDetail(
      surah: Surah(
        id: 1,
        nameAr: 'الفاتحة',
        nameEn: 'Al-Fatihah',
        type: 'meccan',
        ayahCount: 7,
        juz: 1,
        page: 1,
      ),
      ayahs: [
        Ayah(
          number: 1,
          surahId: 1,
          text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          numberInSurah: 1,
          juz: 1,
          page: 1,
        ),
        Ayah(
          number: 2,
          surahId: 1,
          text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
          numberInSurah: 2,
          juz: 1,
          page: 1,
        ),
      ],
    ),
  };

  final Map<int, QuranPageDetail> pageDetails = {
    1: const QuranPageDetail(
      pageNumber: 1,
      surahs: [
        Surah(
          id: 1,
          nameAr: 'الفاتحة',
          nameEn: 'Al-Fatihah',
          type: 'meccan',
          ayahCount: 7,
          juz: 1,
          page: 1,
        ),
      ],
      ayahs: [
        Ayah(
          number: 1,
          surahId: 1,
          text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          numberInSurah: 1,
          juz: 1,
          page: 1,
        ),
        Ayah(
          number: 2,
          surahId: 1,
          text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
          numberInSurah: 2,
          juz: 1,
          page: 1,
        ),
      ],
    ),
  };

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async {
    final detail = surahDetails[surahId];
    if (detail != null) return Right(detail);
    return const Left(NotFoundFailure());
  }

  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) async {
    final detail = pageDetails[pageNumber];
    if (detail != null) return Right(detail);
    return const Left(NotFoundFailure());
  }

  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) async =>
      const Right([]);

  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) async =>
      const Right([]);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranContinuousPlayerService service;
  late FakeQuranRepository repository;
  late QuranReciterService reciterService;
  late ControlledAudioPlayer audioPlayer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    reciterService = QuranReciterService(prefs);
    repository = FakeQuranRepository();
    audioPlayer = ControlledAudioPlayer();

    service = QuranContinuousPlayerService(
      quranRepository: repository,
      reciterService: reciterService,
      player: audioPlayer,
    );
  });

  tearDown(() async {
    service.dispose();
    await audioPlayer.closeControllers();
  });

  test('initial state is idle', () {
    expect(service.state.status, PlaybackStatus.idle);
    expect(service.state.isIdle, isTrue);
    expect(service.state.hasActiveAudio, isFalse);
  });

  test('playSurah emits error on non-existent surah', () async {
    await service.playSurah(999);
    expect(service.state.status, PlaybackStatus.error);
    expect(service.state.errorMessage, isNotNull);
  });

  test('playSurah loads playlist and starts playing', () async {
    await service.playSurah(1);

    expect(service.state.currentSurahId, 1);
    expect(service.state.currentAyahNumber, 1);
    expect(audioPlayer.playCallCount, greaterThanOrEqualTo(1));
  });

  test(
    'surah playback advances automatically when engine emits next index',
    () async {
      await service.playSurah(1);
      expect(service.state.currentAyahNumber, 1);

      // Simulate just_audio's gapless advance to the next item.
      audioPlayer.advanceToIndex(1);
      await Future<void>.delayed(Duration.zero);

      expect(service.state.currentAyahNumber, 2);
      expect(service.state.scope, PlayScope.surah);
      expect(service.state.hasNext, isFalse);
    },
  );

  test('surah playback stops after playlist completed signal', () async {
    final stopped = Completer<void>();
    service.stateNotifier.addListener(() {
      if (service.state.isIdle && !stopped.isCompleted) stopped.complete();
    });

    await service.playSurah(1);
    audioPlayer.finishCurrentTrack();
    await stopped.future.timeout(const Duration(seconds: 2));

    expect(service.state.status, PlaybackStatus.idle);
  });

  test('page playback starts with correct scope and page number', () async {
    await service.playPage(1);

    expect(service.state.scope, PlayScope.page);
    expect(service.state.currentAyahNumber, 1);
    expect(service.state.currentPageNumber, 1);
    expect(service.state.hasNext, isTrue);
  });

  test('page playback advances to next ayah via index stream', () async {
    await service.playPage(1);
    audioPlayer.advanceToIndex(1);
    await Future<void>.delayed(Duration.zero);

    expect(service.state.currentAyahNumber, 2);
    expect(service.state.hasNext, isFalse);
  });

  test('single ayah playback sets singleAyah scope', () async {
    await service.playAyah(1, 1);

    expect(service.state.scope, PlayScope.singleAyah);
    expect(service.state.hasNext, isFalse);
    expect(service.state.hasPrevious, isFalse);
  });

  test('single ayah playback stops on playlist completion', () async {
    final stopped = Completer<void>();
    service.stateNotifier.addListener(() {
      if (service.state.isIdle && !stopped.isCompleted) stopped.complete();
    });

    await service.playAyah(1, 1);
    audioPlayer.finishCurrentTrack();
    await stopped.future.timeout(const Duration(seconds: 2));

    expect(service.state.status, PlaybackStatus.idle);
  });

  test('playPage emits error on non-existent page', () async {
    await service.playPage(999);
    expect(service.state.status, PlaybackStatus.error);
    expect(service.state.errorMessage, isNotNull);
  });

  test('changeReciter updates state reciter', () async {
    const newReciter = QuranReciter.alafasy;
    await service.changeReciter(newReciter);
    expect(service.state.reciter?.id, 'alafasy');
  });

  test('stop resets state to idle', () async {
    await service.stop();
    expect(service.state.status, PlaybackStatus.idle);
    expect(service.state.isIdle, isTrue);
  });

  test('pause and resume toggle playback status', () async {
    await service.playSurah(1);
    expect(service.state.status, PlaybackStatus.playing);

    await service.pause();
    expect(service.state.status, PlaybackStatus.paused);

    await service.resume();
    expect(service.state.status, PlaybackStatus.playing);
  });

  test('nextAyah seeks player to next index', () async {
    await service.playPage(1); // 2 ayahs, starts at index 0
    await service.nextAyah(); // internally calls seekToNext → advanceToIndex(1)
    // Allow the currentIndexStream event to propagate through the listener.
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(service.state.currentAyahNumber, 2);
  });
}
