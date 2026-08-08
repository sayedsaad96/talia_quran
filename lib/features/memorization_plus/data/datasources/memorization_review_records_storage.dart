part of 'memorization_plus_local_datasource.dart';

/// Review-record storage: Isar/SharedPreferences CRUD, identity migrations and
/// cloud dirty tracking.
mixin MemorizationReviewRecordsStorageMixin on MemorizationLocalStorageMixin {
  String _reviewKey(int surahId, int ayahNumber) =>
      '${MemorizationPlusLocalDatasourceImpl._kReviewPrefix}_${surahId}_$ayahNumber';

  /// Identity of the row this record must be written to, under the active owner.
  ReviewRecordIdentity _writeIdentity(AyahReviewRecordModel record) =>
      ReviewRecordIdentity(
        ownerUserId: _owner.currentOwnerId,
        audience: ReviewRecordAudienceScope.scopeForWriteMode(
          record.createdByMode,
        ),
        surahId: record.surahId,
        ayahNumber: record.ayahNumber,
      );

  ReviewRecordIdentity _readIdentity({
    required int surahId,
    required int ayahNumber,
    required ReviewRecordReadScope scope,
  }) =>
      ReviewRecordIdentity(
        ownerUserId: _owner.currentOwnerId,
        audience: scope,
        surahId: surahId,
        ayahNumber: ayahNumber,
      );

  Future<void> _runReviewRecordMigrations() async {
    await migrateReviewRecordsToIsarIfNeeded();
    await migrateReviewRecordIdentityIfNeeded();
  }

  /// All rows owned by the active account, optionally narrowed to one audience.
  Future<List<IsarAyahReviewRecord>> _ownedRows(
    Isar isar, {
    ReviewRecordReadScope? scope,
  }) async {
    final query = isar.isarAyahReviewRecords
        .filter()
        .ownerUserIdEqualTo(_owner.currentOwnerId);
    if (scope == null) return query.findAll();
    return query.audienceEqualTo(scope.name).findAll();
  }

  Future<void> migrateAudienceScopedReviewKeysIfNeeded() async {
    // Superseded by [migrateReviewRecordIdentityIfNeeded]. Kept on the
    // interface so older call sites compile; no longer invoked on read/write.
  }

  Future<void> migrateReviewRecordsToIsarIfNeeded() async {
    final isar = _isar;
    if (isar == null ||
        (_prefs.getBool(
              MemorizationPlusLocalDatasourceImpl._kReviewIsarMigration,
            ) ??
            false)) {
      return;
    }

    final legacyKeys = _legacyReviewKeys();
    if (legacyKeys.isEmpty) {
      await _prefs.setBool(
        MemorizationPlusLocalDatasourceImpl._kReviewIsarMigration,
        true,
      );
      return;
    }

    final records = legacyKeys
        .map((key) {
          final raw = _prefs.getString(key);
          return raw == null
              ? null
              : _tryParse(raw, AyahReviewRecordModel.fromJson);
        })
        .whereType<AyahReviewRecordModel>()
        // Migrated records enter the V2 source of truth.
        .map(
          (m) => AyahReviewRecordModel.fromEntity(
            m.copyWith(createdByMode: ReviewRecordCreatedByMode.v2Session),
          ),
        )
        .toList();

    await isar.writeTxn(() async {
      await isar.isarAyahReviewRecords.putAll(
        records.map(IsarAyahReviewRecord.fromModel).toList(),
      );
    });

    for (final key in legacyKeys) {
      await _removeOrThrow(key);
    }
    await _prefs.setBool(
      MemorizationPlusLocalDatasourceImpl._kReviewIsarMigration,
      true,
    );
  }

  List<String> _legacyReviewKeys() {
    return _prefs
        .getKeys()
        .where(
          (key) => key.startsWith(
            '${MemorizationPlusLocalDatasourceImpl._kReviewPrefix}_',
          ),
        )
        .toList();
  }

  /// Re-keys every review row to `owner|audience|surah|ayah`.
  ///
  /// Handles all three historical key generations. Runs once per installation
  /// and is safe to call on every read: the prefs flag short-circuits it.
  Future<void> migrateReviewRecordIdentityIfNeeded() async {
    if (_prefs.getBool(
          MemorizationPlusLocalDatasourceImpl._kReviewIdentityMigration,
        ) ??
        false) {
      return;
    }

    final isar = _isar;
    if (isar == null) {
      await _prefs.setBool(
        MemorizationPlusLocalDatasourceImpl._kReviewIdentityMigration,
        true,
      );
      return;
    }

    final ownerUserId = _owner.currentOwnerId;
    final isLocalOwner = ownerUserId == ReviewRecordIdentity.localOwnerId;
    final rows = await isar.isarAyahReviewRecords.where().findAll();

    await isar.writeTxn(() async {
      for (final row in rows) {
        final generation = ReviewRecordIdentity.generationOf(row.compositeKey);
        if (generation == ReviewRecordKeyGeneration.identity) continue;

        final model = row.toModel();
        final audience = switch (generation) {
          ReviewRecordKeyGeneration.audienceScoped =>
            row.compositeKey.startsWith(ReviewRecordAudienceScope.kidsPrefix)
                ? ReviewRecordReadScope.kids
                : ReviewRecordReadScope.adult,
          _ => ReviewRecordAudienceScope.scopeForWriteMode(model.createdByMode),
        };
        final identity = ReviewRecordIdentity(
          ownerUserId: ownerUserId,
          audience: audience,
          surahId: model.surahId,
          ayahNumber: model.ayahNumber,
        );

        final occupied = await isar.isarAyahReviewRecords.getByCompositeKey(
          identity.storageKey,
        );
        if (occupied != null) {
          // A row already owns this identity. Keep it and drop the stale
          // duplicate rather than losing the newer review state.
          await isar.isarAyahReviewRecords.delete(row.id);
          continue;
        }

        row.compositeKey = identity.storageKey;
        row.ownerUserId = identity.ownerUserId;
        row.audience = identity.audience.name;
        if (isLocalOwner) {
          row.cloudDirty = false;
        }
        await isar.isarAyahReviewRecords.put(row);
      }
    });

    await _prefs.setBool(
      MemorizationPlusLocalDatasourceImpl._kReviewIdentityMigration,
      true,
    );
  }

  /// Transfers `local`-owned review records to the signed-in account on first
  /// sign-in. Returns the number of records claimed.
  Future<int> claimLocalReviewRecords() async {
    final isar = _isar;
    final ownerUserId = _owner.currentOwnerId;
    if (isar == null || ownerUserId == ReviewRecordIdentity.localOwnerId) {
      return 0;
    }
    if (_prefs.getString(
          MemorizationPlusLocalDatasourceImpl._kLocalRecordsClaimedBy,
        ) !=
        null) {
      return 0;
    }

    await _runReviewRecordMigrations();

    // Only an account with no history of its own may absorb guest data.
    final alreadyOwned = await isar.isarAyahReviewRecords
        .filter()
        .ownerUserIdEqualTo(ownerUserId)
        .count();
    if (alreadyOwned > 0) return 0;

    final localRows = await isar.isarAyahReviewRecords
        .filter()
        .ownerUserIdEqualTo(ReviewRecordIdentity.localOwnerId)
        .findAll();
    if (localRows.isEmpty) return 0;

    var claimed = 0;
    await isar.writeTxn(() async {
      for (final row in localRows) {
        final parsed = ReviewRecordIdentity.tryParse(row.compositeKey);
        if (parsed == null) continue;
        final identity = ReviewRecordIdentity(
          ownerUserId: ownerUserId,
          audience: parsed.audience,
          surahId: parsed.surahId,
          ayahNumber: parsed.ayahNumber,
        );
        final occupied = await isar.isarAyahReviewRecords.getByCompositeKey(
          identity.storageKey,
        );
        if (occupied != null) continue;

        row.compositeKey = identity.storageKey;
        row.ownerUserId = identity.ownerUserId;
        // Claimed records have never been uploaded under this account.
        row.cloudDirty = true;
        row.lastSyncedAt = null;
        await isar.isarAyahReviewRecords.put(row);
        claimed++;
      }
    });

    if (claimed > 0) {
      await _prefs.setString(
        MemorizationPlusLocalDatasourceImpl._kLocalRecordsClaimedBy,
        ownerUserId,
      );
    }
    return claimed;
  }

  Future<AyahReviewRecordModel?> getReviewRecord(
    int surahId,
    int ayahNumber, {
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async {
    final isar = _isar;
    if (isar == null) {
      final raw = _prefs.getString(_reviewKey(surahId, ayahNumber));
      if (raw == null) return null;
      final model = _tryParse(raw, AyahReviewRecordModel.fromJson);
      if (model == null) return null;
      return ReviewRecordAudienceScope.matchesReadScope(model, scope)
          ? model
          : null;
    }

    await _runReviewRecordMigrations();
    final identity = _readIdentity(
      surahId: surahId,
      ayahNumber: ayahNumber,
      scope: scope,
    );
    final row = await isar.isarAyahReviewRecords.getByCompositeKey(
      identity.storageKey,
    );
    return row?.toModel();
  }

  Future<List<AyahReviewRecordModel>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
    bool includeAllAudiences = false,
  }) async {
    final isar = _isar;
    if (isar == null) {
      return _legacyReviewKeys()
          .map((k) {
            final raw = _prefs.getString(k);
            return raw == null
                ? null
                : _tryParse(raw, AyahReviewRecordModel.fromJson);
          })
          .whereType<AyahReviewRecordModel>()
          .where(
            (m) =>
                includeAllAudiences ||
                ReviewRecordAudienceScope.matchesReadScope(m, scope),
          )
          .toList();
    }

    await _runReviewRecordMigrations();
    final rows = await _ownedRows(
      isar,
      scope: includeAllAudiences ? null : scope,
    );
    return rows.map((row) => row.toModel()).toList();
  }

  Future<void> saveReviewRecord(
    AyahReviewRecordModel record, {
    bool markCloudDirty = true,
  }) async {
    final isar = _isar;
    if (isar == null) {
      await _setStringOrThrow(
        _reviewKey(record.surahId, record.ayahNumber),
        jsonEncode(record.toJson()),
      );
      return;
    }

    await _runReviewRecordMigrations();
    final identity = _writeIdentity(record);
    final isarRecord = IsarAyahReviewRecord.fromModel(record)
      ..compositeKey = identity.storageKey
      ..ownerUserId = identity.ownerUserId
      ..audience = identity.audience.name;
    if (markCloudDirty) {
      isarRecord.cloudDirty = true;
    } else {
      isarRecord.cloudDirty = false;
      isarRecord.lastSyncedAt = DateTime.now().toUtc();
    }
    await isar.writeTxn(() async {
      await isar.isarAyahReviewRecords.put(isarRecord);
    });
  }

  Future<List<AyahReviewRecordModel>> getCloudDirtyReviewRecords({
    bool includeAllAudiences = false,
  }) async {
    final isar = _isar;
    if (isar == null) {
      return getAllReviewRecords(includeAllAudiences: includeAllAudiences);
    }

    await _runReviewRecordMigrations();
    final rows = await _ownedRows(
      isar,
      scope: includeAllAudiences ? null : ReviewRecordReadScope.adult,
    );
    return rows
        .where((row) => row.cloudDirty != false)
        .map((row) => row.toModel())
        .toList();
  }

  Future<void> markReviewRecordsCloudSynced(
    Iterable<String> compositeKeys,
  ) async {
    final isar = _isar;
    if (isar == null) return;

    final syncedAt = DateTime.now().toUtc();
    await isar.writeTxn(() async {
      for (final compositeKey in compositeKeys) {
        final record = await isar.isarAyahReviewRecords.getByCompositeKey(
          compositeKey,
        );
        if (record == null) continue;
        record.cloudDirty = false;
        record.lastSyncedAt = syncedAt;
        await isar.isarAyahReviewRecords.put(record);
      }
    });
  }
}
