import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/parent_pin_recovery_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/parent_pin_recovery_repository.dart';

void main() {
  late List<(String, Map<String, Object?>)> calls;
  late Object? Function(String function) answer;
  late List<String> savedPins;
  late Either<Failure, PinRecoveryRpc> Function() rpc;

  ParentPinRecoveryService service() => ParentPinRecoveryService(
    rpc: () => rpc(),
    deviceId: () async => 'device-1',
    setPin: (pin) async {
      savedPins.add(pin);
      return const Right(null);
    },
  );

  setUp(() {
    calls = [];
    savedPins = [];
    answer = (_) => null;
    rpc = () => Right((function, params) async {
      calls.add((function, params));
      final value = answer(function);
      if (value is Exception) throw value;
      return value;
    });
  });

  group('child side', () {
    test('a request carries this device and returns the challenge', () async {
      answer = (_) => {
        'challenge_id': 'c-1',
        'expires_at': '2026-10-05T19:10:00Z',
      };

      final result = await service().requestPinRecovery();

      expect(
        result,
        Right<Failure, PinRecoveryChallenge>(
          PinRecoveryChallenge(
            id: 'c-1',
            expiresAt: DateTime.utc(2026, 10, 5, 19, 10),
          ),
        ),
      );
      expect(calls.single.$1, 'request_parent_pin_recovery');
      expect(calls.single.$2, {'p_device_id': 'device-1'});
    });

    test('a child without a guardian link gets a clear message', () async {
      answer = (_) =>
          const PostgrestException(message: 'No active guardian link');

      final result = await service().requestPinRecovery();

      expect(
        result.fold((f) => f.message, (_) => null),
        CubitMessageCodes.pinRecoveryUnavailable,
      );
    });

    test('no cloud means no call', () async {
      rpc = () =>
          const Left(NetworkFailure(CubitMessageCodes.guardianSignInRequired));

      final result = await service().requestPinRecovery();

      expect(
        result.fold((f) => f.message, (_) => null),
        CubitMessageCodes.guardianSignInRequired,
      );
      expect(calls, isEmpty);
    });

    test('an accepted code sets the new PIN', () async {
      answer = (_) => true;

      final result = await service().completePinRecovery(
        challengeId: 'c-1',
        code: 'abcd-ef12 3456',
        newPin: '2468',
      );

      expect(result, const Right<Failure, bool>(true));
      expect(calls.single.$1, 'consume_parent_pin_recovery');
      expect(calls.single.$2, {
        'p_challenge_id': 'c-1',
        'p_device_id': 'device-1',
        'p_code': 'ABCDEF123456',
      });
      expect(savedPins, ['2468']);
    });

    test('a rejected code keeps the old PIN', () async {
      answer = (_) => false;

      final result = await service().completePinRecovery(
        challengeId: 'c-1',
        code: 'ABCDEF123456',
        newPin: '2468',
      );

      expect(result, const Right<Failure, bool>(false));
      expect(savedPins, isEmpty);
    });

    test('a code that cannot be one the server issued is not sent', () async {
      final result = await service().completePinRecovery(
        challengeId: 'c-1',
        code: '1234',
        newPin: '2468',
      );

      expect(result, const Right<Failure, bool>(false));
      expect(calls, isEmpty);
    });
  });

  group('guardian side', () {
    test('open requests skip malformed rows', () async {
      answer = (_) => [
        {'challenge_id': 'c-1', 'expires_at': '2026-10-05T19:10:00Z'},
        {'challenge_id': 7},
      ];

      final result = await service().pendingPinRecoveries('child-1');

      expect(result.getOrElse(() => []).map((c) => c.id), ['c-1']);
      expect(calls.single.$2, {'p_child_user_id': 'child-1'});
    });

    test('approval returns the one-time code', () async {
      answer = (_) => 'ABCDEF123456';

      final result = await service().approvePinRecovery('c-1');

      expect(result, const Right<Failure, String>('ABCDEF123456'));
      expect(calls.single.$1, 'approve_parent_pin_recovery');
    });

    test('an expired request is reported, not thrown', () async {
      answer = (_) =>
          const PostgrestException(message: 'Recovery request unavailable');

      final result = await service().approvePinRecovery('c-1');

      expect(
        result.fold((f) => f.message, (_) => null),
        CubitMessageCodes.pinRecoveryUnavailable,
      );
    });
  });
}
