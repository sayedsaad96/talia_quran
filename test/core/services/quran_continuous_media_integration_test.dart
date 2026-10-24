import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/quran_background_audio_handler.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/core/router/quran_audio_notification_controller.dart';
import 'package:talia_quran/core/services/quran_media_metadata.dart';

import 'quran_continuous_player_service_test.dart'
    show ControlledAudioPlayer, FakeQuranRepository;

class _MediaPlayer extends ControlledAudioPlayer {
  int index = 0;
  bool isPlaying = false;
  ProcessingState processing = ProcessingState.idle;
  Completer<void>? loading;

  @override
  Stream<PlaybackEvent> get playbackEventStream => const Stream.empty();
  @override
  int? get currentIndex => index;
  @override
  bool get playing => isPlaying;
  @override
  ProcessingState get processingState => processing;
  @override
  Duration get position => Duration.zero;
  @override
  Duration get bufferedPosition => Duration.zero;
  @override
  double get speed => 1;
  @override
  Future<void> play() async {
    isPlaying = true;
    await super.play();
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
    await super.pause();
  }

  @override
  Future<void> stop() async {
    isPlaying = false;
    processing = ProcessingState.idle;
    await super.stop();
  }

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> sources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    await loading?.future;
    index = initialIndex ?? 0;
    processing = ProcessingState.ready;
    return super.setAudioSources(
      sources,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
      preload: preload,
      shuffleOrder: shuffleOrder,
    );
  }

  @override
  void advanceToIndex(int value) {
    index = value;
    super.advanceToIndex(value);
  }

  void emitOldIndex(int value) => super.advanceToIndex(value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _MediaPlayer player;
  late QuranContinuousPlayerService service;
  late QuranBackgroundAudioHandler handler;
  late Completer<QuranBackgroundAudioHandler?> initialization;
  late Locale locale;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    player = _MediaPlayer();
    locale = const Locale('ar');
    initialization = Completer<QuranBackgroundAudioHandler?>();
    handler = QuranBackgroundAudioHandler(
      player: player,
      onPlay: () => service.resume(),
      onPause: () => service.pause(),
      onStop: () => service.stop(),
      onNext: () => service.nextAyah(),
      onPrevious: () => service.previousAyah(),
      onSeek: (p) => service.seek(p),
    );
    service = QuranContinuousPlayerService(
      quranRepository: FakeQuranRepository(),
      reciterService: QuranReciterService(prefs),
      player: player,
      enableBackgroundAudioIntegration: true,
      backgroundAudioInitializer: () => initialization.future,
      mediaMetadata: QuranMediaMetadata(locale: () => locale),
    );
  });

  tearDown(() async {
    service.dispose();
    await handler.disposeHandler();
    await player.closeControllers();
  });

  test('late media initialization attaches the latest playing queue', () async {
    final playing = service.playSurah(1, startAyah: 2);
    await playing;
    expect(service.state.isPlaying, isTrue);
    initialization.complete(handler);
    await Future<void>.delayed(Duration.zero);
    expect(handler.mediaItem.value?.id, '1_2');
    expect(handler.playbackState.value.playing, isTrue);
  });

  test('stop before late initialization cannot restore an old queue', () async {
    final playing = service.playSurah(1);
    await Future<void>.delayed(Duration.zero);
    await service.stop();
    initialization.complete(handler);
    await Future<void>.delayed(Duration.zero);
    await playing;
    expect(player.playCallCount, 0);
    expect(handler.mediaItem.value, isNull);
    expect(service.state.isIdle, isTrue);
  });

  test(
    'new request wins when initialization completes for both requests',
    () async {
      final first = service.playSurah(1);
      await Future<void>.delayed(Duration.zero);
      final second = service.playSurah(
        1,
        startAyah: 2,
        reciter: QuranReciter.maher,
      );
      await Future<void>.delayed(Duration.zero);
      initialization.complete(handler);
      await Future<void>.delayed(Duration.zero);
      await Future.wait([first, second]);
      expect(handler.mediaItem.value?.id, '1_2');
      expect(service.state.reciter, QuranReciter.maher);
      expect(player.playCallCount, 1);
    },
  );

  test(
    'disposal invalidates a reader load waiting on native initialization',
    () async {
      final playing = service.playSurah(1);
      await Future<void>.delayed(Duration.zero);
      service.dispose();
      initialization.complete(handler);
      await Future<void>.delayed(Duration.zero);
      await playing;
      expect(player.playCallCount, 0);
      expect(handler.mediaItem.value, isNull);
    },
  );

  test(
    'notification opens the active page without restarting real service',
    () async {
      initialization.complete(handler);
      await service.playSurah(1, startAyah: 2);
      final playCalls = player.playCallCount;
      final clicks = StreamController<bool>.broadcast(sync: true);
      final opened = <String>[];
      final controller =
          QuranAudioNotificationController(
              notificationClicks: clicks.stream,
              currentState: () => service.state,
              canOpenReader: () => service.canOpenReaderFromNotification,
              currentLocation: () => '/home',
              onOpen: opened.add,
            )
            ..start()
            ..setReady(true);
      clicks.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(opened, ['/quran/page/1']);
      expect(player.playCallCount, playCalls);
      expect(service.state.currentAyahNumber, 2);
      await controller.dispose();
      await clicks.close();
    },
  );

  test('stop during source loading leaves no resumable notification', () async {
    initialization.complete(handler);
    player.loading = Completer<void>();
    final playing = service.playSurah(1);
    await Future<void>.delayed(Duration.zero);
    await service.stop();
    player.loading!.complete();
    await playing;
    expect(player.playCallCount, 0);
    expect(handler.mediaItem.value, isNull);
    expect(
      handler.playbackState.value.processingState,
      AudioProcessingState.idle,
    );
    expect(service.state.isIdle, isTrue);
  });

  test(
    'reciter switch while paused refreshes metadata without starting audio',
    () async {
      initialization.complete(handler);
      await service.playSurah(1);
      await service.pause();
      final calls = player.playCallCount;
      await service.changeReciter(QuranReciter.maher);
      expect(handler.mediaItem.value?.id, '1_1');
      expect(handler.mediaItem.value?.artist, QuranReciter.maher.nameAr);
      expect(handler.playbackState.value.playing, isFalse);
      expect(player.playCallCount, calls);
    },
  );

  for (final fastSeek in [true, false]) {
    test(
      '${fastSeek ? 'same-surah seek' : 'rejected range'} keeps transport and locale updates',
      () async {
        initialization.complete(handler);
        await service.playSurah(1);
        if (fastSeek) {
          await service.playAyah(1, 2, scope: PlayScope.surah);
        } else {
          expect(await service.playAyahRange(1, 99, 100), isFalse);
          player.advanceToIndex(1);
        }
        expect(
          handler.playbackState.value.controls,
          isNot(contains(MediaControl.skipToNext)),
        );
        locale = const Locale('en');
        service.refreshMediaMetadata();
        expect(handler.mediaItem.value?.artist, QuranReciter.alafasy.nameEn);
        expect(handler.mediaItem.value?.title, contains('Surah'));
      },
    );
  }

  test(
    'delayed old source index cannot move reader highlight after commit',
    () async {
      initialization.complete(handler);
      await service.playSurah(1, startAyah: 2);
      player.emitOldIndex(0);
      expect(service.state.currentAyahNumber, 2);
      expect(handler.mediaItem.value?.id, '1_2');
    },
  );
}
