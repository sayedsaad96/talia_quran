part of 'memorization_plus_repository_impl.dart';

mixin _MemorizationIdentityReads on _MemorizationPlusRepositoryCore {
  // ─── Identity profile ──────────────────────────────────────────────────────
  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() =>
      _profile.getMemorizationProfile();

  @override
  Future<Either<Failure, MemorizationProfile>> selectMemorizationPath(
    MemorizationPath path,
  ) async {
    if (path != MemorizationPath.child) {
      final failure = await _releaseGuardianLink();
      if (failure != null) return Left(failure);
    }
    return _profile.selectMemorizationPath(path);
  }

  /// Leaving the kids path must not leave a link on the server that this
  /// device no longer knows about.
  Future<Failure?> _releaseGuardianLink() async {
    try {
      final profile = await _profileStore.loadProfile();
      final result = await _parentAccess.revokeOwnGuardianLink(profile);
      return result.fold<Failure?>(
        (_) => const NetworkFailure(
          CubitMessageCodes.guardianUnlinkBeforePathChangeFailed,
        ),
        (_) => null,
      );
    } catch (e) {
      return CacheFailure.from(e);
    }
  }

  @override
  Future<Either<Failure, MemorizationProfile>> configureChildAge(int age) =>
      _profile.configureChildAge(age);

  @override
  Future<Either<Failure, MemorizationProfile>> continueWithoutGuardian() =>
      _profile.continueWithoutGuardian();

  @override
  Future<Either<Failure, MemorizationProfile>> reopenGuardianLinking() =>
      _profile.reopenGuardianLinking();

  @override
  Future<Either<Failure, PairingSession>> createGuardianPairingSession() =>
      _parentAccess.createGuardianPairingSession();

  @override
  Future<Either<Failure, PairingSession?>> refreshPairingSession() =>
      _parentAccess.refreshPairingSession();

  @override
  Future<Either<Failure, MemorizationProfile>> unlinkGuardian() =>
      _parentAccess.unlinkGuardian();

  // ─── Forgotten PIN ─────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, PinRecoveryChallenge>> requestPinRecovery() =>
      _pinRecovery.requestPinRecovery();

  @override
  Future<Either<Failure, bool>> completePinRecovery({
    required String challengeId,
    required String code,
    required String newPin,
  }) => _pinRecovery.completePinRecovery(
    challengeId: challengeId,
    code: code,
    newPin: newPin,
  );

  @override
  Future<Either<Failure, List<PinRecoveryChallenge>>> pendingPinRecoveries(
    String childUserId,
  ) => _pinRecovery.pendingPinRecoveries(childUserId);

  @override
  Future<Either<Failure, String>> approvePinRecovery(String challengeId) =>
      _pinRecovery.approvePinRecovery(challengeId);

  @override
  Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(
    bool value,
  ) => _parentAccess.setParentGuardianMode(value);

  @override
  Future<Either<Failure, MemorizationProfile>> refreshChildGuardianLink() =>
      _parentAccess.refreshChildGuardianLink();

  @override
  Future<Either<Failure, MemorizationProfile>>
  resetMemorizationIdentity() async {
    final failure = await _releaseGuardianLink();
    if (failure != null) return Left(failure);
    return _profile.resetMemorizationIdentity();
  }

  @override
  Future<Either<Failure, SmartMemorizationSettings>> getSmartSettings() =>
      _profile.getSmartSettings();

  @override
  Future<Either<Failure, void>> saveSmartSettings(
    SmartMemorizationSettings settings,
  ) => _profile.saveSmartSettings(settings);

  // ─── Track ──────────────────────────────────────────────────────────────────
  @override
  Either<Failure, MemorizationTrack?> getSelectedTrack() =>
      _profile.getSelectedTrack();

  @override
  Future<Either<Failure, void>> saveSelectedTrack(MemorizationTrack track) =>
      _profile.saveSelectedTrack(track);

  // ─── Daily plan ─────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, DailyPlan>> generateDailyPlan({
    required int surahId,
    required int newAyahsPerDay,
  }) => _dailyPlan.generateDailyPlan(
    surahId: surahId,
    newAyahsPerDay: newAyahsPerDay,
  );

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() =>
      _dailyPlan.getCachedDailyPlan();

  @override
  Future<Either<Failure, void>> saveDailyPlan(DailyPlan plan) =>
      _saveProductionMutation(_dailyPlan.saveDailyPlan(plan));

  @override
  Future<SyncConflict<DailyPlan>?> getDailyPlanConflict() =>
      _productionSync.getDailyPlanConflict();

  @override
  Future<Either<Failure, void>> resolveDailyPlanConflict(
    SyncConflictResolution resolution,
  ) => _resolveProductionConflict(
    _productionSync.resolveDailyPlanConflict(resolution),
  );

  @override
  Future<Either<Failure, bool>> markDailyPlanAyahCompleted({
    required int surahId,
    required int ayahNumber,
  }) => _dailyPlan.markDailyPlanAyahCompleted(
    surahId: surahId,
    ayahNumber: ayahNumber,
  );
}
