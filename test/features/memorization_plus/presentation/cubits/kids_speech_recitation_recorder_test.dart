import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';

void main() {
  group('KidsSpeechRecitationRecorder errors (K21)', () {
    Future<KidsRecitationCaptureResult> captureWith(_FakeSpeech speech) {
      final recorder = KidsSpeechRecitationRecorder(
        speechToText: speech,
        microphonePermission: () async => true,
      );
      return recorder.capture(
        externalCompleter: Completer<KidsRecitationCaptureResult>(),
      );
    }

    for (final errorMsg in ['error_no_match', 'error_speech_timeout']) {
      test('$errorMsg is silence, not a broken microphone', () async {
        final result = await captureWith(_FakeSpeech(errorMsg: errorMsg));

        expect(result.isError, isFalse);
        expect(result.recognizedWords, isEmpty);
      });
    }

    test('silence after partial words still evaluates those words', () async {
      final result = await captureWith(
        _FakeSpeech(errorMsg: 'error_no_match', partialWords: 'قل هو'),
      );

      expect(result.isError, isFalse);
      expect(result.recognizedWords, 'قل هو');
    });

    for (final errorMsg in ['error_network', 'error_audio', 'error_busy']) {
      test('$errorMsg is a real recognizer fault', () async {
        final result = await captureWith(_FakeSpeech(errorMsg: errorMsg));

        expect(result.isError, isTrue);
        expect(result.messageCode, CubitMessageCodes.kidsRecordingUnavailable);
      });
    }
  });
}

/// Recognizer that reports optional partial words, then fails with
/// [errorMsg] — the way Android ends a listen the child stayed quiet in.
class _FakeSpeech implements SpeechToText {
  _FakeSpeech({required this.errorMsg, this.partialWords = ''});

  final String errorMsg;
  final String partialWords;
  SpeechErrorListener? _onError;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    dynamic debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    _onError = onError;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #listen) {
      final onResult =
          invocation.namedArguments[#onResult] as SpeechResultListener?;
      if (partialWords.isNotEmpty) {
        onResult?.call(
          SpeechRecognitionResult([
            SpeechRecognitionWords(partialWords, null, 0.9),
          ], ResultType.partial.value),
        );
      }
      scheduleMicrotask(
        () => _onError?.call(SpeechRecognitionError(errorMsg, true)),
      );
      return Future<void>.value();
    }
    if (invocation.memberName == #stop || invocation.memberName == #cancel) {
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}
