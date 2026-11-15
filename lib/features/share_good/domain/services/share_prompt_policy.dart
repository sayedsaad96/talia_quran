import '../entities/share_prompt_state.dart';

/// Presentation hints have no effect on worship completion or rewards.
final class SharePromptPolicy {
  const SharePromptPolicy();

  bool shouldPrompt(SharePromptState state, DateTime now) {
    if (state.invitesCreated >= 3 || state.shownCount >= 12) return false;
    final last = state.lastShownAt;
    if (last == null) return true;
    final multiplier = 1 << state.dismissCount.clamp(0, 3);
    return now.difference(last) >= Duration(hours: 72 * multiplier);
  }
}
