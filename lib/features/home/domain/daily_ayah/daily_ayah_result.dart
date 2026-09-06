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
}

class DailyAyahUnavailable extends DailyAyahResult {
  const DailyAyahUnavailable({required super.reference, required this.failure});

  final Failure failure;
}
