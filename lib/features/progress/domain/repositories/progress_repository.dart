import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../entities/progress_entities.dart';

abstract class ProgressRepository {
  Future<Either<Failure, OverallProgress>> getOverallProgress();
  Future<Either<Failure, void>> updateStreak();
  Future<Either<Failure, void>> saveReadPage(int pageNumber);
}
