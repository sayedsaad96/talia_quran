import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/kids_home_mission.dart';
import '../repositories/memorization_plus_repository.dart';

/// The child's own view of the home missions on this device.
class KidsHomeMissionsUsecase {
  const KidsHomeMissionsUsecase(this._repository);

  final MemorizationPlusRepository _repository;

  /// What still needs the child or the guardian: new missions first (oldest
  /// first), then the ones reported and waiting to be seen.
  Future<Either<Failure, List<KidsHomeMission>>> open() async {
    final result = await _repository.getHomeMissions();
    return result.map(openMissions);
  }

  Future<Either<Failure, List<KidsHomeMission>>> report(String id) async {
    final result = await _repository.reportHomeMission(id);
    return result.map(openMissions);
  }

  static List<KidsHomeMission> openMissions(List<KidsHomeMission> all) {
    int byCreated(KidsHomeMission a, KidsHomeMission b) =>
        a.createdAt.compareTo(b.createdAt);
    return [
      ...all.where((m) => m.status == KidsHomeMissionStatus.assigned).toList()
        ..sort(byCreated),
      ...all.where((m) => m.status == KidsHomeMissionStatus.reported).toList()
        ..sort(byCreated),
    ];
  }
}
