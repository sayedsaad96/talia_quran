import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../domain/entities/memorization_entities.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import '../../models/memorization_models.dart';

/// Owns the memorization identity profile load/save lifecycle, including the
/// legacy track/hifz-path migration path. Single collaborator responsible for
/// profile persistence so cloud and local collaborators read consistent state.
class MemorizationProfileStore {
  MemorizationProfileStore(this._datasource, this._prefs);

  final MemorizationPlusLocalDatasource _datasource;
  final SharedPreferences _prefs;

  Future<MemorizationProfile> loadProfile() async {
    final stored = await _datasource.getMemorizationProfile();
    if (stored.hasSelectedPath) return stored;

    final legacyTrack = _datasource.getSelectedTrack();
    final isParent = _datasource.getIsParentMode();
    final legacyHifzPath = _prefs.getString(AppConstants.kHifzPathMode);
    MemorizationPath? migratedPath;
    if (legacyTrack == MemorizationTrack.adults.name) {
      migratedPath = MemorizationPath.adult;
    } else if (legacyTrack == MemorizationTrack.kids.name) {
      migratedPath = MemorizationPath.child;
    }

    if (migratedPath == null && legacyHifzPath != null) {
      migratedPath = legacyHifzPath == 'backward'
          ? MemorizationPath.child
          : MemorizationPath.adult;
    }

    if (migratedPath == null && isParent) {
      migratedPath = MemorizationPath.adult;
    }

    if (migratedPath == null) return stored;
    final migrated = stored.copyWith(
      selectedPath: migratedPath,
      guardianLinkStatus: GuardianLinkStatus.none,
      guardianOnboardingStatus: migratedPath == MemorizationPath.child
          ? GuardianOnboardingStatus.skipped
          : GuardianOnboardingStatus.completed,
      isParentGuardian: migratedPath == MemorizationPath.adult && isParent,
    );
    return saveProfile(migrated);
  }

  Future<MemorizationProfile> saveProfile(MemorizationProfile profile) async {
    final model = MemorizationProfileModel.fromEntity(
      // UTC: consistent with review scheduling and streak date policy.
      profile.copyWith(updatedAt: DateTime.now().toUtc()),
    );
    await _datasource.saveMemorizationProfile(model);
    return model;
  }
}
