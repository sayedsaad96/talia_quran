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
    expect(idsToCancel, containsAll(<int>[...List<int>.generate(16, (i) => 1010 + i)]));
    expect(idsToCancel, isNot(contains(1040)));
  });
}
