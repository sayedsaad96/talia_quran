import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';

void main() {
  final occurrence = PrayerOccurrence(
    ownerId: 'owner',
    localDate: DateTime(2026, 10, 20),
    prayerKey: PrayerKey.fajr,
    scheduledAt: DateTime.utc(2026, 10, 20, 4),
  );
  test('disabled review and missing occurrence cannot build a review page', () {
    expect(prayerReviewRedirect(null, occurrence), AppRoutes.memorizationHub);
    expect(
      prayerReviewRedirect(ExperienceFlags((_) => false), occurrence),
      AppRoutes.memorizationHub,
    );
    expect(
      prayerReviewRedirect(ExperienceFlags((_) => true), null),
      AppRoutes.home,
    );
    expect(
      prayerReviewRedirect(ExperienceFlags((_) => true), occurrence),
      isNull,
    );
  });
}
