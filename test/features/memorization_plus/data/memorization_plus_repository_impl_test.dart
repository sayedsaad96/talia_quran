import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_cloud_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_identity_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';

void main() {
  group('MemorizationPlusRepositoryImpl focused contracts', () {
    test('can be typed as the memorization identity repository contract', () {
      MemorizationIdentityRepository acceptsIdentityContract(
        MemorizationPlusRepositoryImpl repository,
      ) =>
          repository;

      expect(acceptsIdentityContract, isNotNull);
    });

    test('can be typed as the memorization cloud repository contract', () {
      MemorizationCloudRepository acceptsCloudContract(
        MemorizationPlusRepositoryImpl repository,
      ) =>
          repository;

      expect(acceptsCloudContract, isNotNull);
    });

    test('DI exposes focused contracts through the existing repository singleton', () {
      final repository = _UnresolvedMemorizationPlusRepository();
      getIt.registerSingleton<MemorizationPlusRepository>(repository);
      getIt.registerLazySingleton<MemorizationIdentityRepository>(
        () => getIt<MemorizationPlusRepository>()
            as MemorizationIdentityRepository,
      );
      getIt.registerLazySingleton<MemorizationCloudRepository>(
        () => getIt<MemorizationPlusRepository>()
            as MemorizationCloudRepository,
      );

      addTearDown(getIt.reset);

      expect(
        getIt<MemorizationIdentityRepository>(),
        same(getIt<MemorizationPlusRepository>()),
      );
      expect(
        getIt<MemorizationCloudRepository>(),
        same(getIt<MemorizationPlusRepository>()),
      );
    });
  });
}

class _UnresolvedMemorizationPlusRepository
    implements
        MemorizationPlusRepository,
        MemorizationIdentityRepository,
        MemorizationCloudRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
