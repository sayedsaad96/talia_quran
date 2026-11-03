import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/retained_account_recovery_repository.dart';

class RetainedAccountRecoveryState {
  const RetainedAccountRecoveryState({this.busy = false, this.error});
  final bool busy;
  final RetainedAccountRecoveryResult? error;
}

class RetainedAccountRecoveryCubit extends Cubit<RetainedAccountRecoveryState> {
  RetainedAccountRecoveryCubit({required this.repository, required this.resume})
    : super(const RetainedAccountRecoveryState());
  final RetainedAccountRecoveryRepository repository;
  final Future<void> Function() resume;

  Future<void> signIn({required String email, required String password}) async {
    if (state.busy || isClosed) return;
    emit(const RetainedAccountRecoveryState(busy: true));
    try {
      final result = await repository.signIn(
        email: email.trim(),
        password: password,
      );
      if (isClosed) return;
      if (result != RetainedAccountRecoveryResult.recovered) {
        emit(RetainedAccountRecoveryState(error: result));
        return;
      }
      await resume();
      if (!isClosed) emit(const RetainedAccountRecoveryState());
    } catch (_) {
      if (!isClosed) {
        emit(
          const RetainedAccountRecoveryState(
            error: RetainedAccountRecoveryResult.failed,
          ),
        );
      }
    }
  }

  Future<void> retry() async {
    if (state.busy || isClosed) return;
    emit(const RetainedAccountRecoveryState(busy: true));
    try {
      await resume();
      if (!isClosed) emit(const RetainedAccountRecoveryState());
    } catch (_) {
      if (!isClosed) {
        emit(
          const RetainedAccountRecoveryState(
            error: RetainedAccountRecoveryResult.failed,
          ),
        );
      }
    }
  }
}
