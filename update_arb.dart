import 'dart:convert';
import 'dart:io';

void main() {
  final keysEn = {
    'learningAlertReduceNewTitle': 'Reduce New Memorization',
    'learningAlertReduceNewSubtitle': 'Your workload is heavy, focus on review',
    'learningAlertFocusWeakTitle': 'Focus on Weak Ayahs',
    'learningAlertFocusWeakSubtitle': 'You have difficult ayahs to review',
    'learningAlertGenericTitle': 'Learning Alert',
    'learningAlertGenericSubtitle': 'Action required',
    'reviewBacklogTitle': 'Review Backlog',
    'reviewBacklogSubtitle': 'You have {overdue} overdue ayahs',
    '@reviewBacklogSubtitle': {
      'placeholders': {
        'overdue': {'type': 'String'}
      }
    },
    'smartPlanCustomTitle': 'Custom Plan',
    'smartPlanReviewTitle': 'Review Plan',
    'smartPlanTodayTitle': 'Today''s Plan',
    'smartPlanSubtitle': 'Continue your memorization journey',
    'dailyWirdTitle': 'Daily Wird',
    'dailyWirdSubtitle': 'Read your daily portion',
    'exploreAzkarTitle': 'Time for Dhikr',
    'exploreAzkarSubtitle': 'Start your daily Azkar',
    'exploreMissionTitle': 'Current Mission',
    'exploreMissionSubtitle': 'Start your current mission',
    'exploreQuranTitle': 'Quran',
    'exploreQuranSubtitle': 'Read the Quran',
    'parentDashboardLinkHint': 'talia-kids-link:...'
  };

  final keysAr = {
    'learningAlertReduceNewTitle': 'تقليل الحفظ الجديد',
    'learningAlertReduceNewSubtitle': 'حِملك الدراسي ثقيل، ركز على المراجعة',
    'learningAlertFocusWeakTitle': 'ركز على الآيات الصعبة',
    'learningAlertFocusWeakSubtitle': 'لديك آيات صعبة تحتاج مراجعة مكثفة',
    'learningAlertGenericTitle': 'تنبيه تعليمي',
    'learningAlertGenericSubtitle': 'مطلوب اتخاذ إجراء',
    'reviewBacklogTitle': 'تراكم المراجعة',
    'reviewBacklogSubtitle': 'لديك {overdue} آيات متأخرة',
    '@reviewBacklogSubtitle': {
      'placeholders': {
        'overdue': {'type': 'String'}
      }
    },
    'smartPlanCustomTitle': 'خطة مخصصة',
    'smartPlanReviewTitle': 'خطة المراجعة',
    'smartPlanTodayTitle': 'خطة اليوم',
    'smartPlanSubtitle': 'أكمل رحلة حفظك',
    'dailyWirdTitle': 'الورد اليومي',
    'dailyWirdSubtitle': 'اقرأ وردك اليومي',
    'exploreAzkarTitle': 'وقت الذكر',
    'exploreAzkarSubtitle': 'ابدأ أذكارك اليومية',
    'exploreMissionTitle': 'المهمة الحالية',
    'exploreMissionSubtitle': 'ابدأ مهمتك الحالية',
    'exploreQuranTitle': 'القرآن الكريم',
    'exploreQuranSubtitle': 'اقرأ القرآن',
    'parentDashboardLinkHint': 'talia-kids-link:...'
  };

  void updateFile(String path, Map<String, dynamic> newKeys) {
    final file = File(path);
    final str = file.readAsStringSync();
    final Map<String, dynamic> json = jsonDecode(str);
    json.addAll(newKeys);
    file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(json));
  }

  updateFile('lib/core/l10n/app_en.arb', keysEn);
  updateFile('lib/core/l10n/app_ar.arb', keysAr);
}
