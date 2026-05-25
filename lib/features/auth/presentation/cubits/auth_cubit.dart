import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authRepository) : super(const AuthInitial()) {
    // Listen to auth state changes stream
    _authSub = _authRepository.authStateChanges.listen((user) {
      if (isClosed) return;
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    });

    // Set initial state immediately
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      emit(AuthAuthenticated(user: currentUser));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _authSub;

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
    result.fold(
      (failure) => emit(AuthError(failure.toString())),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthLoading());
    final result = await _authRepository.signIn(
      email: email,
      password: password,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthError(failure.toString())),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    final result = await _authRepository.signOut();
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthError(failure.toString())),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  /// Resend confirmation email for unconfirmed accounts
  Future<void> resendConfirmation(String email) async {
    try {
      await _authRepository.resendConfirmation(email);
      if (!isClosed) emit(const AuthError('__resent__'));
    } catch (_) {
      if (!isClosed) emit(const AuthError('فشل إعادة الإرسال، حاول مرة أخرى'));
    }
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}

