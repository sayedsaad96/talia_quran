import '../../../../core/error/app_failure.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import 'daily_ayah_reference.dart';
import 'daily_ayah_result.dart';

/// Resolves a deterministic daily Quran reference through the trusted local
/// Quran repository. It never owns, transforms, or falls back to copied text.
class DailyAyahResolver {
  DailyAyahResolver(this._quranRepository);

  final QuranRepository _quranRepository;

  static const List<DailyAyahReference> references = [
    DailyAyahReference(surahId: 1, ayahNumber: 5),
    DailyAyahReference(surahId: 2, ayahNumber: 286),
    DailyAyahReference(surahId: 2, ayahNumber: 152),
    DailyAyahReference(surahId: 2, ayahNumber: 153),
    DailyAyahReference(surahId: 2, ayahNumber: 186),
    DailyAyahReference(surahId: 2, ayahNumber: 201),
    DailyAyahReference(surahId: 3, ayahNumber: 8),
    DailyAyahReference(surahId: 3, ayahNumber: 26),
    DailyAyahReference(surahId: 3, ayahNumber: 139),
    DailyAyahReference(surahId: 9, ayahNumber: 51),
    DailyAyahReference(surahId: 10, ayahNumber: 57),
    DailyAyahReference(surahId: 12, ayahNumber: 87),
    DailyAyahReference(surahId: 13, ayahNumber: 28),
    DailyAyahReference(surahId: 14, ayahNumber: 7),
    DailyAyahReference(surahId: 16, ayahNumber: 97),
    DailyAyahReference(surahId: 17, ayahNumber: 82),
    DailyAyahReference(surahId: 18, ayahNumber: 10),
    DailyAyahReference(surahId: 20, ayahNumber: 114),
    DailyAyahReference(surahId: 21, ayahNumber: 87),
    DailyAyahReference(surahId: 24, ayahNumber: 35),
    DailyAyahReference(surahId: 25, ayahNumber: 74),
    DailyAyahReference(surahId: 29, ayahNumber: 69),
    DailyAyahReference(surahId: 39, ayahNumber: 53),
    DailyAyahReference(surahId: 39, ayahNumber: 10),
    DailyAyahReference(surahId: 41, ayahNumber: 30),
    DailyAyahReference(surahId: 48, ayahNumber: 4),
    DailyAyahReference(surahId: 57, ayahNumber: 20),
    DailyAyahReference(surahId: 65, ayahNumber: 3),
    DailyAyahReference(surahId: 94, ayahNumber: 5),
    DailyAyahReference(surahId: 94, ayahNumber: 6),
  ];

  DailyAyahReference referenceFor(DateTime localDate) {
    final normalizedDate = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
    );
    final index =
        normalizedDate.difference(DateTime.utc(2024)).inDays %
        references.length;
    return references[index];
  }

  Future<DailyAyahResult> resolveFor(DateTime localDate) async {
    final reference = referenceFor(localDate);
    final result = await _quranRepository.getSurahDetail(reference.surahId);

    return result.fold(
      (failure) => DailyAyahUnavailable(reference: reference, failure: failure),
      (detail) {
        final ayah = detail.ayahs
            .where((item) => item.numberInSurah == reference.ayahNumber)
            .firstOrNull;
        if (ayah == null) {
          return DailyAyahUnavailable(
            reference: reference,
            failure: const NotFoundFailure(),
          );
        }
        return DailyAyahResolved(
          reference: reference,
          surah: detail.surah,
          ayah: ayah,
        );
      },
    );
  }
}
