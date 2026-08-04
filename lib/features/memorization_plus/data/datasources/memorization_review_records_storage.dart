part of 'memorization_plus_local_datasource.dart';

/// Review-record storage: Isar/SharedPreferences CRUD, legacy migrations and
/// cloud dirty tracking.
mixin MemorizationReviewRecordsStorageMixin on MemorizationLocalStorageMixin {
  String _reviewKey(int surahId, int ayahNumber) =>
      '${MemorizationPlusLocalDatasourceImpl._kReviewPrefix}_${surahId}_$ayahNumber';

  bool get _audienceScopedReads => ReviewRecordAudienceScope.isEnabled(
    readBool: (key) => _prefs.getBool(key) ?? false,
  );

  Future<void> migrateAudienceScopedReviewKeysIfNeeded() async {
    if (!_audienceScopedReads) return;
    if (_prefs.getBool(ReviewRecordAudienceScope.migrationKey) == true) {
      return;
    }

    final isar = _isar;
    if (isar == null) {
      await _prefs.setBool(ReviewRecordAudienceScope.migrationKey, true);
      return;
    }

    await migrateReviewRecordsToIsarIfNeeded();
    final records = await isar.isarAyahReviewRecords.where().findAll();

    await isar.writeTxn(() async {
      for (final record in records) {
        if (!ReviewRecordAudienceScope.isLegacyCompositeKey(
          record.compositeKey,
        )) {
          continue;
        }
        final model = record.toModel();
        final scopedKey = ReviewRecordAudienceScope.storageKey(
          surahId: model.surahId,
          ayahNumber: model.ayahNumber,
          mode: model.createdByMode,
          scoped: true,
        );
        if (scopedKey == record.compositeKey) continue;

        final existing = await isar.isarAyahReviewRecords.getByCompositeKey(
          scopedKey,
        );
        if (existing != null) continue;

        final migrated = IsarAyahReviewRecord.fromModel(model)
          ..compositeKey = scopedKey;
        await isar.isarAyahReviewRecords.put(migrated);
      }
    });

    await _prefs.setBool(ReviewRecordAudienceScope.migrationKey, true);
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
          (key) =>
              key.startsWith('${MemorizationPlusLocalDatasourceImpl._kReviewPrefix}_'),
        )
        .toList();
  }

  Future<AyahReviewRecordModel?> _getIsarReviewRecord(
    int surahId,
    int ayahNumber, {
    required ReviewRecordReadScope scope,
  }) async {
    final isar = _isar;
    if (isar == null) return null;

    await migrateReviewRecordsToIsarIfNeeded();
    await migrateAudienceScopedReviewKeysIfNeeded();

    if (!_audienceScopedReads) {
      final record = await isar.isarAyahReviewRecords.getByCompositeKey(
        ReviewRecordAudienceScope.legacyKey(surahId, ayahNumber),
      );
      return record?.toModel();
    }

    final scopedKey = ReviewRecordAudienceScope.readKey(
      surahId: surahId,
      ayahNumber: ayahNumber,
      scope: scope,
      scoped: true,
    );
    final scoped = await isar.isarAyahReviewRecords.getByCompositeKey(
      scopedKey,
    );
    if (scoped != null) return scoped.toModel();

    if (scope == ReviewRecordReadScope.adult) {
      final legacy = await isar.isarAyahReviewRecords.getByCompositeKey(
        ReviewRecordAudienceScope.legacyKey(surahId, ayahNumber),
      );
      final legacyModel = legacy?.toModel();
      if (legacyModel != null &&
          ReviewRecordAudienceScope.matchesReadScope(
            legacyModel,
            ReviewRecordReadScope.adult,
          )) {
        return legacyModel;
      }
    }

    return null;
  }

  Future<AyahReviewRecordModel?> getReviewRecord(
    int surahId,
    int ayahNumber, {
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async {
    final isar = _isar;
    if (isar != null) {
      return _getIsarReviewRecord(surahId, ayahNumber, scope: scope);
    }

    final raw = _prefs.getString(_reviewKey(surahId, ayahNumber));
    if (raw == null) return null;
    final model = _tryParse(raw, AyahReviewRecordModel.fromJson);
    if (model == null) return null;
    if (_audienceScopedReads &&
        !ReviewRecordAudienceScope.matchesReadScope(model, scope)) {
      return null;
    }
    return model;
  }

  Future<List<AyahReviewRecordModel>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
    bool includeAllAudiences = false,
  }) async {
    final isar = _isar;
    if (isar != null) {
      await migrateReviewRecordsToIsarIfNeeded();
      await migrateAudienceScopedReviewKeysIfNeeded();
      final records = await isar.isarAyahReviewRecords.where().findAll();
      final models = records.map((record) => record.toModel()).toList();
      if (!_audienceScopedReads || includeAllAudiences) return models;
      return models
          .where((m) => ReviewRecordAudienceScope.matchesReadScope(m, scope))
          .toList();
    }

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
              !_audienceScopedReads ||
              includeAllAudiences ||
              ReviewRecordAudienceScope.matchesReadScope(m, scope),
        )
        .toList();
  }

  Future<void> saveReviewRecord(
    AyahReviewRecordModel record, {
    bool markCloudDirty = true,
  }) async {
    final isar = _isar;
    if (isar != null) {
      await migrateReviewRecordsToIsarIfNeeded();
      await migrateAudienceScopedReviewKeysIfNeeded();
      final compositeKey = ReviewRecordAudienceScope.storageKey(
        surahId: record.surahId,
        ayahNumber: record.ayahNumber,
        mode: record.createdByMode,
        scoped: _audienceScopedReads,
      );
      final isarRecord = IsarAyahReviewRecord.fromModel(record)
        ..compositeKey = compositeKey;
      if (markCloudDirty) {
        isarRecord.cloudDirty = true;
      } else {
        isarRecord.cloudDirty = false;
        isarRecord.lastSyncedAt = DateTime.now().toUtc();
      }
      await isar.writeTxn(() async {
        await isar.isarAyahReviewRecords.put(isarRecord);
      });
      return;
    }

    await _setStringOrThrow(
      _reviewKey(record.surahId, record.ayahNumber),
      jsonEncode(record.toJson()),
    );
  }

  Future<List<AyahReviewRecordModel>> getCloudDirtyReviewRecords({
    bool includeAllAudiences = false,
  }) async {
    final isar = _isar;
    if (isar == null) {
      return getAllReviewRecords(includeAllAudiences: includeAllAudiences);
    }

    await migrateReviewRecordsToIsarIfNeeded();
    await migrateAudienceScopedReviewKeysIfNeeded();
    final records = await isar.isarAyahReviewRecords
        .filter()
        .group(
          (q) => q.cloudDirtyEqualTo(true).or().cloudDirtyIsNull(),
        )
        .findAll();
    final models = records.map((record) => record.toModel()).toList();
    if (!_audienceScopedReads || includeAllAudiences) return models;
    return models
        .where(
          (m) => ReviewRecordAudienceScope.matchesReadScope(
            m,
            ReviewRecordReadScope.adult,
          ),
        )
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
        final record = await isar.isarAyahReviewRecords
            .filter()
            .compositeKeyEqualTo(compositeKey)
            .findFirst();
        if (record == null) continue;
        record.cloudDirty = false;
        record.lastSyncedAt = syncedAt;
        await isar.isarAyahReviewRecords.put(record);
      }
    });
  }
}
