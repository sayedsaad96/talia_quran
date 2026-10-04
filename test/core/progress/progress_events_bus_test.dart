import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';

void main() {
  group('ProgressEventsBus', () {
    test('notify delivers reason to subscribers', () async {
      final bus = ProgressEventsBus();
      final reasons = <ProgressChangedReason>[];
      final sub = bus.changes.listen(reasons.add);

      bus.notify(ProgressChangedReason.reviewRecord);
      bus.notify(ProgressChangedReason.xp);

      await Future<void>.delayed(Duration.zero);
      expect(reasons, [
        ProgressChangedReason.reviewRecord,
        ProgressChangedReason.xp,
      ]);

      await sub.cancel();
      bus.dispose();
    });

    test('affectsProgressTab excludes xp-only changes', () {
      expect(
        ProgressEventsBus.affectsProgressTab(ProgressChangedReason.xp),
        isFalse,
      );
      expect(
        ProgressEventsBus.affectsProgressTab(ProgressChangedReason.streak),
        isTrue,
      );
    });

    test('activity feed refreshes home only and never pushes to cloud', () {
      const reason = ProgressChangedReason.activityFeed;
      expect(ProgressEventsBus.affectsHomeFullReload(reason), isTrue);
      expect(ProgressEventsBus.affectsProgressTab(reason), isFalse);
      expect(ProgressEventsBus.requiresCloudPush(reason), isFalse);
      expect(
        ProgressEventsBus.requiresCloudPush(ProgressChangedReason.cloudPull),
        isFalse,
      );
      expect(
        ProgressEventsBus.requiresCloudPush(ProgressChangedReason.reviewRecord),
        isTrue,
      );
    });
  });
}
