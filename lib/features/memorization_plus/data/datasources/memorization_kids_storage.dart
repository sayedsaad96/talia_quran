part of 'memorization_plus_local_datasource.dart';

/// Kids progress, session logs and parent-dashboard storage.
mixin MemorizationKidsStorageMixin on MemorizationLocalStorageMixin {
  static const _kidsLegacyClaimedBy = 'mem_plus_kids_legacy_claimed_by';
  static const _lastSignedInUserId = 'auth_last_signed_in_user_id';

  /// Serializes kids session-log writes per owner across every datasource
  /// instance. Kids evidence lives in a single JSON string, so any two
  /// read-modify-write sequences (award, cloud pull-merge, sync marks) must
  /// never interleave or one side's evidence is silently lost.
  static final Map<String, Future<void>> _kidsLogWriteLocks = {};

  String _kidsOwnerKey(String base, String ownerId) => '$base|$ownerId';

  Future<T> _withKidsLogWriteLock<T>(
    String ownerId,
    Future<T> Function() action,
  ) async {
    final previous = _kidsLogWriteLocks[ownerId];
    final completer = Completer<void>();
    _kidsLogWriteLocks[ownerId] = completer.future;
    if (previous != null) {
      try {
        await previous;
      } catch (_) {}
    }
    try {
      return await action();
    } finally {
      completer.complete();
      if (identical(_kidsLogWriteLocks[ownerId], completer.future)) {
        unawaited(_kidsLogWriteLocks.remove(ownerId));
      }
    }
  }

  /// Preserves a corrupt raw payload under a quarantine key instead of
  /// letting the next write wipe it forever. Single slot per key: only a
  /// different payload replaces the quarantined bytes.
  void _quarantineCorruptKidsValue(String base, String ownerId, String raw) {
    try {
      final corruptKey = '${_kidsOwnerKey(base, ownerId)}|corrupt';
      if (_prefs.getString(corruptKey) == raw) return;
      unawaited(_prefs.setString(corruptKey, raw).catchError((_) => false));
    } catch (_) {
      // Quarantine is best-effort; it must never break the read path.
    }
  }

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

  /// Atomic read → mutate → write under the per-owner kids log lock.
  Future<List<KidsSessionLogModel>> updateKidsSessionLogs(
    Future<List<KidsSessionLogModel>> Function(
      List<KidsSessionLogModel> current,
    )
    mutate,
  ) {
    final ownerId = _owner.currentOwnerId;
    return _withKidsLogWriteLock(ownerId, () async {
      await _claimLegacyKidsDataIfAuthorized(ownerId);
      _ensureStorageOwner(ownerId);
      final current = _getKidsSessionLogsForOwner(ownerId);
      final next = await mutate(current);
      _ensureStorageOwner(ownerId);
      await _saveKidsSessionLogsForOwner(next, ownerId);
      _ensureStorageOwner(ownerId);
      return next;
    });
  }

  List<KidsSessionLogModel> _getKidsSessionLogsForOwner(String ownerId) {
    const base = MemorizationPlusLocalDatasourceImpl._kKidsSessionLogs;
    final raw = _readKidsValue(base, ownerId);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _quarantineCorruptKidsValue(base, ownerId, raw);
        return const [];
      }
      final logs = <KidsSessionLogModel>[];
      var dropped = false;
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            logs.add(KidsSessionLogModel.fromJson(item));
          } catch (_) {
            dropped = true;
          }
        } else {
          dropped = true;
        }
      }
      if (dropped) {
        // A malformed entry must never wipe the whole history: salvage the
        // parseable logs and quarantine the raw payload as forensic evidence.
        _quarantineCorruptKidsValue(base, ownerId, raw);
      }
      return logs;
    } catch (_) {
      _quarantineCorruptKidsValue(base, ownerId, raw);
      return const [];
    }
  }

  Future<void> saveKidsSessionLog(KidsSessionLogModel log) =>
      updateKidsSessionLogs((logs) async {
        final next = [...logs.where((item) => item.id != log.id), log]
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
        return next;
      });

  Future<void> saveKidsSessionLogs(List<KidsSessionLogModel> logs) {
    final ownerId = _owner.currentOwnerId;
    return _withKidsLogWriteLock(ownerId, () async {
      _ensureStorageOwner(ownerId);
      await _saveKidsSessionLogsForOwner(logs, ownerId);
      _ensureStorageOwner(ownerId);
    });
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

  Future<void> markKidsSessionLogsCloudSynced(Iterable<String> localIds) {
    final acceptedIds = localIds.toSet();
    if (acceptedIds.isEmpty) return Future.value();
    return updateKidsSessionLogs((current) async {
      final now = DateTime.now().toUtc();
      return current
          .map(
            (log) => acceptedIds.contains(log.id) && !log.isSynced
                ? KidsSessionLogModel.fromEntity(log.copyWith(syncedAt: now))
                : log,
          )
          .toList();
    });
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
    const base = MemorizationPlusLocalDatasourceImpl._kParentRewards;
    final raw = _readKidsValue(base, ownerId);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _quarantineCorruptKidsValue(base, ownerId, raw);
        return const [];
      }
      final rewards = <ParentRewardModel>[];
      var dropped = false;
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            rewards.add(ParentRewardModel.fromJson(item));
          } catch (_) {
            dropped = true;
          }
        } else {
          dropped = true;
        }
      }
      if (dropped) {
        _quarantineCorruptKidsValue(base, ownerId, raw);
      }
      return rewards;
    } catch (_) {
      _quarantineCorruptKidsValue(base, ownerId, raw);
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

  Future<List<KidsHomeMission>> getHomeMissions() async {
    final ownerId = _owner.currentOwnerId;
    _ensureStorageOwner(ownerId);
    const base = MemorizationPlusLocalDatasourceImpl._kHomeMissions;
    final raw = _readKidsValue(base, ownerId);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _quarantineCorruptKidsValue(base, ownerId, raw);
        return const [];
      }
      final missions = <KidsHomeMission>[];
      var dropped = false;
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            missions.add(KidsHomeMission.fromJson(item));
          } catch (_) {
            dropped = true;
          }
        } else {
          dropped = true;
        }
      }
      if (dropped) {
        _quarantineCorruptKidsValue(base, ownerId, raw);
      }
      return missions;
    } catch (_) {
      _quarantineCorruptKidsValue(base, ownerId, raw);
      return const [];
    }
  }

  Future<void> saveHomeMissions(List<KidsHomeMission> missions) {
    final ownerId = _owner.currentOwnerId;
    return _setStringOrThrow(
      _kidsOwnerKey(
        MemorizationPlusLocalDatasourceImpl._kHomeMissions,
        ownerId,
      ),
      jsonEncode(missions.map((mission) => mission.toJson()).toList()),
    );
  }
}
