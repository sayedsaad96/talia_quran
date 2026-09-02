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

class ControlledAudioPlayer extends Mock implements AudioPlayer {
  final _playerStateController = StreamController<PlayerState>.broadcast(
    sync: true,
  );
  final _playStartedController = StreamController<int>.broadcast(sync: true);
  final List<Completer<void>> playCompleters = [];

  Stream<int> get playStarted => _playStartedController.stream;

  void finishCurrentTrack() {
    _playerStateController.add(PlayerState(true, ProcessingState.completed));
    final currentPlay = playCompleters.lastOrNull;
    if (currentPlay != null && !currentPlay.isCompleted) {
      currentPlay.complete();
    }
  }

  void failCurrentTrack(Object error) {
    final currentPlay = playCompleters.lastOrNull;
    if (currentPlay != null && !currentPlay.isCompleted) {
      currentPlay.completeError(error);
    }
  }

  Future<void> closeControllers() async {
    await stop();
    await _playerStateController.close();
    await _playStartedController.close();
  }

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  Future<void> play() {
    final completer = Completer<void>();
    playCompleters.add(completer);
    _playStartedController.add(playCompleters.length);
    return completer.future;
  }

  @override
  Future<void> pause() async {
    final currentPlay = playCompleters.lastOrNull;
    if (currentPlay != null && !currentPlay.isCompleted) {
      currentPlay.complete();
    }
  }

  @override
  Future<void> stop() async {
    for (final completer in playCompleters) {
      if (!completer.isCompleted) completer.complete();
    }
  }

  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async => const Duration(seconds: 1);

