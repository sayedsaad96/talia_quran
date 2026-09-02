import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/sync/sync_result.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../entities/memorization_entities.dart';
import 'memorization_cloud_repository.dart';
import 'memorization_identity_repository.dart';

abstract class MemorizationPlusRepository
    implements MemorizationCloudRepository, MemorizationIdentityRepository {
  // ─── Identity profile ──────────────────────────────────────────────────────
  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile();
  @override
  Future<Either<Failure, MemorizationProfile>> selectMemorizationPath(
    MemorizationPath path,
  );
  @override
  Future<Either<Failure, MemorizationProfile>> configureChildAge(int age);
  @override
  Future<Either<Failure, MemorizationProfile>> continueWithoutGuardian();
  @override
  Future<Either<Failure, PairingSession>> createGuardianPairingSession();
  @override
  Future<Either<Failure, MemorizationProfile>> acceptGuardianPairingCode(
    String codeOrQrData,
  );
  @override
  Future<Either<Failure, PairingSession?>> refreshPairingSession();
  @override
  Future<Either<Failure, MemorizationProfile>> unlinkGuardian();
  @override
  Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(
    bool value,
  );
  @override
  Future<Either<Failure, MemorizationProfile>> refreshChildGuardianLink();
  @override
  Future<Either<Failure, MemorizationProfile>> resetMemorizationIdentity();
  @override
  Future<Either<Failure, SmartMemorizationSettings>> getSmartSettings();
  @override
  Future<Either<Failure, void>> saveSmartSettings(
    SmartMemorizationSettings settings,
  );

  // ─── Track selection ────────────────────────────────────────────────────────
  @override
  Either<Failure, MemorizationTrack?> getSelectedTrack();
  @override
  Future<Either<Failure, void>> saveSelectedTrack(MemorizationTrack track);

  // ─── Daily plan ─────────────────────────────────────────────────────────────
  /// Builds today's plan. [getCachedDailyPlan] calls this automatically when
  /// the cache is missing or from a previous UTC day.
  Future<Either<Failure, DailyPlan>> generateDailyPlan({
    required int surahId,
    required int newAyahsPerDay,
  });

  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan();
  Future<Either<Failure, void>> saveDailyPlan(DailyPlan plan);
  Future<SyncConflict<DailyPlan>?> getDailyPlanConflict();
  Future<Either<Failure, void>> resolveDailyPlanConflict(
    SyncConflictResolution resolution,
  );

  /// Marks [ayahNumber] complete in today's cached plan when it belongs to the
  /// plan workload. No-op (returns [Right] false) when plan missing or ayah
  /// not in plan.
  Future<Either<Failure, bool>> markDailyPlanAyahCompleted({
    required int surahId,
    required int ayahNumber,
  });

  // ─── Review records ─────────────────────────────────────────────────────────
  Future<Either<Failure, AyahReviewRecord?>> getReviewRecord(
    int surahId,
    int ayahNumber, {
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  });
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  });
  Future<Either<Failure, void>> saveReviewRecord(AyahReviewRecord record);

  /// Transfers guest (`local`) review records to the signed-in account once.
  Future<Either<Failure, int>> claimLocalReviewRecords();

  // ─── Kids progress ──────────────────────────────────────────────────────────
  Future<Either<Failure, KidsProgress>> getKidsProgress();
  Future<Either<Failure, void>> saveKidsProgress(KidsProgress progress);
  Future<Either<Failure, List<KidsJourneyStage>>> getKidsJourney({
    required int surahId,
  });
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs();
  Future<Either<Failure, KidsSessionLog>> saveKidsSessionLog({
    String? sessionId,
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
    required int pointsEarned,
    KidsMissionType missionType = KidsMissionType.newMemorization,
    List<int> ayahNumbers = const [],
    int durationSeconds = 0,
    int attemptCount = 1,
    int hintCount = 0,
    PerformanceRating masteryRating = PerformanceRating.excellent,
  });
  Future<Either<Failure, ParentDashboard>> getParentDashboard({
    required int surahId,
  });
  Future<Either<Failure, ParentSettings>> getParentSettings();
  Future<Either<Failure, void>> saveParentSettings(ParentSettings settings);
  Future<Either<Failure, bool>> verifyParentPin(String pin);
  Future<Either<Failure, void>> setParentPin(String pin);
  Future<Either<Failure, void>> resetParentAccess();
  Future<Either<Failure, List<ParentReward>>> saveParentReward(String title);
  Future<Either<Failure, List<ParentReward>>> claimParentReward(String id);
  @override
  Future<Either<Failure, String>> createChildLinkToken();
  @override
  Future<Either<Failure, void>> acceptChildLinkToken(String token);
  @override
  Future<Either<Failure, void>> pullKidsProgressFromCloud();
  @override
  Future<Either<Failure, void>> syncKidsProgressToCloud();

  /// True when kids progress/logs, review rows, daily plan, or certificates
  /// still need uploading (or a delta pull cursor is stale).
  @override
  Future<bool> hasPendingCloudWork();
  @override
  Future<Either<Failure, List<RemoteChildSummary>>> getRemoteChildren();
  @override
  Future<Either<Failure, List<ParentReward>>> saveRemoteParentReward({
    required String childUserId,
    required String title,
  });
  @override
  Future<Either<Failure, List<ParentReward>>> unlockRemoteParentReward(
    String rewardId,
  );
  Future<Either<Failure, KidsCompletionResult>> awardKidsPoints({
    String? sessionId,
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
    KidsMissionType missionType = KidsMissionType.newMemorization,
    List<int> ayahNumbers = const [],
    int durationSeconds = 0,
    int attemptCount = 1,
    int hintCount = 0,
    PerformanceRating masteryRating = PerformanceRating.excellent,
  });

  // ─── Custom memorization plan ──────────────────────────────────────────────
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan();
  Future<Either<Failure, void>> saveCustomPlan(CustomMemorizationPlan plan);
  Future<Either<Failure, void>> deleteCustomPlan();
  Future<SyncConflict<CustomMemorizationPlan>?> getCustomPlanConflict();
  Future<Either<Failure, void>> resolveCustomPlanConflict(
    SyncConflictResolution resolution,
  );

  // ─── Parent mode toggle ───────────────────────────────────────────────────
  @override
  Either<Failure, bool> getIsParentMode();
  @override
  Future<Either<Failure, void>> setIsParentMode(bool value);

  // ─── Phase 7: Production sync (Parent Mode completion) ────────────────────
  /// Full reconciliation push of all local production data (V2 SRS review
  /// records + cached daily plan) to the cloud. Idempotent — safe to call
  /// repeatedly (e.g. on login and app resume) as the self-healing mechanism
  /// for anything a best-effort push missed while offline.
  @override
  Future<Either<Failure, void>> resyncProductionDataToCloud();

  /// Pulls production review rows (+ daily plan when newer) from cloud and
  /// merges into local Isar using GREATEST / latest-timestamp rules.
  /// Pulls production SRS/plan from cloud when logged in.
  /// Opt out via [CloudSyncFeatureFlags.productionPullKey] = false in prefs.
  @override
  Future<Either<Failure, void>> pullProductionDataFromCloud();

  /// Pulls certificate awards for the signed-in user from the cloud mirror.
  @override
  Future<Either<Failure, List<CertificateAward>>> pullCertificatesFromCloud();

  /// Best-effort push of newly-earned certificates to the cloud mirror.
  @override
  Future<Either<Failure, void>> pushCertificatesToCloud(
    List<CertificateAward> certificates,
  );

  /// Revokes the guardian ↔ child link with [counterpartUserId] server-side.
  /// Callable by either side of the link (child unlinking a guardian, or a
  /// guardian removing a child).
  @override
  Future<Either<Failure, void>> revokeGuardianLink(String counterpartUserId);

  /// Parent-initiated removal of a linked child.
  @override
  Future<Either<Failure, void>> removeChild(String childUserId);

  /// Builds a unified FamilyDashboard with all linked children
  /// (local + remote) and parent settings.
  @override
  Future<Either<Failure, FamilyDashboard>> getFamilyDashboard();

  /// Pulls memorization identity (selected path, guardian status, etc.) from
  /// the cloud profiles row and applies it to local state using last-write-wins
  /// merge. Call this BEFORE production SRS/plans on login so routing sees
  /// the restored path.
  @override
  Future<Either<Failure, void>> pullIdentityFromCloud();

  /// Pushes the current memorization identity to the cloud when the dirty flag
  /// is set. Call after [selectMemorizationPath], [continueWithoutGuardian],
  /// or identity reset.
  @override
  Future<Either<Failure, void>> pushIdentityToCloud();
}
