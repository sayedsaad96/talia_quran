import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talia_quran/core/services/quran_background_audio_handler.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'quran_continuous_player_service_test.dart' show ControlledAudioPlayer;

class _Repository extends Mock implements QuranRepository {}

class _MediaPlayer extends ControlledAudioPlayer {
  @override
  bool get playing => false;
  @override
  Stream<PlaybackEvent> get playbackEventStream => const Stream.empty();
}

class _Delegate implements HandsFreeMediaDelegate {
  int interrupted = 0;
  @override
  void onPrimary() {}
  @override
  void onSecondary() {}
  @override
  void onInterrupted() {
    interrupted++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('first practice acquires lazy media and blocks reader resume', () async {
    SharedPreferences.setMockInitialValues({});
    final player = _MediaPlayer();

    var initialized = 0;
    late QuranContinuousPlayerService service;
    final handler = QuranBackgroundAudioHandler(
      player: player,
      onPlay: () => service.resume(),
      onPause: () => service.pause(),
      onStop: () => service.stop(),
      onNext: () => service.nextAyah(),
      onPrevious: () => service.previousAyah(),
      onSeek: (p) => service.seek(p),
    );
    service = QuranContinuousPlayerService(
      quranRepository: _Repository(),
      reciterService: QuranReciterService(
        await SharedPreferences.getInstance(),
      ),
      player: player,
      enableBackgroundAudioIntegration: true,
      backgroundAudioInitializer: () async {
        initialized++;
        return handler;
      },
    );
    final delegate = _Delegate();
    final lease = await service.acquireHandsFreeMedia(delegate);
    expect(lease?.isCurrent, isTrue);
    expect(initialized, 1);
    expect(await service.acquireHandsFreeMedia(_Delegate()), isNull);
    await service.resume();
    expect(player.playCallCount, 0);
    await lease!.release();
    await service.resume();
    expect(player.playCallCount, 1);
    service.dispose();
    await player.closeControllers();
  });

  test('late initialization after disposal cannot attach practice', () async {
    SharedPreferences.setMockInitialValues({});
    final player = _MediaPlayer();

    final pending = Completer<QuranBackgroundAudioHandler?>();
    final service = QuranContinuousPlayerService(
      quranRepository: _Repository(),
      reciterService: QuranReciterService(
        await SharedPreferences.getInstance(),
      ),
      player: player,
      enableBackgroundAudioIntegration: true,
      backgroundAudioInitializer: () => pending.future,
    );
    final acquiring = service.acquireHandsFreeMedia(_Delegate());
    await Future<void>.delayed(Duration.zero);
    service.dispose();
    pending.complete(null);
    expect(await acquiring, isNull);
    await player.closeControllers();
  });
}
