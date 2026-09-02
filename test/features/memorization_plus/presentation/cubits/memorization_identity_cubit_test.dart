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

  test('setupChild persists age, nickname, policy defaults, and PIN', () async {
    final selectedChild = testProfile.copyWith(
      selectedPath: MemorizationPath.child,
      guardianOnboardingStatus: GuardianOnboardingStatus.required,
    );
    final configuredChild = selectedChild.copyWith(childAge: 6);
    when(
      mockRepository.selectMemorizationPath(MemorizationPath.child),
    ).thenAnswer((_) async => Right(selectedChild));
    when(
      mockRepository.configureChildAge(6),
    ).thenAnswer((_) async => Right(configuredChild));
    when(
      mockRepository.getParentSettings(),
    ).thenAnswer((_) async => const Right(ParentSettings()));
    when(
      mockRepository.saveParentSettings(any),
    ).thenAnswer((_) async => const Right(null));
    when(
      mockRepository.setParentPin('1234'),
    ).thenAnswer((_) async => const Right(null));

    await cubit.setupChild(
      nickname: 'مريم',
      age: 6,
      pin: '1234',
      reminderHour: 19,
      reminderMinute: 15,
      weeklyGoalSessions: 4,
      guidanceAudioEnabled: false,
      startingSurahId: 112,
    );

    expect(cubit.state, MemorizationIdentitySuccess(profile: configuredChild));
    final saved =
        verify(mockRepository.saveParentSettings(captureAny)).captured.single
            as ParentSettings;
    expect(saved.localChildNickname, 'مريم');
    expect(saved.reminderHour, 19);
    expect(saved.reminderMinute, 15);
    expect(saved.weeklyGoalSessions, 4);
    expect(saved.guidanceAudioEnabled, isFalse);
    expect(saved.sessionGoalMinutes, 6);
    expect(saved.startingSurahId, 112);
    expect(saved.kidsHifzV2Enabled, isTrue);
    verify(mockRepository.setParentPin('1234')).called(1);
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
