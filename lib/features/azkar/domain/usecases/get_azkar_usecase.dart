import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/azkar_entities.dart';
import '../repositories/azkar_repository.dart';

class GetAzkarUsecase implements UseCase<List<Zikr>, AzkarCategory> {
  GetAzkarUsecase(this._repository);
  final AzkarRepository _repository;

  @override
  Future<Either<Failure, List<Zikr>>> call(AzkarCategory category) =>
      _repository.getAzkar(category);
}
