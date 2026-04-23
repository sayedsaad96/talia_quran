import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../entities/azkar_entities.dart';

abstract class AzkarRepository {
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category);
}
