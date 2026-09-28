import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/services/adhan_preview_service.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('talia/adhan_preview_test');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Android stop waits for an in-flight preview start', () async {
    final startEntered = Completer<void>();
    final allowStart = Completer<void>();
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'previewStart') {
            startEntered.complete();
            await allowStart.future;
            return true;
          }
          return null;
        });
    final service = AdhanPreviewService(
      platform: TargetPlatform.android,
      channel: channel,
    );

    final start = service.start('default');
    await startEntered.future;
    final stop = service.stop();
    allowStart.complete();

    expect(await start, isFalse);
    await stop;
    expect(calls, [
      'previewStop',
      'previewStart',
      'previewStop',
      'previewStop',
    ]);
  });

  test('iOS stop during asset load prevents playback', () async {
    final assetLoaded = Completer<Duration?>();
    final assetLoadStarted = Completer<void>();
    final player = _MockAudioPlayer();
    when(() => player.setAsset('adhan.caf')).thenAnswer((_) {
      assetLoadStarted.complete();
      return assetLoaded.future;
    });
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    final service = AdhanPreviewService(
      platform: TargetPlatform.iOS,
      createIosPlayer: () => player,
      resolveIosAsset: (_) async => 'adhan.caf',
    );

    final start = service.start('default');
    await assetLoadStarted.future;
    final stop = service.stop();
    assetLoaded.complete(Duration.zero);

    expect(await start, isFalse);
    await stop;
    verifyNever(() => player.play());
    verify(() => player.dispose()).called(1);
  });

  test(
    'iOS start completes before playback ends and stop disposes player',
    () async {
      final playbackEnds = Completer<void>();
      final player = _MockAudioPlayer();
      when(
        () => player.setAsset('adhan.caf'),
      ).thenAnswer((_) async => Duration.zero);
      when(() => player.play()).thenAnswer((_) => playbackEnds.future);
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
      final service = AdhanPreviewService(
        platform: TargetPlatform.iOS,
        createIosPlayer: () => player,
        resolveIosAsset: (_) async => 'adhan.caf',
      );

      expect(await service.start('default'), isTrue);
      await service.stop();
      playbackEnds.complete();
      await Future<void>.delayed(Duration.zero);

      verify(() => player.play()).called(1);
      verify(() => player.dispose()).called(1);
    },
  );

  test('old iOS playback completion cannot dispose a newer preview', () async {
    final firstEnds = Completer<void>();
    final secondEnds = Completer<void>();
    final firstPlayer = _MockAudioPlayer();
    final secondPlayer = _MockAudioPlayer();
    for (final player in [firstPlayer, secondPlayer]) {
      when(
        () => player.setAsset('adhan.caf'),
      ).thenAnswer((_) async => Duration.zero);
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
    }
    when(() => firstPlayer.play()).thenAnswer((_) => firstEnds.future);
    when(() => secondPlayer.play()).thenAnswer((_) => secondEnds.future);
    var creations = 0;
    final service = AdhanPreviewService(
      platform: TargetPlatform.iOS,
      createIosPlayer: () => creations++ == 0 ? firstPlayer : secondPlayer,
      resolveIosAsset: (_) async => 'adhan.caf',
    );

    expect(await service.start('first'), isTrue);
    expect(await service.start('second'), isTrue);
    firstEnds.complete();
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => secondPlayer.dispose());

    await service.stop();
    secondEnds.complete();
    verify(() => secondPlayer.dispose()).called(1);
  });
}
