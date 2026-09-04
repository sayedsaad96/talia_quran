part of 'auth_cubit.dart';

@immutable
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Local owner cleanup failed; account data is not ready for navigation.
class AuthOwnerDataFailure extends AuthState {
  const AuthOwnerDataFailure();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});
  final AppUser user;
  @override
  List<Object?> get props => [user];
}

class AuthAccountDataDiscarded extends AuthAuthenticated {
  const AuthAccountDataDiscarded({required super.user});
}

class AuthSignOutBlockedPendingData extends AuthAuthenticated {
  const AuthSignOutBlockedPendingData({required super.user});
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAccountDeleted extends AuthState {
  const AuthAccountDeleted();
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

class AuthPasswordRecoveryDetected extends AuthState {
  const AuthPasswordRecoveryDetected();
}

class AuthPasswordUpdated extends AuthState {
  const AuthPasswordUpdated();
}

class AuthResendConfirmationSuccess extends AuthState {
  const AuthResendConfirmationSuccess();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
