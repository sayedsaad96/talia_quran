import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_profile.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/quran/presentation/widgets/audio_downloads_access.dart';

void main() {
  setUp(() async => getIt.reset());
  tearDown(() async => getIt.reset());

  void register({required bool flag, required MemorizationPath path}) {
    getIt.registerSingleton<ExperienceFlags>(ExperienceFlags((_) => flag));
    getIt.registerSingleton<MemorizationPathResolver>(
      MemorizationPathResolver(_ProfileRepo(path)),
    );
  }

  test('ayah notes are offered to an adult with the flag on', () async {
    register(flag: true, path: MemorizationPath.adult);
    expect(await adultExperienceAvailable(ExperienceFeature.ayahNotes), isTrue);
  });

  test('a child profile never gets the notes entry points', () async {
    register(flag: true, path: MemorizationPath.child);
    expect(
      await adultExperienceAvailable(ExperienceFeature.ayahNotes),
      isFalse,
    );
  });

  test('the flag off hides them for everyone', () async {
    register(flag: false, path: MemorizationPath.adult);
    expect(
      await adultExperienceAvailable(ExperienceFeature.ayahNotes),
      isFalse,
    );
  });
}

class _ProfileRepo extends Fake implements MemorizationPlusRepository {
  _ProfileRepo(this.path);
  final MemorizationPath path;
  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async =>
      Right(
        MemorizationProfile(
          schemaVersion: 1,
          selectedPath: path,
          guardianLinkStatus: GuardianLinkStatus.none,
          guardianOnboardingStatus: GuardianOnboardingStatus.required,
          isParentGuardian: false,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
}
