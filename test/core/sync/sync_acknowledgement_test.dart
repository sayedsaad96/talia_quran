import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/sync/sync_acknowledgement.dart';

void main() {
  group('SyncAcknowledgement', () {
    test('does not acknowledge a newer local daily-activity write', () {
      const outbound = {'day_key': 20260821, 'activity_count': 3};
      const newerLocal = {'day_key': 20260821, 'activity_count': 4};

      expect(
        SyncAcknowledgement.matches(outbound: outbound, current: newerLocal),
        isFalse,
      );
    });

    test('acknowledges only an unchanged outbound snapshot', () {
      const snapshot = {
        'current_streak': 3,
        'longest_streak': 7,
        'last_activity_date': '2026-08-21',
        'freezes_available': 1,
      };

      expect(
        SyncAcknowledgement.matches(outbound: snapshot, current: snapshot),
        isTrue,
      );
    });

    test('compares collection fingerprints by value', () {
      expect(
        SyncAcknowledgement.matches(
          outbound: const {'pages': [2, 4, 6]},
          current: const {'pages': [2, 4, 6]},
        ),
        isTrue,
      );
    });
  });
}
