import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/memorization_plus/data/hands_free/hands_free_audio_session.dart';

class _AudioSessionMock extends Mock implements AudioSession {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AudioSessionConfiguration.music());
  });

  group('PlatformHandsFreeAudioSession', () {
    late StreamController<AudioInterruptionEvent> interruptionEvents;
    late StreamController<void> noisyEvents;
    late _AudioSessionMock audioSession;
    late AudioSessionConfiguration previousConfiguration;

    setUp(() {
      interruptionEvents = StreamController<AudioInterruptionEvent>.broadcast(
        sync: true,
      );
      noisyEvents = StreamController<void>.broadcast(sync: true);
      audioSession = _AudioSessionMock();
      previousConfiguration = const AudioSessionConfiguration.music();

      when(() => audioSession.configuration).thenReturn(previousConfiguration);
      when(
        () => audioSession.interruptionEventStream,
      ).thenAnswer((_) => interruptionEvents.stream);
      when(
        () => audioSession.becomingNoisyEventStream,
      ).thenAnswer((_) => noisyEvents.stream);
      when(() => audioSession.configure(any())).thenAnswer((_) async {});
      when(() => audioSession.setActive(true)).thenAnswer((_) async => true);
      when(() => audioSession.setActive(false)).thenAnswer((_) async => true);
    });

    tearDown(() async {
      await interruptionEvents.close();
      await noisyEvents.close();
    });

    PlatformHandsFreeAudioSession createSession() {
      return PlatformHandsFreeAudioSession(
        sessionResolver: () async => audioSession,
      );
    }

    test('emits for interruption begin and becoming noisy only', () async {
      final session = createSession();
      var interruptions = 0;
      final subscription = session.interruptions.listen((_) => interruptions++);

      await session.activate();
      interruptionEvents.add(
        AudioInterruptionEvent(true, AudioInterruptionType.pause),
      );
      interruptionEvents.add(
        AudioInterruptionEvent(false, AudioInterruptionType.pause),
      );
      noisyEvents.add(null);

      expect(interruptions, 2);

      await subscription.cancel();
      await session.dispose();
    });

    test('release deactivates and restores the prior configuration', () async {
      final session = createSession();

      await session.activate();
      await session.release();

      verifyInOrder([
        () => audioSession.setActive(false),
        () => audioSession.configure(previousConfiguration),
      ]);

      await session.dispose();
    });

    test(
      'failed deactivation retains the session for a successful retry',
      () async {
        var deactivationAttempts = 0;
        when(() => audioSession.setActive(false)).thenAnswer((_) async {
          deactivationAttempts++;
          if (deactivationAttempts == 1) {
            throw StateError('deactivation failed');
          }
          return true;
        });
        final session = createSession();

        await session.activate();
        await expectLater(session.release(), throwsStateError);
        await session.release();
        await session.release();

        verify(() => audioSession.setActive(false)).called(2);
        verify(() => audioSession.configure(previousConfiguration)).called(2);

        await session.dispose();
      },
    );

    test(
      'failed restoration retains the session for a successful retry',
      () async {
        var restorationAttempts = 0;
        when(() => audioSession.configure(previousConfiguration)).thenAnswer((
          _,
        ) async {
          restorationAttempts++;
          if (restorationAttempts == 1) {
            throw StateError('restoration failed');
          }
        });
        final session = createSession();

        await session.activate();
        await expectLater(session.release(), throwsStateError);
        await session.release();
        await session.release();

        verify(() => audioSession.setActive(false)).called(2);
        verify(() => audioSession.configure(previousConfiguration)).called(2);

        await session.dispose();
      },
    );

    test(
      'a denied deactivation retains the session for a successful retry',
      () async {
        var deactivationAttempts = 0;
        when(() => audioSession.setActive(false)).thenAnswer((_) async {
          deactivationAttempts++;
          return deactivationAttempts > 1;
        });
        final session = createSession();

        await session.activate();
        await expectLater(session.release(), throwsStateError);
        await session.release();

        verify(() => audioSession.setActive(false)).called(2);
        await session.dispose();
      },
    );
  });
}
