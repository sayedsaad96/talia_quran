import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/daily_ayah_notification_target.dart';

void main() {
  test('opens the precise daily-ayah page without placing ayah text in payload', () {
    const target = DailyAyahNotificationTarget(
      surahId: 2,
      ayahNumber: 185,
      pageNumber: 28,
    );

    expect(target.payload, '/quran/page/28?dailyAyah=2-185');
  });
}
