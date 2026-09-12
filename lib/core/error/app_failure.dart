import 'package:equatable/equatable.dart';

import '../l10n/cubit_message_codes.dart';
import '../utils/talia_logger.dart';

/// Base failure type for the app.
///
/// [message] carries a **stable message code** (see [CubitMessageCodes]),
/// never raw exception text — UI resolves codes via
/// `context.localizedCubitMessage`. Use the `.from` factories to convert
/// caught exceptions; they log the technical detail and emit a safe code.
abstract class Failure extends Equatable {
  const Failure([this.message = CubitMessageCodes.errorUnknown]);

  final String message;

  @override
  List<Object> get props => [message];

  /// SECURITY: Only expose the human-readable message, not class internals
  @override
  String toString() => message;

  /// Classifies cloud/remote exceptions into [ServerFailure] (for PostgREST/DB/server errors)
  /// or [NetworkFailure] (for connectivity/socket/timeout issues).
  static Failure fromCloud(Object error, [StackTrace? stackTrace]) {
    final str = error.toString();
    if (str.contains('PostgrestException') || str.contains('AuthException')) {
      return ServerFailure.from(error, stackTrace);
    }
    return NetworkFailure.from(error, stackTrace);
  }
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = CubitMessageCodes.errorCache]);

  static CacheFailure from(Object error, [StackTrace? stackTrace]) {
    TaliaLogger.e('CacheFailure', error, stackTrace);
    return const CacheFailure();
  }
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = CubitMessageCodes.errorServer]);

  static ServerFailure from(Object error, [StackTrace? stackTrace]) {
    TaliaLogger.e('ServerFailure', error, stackTrace);
    return const ServerFailure();
  }
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = CubitMessageCodes.errorNetwork]);

  static NetworkFailure from(Object error, [StackTrace? stackTrace]) {
    TaliaLogger.e('NetworkFailure', error, stackTrace);
    return const NetworkFailure();
  }
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = CubitMessageCodes.errorNotFound]);
}

class ParseFailure extends Failure {
  const ParseFailure([super.message = CubitMessageCodes.errorParse]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = CubitMessageCodes.errorUnknown]);

  static UnknownFailure from(Object error, [StackTrace? stackTrace]) {
    TaliaLogger.e('UnknownFailure', error, stackTrace);
    return const UnknownFailure();
  }
}
