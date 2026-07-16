import 'package:flutter/foundation.dart';

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';

import '../../domain/repositories/auth_repository.dart';

import '../../../../core/progress/progress_changed_reason.dart';

import '../../../../core/progress/progress_events_bus.dart';

import '../../../../core/sync/cloud_sync_queue.dart';

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



  Future<void> _performCloudSync() async {

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

      case CloudSyncQueueKind.kidsProgress:

        if (memPlusRepository == null) return true;

        return (await memPlusRepository.syncKidsProgressToCloud()).isRight();

      default:

        return true;

    }

  }



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



  Future<void> signOut() async {

    emit(const AuthLoading());

    final result = await _authRepository.signOut();

    if (isClosed) return;

    result.fold((failure) => emit(AuthError(failure.toString())), (_) {

      // Auth state stream emits AuthUnauthenticated when Supabase session clears.

    });

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

