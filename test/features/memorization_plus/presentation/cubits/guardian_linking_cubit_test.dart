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

  test('createPairingSession emits Pending when successful', () async {
    when(mockRepository.createGuardianPairingSession())
        .thenAnswer((_) async => Right(testSession));

    await expectLater(
      cubit.stream,
      emitsInOrder([
        const GuardianLinkingLoading(),
        GuardianLinkingPending(session: testSession),
      ]),
    );

    await cubit.createPairingSession();
  });

  test('createPairingSession emits Blocked when fails', () async {
    when(mockRepository.createGuardianPairingSession())
        .thenAnswer((_) async => const Left(CacheFailure('Failed to generate')));

    await expectLater(
      cubit.stream,
      emitsInOrder([
        const GuardianLinkingLoading(),
        const GuardianLinkingBlocked('Failed to generate'),
      ]),
    );

    await cubit.createPairingSession();
  });

  test('continueWithoutGuardian emits Skipped when successful', () async {
    when(mockRepository.continueWithoutGuardian())
        .thenAnswer((_) async => Right(testProfile));

    await expectLater(
      cubit.stream,
      emitsInOrder([
        const GuardianLinkingLoading(),
        GuardianLinkingSkipped(profile: testProfile),
      ]),
    );

    await cubit.continueWithoutGuardian();
  });
}
