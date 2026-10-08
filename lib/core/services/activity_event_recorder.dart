import '../../features/home/domain/entities/activity_event.dart';
import '../../features/home/domain/repositories/activity_feed_repository.dart';
import '../progress/progress_changed_reason.dart';
import '../progress/progress_events_bus.dart';

/// Fire-and-forget writer used at domain commit points. Failures never
/// invalidate the originating reading / memorization / khatmah write.
class ActivityEventRecorder {
  const ActivityEventRecorder(this._repository, [this._progressEvents]);

  final ActivityFeedRepository _repository;
  final ProgressEventsBus? _progressEvents;

  /// Appends [event]; with [replace], overwrites the entry with its key.
  Future<void> record(ActivityEvent event, {bool replace = false}) async {
    try {
      await _repository.append(event, replace: replace);
      _progressEvents?.notify(ProgressChangedReason.activityFeed);
    } catch (_) {}
  }

  static String dayKey(DateTime at) {
    final local = at.toLocal();
    return '${local.year}'
        '${local.month.toString().padLeft(2, '0')}'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
