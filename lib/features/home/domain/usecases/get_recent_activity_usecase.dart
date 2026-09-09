import '../entities/activity_event.dart';
import '../repositories/activity_feed_repository.dart';

class GetRecentActivityUsecase {
  GetRecentActivityUsecase(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ActivityFeedRepository _repository;
  final DateTime Function() _now;

  static const int defaultLimit = 20;

  Future<List<ActivityEvent>> call({int limit = defaultLimit}) {
    return _repository.recent(limit: limit);
  }

  /// Work the user actually performed during the current local day.
  Future<Set<ActivityEventKind>> kindsToday() {
    final now = _now();
    return _repository.kindsSince(DateTime(now.year, now.month, now.day));
  }
}
