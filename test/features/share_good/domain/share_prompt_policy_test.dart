import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/share_good/domain/entities/share_prompt_state.dart';
import 'package:talia_quran/features/share_good/domain/services/share_prompt_policy.dart';

void main() {
  const policy = SharePromptPolicy();
  final now = DateTime.utc(2026, 11, 7);
  test('first completion prompts and the 72 hour boundary is inclusive', () {
    expect(policy.shouldPrompt(const SharePromptState(), now), isTrue);
    expect(
      policy.shouldPrompt(SharePromptState(lastShownAt: now), now),
      isFalse,
    );
    expect(
      policy.shouldPrompt(
        SharePromptState(lastShownAt: now.subtract(const Duration(hours: 72))),
        now,
      ),
      isTrue,
    );
  });
  test('dismissals double the gap up to eight times', () {
    for (var dismissals = 0; dismissals <= 5; dismissals++) {
      final hours = 72 * (1 << dismissals.clamp(0, 3));
      final state = SharePromptState(
        lastShownAt: now,
        dismissCount: dismissals,
      );
      expect(
        policy.shouldPrompt(state, now.add(Duration(hours: hours - 1))),
        isFalse,
      );
      expect(
        policy.shouldPrompt(state, now.add(Duration(hours: hours))),
        isTrue,
      );
    }
  });
  test('frequent creators and lifetime cap stop hints', () {
    expect(
      policy.shouldPrompt(const SharePromptState(invitesCreated: 3), now),
      isFalse,
    );
    expect(
      policy.shouldPrompt(const SharePromptState(shownCount: 12), now),
      isFalse,
    );
    expect(
      policy.shouldPrompt(
        const SharePromptState(shownCount: 11, invitesCreated: 2),
        now,
      ),
      isTrue,
    );
  });
}
