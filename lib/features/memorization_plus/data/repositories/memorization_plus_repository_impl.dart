import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/memorization/progress_metrics_service.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../../../core/services/streak_reader.dart';
import '../../../../core/sync/cloud_sync_queue.dart';
import '../../../../features/quran/domain/repositories/quran_repository.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../datasources/memorization_plus_local_datasource.dart';
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
import 'collaborators/memorization_profile_store.dart';

class MemorizationPlusRepositoryImpl implements MemorizationPlusRepository {
  MemorizationPlusRepositoryImpl(
    this._datasource,
    this._quranRepository,
    this._streakReader,
    this._progressEvents,
    this._prefs, [
    this._metrics = const ProgressMetricsService(),
    this._cloudSyncQueue,
  ]);

  late final MemorizationCloudGateway _gateway =
      MemorizationCloudGateway(_prefs);
  late final MemorizationCloudMappers _mappers =
      MemorizationCloudMappers(_metrics);
  late final MemorizationProfileStore _profileStore =
      MemorizationProfileStore(_datasource, _prefs);
  late final MemorizationProfileService _profile =
      MemorizationProfileService(_datasource, _profileStore);
  late final MemorizationParentAccessService _parentAccess =
      MemorizationParentAccessService(_datasource, _profileStore, _gateway);
  late final MemorizationKidsLocalService _kidsLocal =
      MemorizationKidsLocalService(
        _datasource,
        _quranRepository,
        _streakReader,
        _progressEvents,
        _cloudSyncQueue,
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
  late final MemorizationFamilyService _family = MemorizationFamilyService(
    _datasource,
    _profile,
    _kidsLocal,
    _kidsCloudSync,
  );
  late final MemorizationKidsCloudSyncService _kidsCloudSync =
      MemorizationKidsCloudSyncService(
        _datasource,
        _streakReader,
        _gateway,
        _mappers,
      );
  late final MemorizationProductionSyncService _productionSync =
      MemorizationProductionSyncService(
        _datasource,
        _prefs,
        _gateway,
        _mappers,
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

  // ─── Identity profile ──────────────────────────────────────────────────────
  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() =>
      _profile.getMemorizationProfile();

  @override
  Future<Either<Failure, MemorizationProfile>> selectMemorizationPath(
    MemorizationPath path,
  ) =>
      _profile.selectMemorizationPath(path);

  @override
  Future<Either<Failure, MemorizationProfile>> continueWithoutGuardian() =>
      _profile.continueWithoutGuardian();

  @override
  Future<Either<Failure, PairingSession>> createGuardianPairingSession() =>
      _parentAccess.createGuardianPairingSession();

  @override
  Future<Either<Failure, MemorizationProfile>> acceptGuardianPairingCode(
    String codeOrQrData,
  ) =>
      _parentAccess.acceptGuardianPairingCode(codeOrQrData);

  @override
  Future<Either<Failure, PairingSession?>> refreshPairingSession() =>
      _parentAccess.refreshPairingSession();

  @override
  Future<Either<Failure, MemorizationProfile>> unlinkGuardian() =>
      _parentAccess.unlinkGuardian();

  @override
  Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(
    bool value,
  ) =>
      _parentAccess.setParentGuardianMode(value);

  @override
  Future<Either<Failure, MemorizationProfile>>
  refreshChildGuardianLink() => _parentAccess.refreshChildGuardianLink();

  @override
  Future<Either<Failure, MemorizationProfile>>
  resetMemorizationIdentity() => _profile.resetMemorizationIdentity();

  @override
  Future<Either<Failure, SmartMemorizationSettings>> getSmartSettings() =>
      _profile.getSmartSettings();

  @override
  Future<Either<Failure, void>> saveSmartSettings(
    SmartMemorizationSettings settings,
  ) =>
      _profile.saveSmartSettings(settings);

  // ─── Track ──────────────────────────────────────────────────────────────────
  @override
  Either<Failure, MemorizationTrack?> getSelectedTrack() =>
      _profile.getSelectedTrack();

  @override
  Future<Either<Failure, void>> saveSelectedTrack(
    MemorizationTrack track,
  ) =>
      _profile.saveSelectedTrack(track);

  // ─── Daily plan ─────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, DailyPlan>> generateDailyPlan({
    required int surahId,
    required int newAyahsPerDay,
  }) =>
      _dailyPlan.generateDailyPlan(
        surahId: surahId,
        newAyahsPerDay: newAyahsPerDay,
      );

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() =>
      _dailyPlan.getCachedDailyPlan();

  @override
  Future<Either<Failure, void>> saveDailyPlan(DailyPlan plan) =>
      _dailyPlan.saveDailyPlan(plan);

  @override
  Future<Either<Failure, bool>> markDailyPlanAyahCompleted({
    required int surahId,
    required int ayahNumber,
  }) =>
      _dailyPlan.markDailyPlanAyahCompleted(
        surahId: surahId,
        ayahNumber: ayahNumber,
      );

