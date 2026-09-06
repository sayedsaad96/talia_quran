/// A Quran location selected for the Home daily-ayah card.
///
/// It deliberately contains no Quran text. The text is always read from the
/// app's governed [QuranRepository] corpus when the reference is resolved.
class DailyAyahReference {
  const DailyAyahReference({required this.surahId, required this.ayahNumber});

  final int surahId;
  final int ayahNumber;
}
