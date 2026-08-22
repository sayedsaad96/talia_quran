import 'package:flutter/foundation.dart';

import 'package:dartz/dartz.dart';

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_session_recovery.dart';

import '../../domain/repositories/auth_repository.dart';

import '../../../../core/progress/progress_changed_reason.dart';

import '../../../../core/progress/progress_events_bus.dart';

import '../../../../core/sync/cloud_sync_queue.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/account_data_reset.dart';

import '../../../../core/error/app_failure.dart';

import '../../../../core/services/achievement_service.dart';

import '../../../../core/utils/talia_logger.dart';

import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';

import '../../application/cloud_sync_coordinator.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._authRepository, [

    this._memPlusRepository,

    this._progressEvents,

    AchievementService? achievementService,

    CloudSyncQueue? cloudSyncQueue,

    this._prefs,

    this._accountDataReset,

    CloudSyncCoordinator? cloudSyncCoordinator,
  ]) : _cloudSyncCoordinator =
           cloudSyncCoordinator ??
           CloudSyncCoordinator(
             authRepository: _authRepository,
             memorizationCloudRepository: _memPlusRepository,
             progressEvents: _progressEvents,
             achievementService: achievementService,
             cloudSyncQueue: cloudSyncQueue,
           ),
       super(const AuthInitial()) {
    // Listen to Supabase auth state changes.

    // Every time a session becomes active (new login OR session restored on

    // app restart), pull the user's cloud data so local Isar is up-to-date.

    _authSub = _authRepository.authStateChanges.listen(
      (user) {
        if (isClosed) return;

      // Skip auth state changes triggered during the password update flow;

      // the cubit emits AuthPasswordUpdated explicitly after the repository

      // completes its combined updateUser + signOut operation.

      if (_isUpdatingPassword) return;

        if (user != null) {
          emit(AuthAuthenticated(user: user));

        // Cold start already synced from [currentUser]; skip duplicate auth event.

          if (_skipNextAuthSync) {
            _skipNextAuthSync = false;

            return;
          }

          unawaited(_runCloudSync());
        } else {
          emit(const AuthUnauthenticated());
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        unawaited(_recoverFromAuthStreamError(error, stackTrace));
      },
    );

    _passwordRecoverySub = _authRepository.passwordRecoveryChanges.listen(
      (_) {
        if (isClosed) return;

        emit(const AuthPasswordRecoveryDetected());
      },
      onError: (Object error, StackTrace stackTrace) {
        unawaited(_recoverFromAuthStreamError(error, stackTrace));
      },
    );

    // Set initial state immediately from cached Supabase session.

    // If a session already exists (e.g. app restarted without reinstall),

    // pull cloud data once so any remote changes are reflected locally.

    final currentUser = _authRepository.currentUser;

    if (currentUser != null) {
      emit(AuthAuthenticated(user: currentUser));

      _skipNextAuthSync = true;

      unawaited(_runCloudSync());
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _runCloudSync() {
    _syncInFlight ??= _handleAccountOwnerChange()
        .then((_) => _cloudSyncCoordinator.run())
        .catchError((Object error, StackTrace stackTrace) {
          TaliaLogger.e('Unexpected cloud sync failure', error, stackTrace);
        })
        .whenComplete(() => _syncInFlight = null);

    return _syncInFlight!;
  }

  /// Returns a Future that completes when the in-flight cloud sync finishes.
  ///
  /// On login the UI awaits this before routing, so the restored profile is
  /// available by the time routing logic reads it. On cold start this is not
  /// awaited (local data is still on-device).
  Future<void> ensureCloudSyncComplete() => _syncInFlight ?? Future.value();

  static const lastSignedInUserIdKey = 'auth_last_signed_in_user_id';

  /// Decides whether [userId] is a different account than the one last seen on
  /// this device, and clears the departing account's data if so.
  ///
  /// Returns true when a switch was detected and the wipe ran. The last-seen id
  /// is persisted because the process restarts between sessions, so an
  /// in-memory value would treat every cold start as a first sign-in.
  static Future<bool> resolveOwnerChange({
    required SharedPreferences prefs,
    required String userId,
    required Future<void> Function() onDepartingAccount,
    Future<void> Function(String departingOwnerId)? onDepartingOwner,
  }) async {
    final previous = prefs.getString(lastSignedInUserIdKey);
    final changed = previous != null && previous != userId;
    if (changed) {
      if (onDepartingOwner != null) {
        await onDepartingOwner(previous);
      } else {
        await onDepartingAccount();
      }
    }
    await prefs.setString(lastSignedInUserIdKey, userId);
    return changed;
  }

  Future<void> _handleAccountOwnerChange() async {
    final prefs = _prefs;

    final reset = _accountDataReset;

    final userId = _authRepository.currentUser?.id;

    if (prefs != null && reset != null && userId != null) {
      final switched = await resolveOwnerChange(
        prefs: prefs,

        userId: userId,

        onDepartingAccount: reset.clearAccountOwnedData,
        onDepartingOwner: (departingOwnerId) =>
            reset.clearAccountOwnedData(departingOwnerId: departingOwnerId),
      );

      if (switched) {
        TaliaLogger.i(
          'Account switch detected; cleared departing account data',
        );

        _progressEvents?.notify(ProgressChangedReason.certificate);
        emit(AuthAccountDataDiscarded(user: _authRepository.currentUser!));
      }
    }
  }

  Future<bool> _flushBeforeExplicitSignOut() async {
    return _cloudSyncCoordinator.flushBeforeSignOut();
  }

  @visibleForTesting
  Future<bool> retryQueueKindForTesting(String kind) =>
      _cloudSyncCoordinator.retryQueueKindForTesting(kind);

  /// Public entry point for app-lifecycle-triggered resync (e.g. on app
  /// resume). Runs only when the outbox has pending work or a pull cursor
  /// is stale; debounced to avoid resume storms.
  void resyncOnResume({bool force = false}) {
    if (state is! AuthAuthenticated) return;
    unawaited(_cloudSyncCoordinator.resumeIfNeeded(force: force));
  }

  final AuthRepository _authRepository;

  final MemorizationPlusRepository? _memPlusRepository;

  final ProgressEventsBus? _progressEvents;

  final SharedPreferences? _prefs;

  final AccountDataReset? _accountDataReset;

  final CloudSyncCoordinator _cloudSyncCoordinator;

  StreamSubscription<AppUser?>? _authSub;

  StreamSubscription<void>? _passwordRecoverySub;

  // Suppresses authStateChanges events while updatePassword is in progress.

  // The repository signs out after the update, which would otherwise cause

  // AuthUnauthenticated to overwrite the AuthPasswordUpdated state before the

  // UI can respond to it.

  bool _isUpdatingPassword = false;

  /// Prevents duplicate sync when [currentUser] and the initial auth stream

  /// event both fire on cold start.

  bool _skipNextAuthSync = false;

  Future<void>? _syncInFlight;

  Future<void>? _authRecoveryInFlight;

  Future<void> _recoverFromAuthStreamError(
    Object error,
    StackTrace stackTrace,
  ) {
    _authRecoveryInFlight ??= _performAuthRecovery(error, stackTrace)
        .whenComplete(() => _authRecoveryInFlight = null);
    return _authRecoveryInFlight!;
  }

  Future<void> _performAuthRecovery(
    Object error,
    StackTrace stackTrace,
  ) async {
    TaliaLogger.w('Auth lifecycle stream error', error, stackTrace);
    final result = await _authRepository.recoverSessionAfterAuthError(error);
    if (isClosed) return;

    switch (result) {
      case AuthSessionRecovery.recovered:
        final user = _authRepository.currentUser;
        if (user != null) {
          emit(AuthAuthenticated(user: user));
          unawaited(_runCloudSync());
        } else {
          emit(const AuthUnauthenticated());
        }
        return;
      case AuthSessionRecovery.terminalFailure:
        emit(const AuthUnauthenticated());
        return;
      case AuthSessionRecovery.transientFailure:
        // Keep the current authenticated UI and pending local data. A lifecycle
        // event or the next data request will make one bounded recovery attempt.
        return;
    }
  }

  Future<void> signUp({
    required String email,

    required String password,

    required String displayName,
  }) async {
    emit(const AuthLoading());

    final result = await _authRepository.signUp(
      email: email,

      password: password,

      displayName: displayName,
    );

    if (isClosed) return;

    result.fold((failure) => emit(AuthError(failure.toString())), (_) {
      // Auth state stream emits AuthAuthenticated when Supabase session updates.
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthLoading());

    final result = await _authRepository.signIn(
      email: email,

      password: password,
    );

    if (isClosed) return;

    result.fold((failure) => emit(AuthError(failure.toString())), (_) {
      // Auth state stream emits AuthAuthenticated when Supabase session updates.
    });
  }

  Future<void> signOut({bool force = false}) async {
    emit(const AuthLoading());
    final flushed = await _flushBeforeExplicitSignOut();
    if (!force && !flushed) {
      if (isClosed) return;
      final user = _authRepository.currentUser;
      if (user != null) {
        emit(AuthSignOutBlockedPendingData(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
      return;
    }

    final result = await _authRepository.signOut();

    if (isClosed) return;

    result.fold((failure) => emit(AuthError(failure.toString())), (_) {
      // Auth state stream emits AuthUnauthenticated when Supabase session clears.
    });
  }

  /// Imports guest review records only after the signed-in user confirms it.
  Future<Either<Failure, int>> importGuestReviewRecords() {
    final repository = _memPlusRepository;
    if (repository == null) {
      return Future.value(
        const Left(UnknownFailure('Memorization data is unavailable')),
      );
    }
    return repository.claimLocalReviewRecords();
  }

  Future<void> deleteAccount() async {
    emit(const AuthLoading());

    final result = await _authRepository.deleteAccount();

    if (isClosed) return;

    result.fold(
      (failure) => emit(AuthError(failure.toString())),

      (_) => emit(const AuthAccountDeleted()),
    );
  }

  /// Resend confirmation email for unconfirmed accounts

  Future<void> resendConfirmation(String email) async {
    final result = await _authRepository.resendConfirmation(email);

    if (isClosed) return;

    result.fold(
      (failure) => emit(AuthError(failure.toString())),

      (_) => emit(const AuthResendConfirmationSuccess()),
    );
  }

  /// Send a password reset email

  Future<void> resetPassword(String email) async {
    emit(const AuthLoading());

    final result = await _authRepository.resetPassword(email);

    if (isClosed) return;

    result.fold(
      (failure) => emit(AuthError(failure.toString())),

      (_) => emit(const AuthPasswordResetSent()),
    );
  }

  /// Update password after Supabase opens the recovery link in the app.

  Future<void> updatePassword(String newPassword) async {
    emit(const AuthLoading());

    _isUpdatingPassword = true;

    try {
      final result = await _authRepository.updatePassword(newPassword);

      if (isClosed) return;

      result.fold(
        (failure) => emit(AuthError(failure.toString())),

        (_) => emit(const AuthPasswordUpdated()),
      );
    } finally {
      _isUpdatingPassword = false;
    }
  }

  @override
  Future<void> close() {
    _authSub?.cancel();

    _passwordRecoverySub?.cancel();

    return super.close();
  }
}
