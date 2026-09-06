import '../../../../core/error/app_failure.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import 'daily_ayah_reference.dart';

sealed class DailyAyahResult {
  const DailyAyahResult({required this.reference});

  final DailyAyahReference reference;
}

class DailyAyahResolved extends DailyAyahResult {
  const DailyAyahResolved({
    required super.reference,
    required this.surah,
    required this.ayah,
  });

  final Surah surah;
  final Ayah ayah;

  /// Exact reader location. A missing page keeps the card non-navigable
  /// instead of guessing a Quran location.
  String? get readerLocation {
    final pageNumber = ayah.page;
    if (pageNumber == null) return null;
    return Uri(
      path: '/quran/page/$pageNumber',
      queryParameters: {
        'surahId': '${reference.surahId}',
        'ayahNumber': '${reference.ayahNumber}',
      },
    ).toString();
  }
}

class DailyAyahUnavailable extends DailyAyahResult {
  const DailyAyahUnavailable({required super.reference, required this.failure});

  final Failure failure;
}
