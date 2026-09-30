import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations_ar.dart';
import 'package:talia_quran/core/l10n/app_localizations_en.dart';

/// N8: counted nouns used to be glued to a fixed plural ("7 الآيات",
/// "2 عنصر", "١٥١ يوم"). Arabic needs its own form per count, and the right
/// grammatical case for the sentence the count sits in.
void main() {
  final ar = AppLocalizationsAr();
  final en = AppLocalizationsEn();

  test('ayah counts take the Arabic singular, dual, few and many forms', () {
    expect(ar.countAyahs(1, '١'), 'آية واحدة');
    expect(ar.countAyahs(2, '٢'), 'آيتان');
    expect(ar.countAyahs(7, '٧'), '٧ آيات');
    expect(ar.countAyahs(11, '١١'), '١١ آية');
    expect(ar.countAyahs(286, '٢٨٦'), '٢٨٦ آية');
    expect(en.countAyahs(1, '1'), '1 ayah');
    expect(en.countAyahs(7, '7'), '7 ayahs');
  });

  test('day counts use the accusative tamyeez for 11–99', () {
    expect(ar.khatmahDays(151, '١٥١'), '١٥١ يومًا');
    expect(ar.khatmahDurationDays(30, '٣٠'), '٣٠ يومًا');
    expect(ar.khatmahDays(100, '١٠٠'), '١٠٠ يوم');
    expect(ar.khatmahDays(3, '٣'), '٣ أيام');
  });

  test('page counts', () {
    expect(ar.khatmahPages(2, '٢'), 'صفحتان');
    expect(ar.khatmahPages(4, '٤'), '٤ صفحات');
    expect(ar.khatmahPages(20, '٢٠'), '٢٠ صفحة');
    expect(ar.khatmahPaceBehind(2, '٢'), 'متأخر صفحتين عن موعد الختام');
  });

  test('the count follows the case of its sentence', () {
    expect(ar.homeActivityDaysAgo(2, '٢'), 'قبل يومين');
    expect(ar.homeActivityDaysAgo(1, '١'), 'قبل يوم');
    expect(ar.closingSummaryMemorization(2, '٢'), startsWith('حفظتَ آيتين '));
    expect(ar.dailyPlanRemainingItems(2, '٢'), 'تبقّى عنصران');
    expect(ar.dailyPlanHeaderSummary(2, '٢', '٠'), 'عنصران • ٠ مكتمل');
  });

  test('streak unit agrees with the number shown beside it', () {
    expect(ar.streakDaysUnit(0), 'يوم');
    expect(ar.streakDaysUnit(5), 'أيام');
    expect(ar.streakDaysUnit(15), 'يومًا');
    expect(en.streakDaysUnit(1), 'day');
    expect(en.streakDaysUnit(0), 'days');
  });
}
