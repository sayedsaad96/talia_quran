import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_recitation_capture.dart';

/// Mimics the real singleton: once initialize worked, later calls return early
/// and keep the listeners from the first call.
class _SingletonSpeech extends Fake implements SpeechToText {
  SpeechStatusListener? status;
  SpeechErrorListener? error;
  int initializeCalls = 0;
  bool _worked = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == const Symbol('statusListener=')) {
      status = invocation.positionalArguments.first as SpeechStatusListener?;
      return null;
    }
    if (invocation.memberName == const Symbol('errorListener=')) {
      error = invocation.positionalArguments.first as SpeechErrorListener?;
      return null;
    }
    switch (invocation.memberName) {
      case #initialize:
        initializeCalls++;
        if (!_worked) {
          _worked = true;
          status =
              invocation.namedArguments[#onStatus] as SpeechStatusListener?;
          error = invocation.namedArguments[#onError] as SpeechErrorListener?;
        }
        return Future<bool>.value(true);
      case #listen:
      case #stop:
      case #cancel:
        return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('SpeechCallbackRouter', () {
    test(
      'another feature initializing first does not starve a later client',
      () async {
        final speech = _SingletonSpeech();
        final foreign = <String>[];
        // Kids/memorization-style direct initialize wins the singleton.
        await speech.initialize(onStatus: foreign.add);
        final router = SpeechCallbackRouter.of(speech);
        final handsFree = <String>[];
        final owner = Object();
        await router.initialize(
          speech,
          owner,
          onStatus: handsFree.add,
          onError: (_) {},
        );
        speech.status!('done');
        expect(handsFree, ['done']);
        expect(foreign, isEmpty);
      },
    );

    test('a client activating after hands-free still gets callbacks', () async {
      final speech = _SingletonSpeech();
      final router = SpeechCallbackRouter.of(speech);
      final handsFree = Object(), kids = Object();
      final handsFreeStatus = <String>[], kidsErrors = <String>[];
      await router.initialize(
        speech,
        handsFree,
        onStatus: handsFreeStatus.add,
        onError: (_) {},
      );
      router.activate(
        kids,
        onStatus: (_) {},
        onError: (e) => kidsErrors.add(e.errorMsg),
      );
      speech.error!(SpeechRecognitionError('error_no_match', true));
      speech.status!('done');
      expect(kidsErrors, ['error_no_match']);
      expect(handsFreeStatus, isEmpty);
    });

    test('deactivate stops delivery only for the current owner', () async {
      final speech = _SingletonSpeech();
      final router = SpeechCallbackRouter.of(speech);
      final a = Object(), b = Object();
      final seen = <String>[];
      router.activate(a, onStatus: (s) => seen.add('a$s'), onError: (_) {});
      router.activate(b, onStatus: (s) => seen.add('b$s'), onError: (_) {});
      router.deactivate(a); // stale: b stays active
      speech.status!('1');
      router.deactivate(b);
      speech.status!('2');
      expect(seen, ['b1']);
    });
  });

  test('audio-busy recognizer errors are flagged for the cubit', () async {
    final speech = _SingletonSpeech();
    final capture = SpeechToTextListeningCapture(
      speech: speech,
      microphoneGranted: () async => true,
    );
    await capture.prepare();
    await capture.start((_) {}, onStopped: () {});
    speech.error!(SpeechRecognitionError('error_no_match', true));
    expect(capture.audioBusy, isFalse);
    await capture.start((_) {}, onStopped: () {});
    speech.error!(SpeechRecognitionError('error_recognizer_busy', true));
    expect(capture.audioBusy, isTrue);
  });

  test('a second capture still receives status and error callbacks', () async {
    final speech = _SingletonSpeech();
    SpeechToTextListeningCapture create() => SpeechToTextListeningCapture(
      speech: speech,
      microphoneGranted: () async => true,
    );
    final first = create(), second = create();
    expect(await first.prepare(), ListeningCaptureReadiness.ready);
    expect(await second.prepare(), ListeningCaptureReadiness.ready);
    expect(speech.initializeCalls, 2);

    var firstStops = 0, secondStops = 0;
    await first.start((_) {}, onStopped: () => firstStops++);
    await first.cancel();
    await second.start((_) {}, onStopped: () => secondStops++);

    speech.status!(SpeechToText.doneStatus);
    expect(secondStops, 1);
    expect(firstStops, 0);

    await second.start((_) {}, onStopped: () => secondStops++);
    speech.error!(SpeechRecognitionError('error_no_match', true));
    expect(second.hadError, isTrue);
    expect(first.hadError, isFalse);
    expect(secondStops, 2);
  });
}
