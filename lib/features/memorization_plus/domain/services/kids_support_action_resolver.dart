import 'package:equatable/equatable.dart';

/// The one next step a kids session suggests. Every action maps to a help
/// the session already offers; the resolver only chooses which to point at.
enum KidsSupportAction {
  /// Nothing to suggest (recording, completed, technical trouble, no miss).
  none,

  /// «أعطني البداية» while recalling the hidden ayah.
  firstWord,

  /// A near miss at a hidden recitation: say it once more. Deliberately not
  /// «ذكّرني» — the engine keeps a near miss as a free retry, while a
  /// reminder records a failed recall and lowers the rating.
  tryAgain,

  /// After repeated misses, a guardian may listen and confirm.
  guardianHelp,
}

/// What the resolver may look at: the session's own visible state only.
class KidsSupportContext extends Equatable {
  const KidsSupportContext({
    required this.isRecording,
    required this.isCompleted,
    required this.isRecallingFromMemory,
    required this.isAwaitingRecitation,
    required this.firstWordRevealed,
    required this.lastAttemptMissed,
    required this.guardianFallbackAvailable,
    this.technicalTrouble = false,
    this.proactive = false,
  });

  final bool isRecording;
  final bool isCompleted;
  final bool isRecallingFromMemory;
  final bool isAwaitingRecitation;
  final bool firstWordRevealed;

  /// The latest recitation was heard and did not match (a real struggle).
  final bool lastAttemptMissed;

  /// The session already allows the guardian-confirmed completion.
  final bool guardianFallbackAvailable;

  /// Microphone, recognizer, silence or audio failure: never a weakness.
  final bool technicalTrouble;

  /// The guardian asked for help to be suggested before a miss (T7). It
  /// never adds an action the session would not offer anyway.
  final bool proactive;

  @override
  List<Object?> get props => [
    isRecording,
    isCompleted,
    isRecallingFromMemory,
    isAwaitingRecitation,
    firstWordRevealed,
    lastAttemptMissed,
    guardianFallbackAvailable,
    technicalTrouble,
    proactive,
  ];
}

/// Pure. Suggests help only after a heard miss (or proactively when the
/// guardian asked for it), and only an action that is valid in the current
/// phase, so it can never reveal a hint during recording or count anything.
KidsSupportAction resolveKidsSupportAction(KidsSupportContext context) {
  if (context.isRecording || context.isCompleted) {
    return KidsSupportAction.none;
  }
  if (context.technicalTrouble) return KidsSupportAction.none;
  if (!context.lastAttemptMissed && !context.proactive) {
    return KidsSupportAction.none;
  }
  if (context.lastAttemptMissed && context.guardianFallbackAvailable) {
    return KidsSupportAction.guardianHelp;
  }
  if (context.isRecallingFromMemory && !context.firstWordRevealed) {
    return KidsSupportAction.firstWord;
  }
  // Proactive help never applies here: before a first attempt the only help
  // is «ذكّرني», which would record a miss the child has not made.
  if (context.isAwaitingRecitation && context.lastAttemptMissed) {
    return KidsSupportAction.tryAgain;
  }
  return KidsSupportAction.none;
}
