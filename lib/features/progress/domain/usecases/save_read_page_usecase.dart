import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../repositories/progress_repository.dart';

class SaveReadPageUsecase {
  SaveReadPageUsecase(this._repository);
  final ProgressRepository _repository;

  Future<Either<Failure, void>> call(int pageNumber) async {
    return await _repository.saveReadPage(pageNumber);
  }
}
