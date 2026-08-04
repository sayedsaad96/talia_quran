part of 'memorization_plus_local_datasource.dart';

/// Identity-related storage: profile, pairing session, legacy track flag,
/// smart settings and the legacy parent-mode flag.
mixin MemorizationIdentityStorageMixin on MemorizationLocalStorageMixin {
  Future<MemorizationProfileModel> getMemorizationProfile() async {
    final raw = _prefs.getString(MemorizationPlusLocalDatasourceImpl._kProfile);
    if (raw == null) return MemorizationProfileModel.empty();
    return _tryParse(raw, MemorizationProfileModel.fromJson) ??
        MemorizationProfileModel.empty();
  }

  Future<void> saveMemorizationProfile(MemorizationProfileModel profile) =>
      _setStringOrThrow(
        MemorizationPlusLocalDatasourceImpl._kProfile,
        jsonEncode(profile.toJson()),
      );

  Future<void> clearMemorizationProfile() =>
      _removeOrThrow(MemorizationPlusLocalDatasourceImpl._kProfile);

  Future<PairingSessionModel?> getPairingSession() async {
    final raw = _prefs.getString(
      MemorizationPlusLocalDatasourceImpl._kPairingSession,
    );
    if (raw == null) return null;
    return _tryParse(raw, PairingSessionModel.fromJson);
  }

  Future<void> savePairingSession(PairingSessionModel session) =>
      _setStringOrThrow(
        MemorizationPlusLocalDatasourceImpl._kPairingSession,
        jsonEncode(session.toJson()),
      );

  Future<void> clearPairingSession() =>
      _removeOrThrow(MemorizationPlusLocalDatasourceImpl._kPairingSession);

  String? getSelectedTrack() =>
      _prefs.getString(MemorizationPlusLocalDatasourceImpl._kTrack);

  Future<void> saveSelectedTrack(String track) => _setStringOrThrow(
    MemorizationPlusLocalDatasourceImpl._kTrack,
    track,
  );

  Future<void> clearSelectedTrack() =>
      _removeOrThrow(MemorizationPlusLocalDatasourceImpl._kTrack);

  Future<SmartMemorizationSettingsModel> getSmartSettings() async {
    final raw = _prefs.getString(
      MemorizationPlusLocalDatasourceImpl._kSmartSettings,
    );
    if (raw == null) {
      final customPlan = await getCustomPlan();
      return SmartMemorizationSettingsModel(customPlan: customPlan);
    }
    final parsed = _tryParse(raw, SmartMemorizationSettingsModel.fromJson);
    if (parsed != null) return parsed;
    return const SmartMemorizationSettingsModel();
  }

  Future<void> saveSmartSettings(SmartMemorizationSettingsModel settings) =>
      _setStringOrThrow(
        MemorizationPlusLocalDatasourceImpl._kSmartSettings,
        jsonEncode(settings.toJson()),
      );

  bool getIsParentMode() =>
      _prefs.getBool(MemorizationPlusLocalDatasourceImpl._kIsParentMode) ??
      false;

  Future<void> setIsParentMode(bool value) async {
    final saved = await _prefs.setBool(
      MemorizationPlusLocalDatasourceImpl._kIsParentMode,
      value,
    );
    if (!saved) {
      throw StateError('Failed to save parent mode');
    }
  }

  Future<void> clearIsParentMode() =>
      _removeOrThrow(MemorizationPlusLocalDatasourceImpl._kIsParentMode);
}
