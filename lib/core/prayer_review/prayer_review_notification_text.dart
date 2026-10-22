import '../../features/prayer_companion/domain/entities/prayer_companion.dart';
import '../../features/prayer_review/domain/entities/prayer_review_selection.dart';
import '../constants/surah_names.dart';
import '../l10n/app_localizations.dart';
import '../utils/locale_number_formatter.dart';
import 'prayer_review_offer_service.dart';

String prayerReviewReference(
  PrayerReviewSelection selected,
  AppLocalizations l10n,
) {
  final locale = l10n.localeName;
  return l10n.prayerReviewPassage(
    locale.startsWith('ar')
        ? SurahNames.nameAr(selected.surahId)
        : SurahNames.nameEn(selected.surahId),
    LocaleNumberFormatter.number(selected.startAyah, locale),
    LocaleNumberFormatter.number(selected.endAyah, locale),
  );
}

final class PrayerReviewNotificationText {
  const PrayerReviewNotificationText(this._offers);
  final PrayerReviewOfferService _offers;

  Future<String?> forOccurrence(
    PrayerOccurrence occurrence,
    AppLocalizations l10n,
  ) async {
    final offer = await _offers.forOccurrence(occurrence);
    if (offer == null) return null;
    offer.authority.check();
    return l10n.prayerReviewSuggestion(
      prayerReviewReference(offer.selection, l10n),
    );
  }
}
