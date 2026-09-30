import '../entities/azkar_entities.dart';
import 'azkar_time_context.dart';

/// Decides which records of the general category join a composed wird. It only
/// selects existing records; the text is never touched. Everything left out
/// stays available in the general azkar page.
abstract class SmartWirdGeneralPolicy {
  /// Tied to a situation (toilet, rain, travel...), so wrong in a daily wird.
  static const situational = {
    'أذكار الخلاء',
    'أذكار المسجد',
    'أذكار المنزل',
    'أذكار الطعام',
    'أذكار الكرب',
    'أذكار المطر',
    'أذكار السفر',
    'عيادة المريض',
    'كفارة المجلس',
    'أذكار الريح',
    'ذكر الغضب',
    'أذكار اللباس',
    'الرقية الشرعية',
  };

  /// Relevant at any time of day.
  static const alwaysIncluded = {
    'أذكار منوعة',
    'أذكار بعد الصلاة',
    'أذكار الصباح والمساء',
  };

  static const sleep = 'أذكار النوم';
  static const waking = 'أذكار الاستيقاظ';

  static bool includes(Zikr zikr, AzkarPeriod period) {
    final sub = zikr.subcategory;
    if (situational.contains(sub)) return false;
    if (sub == sleep) return period == AzkarPeriod.evening;
    if (sub == waking) return period == AzkarPeriod.morning;
    return true;
  }
}
