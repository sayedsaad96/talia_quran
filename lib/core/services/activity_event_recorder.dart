import '../../features/home/domain/entities/activity_event.dart';
import '../../features/home/domain/repositories/activity_feed_repository.dart';

/// Fire-and-forget writer used at domain commit points. Failures never
/// invalidate the originating reading / memorization / khatmah write.
class ActivityEventRecorder {
  const ActivityEventRecorder(this._repository);

  final ActivityFeedRepository _repository;

  Future<void> record(ActivityEvent event) async {
    try {
      await _repository.append(event);
    } catch (_) {}
  }

  static String dayKey(DateTime at) {
    final local = at.toLocal();
    return '${local.year}'
        '${local.month.toString().padLeft(2, '0')}'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
