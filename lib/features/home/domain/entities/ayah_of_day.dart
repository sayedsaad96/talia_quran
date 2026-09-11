import 'package:equatable/equatable.dart';

enum DailyAyahContext {
  general('general'),
  friday('friday'),
  ramadanStart('ramadanStart'),
  ramadan('ramadan'),
  lastTenNights('lastTenNights'),
  dhulHijjah('dhulHijjah'),
  arafah('arafah'),
  eidAlAdha('eidAlAdha'),
  reading('reading'),
  memorization('memorization'),
  smartReview('smartReview'),
  azkar('azkar'),
  childJourney('childJourney');

  const DailyAyahContext(this.wireName);

  final String wireName;

  static DailyAyahContext? fromWireName(String value) {
    for (final context in values) {
      if (context.wireName == value) return context;
    }
    return null;
  }
}

class AyahOfDay extends Equatable {
  const AyahOfDay({
    required this.surahId,
    required this.ayahNumber,
    required this.text,
    required this.surahNameAr,
    required this.surahNameEn,
    required this.pageNumber,
    this.context = DailyAyahContext.general,
  });

  final int surahId;
  final int ayahNumber;
  final String text;
  final String surahNameAr;
  final String surahNameEn;
  final int pageNumber;
  final DailyAyahContext context;

  @override
  List<Object?> get props => [surahId, ayahNumber, text, pageNumber, context];
}

class DailyAyahRef {
  const DailyAyahRef({
    required this.surahId,
    required this.ayahNumber,
    this.contexts = const <DailyAyahContext>{},
  });

  final int surahId;
  final int ayahNumber;
  final Set<DailyAyahContext> contexts;
}
