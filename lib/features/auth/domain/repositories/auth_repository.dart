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

  /// Sync local progress to cloud
  Future<Either<Failure, Unit>> syncProgressToCloud();

  /// Pull progress from cloud
  Future<Either<Failure, Unit>> pullProgressFromCloud();

  /// Current user (null = not logged in)
  AppUser? get currentUser;

  /// Stream for tracking auth state
  Stream<AppUser?> get authStateChanges;
}
