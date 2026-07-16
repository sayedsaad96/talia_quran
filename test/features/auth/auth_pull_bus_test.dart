import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
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

    when(mockAuthRepository.authStateChanges)
        .thenAnswer((_) => authStreamController.stream);
    when(mockAuthRepository.passwordRecoveryChanges)
        .thenAnswer((_) => passwordRecoveryStreamController.stream);
    when(mockAuthRepository.pullProgressFromCloud())
        .thenAnswer((_) async => const Right(unit));
    when(mockAuthRepository.syncProgressToCloud())
        .thenAnswer((_) async => const Right(unit));
    when(mockAuthRepository.hasPendingCloudPush())
        .thenAnswer((_) async => true);
    when(mockMemPlusRepository.pullProductionDataFromCloud())
        .thenAnswer((_) async => const Right(null));
    when(mockMemPlusRepository.resyncProductionDataToCloud())
        .thenAnswer((_) async => const Right(null));
    when(mockMemPlusRepository.hasPendingCloudWork())
        .thenAnswer((_) async => true);
    when(mockAchievementService.getAllEarnedCertificates()).thenReturn(const []);
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
    await Future<void>.delayed(Duration.zero);

    verifyInOrder([
      mockAuthRepository.pullProgressFromCloud(),
      mockMemPlusRepository.pullProductionDataFromCloud(),
      mockAuthRepository.syncProgressToCloud(),
      mockMemPlusRepository.resyncProductionDataToCloud(),
    ]);
    expect(reasons, contains(ProgressChangedReason.cloudPull));

    await sub.cancel();
    await cubit.close();
  });

  test('cold start runs cloud sync once when auth stream replays session', () async {
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
  });

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
}
