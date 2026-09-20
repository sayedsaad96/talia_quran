import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/services/audio_lifecycle_manager.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {
  bool _isPlaying = true;
  int pauseCount = 0;

  @override
  bool get playing => _isPlaying;

  @override
  Future<void> pause() async {
    pauseCount++;
    _isPlaying = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AudioLifecycleManager manager;
  late MockAudioPlayer player1;
  late MockAudioPlayer player2;

  setUp(() {
    manager = AudioLifecycleManager.instance;
    player1 = MockAudioPlayer();
    player2 = MockAudioPlayer();
  });

  tearDown(() {
    manager.unregister(player1);
    manager.unregister(player2);
    TestWidgetsFlutterBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  test('exempts player when shouldPause returns false', () {
    // player1 is registered with shouldPause: false (background allowed)
    manager.register(player1, shouldPause: () => false);

    // player2 is registered without shouldPause (default: must pause)
    manager.register(player2);

    // Trigger pauseAll
    manager.pauseAll();

    // player1 should NOT have been paused
    expect(player1.pauseCount, 0);

    // player2 should have been paused
    expect(player2.pauseCount, 1);
  });

  test('pauses player when shouldPause returns true', () {
    manager.register(player1, shouldPause: () => true);

    manager.pauseAll();

    expect(player1.pauseCount, 1);
  });
}
