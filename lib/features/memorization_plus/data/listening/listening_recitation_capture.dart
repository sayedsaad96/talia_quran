import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/constants/speech_constants.dart';
import '../../../../core/utils/talia_logger.dart';

enum ListeningCaptureReadiness { ready, permissionDenied, unavailable }

/// Speech seam for Listening Review so the cubit can be unit-tested.
abstract interface class ListeningRecitationCapture {
  Future<ListeningCaptureReadiness> prepare();

  /// Starts listening. [onStopped] fires once if the recognizer ends on its
  /// own (silence timeout or error) before [stop] is called.
  Future<void> start(
    void Function(String words) onWords, {
    required void Function() onStopped,
  });

  /// Stops listening and returns the final recognized words ('' when none).
  Future<String> stop();

  Future<void> cancel();
}

class SpeechToTextListeningCapture implements ListeningRecitationCapture {
  SpeechToTextListeningCapture({
    SpeechToText? speech,
    Future<bool> Function()? voiceConsent,
  }) : _speech = speech ?? SpeechToText(),
       _voiceConsent = voiceConsent;

  /// How long [stop] waits for the recognizer's final result.
  static const _finalResultWait = Duration(milliseconds: 1200);

  final SpeechToText _speech;

  /// The speech disclosure (RecitationVoiceConsent.ensure); declining it is
  /// handled like a denied microphone, which falls back to self-grading.
  final Future<bool> Function()? _voiceConsent;
  bool _initialized = false;
  String _words = '';
  Completer<void>? _finalResult;
  void Function()? _onStopped;

  @override
  Future<ListeningCaptureReadiness> prepare() async {
    if (_initialized) return ListeningCaptureReadiness.ready;
    final consent = _voiceConsent;
    if (consent != null && !await consent()) {
      return ListeningCaptureReadiness.permissionDenied;
    }
    var status = await Permission.microphone.status;
    if (!status.isGranted) status = await Permission.microphone.request();
    if (!status.isGranted) return ListeningCaptureReadiness.permissionDenied;
    try {
      _initialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
    } catch (e, stack) {
      TaliaLogger.w('Listening review: speech unavailable', e, stack);
      _initialized = false;
    }
    return _initialized
        ? ListeningCaptureReadiness.ready
        : ListeningCaptureReadiness.unavailable;
  }

  @override
  Future<void> start(
    void Function(String words) onWords, {
    required void Function() onStopped,
  }) async {
    _words = '';
    _finalResult = Completer<void>();
    _onStopped = onStopped;
    await _speech.listen(
      onResult: (result) {
        _words = result.recognizedWords;
        onWords(_words);
        if (result.finalResult) _completeFinal();
      },
      listenOptions: SpeechListenOptions(
        localeId: kArabicSpeechLocaleId,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Future<String> stop() async {
    _onStopped = null; // an explicit stop is not an auto-stop
    await _speech.stop();
    final pending = _finalResult;
    if (pending != null) {
      await pending.future.timeout(_finalResultWait, onTimeout: () {});
    }
    return _words;
  }

  @override
  Future<void> cancel() async {
    _onStopped = null;
    _completeFinal();
    await _speech.cancel();
  }

  void _handleStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _fireStopped();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    TaliaLogger.w('Listening review: speech error ${error.errorMsg}');
    _completeFinal();
    _fireStopped();
  }

  void _fireStopped() {
    final callback = _onStopped;
    _onStopped = null;
    callback?.call();
  }

  void _completeFinal() {
    final pending = _finalResult;
    if (pending != null && !pending.isCompleted) pending.complete();
  }
}
