import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';

import '../auth_pull_bus_test.mocks.dart';

void main() {
  const testUser = AppUser(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  test('login restore pulls certificates and kids progress before push', () async {
    final mockAuth = MockAuthRepository();
    final mockMem = MockMemorizationPlusRepository();
    final mockAchievements = MockAchievementService();
    final bus = ProgressEventsBus();
    final authStream = StreamController<AppUser?>.broadcast();
    final recoveryStream = StreamController<void>.broadcast();
    addTearDown(() async {
      bus.dispose();
      await authStream.close();
      await recoveryStream.close();
    });

    when(mockAuth.authStateChanges).thenAnswer((_) => authStream.stream);
    when(mockAuth.passwordRecoveryChanges)
        .thenAnswer((_) => recoveryStream.stream);
    when(mockAuth.currentUser).thenReturn(testUser);
    when(mockAuth.pullProgressFromCloud())
        .thenAnswer((_) async => const Right(unit));
    when(mockAuth.syncProgressToCloud())
        .thenAnswer((_) async => const Right(unit));
    when(mockAuth.hasPendingCloudPush()).thenAnswer((_) async => true);
    when(mockMem.pullProductionDataFromCloud())
        .thenAnswer((_) async => const Right(null));
    when(mockMem.pullIdentityFromCloud())
        .thenAnswer((_) async => const Right(null));
    when(mockMem.pullCertificatesFromCloud()).thenAnswer(
      (_) async => Right([
        CertificateAward(
          id: 'cert_juz_1',
          titleAr: 'جزء 1',
          type: CertificateType.juz,
          earnedAt: DateTime.utc(2026, 8, 1),
          juzNumber: 1,
        ),
      ]),
    );
    when(mockMem.pullKidsProgressFromCloud())
        .thenAnswer((_) async => const Right(null));
    when(mockMem.resyncProductionDataToCloud())
        .thenAnswer((_) async => const Right(null));
    when(mockMem.claimLocalReviewRecords())
        .thenAnswer((_) async => const Right(0));
    when(mockMem.hasPendingCloudWork()).thenAnswer((_) async => true);
    when(mockMem.syncKidsProgressToCloud())
        .thenAnswer((_) async => const Right(null));
    when(mockMem.pushCertificatesToCloud(any))
        .thenAnswer((_) async => const Right(null));
    when(mockAchievements.getAllEarnedCertificates()).thenReturn(const []);
    when(mockAchievements.mergeEarnedFromCloud(any, isKids: anyNamed('isKids')))
        .thenAnswer((_) async => 1);
    when(mockAchievements.checkAndUnlockCertificates(isKids: anyNamed('isKids')))
        .thenAnswer((_) async => const []);

    final cubit = AuthCubit(mockAuth, mockMem, bus, mockAchievements);
    await cubit.ensureCloudSyncComplete();

    verifyInOrder([
      mockAuth.pullProgressFromCloud(),
      mockMem.pullIdentityFromCloud(),
      mockMem.pullProductionDataFromCloud(),
      mockMem.pullCertificatesFromCloud(),
      mockMem.pullKidsProgressFromCloud(),
      mockAuth.syncProgressToCloud(),
      mockMem.resyncProductionDataToCloud(),
    ]);
    verify(
      mockAchievements.mergeEarnedFromCloud(
        any,
        isKids: false,
      ),
    ).called(1);
    verify(
      mockAchievements.checkAndUnlockCertificates(isKids: true),
    ).called(1);

    await cubit.close();
  });
}
