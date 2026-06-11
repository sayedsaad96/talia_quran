import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
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
  Future<Either<Failure, DailyPlan>> generateDailyPlan({
    required int surahId,
    required int newAyahsPerDay,
  });

  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan();
  Future<Either<Failure, void>> saveDailyPlan(DailyPlan plan);

  // ─── Review records ─────────────────────────────────────────────────────────
  Future<Either<Failure, AyahReviewRecord?>> getReviewRecord(
    int surahId,
    int ayahNumber,
  );
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords();
  Future<Either<Failure, void>> saveReviewRecord(AyahReviewRecord record);

  // ─── Evaluation ─────────────────────────────────────────────────────────────
  Future<Either<Failure, AyahReviewRecord>> evaluateAyah({
    required int surahId,
    required int ayahNumber,
    required PerformanceRating rating,
    ReviewRecordCreatedByMode createdByMode =
        ReviewRecordCreatedByMode.adultMemPlus,
  });
  Future<Either<Failure, AyahReviewRecord>> markAyahMemorized({
    required int surahId,
    required int ayahNumber,
    ReviewRecordCreatedByMode createdByMode =
        ReviewRecordCreatedByMode.kidsMode,
  });

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
}
