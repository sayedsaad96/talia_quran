import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/memorization_identity_cubit.dart';

import 'guardian_linking_cubit_test.mocks.dart';

void main() {
  late MemorizationIdentityCubit cubit;
  late MockMemorizationPlusRepository mockRepository;

  setUp(() {
    mockRepository = MockMemorizationPlusRepository();
    cubit = MemorizationIdentityCubit(repository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  final testProfile = MemorizationProfile(
    schemaVersion: 1,
    selectedPath: MemorizationPath.adult,
    guardianLinkStatus: GuardianLinkStatus.none,
    guardianOnboardingStatus: GuardianOnboardingStatus.completed,
    isParentGuardian: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  test('initial state should be MemorizationIdentityInitial', () {
    expect(cubit.state, equals(const MemorizationIdentityInitial()));
  });

  test('selectPath emits Loading then Success when successful', () async {
    when(mockRepository.selectMemorizationPath(MemorizationPath.adult))
        .thenAnswer((_) async => Right(testProfile));

    await expectLater(
      cubit.stream,
      emitsInOrder([
        const MemorizationIdentityLoading(),
        MemorizationIdentitySuccess(profile: testProfile),
      ]),
    );

    await cubit.selectPath(MemorizationPath.adult);
  });

  test('selectPath emits Loading then Error when fails', () async {
    when(mockRepository.selectMemorizationPath(MemorizationPath.adult))
        .thenAnswer((_) async => const Left(CacheFailure('Save failed')));

    await expectLater(
      cubit.stream,
      emitsInOrder([
        const MemorizationIdentityLoading(),
        const MemorizationIdentityError(message: 'Save failed'),
      ]),
    );

    await cubit.selectPath(MemorizationPath.adult);
  });
}
