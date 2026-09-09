import '../entities/activity_event.dart';

abstract class ActivityFeedRepository {
  Future<void> append(ActivityEvent event);

  Future<List<ActivityEvent>> recent({int limit = 20});

  /// Kinds of work logged at or after [start], unbounded by the feed limit so
  /// "did the user do this today" cannot be answered wrong on a busy day.
  Future<Set<ActivityEventKind>> kindsSince(DateTime start);
}
