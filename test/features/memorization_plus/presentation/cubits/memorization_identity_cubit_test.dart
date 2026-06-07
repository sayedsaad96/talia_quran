import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/memorization_identity_cubit.dart';

import 'guardian_linking_cubit_test.mocks.dart';

void main() {
  late MemorizationIdentityCubit cubit;
  late MockMemorizationPlusRepository mockRepository;
  late MemorizationPathResolver pathResolver;

  setUp(() {
    mockRepository = MockMemorizationPlusRepository();
    pathResolver = MemorizationPathResolver(mockRepository);
    cubit = MemorizationIdentityCubit(
      repository: mockRepository,
      pathResolver: pathResolver,
    );
  });

  tearDown(() async {
    await cubit.close();
    await pathResolver.dispose();
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
    when(
      mockRepository.selectMemorizationPath(MemorizationPath.adult),
    ).thenAnswer((_) async => Right(testProfile));

    // Wire up expectation BEFORE calling the action, then await AFTER — fixes
    // the race where await expectLater blocks before the cubit method is called.
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const MemorizationIdentityLoading(),
        MemorizationIdentitySuccess(profile: testProfile),
      ]),
    );

    await cubit.selectPath(MemorizationPath.adult);
    await expectation;
  });

  test('selectPath emits Loading then Error when fails', () async {
    when(
      mockRepository.selectMemorizationPath(MemorizationPath.adult),
    ).thenAnswer((_) async => const Left(CacheFailure('Save failed')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const MemorizationIdentityLoading(),
        const MemorizationIdentityError(message: 'Save failed'),
      ]),
    );

    await cubit.selectPath(MemorizationPath.adult);
    await expectation;
  });
}
