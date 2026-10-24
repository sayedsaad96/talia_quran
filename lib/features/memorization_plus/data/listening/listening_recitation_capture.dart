import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/constants/speech_constants.dart';
import '../../../../core/utils/talia_logger.dart';

enum ListeningCaptureReadiness { ready, permissionDenied, unavailable }

/// Optional recognizer health: an error is not a completed recitation attempt.
abstract interface class ListeningCaptureHealth {
  bool get hadError;
}

/// Optional recognizer health: the microphone itself is unavailable or taken
/// by another app (call, other recorder), which is an interruption rather
/// than a per-item "mic failed" fallback.
abstract interface class ListeningCaptureFault {
  bool get audioBusy;
}

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

/// `SpeechToText` is a process singleton whose `initialize` returns early
/// (keeping the FIRST caller's listeners) once it has worked. This router is
/// the single owner of the engine's listeners: it installs one stable pair on
/// every activation and forwards status/error to the active client only, so
/// whichever feature listens next still gets its callbacks.
final class SpeechCallbackRouter {
  SpeechCallbackRouter._(this._speech);
  static final _byEngine = Expando<SpeechCallbackRouter>();

  /// One router per engine instance (the real engine is itself a singleton).
  static SpeechCallbackRouter of(SpeechToText speech) =>
      _byEngine[speech] ??= SpeechCallbackRouter._(speech);

  final SpeechToText _speech;
  Object? _owner;
  SpeechStatusListener? _onStatus;
  SpeechErrorListener? _onError;

  /// Makes [owner] the receiver of status and error callbacks.
  void activate(
    Object owner, {
    required SpeechStatusListener onStatus,
    required SpeechErrorListener onError,
  }) {
    _owner = owner;
    _onStatus = onStatus;
    _onError = onError;
    _bindEngineListeners();
  }

  /// Stops forwarding to [owner]; a no-op when another client took over.
  void deactivate(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _onStatus = null;
    _onError = null;
  }

  /// The engine keeps the first initializer's listeners; overwrite them.
  void _bindEngineListeners() {
    try {
      _speech.statusListener = _status;
      _speech.errorListener = _error;
    } catch (_) {
      // Test doubles may not support the setters; initialize() already
      // received the dispatchers.
    }
  }

  void _status(String status) => _onStatus?.call(status);
  void _error(SpeechRecognitionError error) => _onError?.call(error);

  Future<bool> initialize(
    SpeechToText speech,
    Object owner, {
    required SpeechStatusListener onStatus,
    required SpeechErrorListener onError,
  }) async {
    _owner = owner;
    _onStatus = onStatus;
    _onError = onError;
    final worked = await speech.initialize(onStatus: _status, onError: _error);
    _bindEngineListeners();
    return worked;
  }
}

class SpeechToTextListeningCapture
    implements
        ListeningRecitationCapture,
        ListeningCaptureHealth,
        ListeningCaptureFault {
  SpeechToTextListeningCapture({
    SpeechToText? speech,
    this._voiceConsent,
    Future<bool> Function()? microphoneGranted,
  }) : _speech = speech ?? SpeechToText(),
       _microphoneGranted = microphoneGranted ?? _platformMicrophoneGranted;

  static Future<bool> _platformMicrophoneGranted() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) status = await Permission.microphone.request();
    return status.isGranted;
  }

  final Future<bool> Function() _microphoneGranted;

  /// How long [stop] waits for the recognizer's final result.
  static const _finalResultWait = Duration(milliseconds: 1200);

  final SpeechToText _speech;

  /// The speech disclosure (RecitationVoiceConsent.ensure); declining it is
  /// handled like a denied microphone, which falls back to self-grading.
  final Future<bool> Function()? _voiceConsent;
  bool _initialized = false;
  @override
  bool hadError = false;
  @override
  bool audioBusy = false;

  static const _audioBusyErrors = {
    'error_audio',
    'error_recognizer_busy',
    'error_busy',
  };
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
    if (!await _microphoneGranted()) {
      return ListeningCaptureReadiness.permissionDenied;
    }
    try {
      _initialized = await SpeechCallbackRouter.of(_speech).initialize(
        _speech,
        this,
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
    SpeechCallbackRouter.of(
      _speech,
    ).activate(this, onStatus: _handleStatus, onError: _handleError);
    hadError = false;
    audioBusy = false;
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
    SpeechCallbackRouter.of(_speech).deactivate(this);
    await _speech.cancel();
  }

  void _handleStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _fireStopped();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    hadError = true;
    if (_audioBusyErrors.contains(error.errorMsg)) audioBusy = true;
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
