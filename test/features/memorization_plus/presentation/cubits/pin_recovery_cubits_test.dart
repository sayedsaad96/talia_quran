import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/parent_pin_recovery_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/parent_pin_recovery_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/pin_recovery_approval_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/pin_recovery_request_cubit.dart';

class _MockRecovery extends Mock implements ParentPinRecoveryUsecase {}

final _challenge = PinRecoveryChallenge(
  id: 'c-1',
  expiresAt: DateTime.utc(2026, 10, 5, 19, 10),
);

void main() {
  late _MockRecovery recovery;

  setUp(() => recovery = _MockRecovery());

  group('PinRecoveryRequestCubit', () {
    Future<PinRecoveryRequestCubit> started() async {
      when(() => recovery.request()).thenAnswer((_) async => Right(_challenge));
      final cubit = PinRecoveryRequestCubit(recovery);
      await cubit.start();
      return cubit;
    }

    void answerComplete(Either<Failure, bool> result) => when(
      () => recovery.complete(
        challengeId: any(named: 'challengeId'),
        code: any(named: 'code'),
        newPin: any(named: 'newPin'),
      ),
    ).thenAnswer((_) async => result);

    test('waits for the code once the request is open', () async {
      final cubit = await started();

      expect(cubit.state.status, PinRecoveryRequestStatus.waitingForCode);
      expect(cubit.state.challenge, _challenge);
    });

    test('a failed request reports why', () async {
      when(() => recovery.request()).thenAnswer(
        (_) async =>
            const Left(ServerFailure(CubitMessageCodes.pinRecoveryUnavailable)),
      );
      final cubit = PinRecoveryRequestCubit(recovery);

      await cubit.start();

      expect(cubit.state.status, PinRecoveryRequestStatus.failed);
      expect(cubit.state.errorCode, CubitMessageCodes.pinRecoveryUnavailable);
    });

    test('a new PIN must be four digits before anything is sent', () async {
      final cubit = await started();

      await cubit.submit(code: 'ABCDEF123456', newPin: '12a');

      expect(cubit.state.status, PinRecoveryRequestStatus.pinInvalid);
      verifyNever(
        () => recovery.complete(
          challengeId: any(named: 'challengeId'),
          code: any(named: 'code'),
          newPin: any(named: 'newPin'),
        ),
      );
    });

    test('a rejected code can be retried', () async {
      final cubit = await started();
      answerComplete(const Right(false));

      await cubit.submit(code: 'ABCDEF123456', newPin: '2468');

      expect(cubit.state.status, PinRecoveryRequestStatus.wrongCode);
      expect(cubit.state.challenge, _challenge);
    });

    test('an accepted code finishes', () async {
      final cubit = await started();
      answerComplete(const Right(true));

      await cubit.submit(code: 'ABCDEF123456', newPin: '2468');

      expect(cubit.state.status, PinRecoveryRequestStatus.done);
      verify(
        () => recovery.complete(
          challengeId: 'c-1',
          code: 'ABCDEF123456',
          newPin: '2468',
        ),
      ).called(1);
    });
  });

  group('PinRecoveryApprovalCubit', () {
    test('loads the open requests', () async {
      when(
        () => recovery.pending('child-1'),
      ).thenAnswer((_) async => Right([_challenge]));
      final cubit = PinRecoveryApprovalCubit(recovery, 'child-1');

      await cubit.load();

      expect(cubit.state.requests, [_challenge]);
    });

    test('a failed read stays quiet', () async {
      when(
        () => recovery.pending('child-1'),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
      final cubit = PinRecoveryApprovalCubit(recovery, 'child-1');

      await cubit.load();

      expect(cubit.state, const PinRecoveryApprovalState());
    });

    test('approval exposes the code until dismissed', () async {
      when(
        () => recovery.pending('child-1'),
      ).thenAnswer((_) async => Right([_challenge]));
      when(
        () => recovery.approve('c-1'),
      ).thenAnswer((_) async => const Right('ABCDEF123456'));
      final cubit = PinRecoveryApprovalCubit(recovery, 'child-1');
      await cubit.load();

      await cubit.approve('c-1');
      expect(cubit.state.approvedCode, 'ABCDEF123456');

      cubit.dismissCode();
      expect(cubit.state.approvedCode, isNull);
      expect(cubit.state.requests, [_challenge]);
    });

    test('a failed approval raises a new error event', () async {
      when(() => recovery.approve('c-1')).thenAnswer(
        (_) async =>
            const Left(ServerFailure(CubitMessageCodes.pinRecoveryUnavailable)),
      );
      final cubit = PinRecoveryApprovalCubit(recovery, 'child-1');

      await cubit.approve('c-1');

      expect(cubit.state.errorCode, CubitMessageCodes.pinRecoveryUnavailable);
      expect(cubit.state.errorEventId, 1);
      expect(cubit.state.busy, isFalse);
    });
  });
}
