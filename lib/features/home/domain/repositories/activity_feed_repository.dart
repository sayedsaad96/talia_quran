import '../entities/activity_event.dart';

abstract class ActivityFeedRepository {
  /// Adds [event] once per idempotency key. With [replace], an existing entry
  /// with the same key is overwritten instead (a session growing ayah by ayah).
  Future<void> append(ActivityEvent event, {bool replace = false});

  /// Newest entries of one audience: the primary (adult) learner by default,
  /// or the kids track when [kids] is true. The two never mix.
  Future<List<ActivityEvent>> recent({int limit = 20, bool kids = false});

  /// Kinds of adult work logged at or after [start], unbounded by the feed
  /// limit so "did the user do this today" cannot be answered wrong on a
  /// busy day.
  Future<Set<ActivityEventKind>> kindsSince(DateTime start);
}
