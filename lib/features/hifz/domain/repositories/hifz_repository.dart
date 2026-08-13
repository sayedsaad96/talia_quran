import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../entities/hifz_entities.dart';

/// Legacy Hifz repository kept for migration reads (IS-5).
///
/// Write methods are retired in the implementation — new progress must go
/// through Memorization Plus. Datasource-level APIs remain only for tests and
/// historical Isar rows until the migration path is fully removed.
abstract class HifzRepository {
  Future<Either<Failure, List<AyahProgress>>> getProgressForSurah(int surahId);
  Future<Either<Failure, AyahProgress?>> getAyahProgress(
    int surahId,
    int ayahNumber,
  );
  Future<Either<Failure, void>> saveAyahProgress(AyahProgress progress);
  Future<Either<Failure, List<AyahProgress>>> getDueReviews();
  Future<Either<Failure, List<SurahHifzProgress>>> getAllSurahProgress();
  Either<Failure, String?> getHifzPath();
  Future<Either<Failure, void>> saveHifzPath(String path);
}
