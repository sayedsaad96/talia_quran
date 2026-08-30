import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/auth/application/cloud_sync_coordinator.dart';
import 'package:talia_quran/features/auth/domain/entities/auth_session_recovery.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/domain/repositories/auth_repository.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';

import 'auth_cubit_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;
  late StreamController<AppUser?> authStreamController;
  late StreamController<void> passwordRecoveryStreamController;

  const testUser = AppUser(
    id: 'test-uid-1',
    email: 'test@talia.app',
    displayName: 'اختبار',
  );

  /// Helper: creates a cubit with no current user (typical unauthenticated state).
  AuthCubit buildCubit({
    AppUser? currentUser,
    CloudSyncCoordinator? cloudSyncCoordinator,
  }) {
    when(
      mockAuthRepository.authStateChanges,
    ).thenAnswer((_) => authStreamController.stream);
    when(
      mockAuthRepository.passwordRecoveryChanges,
    ).thenAnswer((_) => passwordRecoveryStreamController.stream);
    when(mockAuthRepository.currentUser).thenReturn(currentUser);
    when(
      mockAuthRepository.pullProgressFromCloud(),
    ).thenAnswer((_) async => const Right(unit));
    when(
      mockAuthRepository.syncProgressToCloud(),
    ).thenAnswer((_) async => const Right(unit));
    when(
      mockAuthRepository.hasPendingCloudPush(),
    ).thenAnswer((_) async => false);
    return AuthCubit(
      mockAuthRepository,
      null,
      null,
      null,
      null,
      null,
      null,
      cloudSyncCoordinator,
    );
  }

  setUp(() {
    authStreamController = StreamController<AppUser?>.broadcast();
    passwordRecoveryStreamController = StreamController<void>.broadcast();
    mockAuthRepository = MockAuthRepository();
  });

  tearDown(() async {
    await authStreamController.close();
    await passwordRecoveryStreamController.close();
  });

  // ─── Initial State ──────────────────────────────────────────────────────────

  group('initial state', () {
    test('emits AuthUnauthenticated when no current user', () {
      final cubit = buildCubit(currentUser: null);
      expect(cubit.state, isA<AuthUnauthenticated>());
      cubit.close();
    });

    test('emits AuthAuthenticated when a user is already logged in', () {
      final cubit = buildCubit(currentUser: testUser);
      expect(cubit.state, isA<AuthAuthenticated>());
      expect((cubit.state as AuthAuthenticated).user, equals(testUser));
      cubit.close();
    });
  });

  // ─── Auth Stream ────────────────────────────────────────────────────────────

  group('auth stream', () {
    test('transitions to AuthAuthenticated when stream emits a user', () async {
      final cubit = buildCubit(currentUser: null);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthAuthenticated>()]),
      );

      authStreamController.add(testUser);
      await expectation;
      await cubit.close();
    });

    test('transitions to AuthUnauthenticated when stream emits null', () async {
      final cubit = buildCubit(currentUser: testUser);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthUnauthenticated>()]),
      );

      authStreamController.add(null);
      await expectation;
      await cubit.close();
    });

    test('transitions to PasswordRecoveryDetected on recovery event', () async {
      final cubit = buildCubit(currentUser: null);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthPasswordRecoveryDetected>()]),
      );

      passwordRecoveryStreamController.add(null);
      await expectation;
      await cubit.close();
    });

    test(
      'terminal auth recovery opens a new session generation for the same owner',
      () async {
        AppUser? currentUser = testUser;
        when(mockAuthRepository.currentUser).thenAnswer((_) => currentUser);
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
        final recoveryFinished = Completer<void>();
        when(mockAuthRepository.recoverSessionAfterAuthError(any)).thenAnswer((
          _,
        ) async {
          currentUser = null;
          recoveryFinished.complete();
          return AuthSessionRecovery.terminalFailure;
        });
        final cubit = AuthCubit(mockAuthRepository);
        addTearDown(cubit.close);
        await cubit.ensureCloudSyncComplete();

        authStreamController.addError(StateError('expired session'));
        await recoveryFinished.future;
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state, isA<AuthUnauthenticated>());

        currentUser = testUser;
        authStreamController.add(testUser);
        await Future<void>.delayed(Duration.zero);
        await cubit.ensureCloudSyncComplete();

        verify(mockAuthRepository.pullProgressFromCloud()).called(2);
      },
    );
  });

  test(
    'credential-changing auth paths raise the identity gate before repository calls',
    () async {
      AppUser? currentUser;
      when(mockAuthRepository.currentUser).thenAnswer((_) => currentUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => authStreamController.stream);
      when(
        mockAuthRepository.passwordRecoveryChanges,
      ).thenAnswer((_) => passwordRecoveryStreamController.stream);
      when(
        mockAuthRepository.hasPendingCloudPush(),
      ).thenAnswer((_) async => false);
      late final _GateTrackingCloudSyncCoordinator coordinator;
      void expectGate(String operation) {
        expect(coordinator.isGated, isTrue, reason: operation);
      }

      when(
        mockAuthRepository.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async {
        expectGate('signIn');
        currentUser = testUser;
        return const Right(testUser);
      });
      when(
        mockAuthRepository.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        ),
      ).thenAnswer((_) async {
        expectGate('signUp');
        currentUser = testUser;
        return const Right(testUser);
      });
      when(mockAuthRepository.updatePassword(any)).thenAnswer((_) async {
        expectGate('updatePassword');
        return const Right(unit);
      });
      when(mockAuthRepository.deleteAccount()).thenAnswer((_) async {
        expectGate('deleteAccount');
        return const Right(unit);
      });
      when(mockAuthRepository.signOut()).thenAnswer((_) async {
        expectGate('signOut');
        return const Right(unit);
      });
      final recoveryCalled = Completer<void>();
      when(mockAuthRepository.recoverSessionAfterAuthError(any)).thenAnswer((
        _,
      ) async {
        expectGate('auth recovery');
        recoveryCalled.complete();
        return AuthSessionRecovery.transientFailure;
      });
      coordinator = _GateTrackingCloudSyncCoordinator(mockAuthRepository);
      final cubit = AuthCubit(
        mockAuthRepository,
        null,
        null,
        null,
        null,
        null,
        null,
        coordinator,
      );
      addTearDown(cubit.close);

      await cubit.signIn(email: 'test@talia.app', password: 'password123');
      await cubit.ensureCloudSyncComplete();
      await cubit.signUp(
        email: 'test@talia.app',
        password: 'password123',
        displayName: 'اختبار',
      );
      await cubit.ensureCloudSyncComplete();
      await cubit.updatePassword('new-password');
      await cubit.deleteAccount();
      await cubit.signOut();
      authStreamController.addError(StateError('auth stream failed'));
      await recoveryCalled.future;
    },
  );

  test(
    'login routing wait started during auth transition waits for the new owner restore',
    () async {
      AppUser? currentUser;
      when(mockAuthRepository.currentUser).thenAnswer((_) => currentUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => authStreamController.stream);
      when(
        mockAuthRepository.passwordRecoveryChanges,
      ).thenAnswer((_) => passwordRecoveryStreamController.stream);
      when(
        mockAuthRepository.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async {
        currentUser = testUser;
        authStreamController.add(testUser);
        await Future<void>.delayed(Duration.zero);
        return const Right(testUser);
      });
      final restoreRelease = Completer<void>();
      final coordinator = _BlockingRunCloudSyncCoordinator(
        mockAuthRepository,
        restoreRelease.future,
      );
      final cubit = AuthCubit(
        mockAuthRepository,
        null,
        null,
        null,
        null,
        null,
        null,
        coordinator,
      );
      addTearDown(cubit.close);
      final authenticated = Completer<void>();
      Future<void>? routeWait;
      var routeWaitCompleted = false;
      final subscription = cubit.stream.listen((state) {
        if (state is! AuthAuthenticated || routeWait != null) return;
        routeWait = cubit.ensureCloudSyncComplete()
          ..then((_) {
            routeWaitCompleted = true;
          });
        authenticated.complete();
      });
      addTearDown(subscription.cancel);

      final signIn = cubit.signIn(
        email: 'test@talia.app',
        password: 'password123',
      );
      await authenticated.future;
      await Future<void>.delayed(Duration.zero);

      expect(routeWaitCompleted, isFalse);
      await signIn;
      expect(coordinator.runCallCount, 1);
      expect(routeWaitCompleted, isFalse);

      restoreRelease.complete();
      await routeWait;
      expect(routeWaitCompleted, isTrue);
    },
  );

  // ─── Sign In ────────────────────────────────────────────────────────────────

  group('signIn', () {
    late AuthCubit cubit;

    setUp(() => cubit = buildCubit(currentUser: null));
    tearDown(() => cubit.close());

    test('emits Loading then Authenticated on success', () async {
      when(
        mockAuthRepository.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async {
        authStreamController.add(testUser);
        return const Right(testUser);
      });

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );

      await cubit.signIn(email: 'test@talia.app', password: 'password123');
      await expectation;
    });

    test(
      'delayed auth listener event does not duplicate the controlled owner sync',
      () async {
        AppUser? currentUser;
        when(mockAuthRepository.currentUser).thenAnswer((_) => currentUser);
        when(
          mockAuthRepository.signIn(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async {
          currentUser = testUser;
          return const Right(testUser);
        });

        await cubit.signIn(email: 'test@talia.app', password: 'password123');
        await cubit.ensureCloudSyncComplete();
        authStreamController.add(testUser);
        await Future<void>.delayed(Duration.zero);
        await cubit.ensureCloudSyncComplete();

        verify(mockAuthRepository.pullProgressFromCloud()).called(1);
      },
    );

    test(
      'missing delayed event does not suppress same-owner reauth after null',
      () async {
        AppUser? currentUser;
        when(mockAuthRepository.currentUser).thenAnswer((_) => currentUser);
        when(
          mockAuthRepository.signIn(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async {
          currentUser = testUser;
          return const Right(testUser);
        });

        await cubit.signIn(email: 'test@talia.app', password: 'password123');
        await cubit.ensureCloudSyncComplete();

        currentUser = null;
        authStreamController.add(null);
        await Future<void>.delayed(Duration.zero);
        currentUser = testUser;
        authStreamController.add(testUser);
        await Future<void>.delayed(Duration.zero);
        await cubit.ensureCloudSyncComplete();

        verify(mockAuthRepository.pullProgressFromCloud()).called(2);
      },
    );

    test('same active owner token refresh does not repeat full sync', () async {
      AppUser? currentUser;
      when(mockAuthRepository.currentUser).thenAnswer((_) => currentUser);
      when(
        mockAuthRepository.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async {
        currentUser = testUser;
        return const Right(testUser);
      });

      await cubit.signIn(email: 'test@talia.app', password: 'password123');
      await cubit.ensureCloudSyncComplete();
      authStreamController.add(testUser); // Expected delayed sign-in event.
      await Future<void>.delayed(Duration.zero);
      await cubit.ensureCloudSyncComplete();
      authStreamController.add(testUser); // Later token refresh, same session.
      await Future<void>.delayed(Duration.zero);
      await cubit.ensureCloudSyncComplete();

      verify(mockAuthRepository.pullProgressFromCloud()).called(1);
    });

    test('owner switches reset the active auth session owner', () async {
      const otherUser = AppUser(
        id: 'test-uid-2',
        email: 'other@talia.app',
        displayName: 'آخر',
      );
      AppUser? currentUser;
      when(mockAuthRepository.currentUser).thenAnswer((_) => currentUser);
      when(
        mockAuthRepository.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async {
        currentUser = testUser;
        return const Right(testUser);
      });

      await cubit.signIn(email: 'test@talia.app', password: 'password123');
      await cubit.ensureCloudSyncComplete();
      currentUser = otherUser;
      authStreamController.add(otherUser);
      await Future<void>.delayed(Duration.zero);
      await cubit.ensureCloudSyncComplete();
      currentUser = testUser;
      authStreamController.add(testUser);
      await Future<void>.delayed(Duration.zero);
      await cubit.ensureCloudSyncComplete();

      verify(mockAuthRepository.pullProgressFromCloud()).called(3);
    });

    test('emits Loading then Error on failure', () async {
      when(
        mockAuthRepository.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('بيانات خاطئة')));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthError>()]),
      );

      await cubit.signIn(email: 'bad@bad.com', password: 'wrong');
      await expectation;
    });
  });

  // ─── Sign Up ────────────────────────────────────────────────────────────────

  group('signUp', () {
    late AuthCubit cubit;

    setUp(() => cubit = buildCubit(currentUser: null));
    tearDown(() => cubit.close());

    test('emits Loading then Authenticated on success', () async {
      when(
        mockAuthRepository.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        ),
      ).thenAnswer((_) async {
        authStreamController.add(testUser);
        return const Right(testUser);
      });

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );

      await cubit.signUp(
        email: 'new@talia.app',
        password: 'secure123',
        displayName: 'مستخدم جديد',
      );
      await expectation;
    });

    test('emits Loading then Error on failure', () async {
      when(
        mockAuthRepository.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('البريد مستخدم')));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthError>()]),
      );

      await cubit.signUp(
        email: 'existing@talia.app',
        password: 'pass',
        displayName: 'مستخدم',
      );
      await expectation;
    });
  });

  // ─── Sign Out ───────────────────────────────────────────────────────────────

  group('signOut', () {
    late AuthCubit cubit;

    setUp(() => cubit = buildCubit(currentUser: testUser));
    tearDown(() => cubit.close());

    test('emits Loading then Unauthenticated on success', () async {
      when(mockAuthRepository.signOut()).thenAnswer((_) async {
        authStreamController.add(null);
        return const Right(unit);
      });

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
      );

      await cubit.signOut();
      await expectation;
    });

    test('emits Loading then Error when signOut fails', () async {
      when(mockAuthRepository.signOut()).thenAnswer(
        (_) async => const Left(CacheFailure('خطأ في تسجيل الخروج')),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthError>()]),
      );

      await cubit.signOut();
      await expectation;
    });

    test(
      'blocks sign-out when pending cloud work remains after a failed flush',
      () async {
        when(
          mockAuthRepository.hasPendingCloudPush(),
        ).thenAnswer((_) async => true);
        when(
          mockAuthRepository.syncProgressToCloud(),
        ).thenAnswer((_) async => const Left(NetworkFailure('offline')));

        await cubit.signOut();

        expect(cubit.state, isA<AuthSignOutBlockedPendingData>());
        verifyNever(mockAuthRepository.signOut());
      },
    );

    test('force sign-out proceeds even when pending work remains', () async {
      when(
        mockAuthRepository.hasPendingCloudPush(),
      ).thenAnswer((_) async => true);
      when(mockAuthRepository.signOut(preserveAccountData: true)).thenAnswer((
        _,
      ) async {
        authStreamController.add(null);
        return const Right(unit);
      });

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
      );

      await cubit.signOut(force: true);
      await expectation;
      verify(mockAuthRepository.signOut(preserveAccountData: true)).called(1);
    });
  });

  // ─── Reset Password ────────────────────────────────────────────────────────

  group('resetPassword', () {
    late AuthCubit cubit;

    setUp(() => cubit = buildCubit(currentUser: null));
    tearDown(() => cubit.close());

    test('emits Loading then PasswordResetSent on success', () async {
      when(
        mockAuthRepository.resetPassword(any),
      ).thenAnswer((_) async => const Right(unit));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthPasswordResetSent>()]),
      );

      await cubit.resetPassword('test@talia.app');
      await expectation;
      verify(mockAuthRepository.resetPassword('test@talia.app')).called(1);
    });

    test('emits Loading then Error when reset email fails', () async {
      when(mockAuthRepository.resetPassword(any)).thenAnswer(
        (_) async => const Left(CacheFailure('تعذر إرسال رابط إعادة التعيين')),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthError>()]),
      );

      await cubit.resetPassword('missing@talia.app');
      await expectation;
    });
  });

  group('updatePassword', () {
    late AuthCubit cubit;

    setUp(() => cubit = buildCubit(currentUser: testUser));
    tearDown(() => cubit.close());

    test('emits Loading then PasswordUpdated on success', () async {
      when(
        mockAuthRepository.updatePassword(any),
      ).thenAnswer((_) async => const Right(unit));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthPasswordUpdated>()]),
      );

      await cubit.updatePassword('new-password');
      await expectation;
      verify(mockAuthRepository.updatePassword('new-password')).called(1);
    });

    test('emits Loading then Error when update fails', () async {
      when(mockAuthRepository.updatePassword(any)).thenAnswer(
        (_) async => const Left(CacheFailure('تعذر تحديث كلمة المرور')),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthError>()]),
      );

      await cubit.updatePassword('new-password');
      await expectation;
    });

    test(
      'pending cloud work blocks password update before destructive sign-out',
      () async {
        final protectedCubit = buildCubit(
          currentUser: testUser,
          cloudSyncCoordinator: _PendingWorkCloudSyncCoordinator(
            mockAuthRepository,
          ),
        );
        addTearDown(protectedCubit.close);

        final expectation = expectLater(
          protectedCubit.stream,
          emitsInOrder([isA<AuthLoading>(), isA<AuthError>()]),
        );

        await protectedCubit.updatePassword('new-password');
        await expectation;

        verifyNever(mockAuthRepository.updatePassword(any));
      },
    );
  });

  group('deleteAccount', () {
    late AuthCubit cubit;

    setUp(() => cubit = buildCubit(currentUser: testUser));
    tearDown(() => cubit.close());

    test('emits Loading then AccountDeleted on success', () async {
      when(
        mockAuthRepository.deleteAccount(),
      ).thenAnswer((_) async => const Right(unit));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAccountDeleted>()]),
      );

      await cubit.deleteAccount();
      await expectation;
    });

    test('emits Loading then Error when deletion fails', () async {
      when(mockAuthRepository.deleteAccount()).thenAnswer(
        (_) async => const Left(CacheFailure('delete_current_user غير مفعلة')),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthError>()]),
      );

      await cubit.deleteAccount();
      await expectation;
    });
  });

  // ─── Parent Mode production resync (Phase 7) ───────────────────────────────

  group('production data resync', () {
    test(
      'pushes streak/heatmap and production data on session restore',
      () async {
        when(
          mockAuthRepository.pullProgressFromCloud(),
        ).thenAnswer((_) async => const Right(unit));
        when(
          mockAuthRepository.syncProgressToCloud(),
        ).thenAnswer((_) async => const Right(unit));
        when(mockAuthRepository.currentUser).thenReturn(testUser);
        when(
          mockAuthRepository.authStateChanges,
        ).thenAnswer((_) => authStreamController.stream);
        when(
          mockAuthRepository.passwordRecoveryChanges,
        ).thenAnswer((_) => passwordRecoveryStreamController.stream);
        final memPlusRepository = _FakeMemPlusRepository();

        final cubit = AuthCubit(mockAuthRepository, memPlusRepository);
        await Future<void>.delayed(Duration.zero);

        verify(mockAuthRepository.pullProgressFromCloud()).called(1);
        verify(mockAuthRepository.syncProgressToCloud()).called(1);
        expect(memPlusRepository.pullCallCount, 1);
        expect(memPlusRepository.resyncCallCount, 1);
        await cubit.close();
      },
    );

    test('resyncOnResume re-syncs while authenticated', () async {
      when(
        mockAuthRepository.pullProgressFromCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(
        mockAuthRepository.syncProgressToCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(
        mockAuthRepository.hasPendingCloudPush(),
      ).thenAnswer((_) async => true);
      when(mockAuthRepository.currentUser).thenReturn(testUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => authStreamController.stream);
      when(
        mockAuthRepository.passwordRecoveryChanges,
      ).thenAnswer((_) => passwordRecoveryStreamController.stream);
      final memPlusRepository = _FakeMemPlusRepository();

      final cubit = AuthCubit(mockAuthRepository, memPlusRepository);
      await Future<void>.delayed(Duration.zero);

      cubit.resyncOnResume();
      await Future<void>.delayed(Duration.zero);

      verify(mockAuthRepository.pullProgressFromCloud()).called(2);
      verify(mockAuthRepository.syncProgressToCloud()).called(2);
      expect(memPlusRepository.pullCallCount, 2);
      expect(memPlusRepository.resyncCallCount, 2);
      await cubit.close();
    });

    test('resyncOnResume is a no-op while unauthenticated', () async {
      final cubit = buildCubit(currentUser: null);
      final memPlusRepository = _FakeMemPlusRepository();
      await cubit.close();

      final signedOutCubit = AuthCubit(mockAuthRepository, memPlusRepository);
      signedOutCubit.resyncOnResume();
      await Future<void>.delayed(Duration.zero);

      expect(memPlusRepository.resyncCallCount, 0);
      await signedOutCubit.close();
    });
  });
}

class _FakeMemPlusRepository implements MemorizationPlusRepository {
  int resyncCallCount = 0;
  int pullCallCount = 0;

  @override
  Future<Either<Failure, void>> pullProductionDataFromCloud() async {
    pullCallCount += 1;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> pullIdentityFromCloud() async =>
      const Right(null);

  @override
  Future<Either<Failure, List<CertificateAward>>>
  pullCertificatesFromCloud() async => const Right([]);

  @override
  Future<Either<Failure, void>> pullKidsProgressFromCloud() async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> syncKidsProgressToCloud() async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> pushCertificatesToCloud(
    List<CertificateAward> certificates,
  ) async => const Right(null);

  @override
  Future<bool> hasPendingCloudWork() async => true;

  @override
  Future<Either<Failure, void>> resyncProductionDataToCloud() async {
    resyncCallCount += 1;
    return const Right(null);
  }

  @override
  Future<Either<Failure, int>> claimLocalReviewRecords() async =>
      const Right(0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GateTrackingCloudSyncCoordinator extends CloudSyncCoordinator {
  _GateTrackingCloudSyncCoordinator(AuthRepository authRepository)
    : super(authRepository: authRepository);

  var _depth = 0;

  bool get isGated => _depth > 0;

  @override
  Future<void> beginIdentityTransition() async {
    _depth += 1;
  }

  @override
  void endIdentityTransition() {
    if (_depth == 0) throw StateError('Unbalanced test identity gate');
    _depth -= 1;
  }

  @override
  Future<bool> flushBeforeSignOut() async => true;

  @override
  Future<void> run() async {}
}

class _PendingWorkCloudSyncCoordinator extends CloudSyncCoordinator {
  _PendingWorkCloudSyncCoordinator(AuthRepository authRepository)
    : super(authRepository: authRepository);

  @override
  Future<bool> flushBeforeSignOut() async => false;
}

class _BlockingRunCloudSyncCoordinator extends CloudSyncCoordinator {
  _BlockingRunCloudSyncCoordinator(
    AuthRepository authRepository,
    this._runRelease,
  ) : super(authRepository: authRepository);

  final Future<void> _runRelease;
  var runCallCount = 0;

  @override
  Future<void> run() {
    runCallCount += 1;
    return _runRelease;
  }
}
