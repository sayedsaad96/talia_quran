import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/services/quran_background_audio_handler.dart';

class _Player extends Mock implements AudioPlayer {}

class _Delegate implements HandsFreeMediaDelegate {
  int primary = 0, secondary = 0, interrupted = 0;
  @override
  void onPrimary() => primary++;
  @override
  void onSecondary() => secondary++;
  @override
  void onInterrupted() => interrupted++;
}

void main() {
  late QuranBackgroundAudioHandler handler;
  late StreamController<PlaybackEvent> events;
  late List<String> readerCalls;
  setUp(() {
    final player = _Player();
    events = StreamController<PlaybackEvent>.broadcast();
    readerCalls = [];
    when(() => player.playbackEventStream).thenAnswer((_) => events.stream);
    handler = QuranBackgroundAudioHandler(
      player: player,
      onPlay: () async => readerCalls.add('play'),
      onPause: () async => readerCalls.add('pause'),
      onStop: () async => readerCalls.add('stop'),
      onNext: () async => readerCalls.add('next'),
      onPrevious: () async => readerCalls.add('previous'),
      onSeek: (_) async => readerCalls.add('seek'),
    );
  });
  tearDown(() async {
    await handler.disposeHandler();
    await events.close();
  });

  test('reader controls stay unchanged without a delegate', () async {
    await handler.play();
    await handler.pause();
    await handler.skipToNext();
    expect(readerCalls, ['play', 'pause', 'next']);
  });

  test('owned controls cannot reach reader callbacks', () async {
    final delegate = _Delegate();
    handler.setMediaDelegate(delegate);
    await handler.play();
    await handler.pause();
    await handler.skipToNext();
    await handler.seek(const Duration(seconds: 2));
    await handler.skipToPrevious();
    await handler.stop();
    expect(delegate.primary, 2);
    expect(delegate.secondary, 1);
    expect(delegate.interrupted, 1);
    expect(readerCalls, isEmpty);
  });

  test('an old owner cannot detach a replacement delegate', () async {
    final first = _Delegate(), next = _Delegate();
    handler.setMediaDelegate(first);
    handler.setMediaDelegate(next);
    handler.clearMediaDelegate(first);
    await handler.play();
    expect(next.primary, 1);
    expect(first.interrupted, 1);
    handler.clearMediaDelegate(next);
    await handler.play();
    expect(readerCalls, ['play']);
  });

  test('compatibility setter cannot evict a production lease', () async {
    final token = Object(), delegate = _Delegate(), other = _Delegate();
    expect(handler.attachMediaDelegate(token, delegate), isTrue);
    handler.setMediaDelegate(other);
    handler.setMediaDelegate(null);
    await handler.play();
    expect(delegate.primary, 1);
    expect(handler.ownsMedia(token), isTrue);
  });

  test('reader queue mutations cannot overwrite practice metadata', () async {
    final token = Object();
    handler.attachMediaDelegate(token, _Delegate());
    handler.publishPractice(
      token,
      item: const MediaItem(id: 'practice', title: 'test'),
      playing: false,
    );
    handler.setQueueItems(const [MediaItem(id: 'reader', title: 'reader')]);
    handler.clearQueue();
    expect(handler.mediaItem.value?.id, 'practice');
  });
}
