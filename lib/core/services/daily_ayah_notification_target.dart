/// A compact route payload for a scheduled daily ayah notification.
///
/// It deliberately contains identifiers only. Quran text remains in the
/// verified on-device corpus and is read only after the user opens the app.
class DailyAyahNotificationTarget {
  const DailyAyahNotificationTarget({
    required this.surahId,
    required this.ayahNumber,
    required this.pageNumber,
  });

  final int surahId;
  final int ayahNumber;
  final int pageNumber;

  String get payload => '/quran/page/$pageNumber?dailyAyah=$surahId-$ayahNumber';
}

class DailyAyahReminder {
  const DailyAyahReminder({
    required this.title,
    required this.body,
    required this.target,
  });

  final String title;
  final String body;
  final DailyAyahNotificationTarget target;
}
