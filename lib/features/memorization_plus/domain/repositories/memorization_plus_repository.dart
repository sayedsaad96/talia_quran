import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../entities/memorization_entities.dart';

abstract class MemorizationPlusRepository {
  // ─── Identity profile ──────────────────────────────────────────────────────
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile();
  Future<Either<Failure, MemorizationProfile>> selectMemorizationPath(
    MemorizationPath path,
  );
  Future<Either<Failure, MemorizationProfile>> continueWithoutGuardian();
  Future<Either<Failure, PairingSession>> createGuardianPairingSession();
  Future<Either<Failure, MemorizationProfile>> acceptGuardianPairingCode(
    String codeOrQrData,
  );
  Future<Either<Failure, PairingSession?>> refreshPairingSession();
  Future<Either<Failure, MemorizationProfile>> unlinkGuardian();
  Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(
    bool value,
  );
  Future<Either<Failure, MemorizationProfile>> refreshChildGuardianLink();
  Future<Either<Failure, MemorizationProfile>> resetMemorizationIdentity();
  Future<Either<Failure, SmartMemorizationSettings>> getSmartSettings();
  Future<Either<Failure, void>> saveSmartSettings(
    SmartMemorizationSettings settings,
  );

  // ─── Track selection ────────────────────────────────────────────────────────
  Either<Failure, MemorizationTrack?> getSelectedTrack();
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

  // ─── Kids progress ──────────────────────────────────────────────────────────
  Future<Either<Failure, KidsProgress>> getKidsProgress();
  Future<Either<Failure, void>> saveKidsProgress(KidsProgress progress);
  Future<Either<Failure, List<KidsJourneyStage>>> getKidsJourney({
    required int surahId,
  });
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs();
  Future<Either<Failure, KidsSessionLog>> saveKidsSessionLog({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
    required int pointsEarned,
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
  Future<Either<Failure, String>> createChildLinkToken();
  Future<Either<Failure, void>> acceptChildLinkToken(String token);
  Future<Either<Failure, void>> syncKidsProgressToCloud();
  Future<Either<Failure, List<RemoteChildSummary>>> getRemoteChildren();
  Future<Either<Failure, List<ParentReward>>> saveRemoteParentReward({
    required String childUserId,
    required String title,
  });
  Future<Either<Failure, KidsCompletionResult>> awardKidsPoints({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
  });

  // ─── Custom memorization plan ──────────────────────────────────────────────
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan();
  Future<Either<Failure, void>> saveCustomPlan(CustomMemorizationPlan plan);
  Future<Either<Failure, void>> deleteCustomPlan();

  // ─── Parent mode toggle ───────────────────────────────────────────────────
  Either<Failure, bool> getIsParentMode();
  Future<Either<Failure, void>> setIsParentMode(bool value);

  // ─── Phase 7: Production sync (Parent Mode completion) ────────────────────
  /// Full reconciliation push of all local production data (V2 SRS review
  /// records + cached daily plan) to the cloud. Idempotent — safe to call
  /// repeatedly (e.g. on login and app resume) as the self-healing mechanism
  /// for anything a best-effort push missed while offline.
  Future<Either<Failure, void>> resyncProductionDataToCloud();

  /// Pulls production review rows (+ daily plan when newer) from cloud and
  /// merges into local Isar using GREATEST / latest-timestamp rules.
  /// No-op when [CloudSyncFeatureFlags.productionPullKey] is false.
  Future<Either<Failure, void>> pullProductionDataFromCloud();

  /// Best-effort push of newly-earned certificates to the cloud mirror.
  Future<Either<Failure, void>> pushCertificatesToCloud(
    List<CertificateAward> certificates,
  );

  /// Revokes the guardian ↔ child link with [counterpartUserId] server-side.
  /// Callable by either side of the link (child unlinking a guardian, or a
  /// guardian removing a child).
  Future<Either<Failure, void>> revokeGuardianLink(String counterpartUserId);

  /// Parent-initiated removal of a linked child.
  Future<Either<Failure, void>> removeChild(String childUserId);
}
