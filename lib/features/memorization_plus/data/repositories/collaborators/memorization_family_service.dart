import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/error/app_failure.dart';
import '../../../../../core/identity/record_owner_provider.dart';
import '../../../../../core/l10n/cubit_message_codes.dart';
import '../../../domain/entities/kids_child_policy.dart';
import '../../../domain/entities/kids_home_mission.dart';
import '../../../domain/entities/memorization_entities.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import '../../datasources/remote_children_dashboard_cache.dart';
import 'memorization_cloud_mappers.dart';
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
    this._mappers, {
    RemoteChildrenDashboardCache? dashboardCache,
    RecordOwnerProvider owner = const SupabaseRecordOwnerProvider(),
  }) : _dashboardCache = dashboardCache,
       _owner = owner;

  final MemorizationPlusLocalDatasource _datasource;
  final MemorizationProfileService _profile;
  final MemorizationKidsLocalService _kidsLocal;
  final MemorizationKidsCloudSyncService _kidsCloudSync;
  final MemorizationCloudMappers _mappers;
  final RemoteChildrenDashboardCache? _dashboardCache;
  final RecordOwnerProvider _owner;

  Future<Either<Failure, FamilyDashboard>> getFamilyDashboard() =>
      watchFamilyDashboard().last;

  /// The local child and the linked children's summaries first, then one
  /// update per batch of missions/policy reads; the last event is complete.
  Stream<Either<Failure, FamilyDashboard>> watchFamilyDashboard() async* {
    final _DashboardBase base;
    try {
      base = await _readBase();
    } catch (e) {
      yield Left(CacheFailure.from(e));
      return;
    }
    final remote = base.remote;
    final remoteChildren = remote.children
        .where((r) => base.local?.childUserId != r.childUserId)
        .toList();
    if (remote.status != FamilyRemoteStatus.live) {
      // A saved copy has no missions or policy: both are flagged so the
      // guardian sees "unavailable" instead of empty lists or defaults.
      yield Right(
        base.build([
          for (final r in remoteChildren)
            r.copyWith(policyUnavailable: true, homeMissionsUnavailable: true),
        ]),
      );
      return;
    }
    final summaries = [
      for (final r in remoteChildren) r.copyWith(detailsLoading: true),
    ];
    yield Right(base.build(summaries));
    for (var i = 0; i < remoteChildren.length; i += maxParallelChildReads) {
      final end = math.min(i + maxParallelChildReads, remoteChildren.length);
      final filled = await Future.wait(
        remoteChildren.sublist(i, end).map(_withMissionsAndPolicy),
      );
      summaries.setRange(i, end, filled);
      yield Right(base.build(List.of(summaries)));
    }
  }

  Future<_DashboardBase> _readBase() async {
    final settings = await _datasource.getParentSettings();
    final profile = await _profile.loadProfile();
    // Shown on a parent-guardian device, and on the child's own device
    // (reached only through a guardian session).
    final local = profile.isParentGuardian || profile.isChild
        ? await _readLocalChild(profile, settings)
        : null;
    // A child account has no linked children of its own.
    final remote = profile.isChild
        ? const _RemoteRead([], FamilyRemoteStatus.notConnected)
        : await _readRemoteChildren();
    return _DashboardBase(settings, local, remote);
  }

  Future<FamilyChildEntry> _readLocalChild(
    MemorizationProfile profile,
    ParentSettings settings,
  ) async {
    final progressResult = await _kidsLocal.getKidsProgress();
    final progress = progressResult.getOrElse(
      () => const KidsProgress.initial(),
    );
    final logs = await _datasource.getKidsSessionLogs();
    final rewards = await _datasource.getParentRewards();
    final homeMissions = await _datasource.getHomeMissions();
    final latestLog = logs.isEmpty
        ? null
        : logs.reduce(
            (latest, log) =>
                log.completedAt.isAfter(latest.completedAt) ? log : latest,
          );
    final activeSurahId = latestLog?.surahId ?? settings.startingSurahId;
    final journeyResult = await _kidsLocal.getKidsJourney(
      surahId: activeSurahId,
    );
    final stages = journeyResult.getOrElse(() => const []);
    final localChildId =
        profile.linkedChildId ??
        (profile.isChild ? 'local-child' : null) ??
        () {
          assert(() {
            // In debug builds this surfaces as a visible warning rather than
            // a silent fallback that could confuse cloud-sync operations.
            debugPrint(
              '[MemorizationFamilyService] WARNING: parent-guardian device has '
              'no linkedChildId — using synthetic "local-child" id. '
              'Cloud sync will use this device-local identity only.',
            );
            return true;
          }());
          return 'local-child';
        }();
    final localDashboard = ParentDashboard(
      progress: progress,
      stages: stages,
      logs: logs,
      rewards: rewards,
      settings: settings,
      homeMissions: homeMissions,
    );
    return FamilyChildEntry(
      childUserId: localChildId,
      displayName: settings.localChildNickname?.trim() ?? '',
      isLocal: true,
      localData: localDashboard,
    );
  }

  Future<_RemoteRead> _readRemoteChildren() async {
    final result = await _kidsCloudSync.getRemoteChildren();
    return result.fold(_savedCopy, (children) {
      return _RemoteRead(children, FamilyRemoteStatus.live);
    });
  }

  _RemoteRead _savedCopy(Failure failure) {
    const notConnected = {
      CubitMessageCodes.guardianSignInRequired,
      CubitMessageCodes.guardianCloudUnavailable,
    };
    if (notConnected.contains(failure.message) || !_owner.isSignedIn) {
      return const _RemoteRead([], FamilyRemoteStatus.notConnected);
    }
    final cached = _dashboardCache?.read(_owner.currentOwnerId);
    if (cached == null) {
      return const _RemoteRead([], FamilyRemoteStatus.unavailable);
    }
    try {
      return _RemoteRead(
        _mappers.parseRemoteChildrenDashboard(cached.payload),
        FamilyRemoteStatus.cached,
        cached.fetchedAt,
      );
    } catch (_) {
      return const _RemoteRead([], FamilyRemoteStatus.unavailable);
    }
  }

  /// At most this many children are read at once, so a large family does not
  /// open dozens of requests together.
  static const maxParallelChildReads = 4;

  /// Never throws: a child whose reads fail is flagged, not left loading.
  Future<RemoteChildSummary> _withMissionsAndPolicy(
    RemoteChildSummary child,
  ) async {
    // Policy: no row → defaults at version 0; a failed read is flagged
    // so the guardian controls are hidden instead of showing defaults.
    final Either<Failure, List<KidsHomeMission>> missionsResult;
    final Either<Failure, KidsChildPolicy?> policyResult;
    try {
      (missionsResult, policyResult) = await (
        _kidsCloudSync.getRemoteHomeMissions(child.childUserId),
        _kidsCloudSync.getRemoteChildPolicy(child.childUserId),
      ).wait;
    } catch (_) {
      return child.copyWith(
        policyUnavailable: true,
        homeMissionsUnavailable: true,
        detailsLoading: false,
      );
    }
    final missions = missionsResult.getOrElse(() => const <KidsHomeMission>[]);
    final policy = policyResult.getOrElse(() => null);
    return child.copyWith(
      homeMissions: missions,
      policy: policy,
      policyUnavailable: policyResult.isLeft(),
      homeMissionsUnavailable: missionsResult.isLeft(),
      detailsLoading: false,
    );
  }
}

class _DashboardBase {
  const _DashboardBase(this.settings, this.local, this.remote);

  final ParentSettings settings;
  final FamilyChildEntry? local;
  final _RemoteRead remote;

  FamilyDashboard build(List<RemoteChildSummary> summaries) => FamilyDashboard(
    children: [
      ?local,
      for (final summary in summaries)
        FamilyChildEntry(
          childUserId: summary.childUserId,
          displayName: summary.displayName,
          isLocal: false,
          remoteSummary: summary,
          childAge: summary.childAge,
        ),
    ],
    settings: settings,
    remoteStatus: remote.status,
    remoteFetchedAt: remote.fetchedAt,
  );
}

class _RemoteRead {
  const _RemoteRead(this.children, this.status, [this.fetchedAt]);

  final List<RemoteChildSummary> children;
  final FamilyRemoteStatus status;
  final DateTime? fetchedAt;
}
