import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/error/app_failure.dart';
import '../../../domain/entities/memorization_entities.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import '../../models/memorization_models.dart';
import 'memorization_profile_store.dart';

/// Identity/profile domain: reading + writing the memorization profile,
/// path selection, guardian-skip flow, identity reset, smart settings and the
/// legacy track flag. Persists through [MemorizationProfileStore] and the
/// local datasource.
class MemorizationProfileService {
  MemorizationProfileService(this._datasource, this._profileStore, [this._prefs]);

  final MemorizationPlusLocalDatasource _datasource;
  final MemorizationProfileStore _profileStore;
  final SharedPreferences? _prefs;

  /// SharedPreferences key set when the memorization path/guardian status
  /// changes. Cleared by [MemorizationPlusRepositoryImpl.pushIdentityToCloud]
  /// after a successful cloud push.
  static const kIdentityCloudDirty = 'mem_plus_identity_cloud_dirty';

  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async {
    try {
      return Right(await _loadProfile());
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, MemorizationProfile>> selectMemorizationPath(
    MemorizationPath path,
  ) async {
    try {
      final current = await _loadProfile();
      final selected = current.copyWith(
        selectedPath: path,
        guardianLinkStatus: GuardianLinkStatus.none,
        guardianOnboardingStatus: path == MemorizationPath.child
            ? GuardianOnboardingStatus.required
            : GuardianOnboardingStatus.completed,
        isParentGuardian: path == MemorizationPath.adult
            ? current.isParentGuardian
            : false,
        clearGuardianId: true,
        clearLinkedChildId: path == MemorizationPath.child,
      );
      final saved = await _saveProfile(selected);
      await _datasource.saveSelectedTrack(saved.legacyTrack!.name);
      if (path == MemorizationPath.child) {
        await _datasource.setIsParentMode(false);
      }
      await _prefs?.setBool(kIdentityCloudDirty, true);
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, MemorizationProfile>> continueWithoutGuardian() async {
    try {
      final profile = await _loadProfile();
      if (!profile.isChild) {
        return const Left(
          CacheFailure('Guardian linking is only for children'),
        );
      }
      final saved = await _saveProfile(
        profile.copyWith(
          guardianLinkStatus: GuardianLinkStatus.none,
          guardianOnboardingStatus: GuardianOnboardingStatus.skipped,
          clearGuardianId: true,
        ),
      );
      await _datasource.clearPairingSession();
      await _prefs?.setBool(kIdentityCloudDirty, true);
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, MemorizationProfile>>
  resetMemorizationIdentity() async {
    try {
      await _datasource.clearMemorizationProfile();
      await _datasource.clearPairingSession();
      await _datasource.clearSelectedTrack();
      await _datasource.clearIsParentMode();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.kHifzPathMode);
      return Right(await _loadProfile());
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, SmartMemorizationSettings>> getSmartSettings() async {
    try {
      return Right(await _datasource.getSmartSettings());
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, void>> saveSmartSettings(
    SmartMemorizationSettings settings,
  ) async {
    try {
      await _datasource.saveSmartSettings(
        SmartMemorizationSettingsModel.fromEntity(settings),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Either<Failure, MemorizationTrack?> getSelectedTrack() {
    try {
      final raw = _datasource.getSelectedTrack();
      if (raw == null) return const Right(null);
      final track = MemorizationTrack.values.firstWhere(
        (t) => t.name == raw,
        orElse: () => MemorizationTrack.adults,
      );
      return Right(track);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, void>> saveSelectedTrack(
    MemorizationTrack track,
  ) async {
    try {
      final path = track == MemorizationTrack.kids
          ? MemorizationPath.child
          : MemorizationPath.adult;
      final result = await selectMemorizationPath(path);
      final failure = result.fold((failure) => failure, (_) => null);
      if (failure != null) return Left(failure);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<MemorizationProfile> _loadProfile() => _profileStore.loadProfile();

  Future<MemorizationProfile> loadProfile() => _profileStore.loadProfile();

  Future<MemorizationProfile> _saveProfile(MemorizationProfile profile) =>
      _profileStore.saveProfile(profile);
}
