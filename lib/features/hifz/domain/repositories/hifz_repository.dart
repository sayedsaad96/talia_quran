import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../entities/hifz_entities.dart';

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
