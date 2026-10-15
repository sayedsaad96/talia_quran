import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_learning_game.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_log.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_learning_game_cubit.dart';

import 'memorization_session_cubit_test.mocks.dart' show MockAudioPlayer;

KidsSessionLog _log(int surahId, int ayah) => KidsSessionLog(
  id: '$surahId:$ayah',
  surahId: surahId,
  ayahNumber: ayah,
  repeatsCompleted: 1,
  pointsEarned: 10,
  completedAt: DateTime.utc(2026, 10, 1),
  missionType: KidsMissionType.newMemorization,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAudioPlayer player;
  late StreamController<PlayerState> playerStates;

  setUp(() {
    player = MockAudioPlayer();
    playerStates = StreamController<PlayerState>.broadcast(sync: true);
    when(player.playerStateStream).thenAnswer((_) => playerStates.stream);
    when(player.setUrl(any)).thenAnswer((_) async => Duration.zero);
    when(player.seek(any)).thenAnswer((_) async {});
    when(player.play()).thenAnswer((_) async {});
    when(player.stop()).thenAnswer((_) async {});
    when(player.dispose()).thenAnswer((_) async {});
  });

  tearDown(() => playerStates.close());

  KidsLearningGameCubit build({
    Future<List<KidsSessionLog>> Function()? logs,
    KidsGameAudioSourceLoader? audio,
    Future<KidsJourneyPathDefinition> Function()? pathLoader,
  }) => KidsLearningGameCubit(
    sessionLogs: logs ?? () async => [_log(114, 1), _log(113, 1), _log(112, 1)],
    audioSource: audio ?? (_, _) async => 'https://example.test/a.mp3',
    pathLoader: pathLoader,
    player: player,
    random: Random(3),
  );

  test('the game follows the stored journey path', () async {
    final cubit = build(
      logs: () async => [_log(67, 1)],
      pathLoader: () async =>
          KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas),
    );
    await cubit.start();

    expect(cubit.state.status, KidsLearningGameStatus.playing);
    expect(cubit.state.round?.surahId, 67);
    await cubit.close();
  });

  test('a failing path loader falls back to the adventure', () async {
    final cubit = build(
      logs: () async => [_log(67, 1)],
      pathLoader: () async => throw StateError('prefs'),
    );
    await cubit.start();

    expect(cubit.state.status, KidsLearningGameStatus.unavailable);
    await cubit.close();
  });

  test('no memorized ayah makes the game unavailable', () async {
    final cubit = build(logs: () async => const []);
    await cubit.start();

    expect(cubit.state.status, KidsLearningGameStatus.unavailable);
    await cubit.close();
  });

  test('unreadable logs make the game unavailable, not an error', () async {
    final cubit = build(logs: () async => throw StateError('storage'));
    await cubit.start();

    expect(cubit.state.status, KidsLearningGameStatus.unavailable);
    await cubit.close();
  });

  test('a round set plays through to a finished score', () async {
    final cubit = build();
    await cubit.start();
    expect(cubit.state.status, KidsLearningGameStatus.playing);

    var expected = 0;
    while (cubit.state.status == KidsLearningGameStatus.playing) {
      final round = cubit.state.round!;
      final pickRight = cubit.state.roundIndex.isEven;
      final pick = pickRight
          ? round.surahId
          : round.options.firstWhere((id) => id != round.surahId);
      if (pickRight) expected++;
      await cubit.answer(pick);
      await cubit.next();
    }

    expect(cubit.state.status, KidsLearningGameStatus.finished);
    expect(cubit.state.correctCount, expected);
    await cubit.close();
  });

  test('a double tap scores once; unknown options are ignored', () async {
    final cubit = build();
    await cubit.start();
    final round = cubit.state.round!;

    await cubit.answer(9999);
    expect(cubit.state.answered, isFalse);

    await cubit.answer(round.surahId);
    await cubit.answer(round.surahId);

    expect(cubit.state.correctCount, 1);
    expect(cubit.state.result, KidsGameResult.correct);
    await cubit.close();
  });

  test('next before answering does not skip the round', () async {
    final cubit = build();
    await cubit.start();

    await cubit.next();

    expect(cubit.state.roundIndex, 0);
    await cubit.close();
  });

  test('answering stops the recitation', () async {
    final cubit = build();
    await cubit.start();
    await cubit.playRecitation();
    expect(cubit.state.isAudioPlaying, isTrue);

    await cubit.answer(cubit.state.round!.surahId);

    expect(cubit.state.isAudioPlaying, isFalse);
    verify(player.stop()).called(greaterThanOrEqualTo(1));
    await cubit.close();
  });

  test('a recitation that cannot load shows a retryable failure', () async {
    final cubit = build(audio: (_, _) async => throw StateError('offline'));
    await cubit.start();

    await cubit.playRecitation();

    expect(cubit.state.audioFailed, isTrue);
    expect(cubit.state.isAudioPlaying, isFalse);
    expect(cubit.state.answered, isFalse);
    await cubit.close();
  });

  test('a source that arrives after an answer never plays', () async {
    final source = Completer<String>();
    final cubit = build(audio: (_, _) => source.future);
    await cubit.start();

    final playing = cubit.playRecitation();
    await cubit.answer(cubit.state.round!.surahId);
    source.complete('https://example.test/late.mp3');
    await playing;

    verifyNever(player.setUrl(any));
    verifyNever(player.play());
    await cubit.close();
  });

  test('a playback error after starting is shown, not thrown', () async {
    when(player.play()).thenAnswer((_) async => throw StateError('decoder'));
    final cubit = build();
    await cubit.start();

    await cubit.playRecitation();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.audioFailed, isTrue);
    expect(cubit.state.isAudioPlaying, isFalse);
    await cubit.close();
  });

  test('closing releases the player', () async {
    final cubit = build();
    await cubit.start();
    await cubit.close();

    verify(player.dispose()).called(1);
  });
}
