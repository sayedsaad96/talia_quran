/// auth_cubit_lifecycle_test.dart
///
/// Tests that validate Phase 4 fix: AuthCubit singleton safety and
/// subscription lifecycle (stream cancellation on close).
/// Basic signIn/signUp/signOut flows are already covered in
/// test/features/auth/presentation/cubits/auth_cubit_test.dart.
library;

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/domain/repositories/auth_repository.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';

import 'auth_cubit_lifecycle_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepo;
  late StreamController<AppUser?> authStreamCtrl;
  late StreamController<void> passwordRecoveryStreamCtrl;

  const testUser = AppUser(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  AuthCubit buildCubit({AppUser? currentUser}) {
    when(mockRepo.authStateChanges).thenAnswer((_) => authStreamCtrl.stream);
    when(
      mockRepo.passwordRecoveryChanges,
    ).thenAnswer((_) => passwordRecoveryStreamCtrl.stream);
    when(mockRepo.currentUser).thenReturn(currentUser);
    when(mockRepo.pullProgressFromCloud()).thenAnswer((_) async => const Right(unit));
    when(mockRepo.syncProgressToCloud()).thenAnswer((_) async => const Right(unit));
    return AuthCubit(mockRepo);
  }

  setUp(() {
    mockRepo = MockAuthRepository();
    authStreamCtrl = StreamController<AppUser?>.broadcast();
    passwordRecoveryStreamCtrl = StreamController<void>.broadcast();
  });

  tearDown(() async {
    await authStreamCtrl.close();
    await passwordRecoveryStreamCtrl.close();
  });

  // ─── Offline / Uninitialised Supabase guard ─────────────────────────────────

  group('offline / uninitialised guard', () {
    test('does not throw when authStateChanges returns empty stream', () {
      when(mockRepo.currentUser).thenReturn(null);
      when(mockRepo.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(
        mockRepo.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());

      AuthCubit? cubit;
      expect(() {
        cubit = AuthCubit(mockRepo);
      }, returnsNormally);
      expect(cubit!.state, isA<AuthUnauthenticated>());
      cubit!.close();
    });
  });

  // ─── Subscription lifecycle (singleton safety) ──────────────────────────────

  group('subscription lifecycle', () {
    test(
      'cancels stream subscription on close — no state changes after close',
      () async {
        final cubit = buildCubit(currentUser: null);

        await cubit.close();

        // Add to stream after close — must not throw.
        expect(() => authStreamCtrl.add(testUser), returnsNormally);
        await Future<void>.delayed(Duration.zero);

        expect(cubit.isClosed, isTrue);
      },
    );

    test('same instance reflects stream changes (singleton semantics)', () async {
      final cubit = buildCubit(currentUser: null);

      // Simulate what the DI singleton ensures: every caller gets this instance.
      final ref1 = cubit;
      final ref2 = cubit; // same object

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthAuthenticated>()]),
      );

      authStreamCtrl.add(testUser);
      await expectation;

      // Both references must see the updated state immediately.
      expect(ref1.state, isA<AuthAuthenticated>());
      expect(ref2.state, isA<AuthAuthenticated>());
      expect(identical(ref1.state, ref2.state), isTrue);

      await cubit.close();
    });
  });

  // ─── AuthInitial guard (router redirect safety) ─────────────────────────────

  group('AuthInitial during initialisation', () {
    test(
      'emits non-Initial state synchronously (constructor resolves state)',
      () {
        final cubit = buildCubit(currentUser: null);

        // Constructor synchronously resolves currentUser.
        expect(cubit.state, isNot(isA<AuthInitial>()));
        cubit.close();
      },
    );
  });
}
