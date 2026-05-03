import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([this.message = '']);
  final String message;

  @override
  List<Object> get props => [message];

  /// SECURITY: Only expose the human-readable message, not class internals
  @override
  String toString() => message;
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}

class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Parse error']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown error']);
}
