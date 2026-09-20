import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/services/quran_background_audio_handler.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  test('publishes the Quran queue and delegates platform controls', () async {
    final player = _MockAudioPlayer();
    final events = StreamController<PlaybackEvent>.broadcast(sync: true);
    var playCalls = 0;
    var pauseCalls = 0;
    var stopCalls = 0;
    var nextCalls = 0;
    var previousCalls = 0;
    Duration? seekPosition;

    when(() => player.playbackEventStream).thenAnswer((_) => events.stream);
    when(() => player.currentIndex).thenReturn(0);
    when(() => player.playing).thenReturn(true);
    when(() => player.processingState).thenReturn(ProcessingState.ready);
    when(() => player.position).thenReturn(const Duration(seconds: 3));
    when(() => player.bufferedPosition).thenReturn(const Duration(seconds: 8));
    when(() => player.speed).thenReturn(1);

    final handler = QuranBackgroundAudioHandler(
      player: player,
      onPlay: () async => playCalls++,
      onPause: () async => pauseCalls++,
      onStop: () async => stopCalls++,
      onNext: () async => nextCalls++,
      onPrevious: () async => previousCalls++,
      onSeek: (position) async => seekPosition = position,
    );
    addTearDown(() async {
      await handler.disposeHandler();
      await events.close();
    });

    handler.setQueueItems(const [
      MediaItem(id: '1_1', title: 'Al-Fatihah 1'),
      MediaItem(id: '1_2', title: 'Al-Fatihah 2'),
    ]);
    events.add(
      PlaybackEvent(processingState: ProcessingState.ready, currentIndex: 0),
    );

    expect(handler.queue.value.map((item) => item.id), ['1_1', '1_2']);
    expect(handler.mediaItem.value?.id, '1_1');
    expect(handler.playbackState.value.playing, isTrue);
    expect(
      handler.playbackState.value.controls,
      containsAll([
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.stop,
        MediaControl.skipToNext,
      ]),
    );

    await handler.play();
    await handler.pause();
    await handler.stop();
    await handler.skipToNext();
    await handler.skipToPrevious();
    await handler.seek(const Duration(seconds: 5));

    expect(playCalls, 1);
    expect(pauseCalls, 1);
    expect(stopCalls, 1);
    expect(nextCalls, 1);
    expect(previousCalls, 1);
    expect(seekPosition, const Duration(seconds: 5));
  });
}
