import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/auth/domain/repositories/retained_account_recovery_repository.dart';
import 'package:talia_quran/features/auth/presentation/cubits/retained_account_recovery_cubit.dart';

class FakeRecovery implements RetainedAccountRecoveryRepository {
  RetainedAccountRecoveryResult result = RetainedAccountRecoveryResult.failed;
  Completer<RetainedAccountRecoveryResult>? pending;
  int calls = 0;
  @override
  Future<RetainedAccountRecoveryResult> signIn({
    required String email,
    required String password,
  }) {
    calls++;
    return pending?.future ?? Future.value(result);
  }
}

void main() {
  test('wrong account is displayed without resuming', () async {
    final repo = FakeRecovery()
      ..result = RetainedAccountRecoveryResult.wrongAccount;
    var resumes = 0;
    final cubit = RetainedAccountRecoveryCubit(
      repository: repo,
      resume: () async {
        resumes++;
      },
    );
    await cubit.signIn(email: 'a@example.test', password: 'password');
    expect(cubit.state.error, RetainedAccountRecoveryResult.wrongAccount);
    expect(resumes, 0);
    await cubit.close();
  });
  test(
    'recovered rechecks startup, prevents duplicate and handles resume failure',
    () async {
      final repo = FakeRecovery()
        ..pending = Completer<RetainedAccountRecoveryResult>();
      var resumes = 0;
      final cubit = RetainedAccountRecoveryCubit(
        repository: repo,
        resume: () async {
          resumes++;
          throw StateError('fixture');
        },
      );
      final first = cubit.signIn(email: 'a@example.test', password: 'password');
      await cubit.signIn(email: 'a@example.test', password: 'password');
      expect(repo.calls, 1);
      repo.pending!.complete(RetainedAccountRecoveryResult.recovered);
      await first;
      expect(resumes, 1);
      expect(cubit.state.error, RetainedAccountRecoveryResult.failed);
      expect(cubit.state.busy, isFalse);
      await cubit.close();
    },
  );
  test('retry asks startup to reevaluate without signing in', () async {
    final repo = FakeRecovery();
    var resumes = 0;
    final cubit = RetainedAccountRecoveryCubit(
      repository: repo,
      resume: () async {
        resumes++;
      },
    );
    await cubit.retry();
    expect(resumes, 1);
    expect(repo.calls, 0);
    await cubit.close();
  });
}
