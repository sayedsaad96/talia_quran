import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

void main() {
  group('MemorizationPlusRepositoryImpl', () {
    late MemorizationPlusLocalDatasourceImpl datasource;
    late MemorizationPlusRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      datasource = MemorizationPlusLocalDatasourceImpl(prefs);
      repository = MemorizationPlusRepositoryImpl(
        datasource,
        _UnusedQuranRepository(),
      );
    });

    test('markAyahMemorized stores a smart memorized review record', () async {
      final result = await repository.markAyahMemorized(
        surahId: 114,
        ayahNumber: 1,
      );

      final record = result.getOrElse(
        () => throw StateError('Expected markAyahMemorized to succeed'),
      );
      final persisted = await datasource.getReviewRecord(114, 1);

      expect(record.isMemorized, isTrue);
      expect(record.strengthLevel, greaterThanOrEqualTo(6));
      expect(persisted, isNotNull);
      expect(persisted!.isMemorized, isTrue);
    });
  });
}

class _UnusedQuranRepository implements QuranRepository {
  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) =>
      throw UnimplementedError();
}
