import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/constants/speech_constants.dart';
import '../../../../core/utils/talia_logger.dart';

enum ListeningCaptureReadiness { ready, permissionDenied, unavailable }

/// Speech seam for Listening Review so the cubit can be unit-tested.
abstract interface class ListeningRecitationCapture {
  Future<ListeningCaptureReadiness> prepare();

  Future<void> start(void Function(String words) onWords);

  /// Stops listening and returns the recognized words ('' when none).
  Future<String> stop();

  Future<void> cancel();
}

class SpeechToTextListeningCapture implements ListeningRecitationCapture {
  SpeechToTextListeningCapture([SpeechToText? speech])
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;
  String _words = '';

  @override
  Future<ListeningCaptureReadiness> prepare() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) status = await Permission.microphone.request();
    if (!status.isGranted) return ListeningCaptureReadiness.permissionDenied;
    if (!_initialized) {
      try {
        _initialized = await _speech.initialize();
      } catch (e, stack) {
        TaliaLogger.w('Listening review: speech unavailable', e, stack);
        _initialized = false;
      }
    }
    return _initialized
        ? ListeningCaptureReadiness.ready
        : ListeningCaptureReadiness.unavailable;
  }

  @override
  Future<void> start(void Function(String words) onWords) async {
    _words = '';
    await _speech.listen(
      onResult: (result) {
        _words = result.recognizedWords;
        onWords(_words);
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
    await _speech.stop();
    return _words;
  }

  @override
  Future<void> cancel() => _speech.cancel();
}
