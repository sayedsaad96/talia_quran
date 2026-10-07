part of 'memorization_plus_repository_impl.dart';

mixin _MemorizationFamilyReads on _MemorizationPlusRepositoryCore {
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
      return Left(CacheFailure.from(e));
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
      return Left(CacheFailure.from(e));
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
      await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.productionPush);
      // Delta sync: mark dirty locally; [resyncProductionDataToCloud] uploads.
      _progressEvents.notify(ProgressChangedReason.reviewRecord);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, int>> claimLocalReviewRecords() async {
    try {
      return Right(await _datasource.claimLocalReviewRecords());
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, int>> countClaimableLocalReviewRecords() async {
    try {
      return Right(await _datasource.countClaimableLocalReviewRecords());
    } catch (e) {
      return Left(CacheFailure.from(e));
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
  }) => _kidsLocal.getKidsJourney(surahId: surahId);

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() =>
      _kidsLocal.getKidsSessionLogs();

  @override
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
  }) => _kidsLocal.saveKidsSessionLog(
    sessionId: sessionId,
    surahId: surahId,
    ayahNumber: ayahNumber,
    repeatsCompleted: repeatsCompleted,
    pointsEarned: pointsEarned,
    missionType: missionType,
    ayahNumbers: ayahNumbers,
    durationSeconds: durationSeconds,
    attemptCount: attemptCount,
    hintCount: hintCount,
    masteryRating: masteryRating,
  );

  @override
  Future<Either<Failure, ParentDashboard>> getParentDashboard({
    required int surahId,
  }) => _kidsLocal.getParentDashboard(surahId: surahId);

  @override
  Future<Either<Failure, ParentSettings>> getParentSettings() =>
      _kidsLocal.getParentSettings();

  @override
  Future<Either<Failure, void>> saveParentSettings(
    ParentSettings settings,
  ) async {
    final previousNickname = (await _kidsLocal.getParentSettings()).fold(
      (_) => null,
      (previous) => previous.localChildNickname,
    );
    final localResult = await _kidsLocal.saveParentSettings(settings);
    final failure = localResult.fold((failure) => failure, (_) => null);
    if (failure != null) return Left(failure);

    try {
      // Only a real change on this device is published: resending an
      // unchanged name on every identity push could overwrite a correction
      // the guardian made in the meantime.
      if (settings.localChildNickname != null &&
          settings.localChildNickname != previousNickname) {
        await _prefs.setBool(
          _MemorizationPlusRepositoryCore._kChildNicknameDirty,
          true,
        );
      }
      const reminderKey = TaliaNotificationService.kidsReminderPreferenceKey;
      await Future.wait([
        _prefs.setBool(reminderKey, settings.reminderEnabled),
        _prefs.setInt('${reminderKey}_hour', settings.reminderHour),
        _prefs.setInt('${reminderKey}_minute', settings.reminderMinute),
        _prefs.setBool(
          KidsHifzFeatureFlags.enabledKey,
          settings.kidsHifzV2Enabled,
        ),
      ]);
      return const Right(null);
    } catch (error) {
      return Left(CacheFailure.from(error));
    }
  }

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
  Future<Either<Failure, List<ParentReward>>> saveParentReward(String title) =>
      _kidsLocal.saveParentReward(title);

  @override
  Future<Either<Failure, List<KidsHomeMission>>> getHomeMissions() =>
      _kidsLocal.getHomeMissions();

  @override
  Future<Either<Failure, List<KidsHomeMission>>> addLocalHomeMission(
    String title,
  ) => _kidsLocal.addLocalHomeMission(title);

  @override
  Future<Either<Failure, List<KidsHomeMission>>> reportHomeMission(String id) =>
      _kidsLocal.reportHomeMission(
        id,
        markPendingSync: _gateway.hasSignedInCloudUser,
      );

  @override
  Future<Either<Failure, List<KidsHomeMission>>> acknowledgeLocalHomeMission(
    String id,
  ) => _kidsLocal.acknowledgeLocalHomeMission(id);

  /// A child's "claim" is a receipt request the guardian still approves.
  @override
  Future<Either<Failure, List<ParentReward>>> claimParentReward(String id) =>
      requestParentReward(id);

  @override
  Future<Either<Failure, List<ParentReward>>> getDeviceRewards() =>
      _kidsLocal.getParentRewards();

  @override
  Future<Either<Failure, List<ParentReward>>> requestParentReward(String id) {
    if (_gateway.hasSignedInCloudUser) {
      return _kidsCloudSync.requestRemoteParentReward(id);
    }
    return _kidsLocal.requestParentReward(id);
  }

  @override
  Future<Either<Failure, List<ParentReward>>> unlockParentReward(
    String id, {
    String? childUserId,
  }) => childUserId == null
      ? _kidsLocal.unlockParentReward(id)
      : _kidsCloudSync.unlockRemoteParentReward(id);

  @override
  Future<Either<Failure, List<ParentReward>>> approveParentReward(
    String id, {
    String? childUserId,
  }) => childUserId == null
      ? _kidsLocal.approveParentReward(id)
      : _kidsCloudSync.approveRemoteParentReward(id);

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
  Future<Either<Failure, void>> pullKidsInboundFromCloud() async {
    // The link decides what the pull mirrors (gifts only while linked), so it
    // is read first. This also catches a guardian who scanned the code after
    // the child chose "later". A failed read leaves the profile unchanged.
    await _parentAccess.refreshChildGuardianLink();
    return _kidsCloudSync.pullKidsInboundFromCloud();
  }

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
  }) => _kidsCloudSync.saveRemoteParentReward(
    childUserId: childUserId,
    title: title,
  );

  @override
  Future<Either<Failure, List<ParentReward>>> unlockRemoteParentReward(
    String rewardId,
  ) => _kidsCloudSync.unlockRemoteParentReward(rewardId);

  @override
  Future<Either<Failure, List<KidsHomeMission>>> createRemoteHomeMission({
    required String childUserId,
    required String title,
  }) => _kidsCloudSync.createRemoteHomeMission(
    childUserId: childUserId,
    title: title,
  );

  @override
  Future<Either<Failure, List<KidsHomeMission>>> acknowledgeRemoteHomeMission(
    String missionId,
  ) => _kidsCloudSync.acknowledgeRemoteHomeMission(missionId);

  @override
  Future<Either<Failure, List<KidsHomeMission>>> getRemoteHomeMissions(
    String childUserId,
  ) => _kidsCloudSync.getRemoteHomeMissions(childUserId);

  @override
  Future<Either<Failure, KidsChildPolicy>> saveLocalChildPolicy(
    KidsChildPolicy policy,
  ) => _kidsCloudSync.saveLocalChildPolicy(policy);

  @override
  Future<Either<Failure, KidsChildPolicy>> saveRemoteChildPolicy({
    required String childUserId,
    required KidsChildPolicy policy,
  }) => _kidsCloudSync.saveRemoteChildPolicy(
    childUserId: childUserId,
    policy: policy,
  );

  @override
  Future<Either<Failure, KidsCompletionResult>> awardKidsPoints({
    bool completionAuthorized = false,
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
  }) => _kidsLocal.awardKidsPoints(
    completionAuthorized: completionAuthorized,
    sessionId: sessionId,
    surahId: surahId,
    ayahNumber: ayahNumber,
    repeatsCompleted: repeatsCompleted,
    missionType: missionType,
    ayahNumbers: ayahNumbers,
    durationSeconds: durationSeconds,
    attemptCount: attemptCount,
    hintCount: hintCount,
    masteryRating: masteryRating,
  );

  // ─── Custom memorization plan ──────────────────────────────────────────────

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() =>
      _customPlan.getCustomPlan();

  @override
  Future<Either<Failure, void>> saveCustomPlan(CustomMemorizationPlan plan) =>
      _saveProductionMutation(_customPlan.saveCustomPlan(plan));

  @override
  Future<Either<Failure, void>> deleteCustomPlan() =>
      _saveProductionMutation(_customPlan.deleteCustomPlan());

  @override
  Future<SyncConflict<CustomMemorizationPlan>?> getCustomPlanConflict() =>
      _productionSync.getCustomPlanConflict();

  @override
  Future<Either<Failure, void>> resolveCustomPlanConflict(
    SyncConflictResolution resolution,
  ) => _resolveProductionConflict(
    _productionSync.resolveCustomPlanConflict(resolution),
  );

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

  @override
  Future<Either<Failure, void>> pullReviewEvidenceFromCloud() =>
      _productionSync.pullReviewEvidenceFromCloud();

  @override
  bool get isReviewEvidenceTransportEnabled =>
      _productionSync.isReviewEvidenceTransportEnabled;

  @override
  Future<Either<Failure, void>> syncReviewEvidenceToCloud() =>
      _productionSync.syncReviewEvidenceToCloud();

  @override
  Future<Either<Failure, bool>> flushReviewEvidenceBeforeSignOut() =>
      _productionSync.flushReviewEvidenceBeforeSignOut();

  @override
  Future<bool> hasPendingReviewEvidence() =>
      _productionSync.hasPendingReviewEvidence();
}
