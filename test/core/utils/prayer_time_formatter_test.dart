import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/utils/prayer_time_formatter.dart';

void main() {
  group('formatPrayerRemainingTime - Arabic', () {
    test('minutes <= 0 returns أقل من دقيقة', () {
      expect(formatPrayerRemainingTime(0, isArabic: true), 'أقل من دقيقة');
      expect(formatPrayerRemainingTime(-5, isArabic: true), 'أقل من دقيقة');
    });

    test('under 60 minutes uses proper Arabic forms', () {
      expect(formatPrayerRemainingTime(1, isArabic: true), 'دقيقة');
      expect(formatPrayerRemainingTime(2, isArabic: true), 'دقيقتين');
      expect(formatPrayerRemainingTime(3, isArabic: true), '3 دقائق');
      expect(formatPrayerRemainingTime(5, isArabic: true), '5 دقائق');
      expect(formatPrayerRemainingTime(10, isArabic: true), '10 دقائق');
      expect(formatPrayerRemainingTime(11, isArabic: true), '11 دقيقة');
      expect(formatPrayerRemainingTime(25, isArabic: true), '25 دقيقة');
      expect(formatPrayerRemainingTime(59, isArabic: true), '59 دقيقة');
    });

    test('exact hours with 0 remaining minutes', () {
      expect(formatPrayerRemainingTime(60, isArabic: true), 'ساعة');
      expect(formatPrayerRemainingTime(120, isArabic: true), 'ساعتين');
      expect(formatPrayerRemainingTime(180, isArabic: true), '3 ساعات');
      expect(formatPrayerRemainingTime(600, isArabic: true), '10 ساعات');
      expect(formatPrayerRemainingTime(660, isArabic: true), '11 ساعة');
    });

    test('hours with remaining minutes (such as 394 minutes from screenshot)', () {
      // 394 min = 6 hours (6 ساعات) and 34 min (34 دقيقة)
      expect(formatPrayerRemainingTime(394, isArabic: true), '6 ساعات و 34 دقيقة');

      // 61 min = 1 hour (ساعة) and 1 min (ودقيقة)
      expect(formatPrayerRemainingTime(61, isArabic: true), 'ساعة ودقيقة');

      // 62 min = 1 hour (ساعة) and 2 min (ودقيقتين)
      expect(formatPrayerRemainingTime(62, isArabic: true), 'ساعة ودقيقتين');

      // 65 min = 1 hour (ساعة) and 5 min (و 5 دقائق)
      expect(formatPrayerRemainingTime(65, isArabic: true), 'ساعة و 5 دقائق');

      // 75 min = 1 hour (ساعة) and 15 min (و 15 دقيقة)
      expect(formatPrayerRemainingTime(75, isArabic: true), 'ساعة و 15 دقيقة');

      // 125 min = 2 hours (ساعتين) and 5 min (و 5 دقائق)
      expect(formatPrayerRemainingTime(125, isArabic: true), 'ساعتين و 5 دقائق');

      // 122 min = 2 hours (ساعتين) and 2 min (ودقيقتين)
      expect(formatPrayerRemainingTime(122, isArabic: true), 'ساعتين ودقيقتين');
    });
  });

  group('formatPrayerRemainingTime - English', () {
    test('minutes <= 0 returns less than a min', () {
      expect(formatPrayerRemainingTime(0, isArabic: false), 'less than a min');
    });

    test('under 60 minutes returns X min', () {
      expect(formatPrayerRemainingTime(1, isArabic: false), '1 min');
      expect(formatPrayerRemainingTime(25, isArabic: false), '25 min');
    });

    test('exact hours', () {
      expect(formatPrayerRemainingTime(60, isArabic: false), '1 hour');
      expect(formatPrayerRemainingTime(120, isArabic: false), '2 hours');
      expect(formatPrayerRemainingTime(360, isArabic: false), '6 hours');
    });

    test('hours and minutes', () {
      expect(formatPrayerRemainingTime(394, isArabic: false), '6h 34m');
      expect(formatPrayerRemainingTime(65, isArabic: false), '1h 5m');
    });
  });

  group('formatPrayerRemainingTimeCompact', () {
    test('Arabic compact', () {
      expect(formatPrayerRemainingTimeCompact(0, isArabic: true), '< 1 د');
      expect(formatPrayerRemainingTimeCompact(25, isArabic: true), '25 د');
      expect(formatPrayerRemainingTimeCompact(60, isArabic: true), '1 س');
      expect(formatPrayerRemainingTimeCompact(394, isArabic: true), '6 س 34 د');
    });

    test('English compact', () {
      expect(formatPrayerRemainingTimeCompact(0, isArabic: false), '< 1m');
      expect(formatPrayerRemainingTimeCompact(25, isArabic: false), '25 min');
      expect(formatPrayerRemainingTimeCompact(60, isArabic: false), '1h');
      expect(formatPrayerRemainingTimeCompact(394, isArabic: false), '6h 34m');
    });
  });
}
