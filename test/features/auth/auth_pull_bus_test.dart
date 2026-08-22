import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/domain/repositories/auth_repository.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';

import 'auth_pull_bus_test.mocks.dart';

@GenerateMocks([AuthRepository, MemorizationPlusRepository, AchievementService])
void main() {
  late MockAuthRepository mockAuthRepository;
  late MockMemorizationPlusRepository mockMemPlusRepository;
  late MockAchievementService mockAchievementService;
  late ProgressEventsBus progressEvents;
  late StreamController<AppUser?> authStreamController;
  late StreamController<void> passwordRecoveryStreamController;

  const testUser = AppUser(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockMemPlusRepository = MockMemorizationPlusRepository();
    mockAchievementService = MockAchievementService();
    progressEvents = ProgressEventsBus();
    authStreamController = StreamController<AppUser?>.broadcast();
    passwordRecoveryStreamController = StreamController<void>.broadcast();

    when(
      mockAuthRepository.authStateChanges,
    ).thenAnswer((_) => authStreamController.stream);
    when(
      mockAuthRepository.passwordRecoveryChanges,
    ).thenAnswer((_) => passwordRecoveryStreamController.stream);
    when(
      mockAuthRepository.pullProgressFromCloud(),
    ).thenAnswer((_) async => const Right(unit));
    when(
      mockAuthRepository.syncProgressToCloud(),
    ).thenAnswer((_) async => const Right(unit));
    when(
      mockAuthRepository.hasPendingCloudPush(),
    ).thenAnswer((_) async => true);
    when(
      mockMemPlusRepository.pullProductionDataFromCloud(),
    ).thenAnswer((_) async => const Right(null));
    when(
      mockMemPlusRepository.pullIdentityFromCloud(),
    ).thenAnswer((_) async => const Right(null));
    when(
      mockMemPlusRepository.pullCertificatesFromCloud(),
    ).thenAnswer((_) async => const Right([]));
    when(
      mockMemPlusRepository.pullKidsProgressFromCloud(),
    ).thenAnswer((_) async => const Right(null));
    when(
      mockMemPlusRepository.resyncProductionDataToCloud(),
    ).thenAnswer((_) async => const Right(null));
    when(
      mockMemPlusRepository.claimLocalReviewRecords(),
    ).thenAnswer((_) async => const Right(0));
    when(
      mockMemPlusRepository.hasPendingCloudWork(),
    ).thenAnswer((_) async => true);
    when(
      mockMemPlusRepository.syncKidsProgressToCloud(),
    ).thenAnswer((_) async => const Right(null));
    when(
      mockMemPlusRepository.pushIdentityToCloud(),
    ).thenAnswer((_) async => const Right(null));
    when(
      mockMemPlusRepository.pushCertificatesToCloud(any),
    ).thenAnswer((_) async => const Right(null));
    when(
      mockAchievementService.getAllEarnedCertificates(),
    ).thenReturn(const []);
    when(
      mockAchievementService.mergeEarnedFromCloud(
        any,
        isKids: anyNamed('isKids'),
      ),
    ).thenAnswer((_) async => 0);
    when(
      mockAchievementService.checkAndUnlockCertificates(
        isKids: anyNamed('isKids'),
      ),
    ).thenAnswer((_) async => const []);
  });

  tearDown(() {
    progressEvents.dispose();
    authStreamController.close();
    passwordRecoveryStreamController.close();
  });

  test('login sync pulls before push and emits cloudPull on bus', () async {
    when(mockAuthRepository.currentUser).thenReturn(testUser);

    final reasons = <ProgressChangedReason>[];
    final sub = progressEvents.changes.listen(reasons.add);

    final cubit = AuthCubit(
      mockAuthRepository,
      mockMemPlusRepository,
      progressEvents,
      mockAchievementService,
    );
    await cubit.ensureCloudSyncComplete();
    await Future<void>.delayed(Duration.zero);

    verifyInOrder([
      mockAuthRepository.pullProgressFromCloud(),
      mockMemPlusRepository.pullIdentityFromCloud(),
      mockMemPlusRepository.pullProductionDataFromCloud(),
      mockMemPlusRepository.pullCertificatesFromCloud(),
      mockMemPlusRepository.pullKidsProgressFromCloud(),
      mockAuthRepository.syncProgressToCloud(),
      mockMemPlusRepository.resyncProductionDataToCloud(),
    ]);
    expect(reasons, contains(ProgressChangedReason.cloudPull));

    await sub.cancel();
    await cubit.close();
  });

  test(
    'automatic login sync does not claim local guest review records',
    () async {
      when(mockAuthRepository.currentUser).thenReturn(testUser);

      final cubit = AuthCubit(
        mockAuthRepository,
        mockMemPlusRepository,
        progressEvents,
        mockAchievementService,
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(mockMemPlusRepository.claimLocalReviewRecords());
      await cubit.close();
    },
  );

  test(
    'explicit guest migration delegates to the memorization repository',
    () async {
      when(mockAuthRepository.currentUser).thenReturn(testUser);
      when(
        mockMemPlusRepository.claimLocalReviewRecords(),
      ).thenAnswer((_) async => const Right(2));
      final cubit = AuthCubit(
        mockAuthRepository,
        mockMemPlusRepository,
        progressEvents,
        mockAchievementService,
      );

      final claim = await cubit.importGuestReviewRecords();

      expect(claim, const Right(2));
      verify(mockMemPlusRepository.claimLocalReviewRecords()).called(1);
      await cubit.close();
    },
  );

  test(
    'cold start runs cloud sync once when auth stream replays session',
    () async {
      when(mockAuthRepository.currentUser).thenReturn(testUser);

      final cubit = AuthCubit(
        mockAuthRepository,
        mockMemPlusRepository,
        progressEvents,
        mockAchievementService,
      );
      await Future<void>.delayed(Duration.zero);

      authStreamController.add(testUser);
      await Future<void>.delayed(Duration.zero);

      verify(mockAuthRepository.pullProgressFromCloud()).called(1);

      await cubit.close();
    },
  );

  test('concurrent sync calls share one in-flight operation', () async {
    when(mockAuthRepository.currentUser).thenReturn(testUser);
    final pullGate = Completer<void>();
    when(mockAuthRepository.pullProgressFromCloud()).thenAnswer((_) async {
      await pullGate.future;
      return const Right(unit);
    });

    final cubit = AuthCubit(
      mockAuthRepository,
      mockMemPlusRepository,
      progressEvents,
      mockAchievementService,
    );
    cubit.resyncOnResume();
    cubit.resyncOnResume();
    pullGate.complete();
    await Future<void>.delayed(Duration.zero);

    verify(mockAuthRepository.pullProgressFromCloud()).called(1);
    await cubit.close();
  });

  test(
    'explicit sign-out flushes memorization work before invalidating auth',
    () async {
      when(
        mockAuthRepository.signOut(),
      ).thenAnswer((_) async => const Right(unit));
      when(mockAuthRepository.currentUser).thenReturn(null);
      var memPending = true;
      var authPending = true;
      when(mockMemPlusRepository.hasPendingCloudWork()).thenAnswer((_) async {
        return memPending;
      });
      when(mockMemPlusRepository.resyncProductionDataToCloud()).thenAnswer((
        _,
      ) async {
        memPending = false;
        return const Right(null);
      });
      when(mockAuthRepository.hasPendingCloudPush()).thenAnswer((_) async {
        return authPending;
      });
      when(mockAuthRepository.syncProgressToCloud()).thenAnswer((_) async {
        authPending = false;
        return const Right(unit);
      });

      final cubit = AuthCubit(
        mockAuthRepository,
        mockMemPlusRepository,
        progressEvents,
        mockAchievementService,
      );

      await cubit.signOut();

      verifyInOrder([
        mockMemPlusRepository.hasPendingCloudWork(),
        mockMemPlusRepository.resyncProductionDataToCloud(),
        mockMemPlusRepository.syncKidsProgressToCloud(),
        mockAuthRepository.signOut(),
      ]);
      await cubit.close();
    },
  );

  test('certificate pull retry restores awards from cloud', () async {
    when(mockAuthRepository.currentUser).thenReturn(testUser);
    final awards = [
      CertificateAward(
        id: 'juz-1',
        titleAr: 'جزء 1',
        type: CertificateType.juz,
        earnedAt: DateTime.utc(2026, 1, 1),
      ),
    ];
    when(
      mockMemPlusRepository.pullCertificatesFromCloud(),
    ).thenAnswer((_) async => Right(awards));

    final cubit = AuthCubit(
      mockAuthRepository,
      mockMemPlusRepository,
      progressEvents,
      mockAchievementService,
    );
    await Future<void>.delayed(Duration.zero);
    reset(mockMemPlusRepository);
    reset(mockAchievementService);
    when(
      mockMemPlusRepository.pullCertificatesFromCloud(),
    ).thenAnswer((_) async => Right(awards));
    when(
      mockAchievementService.mergeEarnedFromCloud(
        any,
        isKids: anyNamed('isKids'),
      ),
    ).thenAnswer((_) async => 1);
    when(
      mockAchievementService.checkAndUnlockCertificates(
        isKids: anyNamed('isKids'),
      ),
    ).thenAnswer((_) async => const []);

    final ok = await cubit.retryQueueKindForTesting(
      CloudSyncQueueKind.certificatePull,
    );

    expect(ok, isTrue);
    verify(mockMemPlusRepository.pullCertificatesFromCloud()).called(1);
    verify(
      mockAchievementService.mergeEarnedFromCloud(awards, isKids: false),
    ).called(1);
    await cubit.close();
  });
}
