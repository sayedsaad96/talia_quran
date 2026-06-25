import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  /// Sign up with email & password
  Future<Either<Failure, AppUser>> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign in with email & password
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  });

  /// Sign out
  Future<Either<Failure, Unit>> signOut();

  /// Delete the currently signed-in Supabase account.
  ///
  /// This requires the `delete_current_user` RPC to be deployed in Supabase.
  Future<Either<Failure, Unit>> deleteAccount();

  /// Sync local progress to cloud
  Future<Either<Failure, Unit>> syncProgressToCloud();

  /// Pull progress from cloud
  Future<Either<Failure, Unit>> pullProgressFromCloud();

  /// Resend confirmation email
  Future<Either<Failure, Unit>> resendConfirmation(String email);

  /// Send a password reset email
  Future<Either<Failure, Unit>> resetPassword(String email);

  /// Update the current recovery/session user's password
  Future<Either<Failure, Unit>> updatePassword(String newPassword);

  /// Current user (null = not logged in)
  AppUser? get currentUser;

  /// Stream for tracking auth state
  Stream<AppUser?> get authStateChanges;

  /// Emits when Supabase opens the app from a password recovery link.
  Stream<void> get passwordRecoveryChanges;
}
