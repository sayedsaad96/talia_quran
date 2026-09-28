import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../entities/azkar_entities.dart';

abstract class AzkarRepository {
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category);

  /// All approved records across every category in a single pass — used by the
  /// smart-wird composer and hub counters. Keys without approved records yield
  /// empty lists rather than failures.
  Future<Either<Failure, Map<AzkarCategory, List<Zikr>>>> getAllAzkar();
}
