import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../../../../core/error/app_failure.dart';
import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/memorization/progress_metrics_service.dart';
import '../../../../core/memorization/kids_hifz_feature_flags.dart';
import '../../../../core/memorization/kids_progress_cloud_merge.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../../../core/security/parent_pin_secure_store.dart';
import '../../../../core/sync/sync_result.dart';
import '../../../../core/services/streak_reader.dart';
import '../../../../core/sync/cloud_sync_queue.dart';
import '../../../../features/quran/domain/repositories/quran_repository.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../../domain/entities/kids_child_policy.dart';
import '../../domain/entities/kids_home_mission.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/kids_inbound_repository.dart';
import '../../domain/repositories/memorization_cloud_repository.dart';
import '../../domain/repositories/memorization_identity_repository.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../domain/repositories/family_dashboard_stream_repository.dart';
import '../../domain/repositories/parent_pin_recovery_repository.dart';
import '../../domain/repositories/parent_reward_repository.dart';
import '../datasources/install_device_id.dart';
import '../datasources/memorization_plus_local_datasource.dart';
import '../datasources/remote_children_dashboard_cache.dart';
import '../models/memorization_models.dart';
import 'collaborators/memorization_cloud_gateway.dart';
import 'collaborators/memorization_cloud_mappers.dart';
import 'collaborators/memorization_custom_plan_service.dart';
import 'collaborators/memorization_daily_plan_service.dart';
import 'collaborators/memorization_family_service.dart';
import 'collaborators/memorization_kids_cloud_sync_service.dart';
import 'collaborators/memorization_kids_local_service.dart';
import 'collaborators/memorization_parent_access_service.dart';
import 'collaborators/memorization_production_sync_service.dart';
import 'collaborators/memorization_profile_service.dart';
import 'collaborators/family_activity_publisher.dart';
import 'collaborators/memorization_profile_store.dart';
import 'collaborators/parent_pin_recovery_service.dart';
import 'collaborators/review_evidence_sync_service.dart';
import '../datasources/review_evidence_local_datasource.dart';

part 'memorization_plus_repository_identity.dart';
part 'memorization_plus_repository_family.dart';

class MemorizationPlusRepositoryImpl extends _MemorizationPlusRepositoryCore
    with _MemorizationIdentityReads, _MemorizationFamilyReads
    implements
        MemorizationPlusRepository,
        MemorizationIdentityRepository,
        MemorizationCloudRepository,
        KidsInboundRepository,
        ParentRewardRepository,
        ParentPinRecoveryRepository,
        FamilyDashboardStreamRepository {
  MemorizationPlusRepositoryImpl(
    super._datasource,
    super._quranRepository,
    super._streakReader,
    super._progressEvents,
    super._prefs, {
    super.metrics,
    super.cloudSyncQueue,
    super.parentPinStore,
    super.isar,
    super.owner,
    super.onKidsPolicyChanged,
    super.familyActivityInputs,
  });
}

