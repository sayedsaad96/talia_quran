import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/progress_entities.dart';
import '../repositories/progress_repository.dart';

class GetProgressUsecase implements UseCaseNoParams<OverallProgress> {
  GetProgressUsecase(this._repository);
  final ProgressRepository _repository;

  @override
  Future<Either<Failure, OverallProgress>> call() =>
      _repository.getOverallProgress();
}
