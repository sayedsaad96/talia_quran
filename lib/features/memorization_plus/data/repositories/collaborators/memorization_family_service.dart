import 'package:dartz/dartz.dart';
import '../../../../../core/error/app_failure.dart';
import '../../../domain/entities/memorization_entities.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import 'memorization_kids_cloud_sync_service.dart';
import 'memorization_kids_local_service.dart';
import 'memorization_profile_service.dart';

/// Family dashboard assembly: combines the local child (same device, when
/// configured as a parent-guardian device) with remote children from Supabase,
/// de-duplicating the local child when it also appears remotely.
class MemorizationFamilyService {
  MemorizationFamilyService(
    this._datasource,
    this._profile,
    this._kidsLocal,
    this._kidsCloudSync,
  );

  final MemorizationPlusLocalDatasource _datasource;
  final MemorizationProfileService _profile;
  final MemorizationKidsLocalService _kidsLocal;
  final MemorizationKidsCloudSyncService _kidsCloudSync;

  Future<Either<Failure, FamilyDashboard>> getFamilyDashboard() async {
    try {
      final settings = await _datasource.getParentSettings();
      final children = <FamilyChildEntry>[];

      // ─── 1. Local child (same device) ────────────────────────────────────
      // Only shown when this device is configured as a parent-guardian device.
      final profile = await _profile.loadProfile();
      if (profile.isParentGuardian) {
        final progressResult = await _kidsLocal.getKidsProgress();
        final progress = progressResult.getOrElse(
          () => const KidsProgress.initial(),
        );
        final logs = await _datasource.getKidsSessionLogs();
        final rewards = await _datasource.getParentRewards();
        final localChildId = profile.linkedChildId ?? 'local-child';
        final localDashboard = ParentDashboard(
          progress: progress,
          stages: const [],
          logs: logs,
          rewards: rewards,
          settings: settings,
        );
        children.add(
          FamilyChildEntry(
            childUserId: localChildId,
            displayName: settings.localChildNickname ?? 'طفلي',
            isLocal: true,
            localData: localDashboard,
          ),
        );
      }

      // ─── 2. Remote children (Supabase) ────────────────────────────────────
      final remoteResult = await _kidsCloudSync.getRemoteChildren();
      remoteResult.fold(
        (_) {}, // silently ignore remote errors; show local child if any
        (remoteChildren) {
          for (final r in remoteChildren) {
            // Avoid duplicate if remote child === local child
            final alreadyAdded =
                children.any((c) => c.childUserId == r.childUserId);
            if (!alreadyAdded) {
              children.add(
                FamilyChildEntry(
                  childUserId: r.childUserId,
                  displayName: r.displayName,
                  isLocal: false,
                  remoteSummary: r,
                ),
              );
            }
          }
        },
      );

      return Right(
        FamilyDashboard(children: children, settings: settings),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
