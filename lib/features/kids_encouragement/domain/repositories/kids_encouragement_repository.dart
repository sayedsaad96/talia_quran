import '../entities/kids_encouragement.dart';

abstract interface class KidsEncouragementRepository {
  Future<KidsEncouragementSendResult> send({
    required String childUserId,
    required KidsEncouragementMessage message,
    required KidsEncouragementSticker sticker,
    required String clientRequestId,
  });

  Future<List<KidsEncouragement>> refresh({required String childUserId});

  List<KidsEncouragement> cached({required String childUserId});

  Future<int> markSeen(List<int> ids);

  Future<int> retryPendingSeen();

  Future<List<int>> pendingSeenIds();
}
