part of 'memorization_plus_local_datasource.dart';

/// Kids progress, session logs and parent-dashboard storage.
mixin MemorizationKidsStorageMixin on MemorizationLocalStorageMixin {
  Future<KidsProgressModel> getKidsProgress() async {
    final raw = _prefs.getString(
      MemorizationPlusLocalDatasourceImpl._kKidsProgress,
    );
    if (raw == null) return const KidsProgressModel.empty();
    return _tryParse(raw, KidsProgressModel.fromJson) ??
        const KidsProgressModel.empty();
  }

  Future<void> saveKidsProgress(KidsProgressModel progress) =>
      _setStringOrThrow(
        MemorizationPlusLocalDatasourceImpl._kKidsProgress,
        jsonEncode(progress.toJson()),
      );

  Future<List<KidsSessionLogModel>> getKidsSessionLogs() async {
    final raw = _prefs.getString(
      MemorizationPlusLocalDatasourceImpl._kKidsSessionLogs,
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
    final logs = await getKidsSessionLogs();
    final next = [...logs.where((item) => item.id != log.id), log]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    await saveKidsSessionLogs(next);
  }

  Future<void> saveKidsSessionLogs(List<KidsSessionLogModel> logs) =>
      _setStringOrThrow(
        MemorizationPlusLocalDatasourceImpl._kKidsSessionLogs,
        jsonEncode(logs.map((log) => log.toJson()).toList()),
      );

  Future<ParentSettingsModel> getParentSettings() async {
    final raw = _prefs.getString(
      MemorizationPlusLocalDatasourceImpl._kParentSettings,
    );
    if (raw == null) return const ParentSettingsModel.defaults();
    return _tryParse(raw, ParentSettingsModel.fromJson) ??
        const ParentSettingsModel.defaults();
  }

  Future<void> saveParentSettings(ParentSettingsModel settings) =>
      _setStringOrThrow(
        MemorizationPlusLocalDatasourceImpl._kParentSettings,
        jsonEncode(settings.toJson()),
      );

  Future<List<ParentRewardModel>> getParentRewards() async {
    final raw = _prefs.getString(
      MemorizationPlusLocalDatasourceImpl._kParentRewards,
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

  Future<void> saveParentRewards(List<ParentRewardModel> rewards) =>
      _setStringOrThrow(
        MemorizationPlusLocalDatasourceImpl._kParentRewards,
        jsonEncode(rewards.map((reward) => reward.toJson()).toList()),
      );
}
