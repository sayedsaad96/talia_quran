import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/guardian_linking_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/guardian_linking_state.dart';

import 'guardian_linking_cubit_test.mocks.dart';

@GenerateMocks([MemorizationPlusRepository])
void main() {
  late GuardianLinkingCubit cubit;
  late MockMemorizationPlusRepository mockRepository;

  setUp(() {
    mockRepository = MockMemorizationPlusRepository();
    cubit = GuardianLinkingCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  final testSession = PairingSession(
    id: '1',
    pairingCode: 'ABCDEF',
    qrData: 'qr-data',
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    status: PairingSessionStatus.pending,
    isUsed: false,
  );

  final testProfile = MemorizationProfile(
    schemaVersion: 1,
    selectedPath: MemorizationPath.child,
    guardianLinkStatus: GuardianLinkStatus.none,
    guardianOnboardingStatus: GuardianOnboardingStatus.completed,
    isParentGuardian: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  test('initial state should be GuardianLinkingInitial', () {
    expect(cubit.state, equals(const GuardianLinkingInitial()));
  });

  test('load emits Required when guardian status loads successfully', () async {
    when(
      mockRepository.refreshChildGuardianLink(),
    ).thenAnswer((_) async => Right(testProfile));
    when(
      mockRepository.refreshPairingSession(),
    ).thenAnswer((_) async => const Right(null));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GuardianLinkingLoading(),
        GuardianLinkingRequired(profile: testProfile),
      ]),
    );

    await cubit.load();
    await expectation;
  });

  test('load emits explicit Error when guardian status fails', () async {
    when(
      mockRepository.refreshChildGuardianLink(),
    ).thenAnswer((_) async => const Left(CacheFailure('network failed')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GuardianLinkingLoading(),
        const GuardianLinkingError('network failed'),
      ]),
    );

    await cubit.load();
    await expectation;
  });

  test('load emits timeout Error when initial guardian load hangs', () async {
    await cubit.close();
    cubit = GuardianLinkingCubit(
      mockRepository,
      initialLoadTimeout: const Duration(milliseconds: 10),
    );
    when(mockRepository.refreshChildGuardianLink()).thenAnswer(
      (_) => Completer<Either<Failure, MemorizationProfile>>().future,
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GuardianLinkingLoading(),
        const GuardianLinkingError.timeout(),
      ]),
    );

    await cubit.load();
    await expectation;
  });

  test('retry after load failure can recover to Required', () async {
    var attempts = 0;
    when(mockRepository.refreshChildGuardianLink()).thenAnswer((_) async {
      attempts += 1;
      if (attempts == 1) {
        return const Left(CacheFailure('network failed'));
      }
      return Right(testProfile);
    });
    when(
      mockRepository.refreshPairingSession(),
    ).thenAnswer((_) async => const Right(null));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GuardianLinkingLoading(),
        const GuardianLinkingError('network failed'),
        const GuardianLinkingLoading(),
        GuardianLinkingRequired(profile: testProfile),
      ]),
    );

    await cubit.load();
    await cubit.load();
    await expectation;
  });

  test('createPairingSession emits Pending when successful', () async {
    when(
      mockRepository.createGuardianPairingSession(),
    ).thenAnswer((_) async => Right(testSession));

    // Register expectation first, call action second, await expectation last.
    // This prevents the 30s timeout caused by awaiting expectLater before
    // the cubit method fires any states.
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GuardianLinkingLoading(),
        GuardianLinkingPending(session: testSession),
      ]),
    );

    await cubit.createPairingSession();
    await expectation;
  });

  test('createPairingSession emits Blocked when fails', () async {
    when(
      mockRepository.createGuardianPairingSession(),
    ).thenAnswer((_) async => const Left(CacheFailure('Failed to generate')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GuardianLinkingLoading(),
        const GuardianLinkingBlocked('Failed to generate'),
      ]),
    );

    await cubit.createPairingSession();
    await expectation;
  });

  test('continueWithoutGuardian emits Skipped when successful', () async {
    when(
      mockRepository.continueWithoutGuardian(),
    ).thenAnswer((_) async => Right(testProfile));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GuardianLinkingLoading(),
        GuardianLinkingSkipped(profile: testProfile),
      ]),
    );

    await cubit.continueWithoutGuardian();
    await expectation;
  });

  test(
    'checkLinkStatus emits Linked without loading when cloud link exists',
    () async {
      final linkedProfile = testProfile.copyWith(
        guardianLinkStatus: GuardianLinkStatus.linked,
        guardianOnboardingStatus: GuardianOnboardingStatus.completed,
        guardianId: 'parent-user',
      );
      when(
        mockRepository.refreshChildGuardianLink(),
      ).thenAnswer((_) async => Right(linkedProfile));

      final expectation = expectLater(
        cubit.stream,
        emits(GuardianLinkingLinked(profile: linkedProfile)),
      );

      await cubit.checkLinkStatus();
      await expectation;
      verifyNever(mockRepository.refreshPairingSession());
    },
  );
}
