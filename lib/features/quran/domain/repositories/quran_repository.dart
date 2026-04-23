import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../entities/quran_entities.dart';

abstract class QuranRepository {
  Future<Either<Failure, List<Surah>>> getSurahs();
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId);
  Future<Either<Failure, List<Surah>>> searchSurahs(String query);
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber);
}
