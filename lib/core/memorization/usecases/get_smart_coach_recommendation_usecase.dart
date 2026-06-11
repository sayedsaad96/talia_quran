import 'package:dartz/dartz.dart';

import '../../error/app_failure.dart';
import '../../utils/usecase.dart';
import '../smart_coach_engine.dart';
import '../smart_coach_recommendation.dart';
import 'get_memorization_snapshot_usecase.dart';

class GetSmartCoachRecommendationUsecase
    implements UseCaseNoParams<SmartCoachRecommendation?> {
  const GetSmartCoachRecommendationUsecase(this._getSnapshot, this._engine);

  final GetMemorizationSnapshotUsecase _getSnapshot;
  final SmartCoachEngine _engine;

  @override
  Future<Either<Failure, SmartCoachRecommendation?>> call() async {
    final snapshotResult = await _getSnapshot();
    return snapshotResult.map(_engine.recommend);
  }
}
