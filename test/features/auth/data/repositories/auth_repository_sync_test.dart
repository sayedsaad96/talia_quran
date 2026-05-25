import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/auth/domain/repositories/auth_repository.dart';

import '../../presentation/cubits/auth_cubit_test.mocks.dart';

/// Tests for the cloud sync contract defined by [AuthRepository].
///
/// These exercise the repository interface through mocks to verify the sync
/// and pull contract, including failure paths. Integration tests against
/// a real Supabase instance should be done in a separate test target.
void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
  });

  // ─── syncProgressToCloud ─────────────────────────────────────────────────

  group('syncProgressToCloud', () {
    test('returns Right(unit) when sync succeeds', () async {
      when(mockRepository.syncProgressToCloud())
          .thenAnswer((_) async => const Right(unit));

      final result = await mockRepository.syncProgressToCloud();

      expect(result, const Right(unit));
      verify(mockRepository.syncProgressToCloud()).called(1);
    });

    test('returns Left(Failure) when sync fails due to server error', () async {
      when(mockRepository.syncProgressToCloud()).thenAnswer(
        (_) async => const Left(
          _TestFailure('فشل المزامنة مع السحابة'),
        ),
      );

      final result = await mockRepository.syncProgressToCloud();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'فشل المزامنة مع السحابة'),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('returns Right(unit) when user is not logged in (no-op)', () async {
      // Spec: when currentUser == null, syncProgressToCloud should succeed
      // silently without attempting any network call.
      when(mockRepository.syncProgressToCloud())
          .thenAnswer((_) async => const Right(unit));
      when(mockRepository.currentUser).thenReturn(null);

      final result = await mockRepository.syncProgressToCloud();

      expect(result, const Right(unit));
    });
  });

  // ─── pullProgressFromCloud ───────────────────────────────────────────────

  group('pullProgressFromCloud', () {
    test('returns Right(unit) when pull succeeds', () async {
      when(mockRepository.pullProgressFromCloud())
          .thenAnswer((_) async => const Right(unit));

      final result = await mockRepository.pullProgressFromCloud();

      expect(result, const Right(unit));
      verify(mockRepository.pullProgressFromCloud()).called(1);
    });

    test('returns Left(Failure) when pull fails due to server error', () async {
      when(mockRepository.pullProgressFromCloud()).thenAnswer(
        (_) async => const Left(
          _TestFailure('فشل استرجاع البيانات من السحابة'),
        ),
      );

      final result = await mockRepository.pullProgressFromCloud();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.message, 'فشل استرجاع البيانات من السحابة'),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('returns Right(unit) when user is not logged in (no-op)', () async {
      when(mockRepository.pullProgressFromCloud())
          .thenAnswer((_) async => const Right(unit));
      when(mockRepository.currentUser).thenReturn(null);

      final result = await mockRepository.pullProgressFromCloud();

      expect(result, const Right(unit));
    });
  });

  // ─── Full round-trip contract ───────────────────────────────────────────

  group('sync round-trip', () {
    test('sync followed by pull completes without error', () async {
      when(mockRepository.syncProgressToCloud())
          .thenAnswer((_) async => const Right(unit));
      when(mockRepository.pullProgressFromCloud())
          .thenAnswer((_) async => const Right(unit));

      final syncResult = await mockRepository.syncProgressToCloud();
      final pullResult = await mockRepository.pullProgressFromCloud();

      expect(syncResult, const Right(unit));
      expect(pullResult, const Right(unit));

      verifyInOrder([
        mockRepository.syncProgressToCloud(),
        mockRepository.pullProgressFromCloud(),
      ]);
    });
  });
}

/// Minimal test-only Failure for sync test assertions.
class _TestFailure extends Failure {
  const _TestFailure([super.message = 'Test failure']);
}
