import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/auth/domain/repositories/retained_account_recovery_repository.dart';
import 'package:talia_quran/features/auth/presentation/pages/retained_account_recovery_app.dart';

class FakeRecovery implements RetainedAccountRecoveryRepository {
  RetainedAccountRecoveryResult result =
      RetainedAccountRecoveryResult.wrongAccount;
  @override
  Future<RetainedAccountRecoveryResult> signIn({
    required String email,
    required String password,
  }) async => result;
}

void main() {
  testWidgets('shows localized wrong-account error and does not resume', (
    tester,
  ) async {
    final repo = FakeRecovery();
    var resumed = 0;
    await tester.pumpWidget(
      RetainedAccountRecoveryApp(
        repository: repo,
        locale: const Locale('en'),
        resume: () async {
          resumed++;
        },
      ),
    );
    await tester.enterText(
      find.byKey(const Key('retained-email')),
      'a@example.test',
    );
    await tester.enterText(
      find.byKey(const Key('retained-password')),
      'password',
    );
    await tester.ensureVisible(find.byKey(const Key('retained-sign-in')));
    await tester.tap(find.byKey(const Key('retained-sign-in')));
    await tester.pumpAndSettle();
    expect(find.text('This is not the previous account.'), findsOneWidget);
    expect(resumed, 0);
    repo.result = RetainedAccountRecoveryResult.recovered;
    await tester.tap(find.byKey(const Key('retained-sign-in')));
    await tester.pumpAndSettle();
    expect(resumed, 1);
  });
  testWidgets('unknown owner hides sign-in and offers retry at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var resumed = 0;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: RetainedAccountRecoveryApp(
          repository: FakeRecovery(),
          canSignIn: false,
          locale: const Locale('en'),
          resume: () async {
            resumed++;
          },
        ),
      ),
    );
    expect(find.byKey(const Key('retained-sign-in')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('retained-retry')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // The lazy child can enter the tree with only its edge on screen.
    await tester.ensureVisible(find.byKey(const Key('retained-retry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('retained-retry')));
    await tester.pumpAndSettle();
    expect(resumed, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Arabic is the default and the form follows RTL', (tester) async {
    await tester.pumpWidget(
      RetainedAccountRecoveryApp(
        repository: FakeRecovery(),
        resume: () async {},
      ),
    );
    expect(find.text('استعادة حسابك'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('استعادة حسابك'))),
      TextDirection.rtl,
    );
  });
}
