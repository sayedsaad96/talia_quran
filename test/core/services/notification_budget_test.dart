import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/notification_service.dart';

void main() {
  test('frees lower-priority rolling notifications for prayer reminders', () {
    final pendingIds = <int>[
      ...List<int>.generate(21, (index) => 1040 + index),
      ...List<int>.generate(14, (index) => 1070 + index),
      ...List<int>.generate(14, (index) => 1090 + index),
      ...List<int>.generate(16, (index) => 1010 + index),
    ];

    final idsToCancel = notificationIdsToCancelForBudget(
      pendingIds: pendingIds,
      incomingCount: 35,
      limit: 60,
    );

    expect(idsToCancel, hasLength(40));
    expect(
      idsToCancel,
      containsAll(<int>[...List<int>.generate(16, (i) => 1010 + i)]),
    );
    expect(idsToCancel, isNot(contains(1040)));
  });

  test('budget never selects protected Companion IDs', () {
    final pendingIds = <int>[
      ...List<int>.generate(20, (i) => 2100 + i),
      ...List<int>.generate(10, (i) => 2120 + i),
      ...List<int>.generate(21, (i) => 1040 + i),
    ];

    final evicted = notificationIdsToCancelForBudget(
      pendingIds: pendingIds,
      incomingCount: 10,
      limit: 60,
    );

    expect(evicted.any((id) => id >= 2100 && id < 2130), isFalse);
    expect(evicted, contains(1040));
  });

  test(
    'budget never selects legacy prayer or Companion IDs even under pressure',
    () {
      final pendingIds = <int>[
        ...List<int>.generate(40, (i) => 2000 + i),
        ...List<int>.generate(20, (i) => 2100 + i),
        ...List<int>.generate(10, (i) => 2120 + i),
        1009, // smart reminder
      ];

      final evicted = notificationIdsToCancelForBudget(
        pendingIds: pendingIds,
        incomingCount: 20,
        limit: 60,
      );

      expect(evicted.any((id) => id >= 2000 && id < 2040), isFalse);
      expect(evicted.any((id) => id >= 2100 && id < 2130), isFalse);
    },
  );
}
