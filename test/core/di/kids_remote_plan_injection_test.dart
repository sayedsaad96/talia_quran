import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/kids_remote_plan_injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/kids_enrichment_feature_flags.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_remote_plan.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';

void main() {
  late GetIt services;
  late _Repository repository;
  late AccountDataBarrier barrier;
  var enabled = true;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const owner = FixedRecordOwnerProvider('child');
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    services = GetIt.asNewInstance();
    repository = _Repository();
    enabled = true;
    services.registerSingleton<SharedPreferences>(prefs);
    services.registerSingleton<RecordOwnerProvider>(owner);
    services.registerSingleton<KidsEnrichmentFlags>(
      KidsEnrichmentFlags((_) => enabled),
    );
    services.registerSingleton<MemorizationPlusRepository>(repository);
  });
  tearDown(() => services.reset());

  test('flag off retains daily behavior without reading child data', () async {
    enabled = false;
    expect(await readKidsPracticeDays(services), isNull);
    expect(repository.profileReads, 0);
  });

  test(
    'a child weekday mask reaches reminders but failed profile data cannot authorize daily fallback',
    () async {
      expect(await readKidsPracticeDays(services), 65);
      repository.profileFailure = true;
      await expectLater(
        readKidsPracticeDays(services),
        throwsA(isA<Failure>()),
      );
    },
  );

  test(
    'authority invalidated while reading profile cannot schedule from stale settings',
    () async {
      repository.afterProfile = barrier.invalidate;
      await expectLater(
        readKidsPracticeDays(services),
        throwsA(isA<AccountDataUnavailableException>()),
      );
      expect(repository.settingsReads, 0);
    },
  );
}

class _Repository implements MemorizationPlusRepository {
  var profileFailure = false;
  var profileReads = 0;
  var settingsReads = 0;
  void Function()? afterProfile;

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async {
    profileReads++;
    afterProfile?.call();
    return profileFailure
        ? const Left(CacheFailure())
        : Right(
            MemorizationProfile.empty().copyWith(
              selectedPath: MemorizationPath.child,
            ),
          );
  }

  @override
  Future<Either<Failure, ParentSettings>> getParentSettings() async {
    settingsReads++;
    return Right(
      const ParentSettings().copyWith(
        remotePlan: const KidsRemotePlan(practiceDays: 65),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
