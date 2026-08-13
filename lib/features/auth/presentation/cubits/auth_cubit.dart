import 'package:flutter/foundation.dart';

import 'package:dartz/dartz.dart';

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';

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



part 'auth_state.dart';



class AuthCubit extends Cubit<AuthState> {

  AuthCubit(

    this._authRepository, [

    this._memPlusRepository,

    this._progressEvents,

    this._achievementService,

    this._cloudSyncQueue,

    this._prefs,

    this._accountDataReset,

  ]) : super(const AuthInitial()) {

    // Listen to Supabase auth state changes.

    // Every time a session becomes active (new login OR session restored on

    // app restart), pull the user's cloud data so local Isar is up-to-date.

    _authSub = _authRepository.authStateChanges.listen((user) {

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

    });

    _passwordRecoverySub = _authRepository.passwordRecoveryChanges.listen((_) {

      if (isClosed) return;

      emit(const AuthPasswordRecoveryDetected());

    });



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



  /// Pulls cloud progress, merges production SRS locally, then pushes local

  /// state. Order matters: pull before push avoids stale-device clobber (B6/B9).

  Future<void> _runCloudSync() {

    _syncInFlight ??= _performCloudSync().whenComplete(

      () => _syncInFlight = null,

    );

    return _syncInFlight!;

  }





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
  }) async {
    final previous = prefs.getString(lastSignedInUserIdKey);
    final changed = previous != null && previous != userId;
    if (changed) {
      await onDepartingAccount();
    }
    await prefs.setString(lastSignedInUserIdKey, userId);
    return changed;
  }

  Future<void> _performCloudSync() async {

    final prefs = _prefs;

    final reset = _accountDataReset;

    final userId = _authRepository.currentUser?.id;

    if (prefs != null && reset != null && userId != null) {

      final switched = await resolveOwnerChange(

        prefs: prefs,

        userId: userId,

        onDepartingAccount: reset.clearAccountOwnedData,

      );

      if (switched) {

        TaliaLogger.i('Account switch detected; cleared departing account data');

        _progressEvents?.notify(ProgressChangedReason.certificate);
        emit(AuthAccountDataDiscarded(user: _authRepository.currentUser!));

      }

    }



    await _processSyncQueue();



    final pullResult = await _authRepository.pullProgressFromCloud();

    pullResult.fold(

      (failure) {

        TaliaLogger.w(

          'Cloud pull failed after login',

          failure.message,

        );

        unawaited(

          _cloudSyncQueue?.enqueue(CloudSyncQueueKind.authPull),

        );

      },

      (_) {

        TaliaLogger.i('Streak/heatmap pull completed');

        unawaited(

          _cloudSyncQueue?.markSuccess(CloudSyncQueueKind.authPull),

        );

      },

    );



    final memPlusRepository = _memPlusRepository;

    if (memPlusRepository != null) {

      final productionPull =

          await memPlusRepository.pullProductionDataFromCloud();

      productionPull.fold(

        (failure) {

          TaliaLogger.w(

            'Production SRS pull failed',

            failure.message,

          );

          unawaited(

            _cloudSyncQueue?.enqueue(CloudSyncQueueKind.productionPull),

          );

        },

        (_) {

          TaliaLogger.i('Production SRS pull completed');

          unawaited(

            _cloudSyncQueue?.markSuccess(CloudSyncQueueKind.productionPull),

          );

        },

      );

      // Restore certificates (cloud has no audience yet → adult list), then
      // recompute kids awards from local kids review records.
      final achievementService = _achievementService;
      if (achievementService != null) {
        final certPull = await memPlusRepository.pullCertificatesFromCloud();
        await certPull.fold(
          (failure) async {
            TaliaLogger.w('Certificate pull failed', failure.message);
            unawaited(
              _cloudSyncQueue?.enqueue(CloudSyncQueueKind.certificatePull),
            );
          },
          (awards) async {
            if (awards.isNotEmpty) {
              await achievementService.mergeEarnedFromCloud(
                awards,
                isKids: false,
              );
            }
            await achievementService.checkAndUnlockCertificates(isKids: true);
          },
        );
      }

      final kidsPull = await memPlusRepository.pullKidsProgressFromCloud();
      kidsPull.fold(
        (failure) {
          TaliaLogger.w('Kids progress pull failed', failure.message);
          unawaited(
            _cloudSyncQueue?.enqueue(CloudSyncQueueKind.kidsProgress),
          );
        },
        (_) => TaliaLogger.i('Kids progress pull completed'),
      );

    }



    final pushResult = await _authRepository.syncProgressToCloud();

    pushResult.fold(

      (failure) {

        TaliaLogger.w('Streak/heatmap cloud sync failed', failure.message);

        unawaited(

          _cloudSyncQueue?.enqueue(CloudSyncQueueKind.authPush),

        );

      },

      (_) {

        TaliaLogger.i('Streak/heatmap cloud sync completed');

        unawaited(

          _cloudSyncQueue?.markSuccess(CloudSyncQueueKind.authPush),

        );

      },

    );



    if (memPlusRepository != null) {

      final resyncResult =

          await memPlusRepository.resyncProductionDataToCloud();

      resyncResult.fold(

        (failure) {

          TaliaLogger.w(

            'Production data cloud resync failed',

            failure.message,

          );

          unawaited(

            _cloudSyncQueue?.enqueue(CloudSyncQueueKind.productionPush),

          );

        },

        (_) {

          TaliaLogger.i('Production data cloud resync completed');

          unawaited(

            _cloudSyncQueue?.markSuccess(CloudSyncQueueKind.productionPush),

          );

        },

      );



      final kidsPush = await memPlusRepository.syncKidsProgressToCloud();
      kidsPush.fold(
        (failure) {
          TaliaLogger.w('Kids progress push failed', failure.message);
          unawaited(
            _cloudSyncQueue?.enqueue(CloudSyncQueueKind.kidsProgress),
          );
        },
        (_) {
          TaliaLogger.i('Kids progress push completed');
          unawaited(
            _cloudSyncQueue?.markSuccess(CloudSyncQueueKind.kidsProgress),
          );
        },
      );

      final achievementService = _achievementService;

      if (achievementService != null) {

        final certificates = achievementService.getAllEarnedCertificates();

        if (certificates.isNotEmpty) {

          final certResult = await memPlusRepository.pushCertificatesToCloud(

            certificates,

          );

          certResult.fold(

            (failure) {

              TaliaLogger.w(

                'Certificate cloud push failed',

                failure.message,

              );

              unawaited(

                _cloudSyncQueue?.enqueue(CloudSyncQueueKind.certificatePush),

              );

            },

            (_) {

              TaliaLogger.i('Certificate cloud push completed');

              unawaited(

                _cloudSyncQueue?.markSuccess(CloudSyncQueueKind.certificatePush),

              );

            },

          );

        }

      }

    }



    _progressEvents?.notify(ProgressChangedReason.cloudPull);

  }



  Future<void> _processSyncQueue() async {

    final queue = _cloudSyncQueue;

    if (queue == null) return;



    final dueItems = await queue.dueItems();

    for (final item in dueItems) {

      final success = await _retryQueueKind(item.kind);

      if (success) {

        await queue.markSuccess(item.kind);

      } else {

        await queue.markFailure(item.kind);

      }

    }

  }

  Future<bool> _flushBeforeExplicitSignOut() async {
    try {
      final memPlusRepository = _memPlusRepository;
      if (memPlusRepository != null &&
          await memPlusRepository.hasPendingCloudWork()) {
        await memPlusRepository.resyncProductionDataToCloud();
        await memPlusRepository.syncKidsProgressToCloud();
      }
      if (await _authRepository.hasPendingCloudPush()) {
        await _authRepository.syncProgressToCloud();
      }
      await _processSyncQueue();
      final memStillPending =
          memPlusRepository != null &&
          await memPlusRepository.hasPendingCloudWork();
      final authStillPending = await _authRepository.hasPendingCloudPush();
      return !memStillPending && !authStillPending;
    } catch (error, stackTrace) {
      TaliaLogger.w(
        'Best-effort cloud flush before sign-out failed; local data will be cleared',
        error,
        stackTrace,
      );
      return false;
    }
  }



  Future<bool> _retryQueueKind(String kind) async {

    final memPlusRepository = _memPlusRepository;

    switch (kind) {

      case CloudSyncQueueKind.authPull:

        return (await _authRepository.pullProgressFromCloud()).isRight();

      case CloudSyncQueueKind.authPush:

        return (await _authRepository.syncProgressToCloud()).isRight();

      case CloudSyncQueueKind.productionPull:

        if (memPlusRepository == null) return true;

        return (await memPlusRepository.pullProductionDataFromCloud()).isRight();

      case CloudSyncQueueKind.productionPush:

        if (memPlusRepository == null) return true;

        return (await memPlusRepository.resyncProductionDataToCloud()).isRight();

      case CloudSyncQueueKind.certificatePush:

        final achievementService = _achievementService;

        if (memPlusRepository == null || achievementService == null) {

          return true;

        }

        final certificates = achievementService.getAllEarnedCertificates();

        if (certificates.isEmpty) return true;

        return (await memPlusRepository.pushCertificatesToCloud(certificates))

            .isRight();

      case CloudSyncQueueKind.certificatePull:

        return _retryCertificatePull();

      case CloudSyncQueueKind.kidsProgress:

        if (memPlusRepository == null) return true;

        final kidsPullOk =

            (await memPlusRepository.pullKidsProgressFromCloud()).isRight();

        if (!kidsPullOk) return false;

        return (await memPlusRepository.syncKidsProgressToCloud()).isRight();

      default:

        return true;

    }

  }

  Future<bool> _retryCertificatePull() async {
    final memPlusRepository = _memPlusRepository;
    final achievementService = _achievementService;
    if (memPlusRepository == null || achievementService == null) {
      return true;
    }
    final certPull = await memPlusRepository.pullCertificatesFromCloud();
    return await certPull.fold<Future<bool>>(
      (failure) async {
        TaliaLogger.w('Certificate pull retry failed', failure.message);
        return false;
      },
      (awards) async {
        if (awards.isNotEmpty) {
          await achievementService.mergeEarnedFromCloud(
            awards,
            isKids: false,
          );
        }
        await achievementService.checkAndUnlockCertificates(isKids: true);
        return true;
      },
    );
  }

  @visibleForTesting
  Future<bool> retryQueueKindForTesting(String kind) => _retryQueueKind(kind);

  /// Public entry point for app-lifecycle-triggered resync (e.g. on app
  /// resume). Runs only when the outbox has pending work or a pull cursor
  /// is stale; debounced to avoid resume storms.
  void resyncOnResume({bool force = false}) {
    if (state is! AuthAuthenticated) return;

    final now = DateTime.now();
    if (!force &&
        _lastResumeSyncAt != null &&
        now.difference(_lastResumeSyncAt!) < _resumeDebounce) {
      return;
    }

    unawaited(_runCloudSyncIfNeeded(force: force));
  }

  Future<void> _runCloudSyncIfNeeded({bool force = false}) async {
    if (!force && !await _hasPendingSyncWork()) {
      TaliaLogger.i('Skipping resume sync — no pending outbox/cursor work');
      return;
    }
    _lastResumeSyncAt = DateTime.now();
    await _runCloudSync();
  }

  Future<bool> _hasPendingSyncWork() async {
    final queue = _cloudSyncQueue;
    if (queue != null && await queue.hasPending()) return true;
    if (await _authRepository.hasPendingCloudPush()) return true;
    final memPlus = _memPlusRepository;
    if (memPlus != null && await memPlus.hasPendingCloudWork()) return true;
    return false;
  }

  final AuthRepository _authRepository;

  final MemorizationPlusRepository? _memPlusRepository;

  final ProgressEventsBus? _progressEvents;

  final AchievementService? _achievementService;

  final CloudSyncQueue? _cloudSyncQueue;

  final SharedPreferences? _prefs;

  final AccountDataReset? _accountDataReset;

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

  DateTime? _lastResumeSyncAt;

  static const _resumeDebounce = Duration(minutes: 5);



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

