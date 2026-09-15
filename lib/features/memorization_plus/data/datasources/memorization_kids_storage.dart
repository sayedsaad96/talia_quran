part of 'memorization_plus_local_datasource.dart';

/// Kids progress, session logs and parent-dashboard storage.
mixin MemorizationKidsStorageMixin on MemorizationLocalStorageMixin {
  static const _kidsLegacyClaimedBy = 'mem_plus_kids_legacy_claimed_by';
  static const _lastSignedInUserId = 'auth_last_signed_in_user_id';

  String _kidsOwnerKey(String base, String ownerId) => '$base|$ownerId';

  String? _readKidsValue(String base, String ownerId) {
    final scoped = _prefs.getString(_kidsOwnerKey(base, ownerId));
    if (scoped != null) return scoped;
    if (ownerId == ReviewRecordIdentity.localOwnerId) {
      return _prefs.getString(base);
    }
    return null;
  }

  Future<void> _claimLegacyKidsDataIfAuthorized(String ownerId) async {
    if (ownerId == ReviewRecordIdentity.localOwnerId) return;
    final claimedBy = _prefs.getString(_kidsLegacyClaimedBy);
    final lastSignedIn = _prefs.getString(_lastSignedInUserId);
    if (claimedBy != ownerId &&
        !(claimedBy == null && lastSignedIn == ownerId)) {
      return;
    }
    final legacyKeys = [
      MemorizationPlusLocalDatasourceImpl._kKidsProgress,
      MemorizationPlusLocalDatasourceImpl._kKidsLegacyCloudFloor,
      MemorizationPlusLocalDatasourceImpl._kKidsSessionLogs,
      MemorizationPlusLocalDatasourceImpl._kParentSettings,
      MemorizationPlusLocalDatasourceImpl._kParentRewards,
    ];
    for (final base in legacyKeys) {
      final scopedKey = _kidsOwnerKey(base, ownerId);
      final legacy = _prefs.getString(base);
      if (_prefs.getString(scopedKey) == null && legacy != null) {
        _ensureStorageOwner(ownerId);
        await _setStringOrThrow(scopedKey, legacy);
        _ensureStorageOwner(ownerId);
      }
    }
    _ensureStorageOwner(ownerId);
    await _setStringOrThrow(_kidsLegacyClaimedBy, ownerId);
    _ensureStorageOwner(ownerId);
  }

  void _ensureStorageOwner(String ownerId) {
    if (_owner.currentOwnerId != ownerId) {
      throw StateError('Kids storage owner changed during operation');
    }
  }

  Future<KidsProgressModel> getKidsProgress() async {
    final ownerId = _owner.currentOwnerId;
    await _claimLegacyKidsDataIfAuthorized(ownerId);
    _ensureStorageOwner(ownerId);
    final raw = _readKidsValue(
      MemorizationPlusLocalDatasourceImpl._kKidsProgress,
      ownerId,
    );
    if (raw == null) return const KidsProgressModel.empty();
    return _tryParse(raw, KidsProgressModel.fromJson) ??
        const KidsProgressModel.empty();
  }

  Future<void> saveKidsProgress(KidsProgressModel progress) {
    final ownerId = _owner.currentOwnerId;
    return _setStringOrThrow(
      _kidsOwnerKey(
        MemorizationPlusLocalDatasourceImpl._kKidsProgress,
        ownerId,
      ),
      jsonEncode(progress.toJson()),
    );
  }

  Future<KidsProgressModel> getKidsLegacyCloudFloor() async {
    final ownerId = _owner.currentOwnerId;
    await _claimLegacyKidsDataIfAuthorized(ownerId);
    _ensureStorageOwner(ownerId);
    final raw = _readKidsValue(
      MemorizationPlusLocalDatasourceImpl._kKidsLegacyCloudFloor,
      ownerId,
    );
    if (raw == null) return const KidsProgressModel.empty();
    return _tryParse(raw, KidsProgressModel.fromJson) ??
        const KidsProgressModel.empty();
  }

  Future<void> saveKidsLegacyCloudFloor(KidsProgressModel progress) {
    final ownerId = _owner.currentOwnerId;
    return _setStringOrThrow(
      _kidsOwnerKey(
        MemorizationPlusLocalDatasourceImpl._kKidsLegacyCloudFloor,
        ownerId,
      ),
      jsonEncode(progress.toJson()),
    );
  }

  Future<List<KidsSessionLogModel>> getKidsSessionLogs() async {
    final ownerId = _owner.currentOwnerId;
    await _claimLegacyKidsDataIfAuthorized(ownerId);
    _ensureStorageOwner(ownerId);
    return _getKidsSessionLogsForOwner(ownerId);
  }

  List<KidsSessionLogModel> _getKidsSessionLogsForOwner(String ownerId) {
    final raw = _readKidsValue(
      MemorizationPlusLocalDatasourceImpl._kKidsSessionLogs,
      ownerId,
    );
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(KidsSessionLogModel.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveKidsSessionLog(KidsSessionLogModel log) async {
    final ownerId = _owner.currentOwnerId;
    await _claimLegacyKidsDataIfAuthorized(ownerId);
    _ensureStorageOwner(ownerId);
    final logs = _getKidsSessionLogsForOwner(ownerId);
    final next = [...logs.where((item) => item.id != log.id), log]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    await _saveKidsSessionLogsForOwner(next, ownerId);
    _ensureStorageOwner(ownerId);
  }

  Future<void> saveKidsSessionLogs(List<KidsSessionLogModel> logs) {
    final ownerId = _owner.currentOwnerId;
    return _saveKidsSessionLogsForOwner(logs, ownerId);
  }

  Future<void> _saveKidsSessionLogsForOwner(
    List<KidsSessionLogModel> logs,
    String ownerId,
  ) => _setStringOrThrow(
    _kidsOwnerKey(
      MemorizationPlusLocalDatasourceImpl._kKidsSessionLogs,
      ownerId,
    ),
    jsonEncode(logs.map((log) => log.toJson()).toList()),
  );

  Future<void> markKidsSessionLogsCloudSynced(Iterable<String> localIds) async {
    final acceptedIds = localIds.toSet();
    if (acceptedIds.isEmpty) return;
    final ownerId = _owner.currentOwnerId;
    await _claimLegacyKidsDataIfAuthorized(ownerId);
    _ensureStorageOwner(ownerId);
    final current = _getKidsSessionLogsForOwner(ownerId);
    final now = DateTime.now().toUtc();
    final updated = current
        .map(
          (log) => acceptedIds.contains(log.id) && !log.isSynced
              ? KidsSessionLogModel.fromEntity(log.copyWith(syncedAt: now))
              : log,
        )
        .toList();
    await _saveKidsSessionLogsForOwner(updated, ownerId);
    _ensureStorageOwner(ownerId);
  }

  Future<ParentSettingsModel> getParentSettings() async {
    final ownerId = _owner.currentOwnerId;
    await _claimLegacyKidsDataIfAuthorized(ownerId);
    _ensureStorageOwner(ownerId);
    final raw = _readKidsValue(
      MemorizationPlusLocalDatasourceImpl._kParentSettings,
      ownerId,
    );
    if (raw == null) return const ParentSettingsModel.defaults();
    return _tryParse(raw, ParentSettingsModel.fromJson) ??
        const ParentSettingsModel.defaults();
  }

  Future<void> saveParentSettings(ParentSettingsModel settings) {
    final ownerId = _owner.currentOwnerId;
    return _setStringOrThrow(
      _kidsOwnerKey(
        MemorizationPlusLocalDatasourceImpl._kParentSettings,
        ownerId,
      ),
      jsonEncode(settings.toJson()),
    );
  }

  Future<List<ParentRewardModel>> getParentRewards() async {
    final ownerId = _owner.currentOwnerId;
    await _claimLegacyKidsDataIfAuthorized(ownerId);
    _ensureStorageOwner(ownerId);
    final raw = _readKidsValue(
      MemorizationPlusLocalDatasourceImpl._kParentRewards,
      ownerId,
    );
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ParentRewardModel.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveParentRewards(List<ParentRewardModel> rewards) {
    final ownerId = _owner.currentOwnerId;
    return _setStringOrThrow(
      _kidsOwnerKey(
        MemorizationPlusLocalDatasourceImpl._kParentRewards,
        ownerId,
      ),
      jsonEncode(rewards.map((reward) => reward.toJson()).toList()),
    );
  }
}
