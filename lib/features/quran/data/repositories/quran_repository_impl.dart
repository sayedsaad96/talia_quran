import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_local_datasource.dart';

class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl(this._datasource);
  final QuranLocalDatasource _datasource;

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() async {
    try {
      final models = await _datasource.getSurahs();
      return Right(models);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async {
    try {
      final surahs = await _datasource.getSurahs();
      final surah = surahs.firstWhere(
        (s) => s.id == surahId,
        orElse: () => throw const NotFoundFailure('Surah not found'),
      );
      final ayahs = await _datasource.getAyahs(surahId);
      return Right(SurahDetail(surah: surah, ayahs: ayahs));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) async {
    try {
      final surahs = await _datasource.getSurahs();
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return Right(surahs);
      final filtered = surahs.where((s) {
        return s.nameAr.contains(q) ||
            s.nameEn.toLowerCase().contains(q) ||
            s.id.toString() == q;
      }).toList();
      return Right(filtered);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) async {
    try {
      final surahs = await _datasource.getSurahs();
      final ayahs = await _datasource.getAyahsByPage(pageNumber);
      
      // Determine which Surahs are present on this page
      final surahIds = ayahs.map((a) => a.surahId).toSet();
      final pageSurahs = surahs.where((s) => surahIds.contains(s.id)).toList();
      
      return Right(QuranPageDetail(
        pageNumber: pageNumber,
        ayahs: ayahs,
        surahs: pageSurahs,
      ));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
