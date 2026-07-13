import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';

import '../../auth/auth_pull_bus_test.mocks.dart';

void main() {
  late MockAuthRepository authRepository;
  late MockMemorizationPlusRepository memPlusRepository;
  late MockAchievementService achievementService;
  late StreamController<AppUser?> authStreamController;
  late StreamController<void> passwordRecoveryStreamController;
  late ProgressEventsBus progressEvents;

  const user = AppUser(
    id: 'child-user',
    email: 'child@example.com',
    displayName: 'Child',
  );

  final certificate = CertificateAward(
    id: 'surah-67',
    titleAr: 'سورة الملك',
    type: CertificateType.surah,
    earnedAt: DateTime.utc(2026, 7, 9),
    surahId: 67,
  );

  setUp(() {
    authRepository = MockAuthRepository();
    memPlusRepository = MockMemorizationPlusRepository();
    achievementService = MockAchievementService();
    authStreamController = StreamController<AppUser?>.broadcast();
    passwordRecoveryStreamController = StreamController<void>.broadcast();
    progressEvents = ProgressEventsBus();

    when(authRepository.currentUser).thenReturn(user);
    when(
      authRepository.authStateChanges,
    ).thenAnswer((_) => authStreamController.stream);
    when(
      authRepository.passwordRecoveryChanges,
    ).thenAnswer((_) => passwordRecoveryStreamController.stream);
    when(
      authRepository.pullProgressFromCloud(),
    ).thenAnswer((_) async => const Right(unit));
    when(
      authRepository.syncProgressToCloud(),
    ).thenAnswer((_) async => const Right(unit));
    when(
      memPlusRepository.pullProductionDataFromCloud(),
    ).thenAnswer((_) async => const Right(null));
    when(
      memPlusRepository.resyncProductionDataToCloud(),
    ).thenAnswer((_) async => const Right(null));
    when(
      memPlusRepository.pushCertificatesToCloud([certificate]),
    ).thenAnswer((_) async => const Right(null));
    when(achievementService.getAllEarnedCertificates()).thenReturn([certificate]);
  });

  tearDown(() async {
    progressEvents.dispose();
    await authStreamController.close();
    await passwordRecoveryStreamController.close();
  });

  test('login resync pushes already-earned certificates to cloud', () async {
    final cubit = AuthCubit(
      authRepository,
      memPlusRepository,
      progressEvents,
      achievementService,
    );
    await Future<void>.delayed(Duration.zero);

    verifyInOrder([
      authRepository.pullProgressFromCloud(),
      memPlusRepository.pullProductionDataFromCloud(),
      authRepository.syncProgressToCloud(),
      memPlusRepository.resyncProductionDataToCloud(),
      achievementService.getAllEarnedCertificates(),
      memPlusRepository.pushCertificatesToCloud([certificate]),
    ]);

    await cubit.close();
  });
}
