import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../domain/entities/hifz_entities.dart';
import '../../domain/repositories/hifz_repository.dart';
import '../../../quran/data/datasources/quran_local_datasource.dart';
import '../datasources/hifz_local_datasource.dart';
import '../models/ayah_progress_model.dart';

class HifzRepositoryImpl implements HifzRepository {
  HifzRepositoryImpl(this._datasource, this._quranDatasource);
  final HifzLocalDatasource _datasource;
  final QuranLocalDatasource _quranDatasource;

  @override
  Future<Either<Failure, List<AyahProgress>>> getProgressForSurah(
      int surahId) async {
    try {
      final models = await _datasource.getProgressForSurah(surahId);
      return Right(models);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AyahProgress?>> getAyahProgress(
      int surahId, int ayahNumber) async {
    try {
      final model = await _datasource.getAyahProgress(surahId, ayahNumber);
      return Right(model);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveAyahProgress(
      AyahProgress progress) async {
    try {
      final model = progress is AyahProgressModel
          ? progress
          : AyahProgressModel(
              surahId: progress.surahId,
              ayahNumber: progress.ayahNumber,
              status: progress.status,
              repetitions: progress.repetitions,
              nextReviewDate: progress.nextReviewDate,
              lastReviewDate: progress.lastReviewDate,
            );
      await _datasource.saveAyahProgress(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AyahProgress>>> getDueReviews() async {
    try {
      final all = await _datasource.getAllProgress();
      final due = all
          .where((p) =>
              p.status != AyahStatus.notStarted &&
              p.status != AyahStatus.memorized &&
              p.isDue)
          .toList();
      return Right(due);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SurahHifzProgress>>> getAllSurahProgress() async {
    try {
      final all = await _datasource.getAllProgress();
      final bySuprah = <int, List<AyahProgressModel>>{};
      for (final p in all) {
        bySuprah.putIfAbsent(p.surahId, () => []).add(p);
      }

      // Get actual surah ayah counts from Quran data
      final surahs = await _quranDatasource.getSurahs();
      final surahAyahCounts = <int, int>{};
      for (final s in surahs) {
        surahAyahCounts[s.id] = s.ayahCount;
      }

      // Build progress for each surah that has any progress
      final result = bySuprah.entries.map((e) {
        final ayahs = e.value;
        return SurahHifzProgress(
          surahId: e.key,
          totalAyahs: surahAyahCounts[e.key] ?? ayahs.length,
          memorizedCount: ayahs
              .where((a) => a.status == AyahStatus.memorized)
              .length,
          reviewCount: ayahs
              .where((a) => a.status == AyahStatus.review)
              .length,
          learningCount: ayahs
              .where((a) => a.status == AyahStatus.learning)
              .length,
        );
      }).toList();

      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Either<Failure, String?> getHifzPath() {
    try {
      final path = _datasource.getHifzPath();
      return Right(path);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveHifzPath(String path) async {
    try {
      await _datasource.saveHifzPath(path);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