  // ─── Review records ─────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, AyahReviewRecord?>> getReviewRecord(
    int surahId,
    int ayahNumber, {
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async {
    try {
      final record = await _datasource.getReviewRecord(
        surahId,
        ayahNumber,
        scope: scope,
      );
      return Right(record);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async {
    try {
      final records = await _datasource.getAllReviewRecords(scope: scope);
      return Right(records);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveReviewRecord(
    AyahReviewRecord record,
  ) async {
    try {
      await _datasource.saveReviewRecord(
        AyahReviewRecordModel.fromEntity(record),
      );
      // Delta sync: mark dirty locally; [resyncProductionDataToCloud] uploads.
      _progressEvents.notify(ProgressChangedReason.reviewRecord);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> claimLocalReviewRecords() async {
    try {
      return Right(await _datasource.claimLocalReviewRecords());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Kids progress ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, KidsProgress>> getKidsProgress() =>
      _kidsLocal.getKidsProgress();

  @override
  Future<Either<Failure, void>> saveKidsProgress(KidsProgress progress) =>
      _kidsLocal.saveKidsProgress(progress);

  @override
  Future<Either<Failure, List<KidsJourneyStage>>> getKidsJourney({
    required int surahId,
  }) =>
      _kidsLocal.getKidsJourney(surahId: surahId);

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() =>
      _kidsLocal.getKidsSessionLogs();

  @override
  Future<Either<Failure, KidsSessionLog>> saveKidsSessionLog({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
    required int pointsEarned,
  }) =>
      _kidsLocal.saveKidsSessionLog(
        surahId: surahId,
        ayahNumber: ayahNumber,
        repeatsCompleted: repeatsCompleted,
        pointsEarned: pointsEarned,
      );

  @override
  Future<Either<Failure, ParentDashboard>> getParentDashboard({
    required int surahId,
  }) =>
      _kidsLocal.getParentDashboard(surahId: surahId);

  @override
  Future<Either<Failure, ParentSettings>> getParentSettings() =>
      _kidsLocal.getParentSettings();

  @override
  Future<Either<Failure, void>> saveParentSettings(
    ParentSettings settings,
  ) =>
      _kidsLocal.saveParentSettings(settings);

  @override
  Future<Either<Failure, bool>> verifyParentPin(String pin) =>
      _kidsLocal.verifyParentPin(pin);

  @override
  Future<Either<Failure, void>> setParentPin(String pin) =>
      _kidsLocal.setParentPin(pin);

  @override
  Future<Either<Failure, void>> resetParentAccess() =>
      _kidsLocal.resetParentAccess();

  @override
  Future<Either<Failure, List<ParentReward>>> saveParentReward(
    String title,
  ) =>
      _kidsLocal.saveParentReward(title);

  @override
  Future<Either<Failure, List<ParentReward>>> claimParentReward(
    String id,
  ) =>
      _kidsLocal.claimParentReward(id);

  @override
  Future<Either<Failure, String>> createChildLinkToken() =>
      _parentAccess.createChildLinkToken();

  @override
  Future<Either<Failure, void>> acceptChildLinkToken(String token) =>
      _parentAccess.acceptChildLinkToken(token);

  @override
  Future<Either<Failure, void>> pullKidsProgressFromCloud() =>
      _kidsCloudSync.pullKidsProgressFromCloud();

  @override
  Future<Either<Failure, void>> syncKidsProgressToCloud() =>
      _kidsCloudSync.syncKidsProgressToCloud();

  @override
  Future<Either<Failure, List<RemoteChildSummary>>> getRemoteChildren() =>
      _kidsCloudSync.getRemoteChildren();

  @override
  Future<Either<Failure, List<ParentReward>>> saveRemoteParentReward({
    required String childUserId,
    required String title,
  }) =>
      _kidsCloudSync.saveRemoteParentReward(
        childUserId: childUserId,
        title: title,
      );

  @override
  Future<Either<Failure, KidsCompletionResult>> awardKidsPoints({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
  }) =>
      _kidsLocal.awardKidsPoints(
        surahId: surahId,
        ayahNumber: ayahNumber,
        repeatsCompleted: repeatsCompleted,
      );

  // ─── Custom memorization plan ──────────────────────────────────────────────

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() =>
      _customPlan.getCustomPlan();

  @override
  Future<Either<Failure, void>> saveCustomPlan(
    CustomMemorizationPlan plan,
  ) =>
      _customPlan.saveCustomPlan(plan);

  @override
  Future<Either<Failure, void>> deleteCustomPlan() =>
      _customPlan.deleteCustomPlan();

  // ─── Parent mode toggle ──────────────────────────────────────────────────
  // T015: Read through MemorizationProfile so the value is always the single
  // source of truth, not the raw legacy SharedPreferences flag.
  @override
  Either<Failure, bool> getIsParentMode() => _parentAccess.getIsParentMode();

  /// Async variant that reads the authoritative MemorizationProfile.
  /// Prefer this over [getIsParentMode] wherever async is acceptable.
  Future<Either<Failure, bool>> getIsParentModeFromProfile() =>
      _parentAccess.getIsParentModeFromProfile();

  @override
  Future<Either<Failure, void>> setIsParentMode(bool value) =>
      _parentAccess.setIsParentMode(value);

  // ─── Phase 7: Production sync (Parent Mode completion) ─────────────────────

  @override
  Future<Either<Failure, void>> pullProductionDataFromCloud() =>
      _productionSync.pullProductionDataFromCloud();

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
  ) =>
      _productionSync.pushCertificatesToCloud(certificates);

  @override
  Future<bool> hasPendingCloudWork() =>
      _productionSync.hasPendingCloudWork();

  @override
  Future<Either<Failure, void>> revokeGuardianLink(
    String counterpartUserId,
  ) =>
      _parentAccess.revokeGuardianLink(counterpartUserId);

  @override
  Future<Either<Failure, void>> removeChild(String childUserId) =>
      _parentAccess.removeChild(childUserId);

  @override
  Future<Either<Failure, FamilyDashboard>> getFamilyDashboard() =>
      _family.getFamilyDashboard();
}
