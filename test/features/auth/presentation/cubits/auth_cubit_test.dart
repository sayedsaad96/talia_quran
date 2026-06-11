import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/domain/repositories/auth_repository.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';

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
  AuthCubit buildCubit({AppUser? currentUser}) {
    when(
      mockAuthRepository.authStateChanges,
    ).thenAnswer((_) => authStreamController.stream);
    when(
      mockAuthRepository.passwordRecoveryChanges,
    ).thenAnswer((_) => passwordRecoveryStreamController.stream);
    when(mockAuthRepository.currentUser).thenReturn(currentUser);
    return AuthCubit(mockAuthRepository);
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
  });

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
}
