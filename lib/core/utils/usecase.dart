import 'package:dartz/dartz.dart';
import '../error/app_failure.dart';

abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

abstract class UseCaseNoParams<T> {
  Future<Either<Failure, T>> call();
}

class NoParams {
  const NoParams();
}
