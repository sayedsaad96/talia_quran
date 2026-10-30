import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_profile.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/guardian_link_scope.dart';

class _ProfileRepository extends Mock implements MemorizationPlusRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemorizationProfile profile;

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    const owner = FixedRecordOwnerProvider('guardian');
    AccountDataBarrier.forPreferences(preferences).owner = owner;
    profile = MemorizationProfile.empty();
    final repository = _ProfileRepository();
    when(
      repository.getMemorizationProfile,
    ).thenAnswer((_) async => Right(profile));
    getIt.registerSingleton<SharedPreferences>(preferences);
    getIt.registerSingleton<RecordOwnerProvider>(owner);
    getIt.registerSingleton<MemorizationPlusRepository>(repository);
  });

  tearDown(() => getIt.reset());

  test(
    'an unconfigured profile can link despite refreshed timestamps',
    () async {
      final scope = await GuardianLinkScope.capture();
      profile = profile.copyWith(
        createdAt: profile.createdAt.add(const Duration(seconds: 1)),
        updatedAt: profile.updatedAt.add(const Duration(seconds: 1)),
      );

      expect(scope, isNotNull);
      expect(await scope!.stillValid(), isTrue);
    },
  );

  test(
    'a changed memorization identity invalidates linking confirmation',
    () async {
      final scope = await GuardianLinkScope.capture();
      profile = profile.copyWith(selectedPath: MemorizationPath.child);

      expect(scope, isNotNull);
      expect(await scope!.stillValid(), isFalse);
    },
  );
}
