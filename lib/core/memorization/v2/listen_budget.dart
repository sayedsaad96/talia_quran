import 'session_phase.dart';
import 'session_state.dart';

/// How long speech recognition listens for the current recitation.
///
/// A single fixed pause window cut long block reviews short: a learner who
/// breathes between ayahs of a five-ayah block lost everything after the
/// first pause. Block reviews get a longer pause allowance and a listening
/// limit sized to the words they contain.
final class V2ListenBudget {
  const V2ListenBudget({required this.listenFor, required this.pauseFor});

  final Duration listenFor;
  final Duration pauseFor;

  /// Generous recitation pace (words per second) for sizing the window.
  static const double _wordsPerSecond = 1.2;

  factory V2ListenBudget.forState(V2SessionState state) {
    final isBlock = state.phase == V2SessionPhase.blockReview;
    final text = isBlock
        ? state.blockAyahs.map((ayah) => ayah.text).join(' ')
        : state.currentAyah.text;
    final words = text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final seconds = (words / _wordsPerSecond).ceil() + (isBlock ? 20 : 10);
    return V2ListenBudget(
      listenFor: Duration(seconds: seconds.clamp(30, 300)),
      pauseFor: Duration(seconds: isBlock ? 8 : 5),
    );
  }
}
