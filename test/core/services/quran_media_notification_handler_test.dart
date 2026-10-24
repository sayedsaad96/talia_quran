import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/services/quran_background_audio_handler.dart';

class _Player extends Mock implements AudioPlayer {}

void main() {
  late _Player player;
  late QuranBackgroundAudioHandler handler;
  late StreamController<PlaybackEvent> events;
  late StreamController<PlayerState> states;
  late bool playing;
  late int index;

  setUp(() {
    player = _Player();
    events = StreamController<PlaybackEvent>.broadcast(sync: true);
    states = StreamController<PlayerState>.broadcast(sync: true);
    playing = false;
    index = 0;
    when(() => player.playbackEventStream).thenAnswer((_) => events.stream);
    when(() => player.playerStateStream).thenAnswer((_) => states.stream);
    when(() => player.currentIndex).thenAnswer((_) => index);
    when(() => player.playing).thenAnswer((_) => playing);
    when(() => player.processingState).thenReturn(ProcessingState.ready);
    when(() => player.position).thenReturn(const Duration(seconds: 2));
    when(() => player.bufferedPosition).thenReturn(const Duration(seconds: 4));
    when(() => player.speed).thenReturn(1);
    handler = QuranBackgroundAudioHandler(
      player: player,
      onPlay: () async {},
      onPause: () async {},
      onStop: () async {},
      onNext: () async {},
      onPrevious: () async {},
      onSeek: (_) async {},
    );
  });

  tearDown(() async {
    await handler.disposeHandler();
    await events.close();
    await states.close();
  });

  test('changing reciter on the same ayah refreshes notification artist', () {
    handler.setQueueItems(const [
      MediaItem(id: '1_1', title: 'Surah 1', artist: 'First reciter'),
    ]);
    handler.setQueueItems(const [
      MediaItem(id: '1_1', title: 'Surah 1', artist: 'Second reciter'),
    ]);
    expect(handler.mediaItem.value?.artist, 'Second reciter');
  });

  test('playing-only events update notification controls', () {
    handler.setQueueItems(const [MediaItem(id: '1_1', title: 'Surah 1')]);
    playing = true;
    states.add(PlayerState(true, ProcessingState.ready));
    expect(handler.playbackState.value.playing, isTrue);
    expect(handler.playbackState.value.controls, contains(MediaControl.pause));
    playing = false;
    states.add(PlayerState(false, ProcessingState.ready));
    expect(handler.playbackState.value.playing, isFalse);
    expect(handler.playbackState.value.controls, contains(MediaControl.play));
  });

  test(
    'disposing clears platform metadata and cancels both subscriptions',
    () async {
      handler.setQueueItems(const [MediaItem(id: '1_1', title: 'Surah 1')]);
      await handler.disposeHandler();
      expect(handler.mediaItem.value, isNull);
      expect(handler.queue.value, isEmpty);
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.idle,
      );
      expect(events.hasListener, isFalse);
      expect(states.hasListener, isFalse);
    },
  );

  test('pending queue uses requested ayah despite previous engine events', () {
    index = 0;
    handler.prepareQueue(
      const [
        MediaItem(id: '1_1', title: 'First'),
        MediaItem(id: '1_2', title: 'Second'),
      ],
      initialIndex: 1,
      hasNext: false,
      hasPrevious: true,
    );
    playing = true;
    events.add(
      PlaybackEvent(currentIndex: 0, processingState: ProcessingState.ready),
    );
    expect(handler.mediaItem.value?.id, '1_2');
    expect(
      handler.playbackState.value.processingState,
      AudioProcessingState.loading,
    );
    expect(handler.playbackState.value.playing, isFalse);
    index = 1;
    handler.commitQueue();
    expect(handler.mediaItem.value?.id, '1_2');
    expect(
      handler.playbackState.value.processingState,
      AudioProcessingState.ready,
    );
    expect(
      handler.playbackState.value.controls,
      isNot(contains(MediaControl.skipToNext)),
    );
    expect(
      handler.playbackState.value.controls,
      contains(MediaControl.skipToPrevious),
    );
  });

  test('late player events cannot resurrect a cleared session', () {
    handler.setQueueItems(const [MediaItem(id: '1_1', title: 'First')]);
    handler.clearQueue();
    playing = true;
    states.add(PlayerState(true, ProcessingState.ready));
    events.add(
      PlaybackEvent(currentIndex: 0, processingState: ProcessingState.ready),
    );
    expect(handler.mediaItem.value, isNull);
    expect(handler.playbackState.value.playing, isFalse);
    expect(handler.playbackState.value.controls, isEmpty);
  });

  test('delayed old index after commit cannot replace the live ayah', () {
    handler.prepareQueue(
      const [
        MediaItem(id: '1_1', title: 'First'),
        MediaItem(id: '1_2', title: 'Second'),
      ],
      initialIndex: 1,
      hasNext: false,
      hasPrevious: true,
    );
    index = 1;
    handler.commitQueue();
    events.add(
      PlaybackEvent(currentIndex: 0, processingState: ProcessingState.ready),
    );
    expect(handler.mediaItem.value?.id, '1_2');
    expect(handler.playbackState.value.queueIndex, 1);
  });
}
