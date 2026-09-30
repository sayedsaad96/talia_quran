import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../domain/entities/azkar_entities.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../../domain/services/azkar_dedupe.dart';
import '../datasources/azkar_alias_registry.dart';
import '../datasources/azkar_local_datasource.dart';

class AzkarRepositoryImpl implements AzkarRepository {
  AzkarRepositoryImpl(this._datasource, {AzkarAliasRegistry? aliasRegistry})
    : _aliasRegistry = aliasRegistry;
  final AzkarLocalDatasource _datasource;
  final AzkarAliasRegistry? _aliasRegistry;

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async {
    try {
      final models = await _datasource.getAzkar(category);
      final deduped = AzkarDedupe.apply(models);
      _aliasRegistry?.record(deduped.aliases);
      return Right(deduped.items);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, Map<AzkarCategory, List<Zikr>>>> getAllAzkar() async {
    final results = <AzkarCategory, List<Zikr>>{};
    for (final category in AzkarCategory.values) {
      final result = await getAzkar(category);
      var list = const <Zikr>[];
      var failed = false;
      result.fold(
        (_) => failed = true,
        (items) => list = items,
      );
      if (failed) return const Left(CacheFailure('Failed to load azkar corpus'));
      results[category] = list;
    }
    return Right(results);
  }
}
