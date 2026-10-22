/// Fixed server-approved encouragement messages. No free-form text is sent.
enum KidsEncouragementMessage {
  proud('proud'),
  wellDone('well_done'),
  keepGoing('keep_going'),
  greatEffort('great_effort'),
  seeYouTomorrow('see_you_tomorrow');

  const KidsEncouragementMessage(this.serverKey);
  final String serverKey;

  static KidsEncouragementMessage? fromServerKey(String value) {
    for (final message in values) {
      if (message.serverKey == value) return message;
    }
    return null;
  }
}

/// Approved local artwork only; remote URLs and arbitrary paths are excluded.
enum KidsEncouragementSticker {
  starReward('star_reward', 'assets/images/kids/star_reward.png'),
  taliaEncourage('talia_encourage', 'assets/images/talia/talia_encourage.png');

  const KidsEncouragementSticker(this.serverKey, this.assetPath);
  final String serverKey;
  final String assetPath;

  static KidsEncouragementSticker? fromServerKey(String value) {
    for (final sticker in values) {
      if (sticker.serverKey == value) return sticker;
    }
    return null;
  }
}

/// A validated server record. All timestamps are normalized to UTC.
final class KidsEncouragement {
  const KidsEncouragement({
    required this.id,
    required this.parentUserId,
    required this.childUserId,
    required this.message,
    required this.sticker,
    required this.createdAt,
    required this.seenAt,
    required this.clientRequestId,
  });

  final int id;
  final String parentUserId;
  final String childUserId;
  final KidsEncouragementMessage message;
  final KidsEncouragementSticker sticker;
  final DateTime createdAt;
  final DateTime? seenAt;
  final String clientRequestId;
}

sealed class KidsEncouragementSendResult {
  const KidsEncouragementSendResult();
}

final class KidsEncouragementSendSuccess extends KidsEncouragementSendResult {
  const KidsEncouragementSendSuccess(this.encouragement);
  final KidsEncouragement encouragement;
}

final class KidsEncouragementSendDisabled extends KidsEncouragementSendResult {
  const KidsEncouragementSendDisabled();
}
