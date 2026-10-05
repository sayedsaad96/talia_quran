import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../../core/error/app_failure.dart';
import '../../../../../core/l10n/cubit_message_codes.dart';
import '../../../domain/repositories/parent_pin_recovery_repository.dart';

typedef PinRecoveryRpc =
    Future<Object?> Function(String function, Map<String, Object?> params);

/// Talks to the `*_parent_pin_recovery` RPCs. The server decides who may
/// request, approve and consume; this only shapes calls and results.
class ParentPinRecoveryService implements ParentPinRecoveryRepository {
  ParentPinRecoveryService({
    required Either<Failure, PinRecoveryRpc> Function() rpc,
    required Future<String> Function() deviceId,
    required Future<Either<Failure, void>> Function(String pin) setPin,
  }) : _rpc = rpc,
       _deviceId = deviceId,
       _setPin = setPin;

  final Either<Failure, PinRecoveryRpc> Function() _rpc;
  final Future<String> Function() _deviceId;
  final Future<Either<Failure, void>> Function(String pin) _setPin;

  static final _codePattern = RegExp(r'^[0-9A-F]{12}$');

  @override
  Future<Either<Failure, PinRecoveryChallenge>> requestPinRecovery() =>
      _call((rpc) async {
        final raw = await rpc('request_parent_pin_recovery', {
          'p_device_id': await _deviceId(),
        });
        final challenge = raw is Map ? _parseChallenge(raw) : null;
        if (challenge == null) throw const FormatException('challenge');
        return challenge;
      });

  @override
  Future<Either<Failure, bool>> completePinRecovery({
    required String challengeId,
    required String code,
    required String newPin,
  }) async {
    final normalized = normalizeCode(code);
    if (normalized == null) return const Right(false);
    final consumed = await _call(
      (rpc) async =>
          await rpc('consume_parent_pin_recovery', {
            'p_challenge_id': challengeId,
            'p_device_id': await _deviceId(),
            'p_code': normalized,
          }) ==
          true,
    );
    return consumed.fold((failure) async => Left(failure), (ok) async {
      if (!ok) return const Right(false);
      final saved = await _setPin(newPin);
      return saved.map((_) => true);
    });
  }

  @override
  Future<Either<Failure, List<PinRecoveryChallenge>>> pendingPinRecoveries(
    String childUserId,
  ) => _call((rpc) async {
    final raw = await rpc('get_child_pin_recovery_requests', {
      'p_child_user_id': childUserId,
    });
    if (raw is! List) return const <PinRecoveryChallenge>[];
    return raw.whereType<Map>().map(_parseChallenge).nonNulls.toList();
  });

  @override
  Future<Either<Failure, String>> approvePinRecovery(String challengeId) =>
      _call((rpc) async {
        final raw = await rpc('approve_parent_pin_recovery', {
          'p_challenge_id': challengeId,
        });
        if (raw is! String || normalizeCode(raw) == null) {
          throw const FormatException('code');
        }
        return raw;
      });

  /// The guardian's code without spaces or dashes, or null when it cannot be
  /// one the server issued (12 hex characters).
  static String? normalizeCode(String raw) {
    final code = raw.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    return _codePattern.hasMatch(code) ? code : null;
  }

  Future<Either<Failure, T>> _call<T>(
    Future<T> Function(PinRecoveryRpc rpc) body,
  ) => _rpc().fold((failure) async => Left(failure), (rpc) async {
    try {
      return Right(await body(rpc));
    } on PostgrestException catch (e) {
      return Left(_failureFor(e));
    } on FormatException {
      return const Left(
        ServerFailure(CubitMessageCodes.pinRecoveryUnavailable),
      );
    } catch (e) {
      return Left(Failure.fromCloud(e));
    }
  });

  static Failure _failureFor(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('no active guardian link') ||
        message.contains('child account required') ||
        message.contains('recovery request unavailable')) {
      return const ServerFailure(CubitMessageCodes.pinRecoveryUnavailable);
    }
    if (message.contains('not authenticated')) {
      return const NetworkFailure(CubitMessageCodes.guardianSignInRequired);
    }
    return ServerFailure.from(error);
  }

  static PinRecoveryChallenge? _parseChallenge(Map raw) {
    final id = raw['challenge_id'];
    final expiresAt = DateTime.tryParse('${raw['expires_at']}');
    if (id is! String || id.isEmpty || expiresAt == null) return null;
    return PinRecoveryChallenge(id: id, expiresAt: expiresAt.toUtc());
  }
}
