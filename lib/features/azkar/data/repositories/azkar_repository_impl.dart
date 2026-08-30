import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../domain/entities/azkar_entities.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../datasources/azkar_local_datasource.dart';

class AzkarRepositoryImpl implements AzkarRepository {
  AzkarRepositoryImpl(this._datasource);
  final AzkarLocalDatasource _datasource;

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async {
    try {
      final models = await _datasource.getAzkar(category);
      return Right(models);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }
}
