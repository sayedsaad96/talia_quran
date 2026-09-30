import '../entities/khatmah_plan.dart';

class KhatmahReminderSlot {
  const KhatmahReminderSlot({
    required this.at,
    required this.startPage,
    required this.endPage,
  });

  final DateTime at;
  final int startPage;
  final int endPage;
}

/// Which khatmah reminders to schedule: one-shot, only for an active plan,
/// never for a day whose wird is already complete or whose time has passed.
class KhatmahReminderPolicy {
  const KhatmahReminderPolicy._();

  static const maxSlots = 7;

  static List<KhatmahReminderSlot> slots({
    required KhatmahPlan? plan,
    required DateTime now,
    required int hour,
    required int minute,
  }) {
    if (plan == null ||
        plan.status != KhatmahStatus.active ||
        plan.isComplete) {
      return const [];
    }
    final result = <KhatmahReminderSlot>[];
    for (var offset = 0; result.length < maxSlots; offset++) {
      final at = DateTime(now.year, now.month, now.day + offset, hour, minute);
      if (!at.isAfter(now)) continue;
      if (offset == 0 && plan.isDailyTargetComplete(now)) continue;
      final target = plan.dailyTargetFor(at);
      result.add(
        KhatmahReminderSlot(
          at: at,
          startPage: target.startPage,
          endPage: target.endPage,
        ),
      );
    }
    return result;
  }
}
