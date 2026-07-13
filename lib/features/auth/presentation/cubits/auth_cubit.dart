import 'package:flutter/foundation.dart';

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';

import '../../domain/repositories/auth_repository.dart';

import '../../../../core/progress/progress_changed_reason.dart';

import '../../../../core/progress/progress_events_bus.dart';

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

      unawaited(_runCloudSync());

    } else {

      emit(const AuthUnauthenticated());

    }

  }



  /// Pulls cloud progress, merges production SRS locally, then pushes local

  /// state. Order matters: pull before push avoids stale-device clobber (B6/B9).

  Future<void> _runCloudSync() async {

    final pullResult = await _authRepository.pullProgressFromCloud();

    pullResult.fold(

      (failure) => TaliaLogger.w(

        'Cloud pull failed after login',

        failure.message,

      ),

      (_) => TaliaLogger.i('Streak/heatmap pull completed'),

    );



    final memPlusRepository = _memPlusRepository;

    if (memPlusRepository != null) {

      final productionPull =

          await memPlusRepository.pullProductionDataFromCloud();

      productionPull.fold(

        (failure) => TaliaLogger.w(

          'Production SRS pull failed',

          failure.message,

        ),

        (_) => TaliaLogger.i('Production SRS pull completed'),

      );

    }



    final pushResult = await _authRepository.syncProgressToCloud();

    pushResult.fold(

      (failure) =>

          TaliaLogger.w('Streak/heatmap cloud sync failed', failure.message),

      (_) => TaliaLogger.i('Streak/heatmap cloud sync completed'),

    );



    if (memPlusRepository != null) {

      final resyncResult =

          await memPlusRepository.resyncProductionDataToCloud();

      resyncResult.fold(

        (failure) => TaliaLogger.w(

          'Production data cloud resync failed',

          failure.message,

        ),

        (_) => TaliaLogger.i('Production data cloud resync completed'),

      );



      final achievementService = _achievementService;

      if (achievementService != null) {

        final certificates = achievementService.getAllEarnedCertificates();

        if (certificates.isNotEmpty) {

          final certResult = await memPlusRepository.pushCertificatesToCloud(

            certificates,

          );

          certResult.fold(

            (failure) => TaliaLogger.w(

              'Certificate cloud push failed',

              failure.message,

            ),

            (_) => TaliaLogger.i('Certificate cloud push completed'),

          );

        }

      }

    }



    _progressEvents?.notify(ProgressChangedReason.cloudPull);

  }



  /// Public entry point for app-lifecycle-triggered resync (e.g. on app

  /// resume), reusing the same pull-then-push sequence as login.

  void resyncOnResume() {

    if (state is! AuthAuthenticated) return;

    unawaited(_runCloudSync());

  }



  final AuthRepository _authRepository;

  final MemorizationPlusRepository? _memPlusRepository;

  final ProgressEventsBus? _progressEvents;

  final AchievementService? _achievementService;

  StreamSubscription<AppUser?>? _authSub;

  StreamSubscription<void>? _passwordRecoverySub;

  // Suppresses authStateChanges events while updatePassword is in progress.

  // The repository signs out after the update, which would otherwise cause

  // AuthUnauthenticated to overwrite the AuthPasswordUpdated state before the

  // UI can respond to it.

  bool _isUpdatingPassword = false;



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