abstract class _MemorizationPlusRepositoryCore
    implements
        MemorizationPlusRepository,
        MemorizationIdentityRepository,
        MemorizationCloudRepository,
        KidsInboundRepository,
        ParentRewardRepository,
        ParentPinRecoveryRepository,
        FamilyDashboardStreamRepository {
  _MemorizationPlusRepositoryCore(
    this._datasource,
    this._quranRepository,
    this._streakReader,
    this._progressEvents,
    this._prefs, {
    ProgressMetricsService metrics = const ProgressMetricsService(),
    CloudSyncQueue? cloudSyncQueue,
    ParentPinSecureStore? parentPinStore,
    Isar? isar,
    RecordOwnerProvider owner = const SupabaseRecordOwnerProvider(),
    void Function()? onKidsPolicyChanged,
    FamilyActivityInputsLoader? familyActivityInputs,
  }) : _metrics = metrics,
       _onKidsPolicyChanged = onKidsPolicyChanged,
       _familyActivityInputs = familyActivityInputs,
       _cloudSyncQueue = cloudSyncQueue,
       _parentPinStore = parentPinStore,
       _isar = isar,
       _owner = owner;

  final ParentPinSecureStore? _parentPinStore;

  /// Runs after any local kids-policy write (DI reloads the controller).
  final void Function()? _onKidsPolicyChanged;

  final FamilyActivityInputsLoader? _familyActivityInputs;

  late final MemorizationCloudGateway _gateway = MemorizationCloudGateway(
    _prefs,
  );
  late final MemorizationCloudMappers _mappers = MemorizationCloudMappers(
    _metrics,
  );
  late final MemorizationProfileStore _profileStore = MemorizationProfileStore(
    _datasource,
    _prefs,
  );
  late final MemorizationProfileService _profile = MemorizationProfileService(
    _datasource,
    _profileStore,
    _prefs,
  );
  late final MemorizationParentAccessService _parentAccess =
      MemorizationParentAccessService(_datasource, _profileStore, _gateway);
  late final MemorizationKidsLocalService _kidsLocal =
      MemorizationKidsLocalService(
        _datasource,
        _quranRepository,
        _streakReader,
        _progressEvents,
        _cloudSyncQueue,
        parentPinStore: _parentPinStore,
        owner: _owner,
      );
  late final MemorizationDailyPlanService _dailyPlan =
      MemorizationDailyPlanService(
        _datasource,
        _quranRepository,
        _prefs,
        _progressEvents,
      );
  late final MemorizationCustomPlanService _customPlan =
      MemorizationCustomPlanService(_datasource, _prefs);
  late final ParentPinRecoveryService _pinRecovery = ParentPinRecoveryService(
    rpc: () {
      if (!_gateway.isSupabaseReady) {
        return const Left(
          NetworkFailure(CubitMessageCodes.guardianCloudUnavailable),
        );
      }
      final client = _gateway.supabase;
      if (client.auth.currentUser == null) {
        return const Left(
          NetworkFailure(CubitMessageCodes.guardianSignInRequired),
        );
      }
      return Right((function, params) => client.rpc(function, params: params));
    },
    deviceId: () => InstallDeviceId.read(_prefs),
    setPin: (pin) => _kidsLocal.setParentPin(pin),
  );
  late final RemoteChildrenDashboardCache _dashboardCache =
      RemoteChildrenDashboardCache(_prefs);
  late final MemorizationFamilyService _family = MemorizationFamilyService(
    _datasource,
    _profile,
    _kidsLocal,
    _kidsCloudSync,
    _mappers,
    dashboardCache: _dashboardCache,
    owner: _owner,
  );
  late final MemorizationKidsCloudSyncService _kidsCloudSync =
      MemorizationKidsCloudSyncService(
        _datasource,
        _streakReader,
        _gateway,
        _mappers,
        owner: _owner,
        onKidsPolicyChanged: _onKidsPolicyChanged,
        activityPublisher: switch (_familyActivityInputs) {
          final loader? => FamilyActivityPublisher(_prefs, _owner, loader),
          null => null,
        },
        dashboardCache: _dashboardCache,
      );
  late final MemorizationProductionSyncService _productionSync =
      MemorizationProductionSyncService(
        _datasource,
        _prefs,
        _gateway,
        _mappers,
        owner: _owner,
        evidenceSync: _isar == null
            ? null
            : ReviewEvidenceSyncService(
                local: ReviewEvidenceLocalDatasource(_isar),
                owner: _owner,
                prefs: _prefs,
                transport: SupabaseReviewEvidenceTransport(_gateway),
              ),
      );

  final MemorizationPlusLocalDatasource _datasource;

  /// For surah ayah counts
  final QuranRepository _quranRepository;

  /// Authoritative streak source — [KidsProgress.currentStreak] is hydrated
  /// from here at read time (not stored in SharedPreferences).
  final StreakReader _streakReader;

  final ProgressEventsBus _progressEvents;
  final SharedPreferences _prefs;
  final ProgressMetricsService _metrics;
  final CloudSyncQueue? _cloudSyncQueue;
  final Isar? _isar;
  final RecordOwnerProvider _owner;

  bool isReviewPullCursorStale() => _productionSync.isReviewPullCursorStale();

  @override
  Future<Either<Failure, void>> resyncProductionDataToCloud() =>
      _productionSync.resyncProductionDataToCloud();

  @override
  Future<Either<Failure, List<CertificateAward>>> pullCertificatesFromCloud() =>
      _productionSync.pullCertificatesFromCloud();

  @override
  Future<Either<Failure, void>> pushCertificatesToCloud(
    List<CertificateAward> certificates,
  ) => _productionSync.pushCertificatesToCloud(certificates);

  @override
  Future<bool> hasPendingCloudWork() async {
    final kidsLogs = await _datasource.getKidsSessionLogs();
    if (kidsLogs.any(
      (log) =>
          !log.isSynced && KidsSessionLogsCloudMerge.isCanonicalRewardLog(log),
    )) {
      return true;
    }
    // An offline home-mission report with a server id must be flushed before
    // sign-out, or AccountDataReset deletes it. Pending policy edits are NOT
    // counted: they would block sign-out for non-child accounts.
    final missions = await _datasource.getHomeMissions();
    if (missions.any(
      (m) => m.pendingReportSync && int.tryParse(m.id) != null,
    )) {
      return true;
    }
    return _productionSync.hasPendingCloudWork();
  }

  @override
  Future<Either<Failure, void>> revokeGuardianLink(String counterpartUserId) =>
      _parentAccess.revokeGuardianLink(counterpartUserId);

  @override
  Future<Either<Failure, void>> removeChild(String childUserId) =>
      _parentAccess.removeChild(childUserId);

  @override
  Future<Either<Failure, void>> updateLinkedChildIdentity({
    required String childUserId,
    required String nickname,
    required int age,
  }) => _kidsCloudSync.updateLinkedChildIdentity(
    childUserId: childUserId,
    nickname: nickname,
    age: age,
  );

  @override
  Future<Either<Failure, FamilyDashboard>> getFamilyDashboard() =>
      _family.getFamilyDashboard();

  @override
  Stream<Either<Failure, FamilyDashboard>> watchFamilyDashboard() =>
      _family.watchFamilyDashboard();

  // --- Identity Cloud Sync --------------------------------------------------

  static const _kIdentityDirty = MemorizationProfileService.kIdentityCloudDirty;

  /// Set when the child's name changes on this device; cleared once
  /// `set_own_child_nickname` accepted it.
  static const _kChildNicknameDirty = 'mem_plus_child_nickname_cloud_dirty';

  static const _identityColumns =
      'selected_path, guardian_onboarding_status, is_parent_guardian, age, '
      'updated_at';

  @override
  Future<Either<Failure, void>> pullIdentityFromCloud() async {
    try {
      if (!_gateway.isSupabaseReady) return const Right(null);
      final uid = _gateway.supabase.auth.currentUser?.id;
      if (uid == null) return const Right(null);

      Map<String, dynamic>? row;
      try {
        row = await _gateway.supabase
            .from('profiles')
            .select('$_identityColumns, child_nickname')
            .eq('id', uid)
            .maybeSingle();
      } on PostgrestException catch (e) {
        // 42703 undefined_column: a server without the child-identity
        // migration still syncs the rest of the identity.
        if (e.code != '42703') rethrow;
        row = await _gateway.supabase
            .from('profiles')
            .select(_identityColumns)
            .eq('id', uid)
            .maybeSingle();
      }

      if (row == null) return const Right(null);
      final rawPath = row['selected_path'] as String?;
      if (rawPath == null) return const Right(null);

      final cloudPath = rawPath == 'adult'
          ? MemorizationPath.adult
          : MemorizationPath.child;
      final cloudOnboarding = _parseGuardianOnboarding(
        row['guardian_onboarding_status'] as String?,
      );
      final isParentGuardian = (row['is_parent_guardian'] as bool?) ?? false;
      final childAge = row['age'] as int?;
      final cloudUpdatedAt = row['updated_at'] == null
          ? null
          : DateTime.tryParse(row['updated_at'] as String);

      final current = await _profileStore.loadProfile();
      final cloudIsNewer =
          cloudUpdatedAt != null && cloudUpdatedAt.isAfter(current.updatedAt);
      final resetPending =
          !current.hasSelectedPath && _prefs.getBool(_kIdentityDirty) == true;
      if (resetPending) return const Right(null);

      if (!current.hasSelectedPath || cloudIsNewer) {
        await _profileStore.saveProfile(
          current.copyWith(
            selectedPath: cloudPath,
            guardianOnboardingStatus: cloudOnboarding,
            isParentGuardian: isParentGuardian,
            childAge: childAge,
          ),
        );
        if (cloudPath == MemorizationPath.child) {
          await _applyCloudChildNickname(row['child_nickname'] as String?);
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to pull memorization identity: $e'));
    }
  }

  /// Takes the guardian's (or another device's) name for this child. Written
  /// straight to storage so it is not mistaken for a local edit to publish.
  Future<void> _applyCloudChildNickname(String? raw) async {
    final nickname = ChildIdentityPolicy.normalizeNickname(raw);
    if (nickname == null) return;
    final settings = await _datasource.getParentSettings();
    if (settings.localChildNickname == nickname) return;
    await _datasource.saveParentSettings(
      ParentSettingsModel.fromEntity(
        settings.copyWith(localChildNickname: nickname),
      ),
    );
  }

  /// Publishes a name changed on this child device. An older server without
  /// `set_own_child_nickname` keeps the flag so the name goes up later.
  Future<void> _pushChildNickname(MemorizationProfile profile) async {
    if (_prefs.getBool(_kChildNicknameDirty) != true) return;
    if (!profile.isChild) {
      await _prefs.remove(_kChildNicknameDirty);
      return;
    }
    final settings = await _datasource.getParentSettings();
    final nickname = ChildIdentityPolicy.normalizeNickname(
      settings.localChildNickname,
    );
    if (nickname == null) {
      await _prefs.remove(_kChildNicknameDirty);
      return;
    }
    try {
      await _gateway.supabase.rpc(
        'set_own_child_nickname',
        params: {'p_nickname': nickname},
      );
      await _prefs.remove(_kChildNicknameDirty);
    } on PostgrestException catch (e) {
      if (!_gateway.isMissingRpc(e, 'set_own_child_nickname')) rethrow;
    }
  }

  @override
  Future<Either<Failure, void>> pushIdentityToCloud() async {
    try {
      if (!_gateway.isSupabaseReady) return const Right(null);
      if (_gateway.supabase.auth.currentUser == null) return const Right(null);
      final identityDirty = _prefs.getBool(_kIdentityDirty) == true;
      final nicknameDirty = _prefs.getBool(_kChildNicknameDirty) == true;
      if (!identityDirty && !nicknameDirty) return const Right(null);

      final profile = await _profileStore.loadProfile();
      if (!profile.hasSelectedPath) return const Right(null);
      if (!identityDirty) {
        await _pushChildNickname(profile);
        return const Right(null);
      }

      await _gateway.supabase.rpc(
        'upsert_memorization_identity',
        params: {
          'p_selected_path': profile.selectedPath?.name,
          'p_guardian_onboarding_status': profile.guardianOnboardingStatus.name,
          'p_is_parent_guardian': profile.isParentGuardian,
          'p_child_age': profile.childAge,
          'p_updated_at': profile.updatedAt.toIso8601String(),
        },
      );

      await _prefs.remove(_kIdentityDirty);
      // After the identity so the server already knows this is a child.
      await _pushChildNickname(profile);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to push memorization identity: $e'));
    }
  }

  GuardianOnboardingStatus _parseGuardianOnboarding(String? raw) {
    switch (raw) {
      case 'required':
        return GuardianOnboardingStatus.required;
      case 'skipped':
        return GuardianOnboardingStatus.skipped;
      case 'completed':
      default:
        return GuardianOnboardingStatus.completed;
    }
  }

  Future<Either<Failure, void>> _saveProductionMutation(
    Future<Either<Failure, void>> operation,
  ) async {
    final result = await operation;
    if (result.isRight()) {
      await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.productionPush);
    }
    return result;
  }

  Future<Either<Failure, void>> _resolveProductionConflict(
    Future<Either<Failure, void>> operation,
  ) async {
    final result = await operation;
    if (result.isRight()) {
      await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.productionPush);
    }
    return result;
  }
}
