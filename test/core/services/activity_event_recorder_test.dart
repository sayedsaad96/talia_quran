import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/activity_event_recorder.dart';
import 'package:talia_quran/features/home/domain/entities/activity_event.dart';
import 'package:talia_quran/features/home/domain/repositories/activity_feed_repository.dart';

class _FakeFeed implements ActivityFeedRepository {
  _FakeFeed({this.fail = false});

  final bool fail;
  final appended = <ActivityEvent>[];

  @override
  Future<void> append(ActivityEvent event) async {
    if (fail) throw StateError('isar');
    appended.add(event);
  }

  @override
  Future<Set<ActivityEventKind>> kindsSince(DateTime start) async => {};

  @override
  Future<List<ActivityEvent>> recent({int limit = 20}) async => appended;
}

ActivityEvent _event() => ActivityEvent(
  occurredAt: DateTime(2026, 10, 5, 9),
  kind: ActivityEventKind.reading,
  idempotencyKey: 'reading|20261005|1',
  pageNumber: 1,
);

void main() {
  test('a recorded event notifies the home activity feed', () async {
    final bus = ProgressEventsBus();
    final reasons = <ProgressChangedReason>[];
    final sub = bus.changes.listen(reasons.add);
    final feed = _FakeFeed();

    await ActivityEventRecorder(feed, bus).record(_event());
    await Future<void>.delayed(Duration.zero);

    expect(feed.appended, hasLength(1));
    expect(reasons, [ProgressChangedReason.activityFeed]);
    await sub.cancel();
    bus.dispose();
  });

  test('a failed write is swallowed and notifies nobody', () async {
    final bus = ProgressEventsBus();
    final reasons = <ProgressChangedReason>[];
    final sub = bus.changes.listen(reasons.add);

    await ActivityEventRecorder(_FakeFeed(fail: true), bus).record(_event());
    await Future<void>.delayed(Duration.zero);

    expect(reasons, isEmpty);
    await sub.cancel();
    bus.dispose();
  });
}
