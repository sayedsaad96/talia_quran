import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/services/khatmah_reminder_policy.dart';

void main() {
  KhatmahPlan plan({
    Set<int> read = const {},
    KhatmahStatus status = KhatmahStatus.active,
  }) => KhatmahPlan(
    id: 'p',
    title: KhatmahPlan.defaultTitle,
    completedPages: read,
    targetPagesPerDay: 5,
    targetDays: 121,
    status: status,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 5, 1),
  );

  test('no plan or a paused plan gets no reminders', () {
    final now = DateTime(2026, 2, 1, 9);
    expect(
      KhatmahReminderPolicy.slots(plan: null, now: now, hour: 17, minute: 0),
      isEmpty,
    );
    expect(
      KhatmahReminderPolicy.slots(
        plan: plan(status: KhatmahStatus.paused),
        now: now,
        hour: 17,
        minute: 0,
      ),
      isEmpty,
    );
  });

  test('before the time with wird pending: today plus six more days', () {
    final slots = KhatmahReminderPolicy.slots(
      plan: plan(),
      now: DateTime(2026, 2, 1, 9),
      hour: 17,
      minute: 0,
    );
    expect(slots, hasLength(7));
    expect(slots.first.at, DateTime(2026, 2, 1, 17));
    expect(slots.last.at, DateTime(2026, 2, 7, 17));
    expect((slots.first.startPage, slots.first.endPage), (1, 5));
  });

  test('wird already done today starts tomorrow with the next range', () {
    final done = plan(read: {1, 2, 3, 4, 5}).copyWith(
      dailyTargetDate: DateTime(2026, 2, 1),
      dailyTargetStartPage: 1,
      dailyTargetEndPage: 5,
    );
    final slots = KhatmahReminderPolicy.slots(
      plan: done,
      now: DateTime(2026, 2, 1, 9),
      hour: 17,
      minute: 0,
    );
    expect(slots.first.at, DateTime(2026, 2, 2, 17));
    expect((slots.first.startPage, slots.first.endPage), (6, 10));
    expect(slots, hasLength(7));
  });

  test('time already passed today starts tomorrow', () {
    final slots = KhatmahReminderPolicy.slots(
      plan: plan(),
      now: DateTime(2026, 2, 1, 18),
      hour: 17,
      minute: 0,
    );
    expect(slots.first.at, DateTime(2026, 2, 2, 17));
    expect(slots, hasLength(7));
  });
}
