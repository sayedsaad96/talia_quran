/// Interprets the precise rows accepted by the kids-log RPC.
abstract final class KidsSessionLogAcknowledgement {
  static Set<String> acceptedIds({
    required Set<String> sentIds,
    required Iterable<Map<String, dynamic>> acknowledgedRows,
  }) {
    return {
      for (final row in acknowledgedRows)
        if (row['local_id'] is String && sentIds.contains(row['local_id']))
          row['local_id'] as String,
    };
  }
}
