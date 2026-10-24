import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/services/quran_background_audio_handler.dart';
import 'package:talia_quran/core/services/quran_reader_media_session.dart';

class _Player extends Mock implements AudioPlayer {}

void main() {
  late QuranReaderMediaSession session;
  late QuranBackgroundAudioHandler handler;
  setUp(() {
    final player = _Player();
    when(
      () => player.playbackEventStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => player.playerStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => player.currentIndex).thenReturn(1);
    when(() => player.playing).thenReturn(true);
    when(() => player.processingState).thenReturn(ProcessingState.ready);
    when(() => player.position).thenReturn(Duration.zero);
    when(() => player.bufferedPosition).thenReturn(Duration.zero);
    when(() => player.speed).thenReturn(1);
    session = QuranReaderMediaSession();
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
  tearDown(() => handler.disposeHandler());

  const items = [
    MediaItem(id: '1_1', title: 'First'),
    MediaItem(id: '1_2', title: 'Second'),
  ];
  void prepare(int generation) => session.prepare(
    generation: generation,
    items: items,
    index: 1,
    hasNext: false,
    hasPrevious: true,
  );

  test('late handler receives committed queue and current playing state', () {
    prepare(1);
    session.commit(1);
    session.attach(handler);
    expect(handler.mediaItem.value?.id, '1_2');
    expect(handler.playbackState.value.playing, isTrue);
  });

  test(
    'late handler receives loading snapshot until matching load commits',
    () {
      prepare(1);
      prepare(2);
      session.commit(1);
      session.attach(handler);
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.loading,
      );
      session.commit(2);
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.ready,
      );
    },
  );

  test('stop clears snapshot before a late handler can attach', () {
    prepare(1);
    session.clear();
    session.attach(handler);
    session.commit(1);
    expect(handler.mediaItem.value, isNull);
    expect(handler.queue.value, isEmpty);
    expect(handler.playbackState.value.playing, isFalse);
  });
}