  @override
  Future<Duration?> setFilePath(
    String filePath, {
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async => const Duration(seconds: 1);

  @override
  Future<void> seek(Duration? position, {int? index}) async {}

  @override
  Future<void> dispose() => stop();
}

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
      audioSourceResolver: (ayah, reciter) async =>
          'https://audio.test/${ayah.surahId}/${ayah.numberInSurah}.mp3',
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

  test('playSurah returns after the first ayah starts', () async {
    final firstPlayStarted = audioPlayer.playStarted.firstWhere(
      (playCount) => playCount == 1,
    );

    final playback = service.playSurah(1);
    await firstPlayStarted;
    await playback.timeout(
      const Duration(seconds: 1),
      onTimeout: () =>
          throw StateError('playSurah waited for the ayah to finish'),
    );

    expect(service.state.currentAyahNumber, 1);
    expect(service.state.status, PlaybackStatus.playing);
  });

  test(
    'surah playback advances automatically after an ayah completes',
    () async {
      final firstPlayStarted = audioPlayer.playStarted.firstWhere(
        (playCount) => playCount == 1,
      );
      final secondPlayStarted = audioPlayer.playStarted.firstWhere(
        (playCount) => playCount == 2,
      );

      final playback = service.playSurah(1);
      await firstPlayStarted;
      await playback;
      audioPlayer.finishCurrentTrack();
      await secondPlayStarted.timeout(const Duration(seconds: 1));

      expect(service.state.currentAyahNumber, 2);
      expect(service.state.scope, PlayScope.surah);
      expect(service.state.hasNext, isFalse);
    },
  );

  test('surah playback stops after the selected surah ends', () async {
    final firstPlayStarted = audioPlayer.playStarted.firstWhere(
      (playCount) => playCount == 1,
    );
    final secondPlayStarted = audioPlayer.playStarted.firstWhere(
      (playCount) => playCount == 2,
    );
    final secondAyahReady = Completer<void>();
    final stopped = Completer<void>();
    void completeWhenStateChanges() {
      if (service.state.status == PlaybackStatus.playing &&
          service.state.currentAyahNumber == 2 &&
          !secondAyahReady.isCompleted) {
        secondAyahReady.complete();
      }
      if (service.state.isIdle && !stopped.isCompleted) stopped.complete();
    }

    service.stateNotifier.addListener(completeWhenStateChanges);
    try {
      final playback = service.playSurah(1);
      await firstPlayStarted;
      await playback;
      audioPlayer.finishCurrentTrack();
      await secondPlayStarted.timeout(const Duration(seconds: 1));
      await secondAyahReady.future.timeout(const Duration(seconds: 1));

      audioPlayer.finishCurrentTrack();
      await stopped.future.timeout(const Duration(seconds: 1));

      expect(audioPlayer.playCompleters, hasLength(2));
      expect(service.state.status, PlaybackStatus.idle);
    } finally {
      service.stateNotifier.removeListener(completeWhenStateChanges);
    }
  });

  test(
    'page playback plays the current page completely and then stops',
    () async {
      final firstPlayStarted = audioPlayer.playStarted.firstWhere(
        (playCount) => playCount == 1,
      );
      final secondPlayStarted = audioPlayer.playStarted.firstWhere(
        (playCount) => playCount == 2,
      );
      final secondAyahReady = Completer<void>();
      final stopped = Completer<void>();
      void completeWhenStateChanges() {
        if (service.state.status == PlaybackStatus.playing &&
            service.state.currentAyahNumber == 2 &&
            !secondAyahReady.isCompleted) {
          secondAyahReady.complete();
        }
        if (service.state.isIdle && !stopped.isCompleted) stopped.complete();
      }

      service.stateNotifier.addListener(completeWhenStateChanges);
      try {
        final playback = service.playPage(1);
        await firstPlayStarted;
        await playback;
        expect(service.state.scope, PlayScope.page);
        expect(service.state.currentAyahNumber, 1);
        expect(service.state.hasNext, isTrue);

        audioPlayer.finishCurrentTrack();
        await secondPlayStarted.timeout(const Duration(seconds: 1));
        await secondAyahReady.future.timeout(const Duration(seconds: 1));
        expect(service.state.currentPageNumber, 1);
        expect(service.state.currentAyahNumber, 2);
        expect(service.state.hasNext, isFalse);

        await service.nextAyah();
        expect(service.state.currentPageNumber, 1);
        expect(service.state.status, PlaybackStatus.playing);

        audioPlayer.finishCurrentTrack();
        await stopped.future.timeout(const Duration(seconds: 1));
        expect(audioPlayer.playCompleters, hasLength(2));
      } finally {
        service.stateNotifier.removeListener(completeWhenStateChanges);
      }
    },
  );

  test('single ayah playback stops without starting another ayah', () async {
    final firstPlayStarted = audioPlayer.playStarted.firstWhere(
      (playCount) => playCount == 1,
    );
    final stopped = Completer<void>();
    void completeWhenStopped() {
      if (service.state.isIdle && !stopped.isCompleted) stopped.complete();
    }

    service.stateNotifier.addListener(completeWhenStopped);
    try {
      final playback = service.playAyah(1, 1);
      await firstPlayStarted;
      await playback;
      expect(service.state.scope, PlayScope.singleAyah);
      expect(service.state.hasNext, isFalse);
      expect(service.state.hasPrevious, isFalse);

      audioPlayer.finishCurrentTrack();
      await stopped.future.timeout(const Duration(seconds: 1));

      expect(audioPlayer.playCompleters, hasLength(1));
      expect(service.state.status, PlaybackStatus.idle);
    } finally {
      service.stateNotifier.removeListener(completeWhenStopped);
    }
  });

  test('an asynchronous player failure becomes an error state', () async {
    final firstPlayStarted = audioPlayer.playStarted.firstWhere(
      (playCount) => playCount == 1,
    );
    final failed = Completer<void>();
    void completeWhenFailed() {
      if (service.state.isError && !failed.isCompleted) failed.complete();
    }

    service.stateNotifier.addListener(completeWhenFailed);
    try {
      final playback = service.playSurah(1);
      await firstPlayStarted;
      await playback;

      audioPlayer.failCurrentTrack(StateError('decoder failed'));
      await failed.future.timeout(const Duration(seconds: 1));

      expect(service.state.errorMessage, isNotNull);
    } finally {
      service.stateNotifier.removeListener(completeWhenFailed);
    }
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
}
