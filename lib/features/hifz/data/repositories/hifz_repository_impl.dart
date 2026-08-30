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
    int surahId,
  ) async {
    try {
      final models = await _datasource.getProgressForSurah(surahId);
      return Right(models);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, AyahProgress?>> getAyahProgress(
    int surahId,
    int ayahNumber,
  ) async {
    try {
      final model = await _datasource.getAyahProgress(surahId, ayahNumber);
      return Right(model);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, void>> saveAyahProgress(AyahProgress progress) async {
    // IS-5: production writes retired with HifzPage. Migration/read APIs stay
    // for upgrades; new progress belongs in Memorization Plus review records.
    return const Left(
      CacheFailure(
        'Hifz write API retired; use Memorization Plus',
      ),
    );
  }

  @override
  Future<Either<Failure, List<AyahProgress>>> getDueReviews() async {
    try {
      final all = await _datasource.getAllProgress();
      final due = all
          .where(
            (p) =>
                // BUG-5 FIX: allow memorized ayahs to appear in due reviews
                // so long-term retention is maintained after the 5th repetition
                p.status != AyahStatus.notStarted && p.isDue,
          )
          .toList();
      return Right(due);
    } catch (e) {
      return Left(CacheFailure.from(e));
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
          reviewCount: ayahs.where((a) => a.status == AyahStatus.review).length,
          learningCount: ayahs
              .where((a) => a.status == AyahStatus.learning)
              .length,
        );
      }).toList();

      return Right(result);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  @override
  Either<Failure, String?> getHifzPath() {
    try {
      final path = _datasource.getHifzPath();
      return Right(path);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, void>> saveHifzPath(String path) async {
    // IS-5: path selection lives on MemorizationProfile / PracticeSurah flow.
    return const Left(
      CacheFailure(
        'Hifz write API retired; use Memorization Plus',
      ),
    );
  }
}
