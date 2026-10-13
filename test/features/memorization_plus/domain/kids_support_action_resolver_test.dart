import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_support_action_resolver.dart';

KidsSupportContext _ctx({
  bool recording = false,
  bool completed = false,
  bool recalling = false,
  bool awaiting = false,
  bool firstWordRevealed = false,
  bool missed = false,
  bool guardian = false,
  bool technical = false,
  bool proactive = false,
}) => KidsSupportContext(
  isRecording: recording,
  isCompleted: completed,
  isRecallingFromMemory: recalling,
  isAwaitingRecitation: awaiting,
  firstWordRevealed: firstWordRevealed,
  lastAttemptMissed: missed,
  guardianFallbackAvailable: guardian,
  technicalTrouble: technical,
  proactive: proactive,
);

void main() {
  KidsSupportAction resolve(KidsSupportContext c) =>
      resolveKidsSupportAction(c);

  test('nothing is suggested before any miss', () {
    expect(resolve(_ctx(recalling: true)), KidsSupportAction.none);
    expect(resolve(_ctx(awaiting: true)), KidsSupportAction.none);
  });

  test('a miss while recalling suggests the first word', () {
    expect(
      resolve(_ctx(recalling: true, missed: true)),
      KidsSupportAction.firstWord,
    );
  });

  test('once the first word is shown it is not suggested again', () {
    expect(
      resolve(_ctx(recalling: true, missed: true, firstWordRevealed: true)),
      KidsSupportAction.none,
    );
  });

  test('a near miss at a hidden recitation suggests trying once more', () {
    // Not «remind me»: that would record a failed recall the engine keeps
    // as a free retry.
    expect(
      resolve(_ctx(awaiting: true, missed: true)),
      KidsSupportAction.tryAgain,
    );
  });

  test('repeated misses that unlock the guardian route suggest a grown-up', () {
    expect(
      resolve(_ctx(awaiting: true, missed: true, guardian: true)),
      KidsSupportAction.guardianHelp,
    );
  });

  test('technical trouble is never treated as a struggle', () {
    expect(
      resolve(
        _ctx(awaiting: true, missed: true, guardian: true, technical: true),
      ),
      KidsSupportAction.none,
    );
    expect(
      resolve(_ctx(recalling: true, technical: true, proactive: true)),
      KidsSupportAction.none,
    );
  });

  test('nothing is ever suggested while recording or after completion', () {
    expect(
      resolve(_ctx(recording: true, awaiting: true, missed: true)),
      KidsSupportAction.none,
    );
    expect(
      resolve(_ctx(completed: true, recalling: true, missed: true)),
      KidsSupportAction.none,
    );
  });

  test('outside recall and recitation there is nothing to point at', () {
    expect(resolve(_ctx(missed: true)), KidsSupportAction.none);
  });

  group('proactive (guardian setting)', () {
    test('suggests the first word while recalling, before a miss', () {
      expect(
        resolve(_ctx(recalling: true, proactive: true)),
        KidsSupportAction.firstWord,
      );
    });

    test('suggests nothing at a hidden recitation before any attempt', () {
      // Every review opens here; the only help would record a miss.
      expect(
        resolve(_ctx(awaiting: true, proactive: true)),
        KidsSupportAction.none,
      );
    });

    test('never jumps to the guardian route without a miss', () {
      expect(
        resolve(_ctx(awaiting: true, guardian: true, proactive: true)),
        KidsSupportAction.none,
      );
    });

    test('adds no help outside the phases that offer it', () {
      expect(resolve(_ctx(proactive: true)), KidsSupportAction.none);
    });
  });
}
