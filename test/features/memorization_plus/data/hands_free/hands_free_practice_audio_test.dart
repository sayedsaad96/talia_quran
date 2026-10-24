import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/hands_free/hands_free_round_state.dart';
import 'package:talia_quran/core/services/audio_cache_service.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/features/memorization_plus/data/hands_free/hands_free_practice_audio.dart';

class _Player extends Mock implements AudioPlayer {}

class _Cache extends Mock implements AudioCacheService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      AudioSource.uri(Uri.parse('https://example.test/1.mp3')),
    );
    registerFallbackValue(Duration.zero);
  });
  late _Player player;
  late _Cache cache;
  late JustAudioHandsFreePractice audio;
  late List<Duration?> ends;
  Duration? duration;
  var plays = 0;
  var loaded = false;
  setUp(() {
    player = _Player();
    cache = _Cache();
    ends = [];
    plays = 0;
    loaded = false;
    duration = const Duration(seconds: 10);
    when(
      () => player.playerStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => cache.getAudioSource(1, 1, reciter: QuranReciter.alafasy),
    ).thenAnswer((_) async => '/tmp/test.mp3');
    when(() => player.setAudioSource(any())).thenAnswer((_) async {
      loaded = true;
      return duration;
    });
    when(
      () => player.setClip(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((call) async {
      if (!loaded) throw StateError('Clip requires a loaded URI source');
      ends.add(call.namedArguments[#end] as Duration?);
      return duration;
    });
    when(() => player.setLoopMode(LoopMode.off)).thenAnswer((_) async {});
    when(() => player.setSpeed(1)).thenAnswer((_) async {});
    when(() => player.play()).thenAnswer((_) async {
      plays++;
    });
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.processingState).thenReturn(ProcessingState.completed);
    audio = JustAudioHandsFreePractice(
      cache,
      QuranReciter.alafasy,
      player: player,
    );
  });
  tearDown(() => audio.dispose());

  test(
    'clips measured duration before playing exact canonical source',
    () async {
      expect(await audio.playPrompt(const ListeningAyahRef(1, 1)), isTrue);
      expect(ends, [const Duration(seconds: 3)]);
      expect(plays, 1);
      verify(
        () => cache.getAudioSource(1, 1, reciter: QuranReciter.alafasy),
      ).called(1);
    },
  );
  test('subsecond source cannot be clipped past its actual duration', () async {
    duration = const Duration(milliseconds: 500);
    expect(await audio.playPrompt(const ListeningAyahRef(1, 1)), isTrue);
    expect(ends.last, duration);
  });
  test('unknown duration fails ungraded without playback', () async {
    duration = null;
    await expectLater(
      audio.playPrompt(const ListeningAyahRef(1, 1)),
      throwsStateError,
    );
    expect(plays, 0);
  });
  test('stop during source resolution prevents late playback', () async {
    final pending = Completer<String>();
    when(
      () => cache.getAudioSource(1, 1, reciter: QuranReciter.alafasy),
    ).thenAnswer((_) => pending.future);
    final playing = audio.playPrompt(const ListeningAyahRef(1, 1));
    final stopped = audio.stop();
    pending.complete('/tmp/test.mp3');
    expect(await playing, isFalse);
    await stopped;
    expect(plays, 0);
  });
  test('timed out preparation cannot play after late completion', () async {
    await audio.dispose();
    audio = JustAudioHandsFreePractice(
      cache,
      QuranReciter.alafasy,
      player: player,
      operationTimeout: const Duration(milliseconds: 10),
    );
    final pending = Completer<String>();
    when(
      () => cache.getAudioSource(1, 1, reciter: QuranReciter.alafasy),
    ).thenAnswer((_) => pending.future);
    await expectLater(
      audio.playPrompt(const ListeningAyahRef(1, 1)),
      throwsA(isA<TimeoutException>()),
    );
    await expectLater(audio.stop(), throwsA(isA<TimeoutException>()));
    pending.complete('/tmp/test.mp3');
    await audio.stop();
    expect(plays, 0);
  });
  test('feedback loads the tone then clears prompt clipping', () async {
    await audio.playPrompt(const ListeningAyahRef(1, 1));
    when(
      () => player.setAsset('assets/audio/tones/correct.wav'),
    ).thenAnswer((_) async => const Duration(milliseconds: 300));
    await audio.playFeedback(HandsFreeGrade.correct);
    expect(ends, [const Duration(seconds: 3), null]);
    expect(plays, 2);
  });
  test(
    'native stop failure is bounded and never reported as shutdown',
    () async {
      await audio.dispose();
      audio = JustAudioHandsFreePractice(
        cache,
        QuranReciter.alafasy,
        player: player,
        operationTimeout: const Duration(milliseconds: 10),
      );
      final pending = Completer<void>();
      when(() => player.stop()).thenAnswer((_) => pending.future);
      try {
        await expectLater(
          audio.stop().timeout(
            const Duration(milliseconds: 200),
            onTimeout: () => throw StateError('Unbounded native stop'),
          ),
          throwsA(isA<TimeoutException>()),
        );
      } finally {
        pending.complete();
      }
    },
  );
}
