import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/home/data/home_slot_snooze_store.dart';
import 'package:talia_quran/features/home/domain/entities/home_contextual_slot.dart';

void main() {
  test('snooze expires and legacy sign-in dismissal migrates', () async {
    SharedPreferences.setMockInitialValues({
      'sign_in_nudge_dismissed': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime(2026, 9, 8);
    final store = HomeSlotSnoozeStore(prefs, now: () => now);

    expect(store.isSnoozed(HomeSlotKind.signIn), isTrue);
    expect(prefs.getBool('sign_in_nudge_dismissed'), isNull);

    await store.snooze(
      HomeSlotKind.tutorial,
      duration: const Duration(hours: 1),
    );
    expect(store.isSnoozed(HomeSlotKind.tutorial), isTrue);

    final later = HomeSlotSnoozeStore(
      prefs,
      now: () => now.add(const Duration(hours: 2)),
    );
    expect(later.isSnoozed(HomeSlotKind.tutorial), isFalse);
  });
}
