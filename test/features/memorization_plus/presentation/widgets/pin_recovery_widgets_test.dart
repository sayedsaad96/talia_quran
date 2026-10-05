import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/parent_pin_recovery_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/parent_pin_recovery_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/child_pin_recovery_panel.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/parent_pin_recovery_dialog.dart';

class _MockRecovery extends Mock implements ParentPinRecoveryUsecase {}

final _challenge = PinRecoveryChallenge(
  id: 'c-1',
  expiresAt: DateTime.utc(2026, 10, 5, 19, 10),
);

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: child),
);

void main() {
  late _MockRecovery recovery;

  setUp(() {
    recovery = _MockRecovery();
    if (getIt.isRegistered<ParentPinRecoveryUsecase>()) {
      getIt.unregister<ParentPinRecoveryUsecase>();
    }
    getIt.registerSingleton<ParentPinRecoveryUsecase>(recovery);
  });

  tearDown(() => getIt.unregister<ParentPinRecoveryUsecase>());

  group('child recovery dialog', () {
    late bool? result;

    Future<void> open(WidgetTester tester) async {
      result = null;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async =>
                  result = await showParentPinRecoveryDialog(context),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    Future<void> submit(WidgetTester tester, String code, String pin) async {
      await tester.enterText(
        find.byKey(const ValueKey('pin-recovery-code')),
        code,
      );
      await tester.enterText(
        find.byKey(const ValueKey('pin-recovery-new-pin')),
        pin,
      );
      await tester.tap(find.byKey(const ValueKey('pin-recovery-submit')));
      await tester.pumpAndSettle();
    }

    setUp(() {
      when(() => recovery.request()).thenAnswer((_) async => Right(_challenge));
    });

    testWidgets('a wrong code keeps the dialog open with a message', (
      tester,
    ) async {
      when(
        () => recovery.complete(
          challengeId: 'c-1',
          code: 'ABCDEF123456',
          newPin: '2468',
        ),
      ).thenAnswer((_) async => const Right(false));
      await open(tester);

      expect(find.textContaining('Ask your guardian'), findsOneWidget);
      await submit(tester, 'ABCDEF123456', '2468');

      expect(find.textContaining('The code is wrong'), findsOneWidget);
      expect(result, isNull);
    });

    testWidgets('an accepted code closes with success', (tester) async {
      when(
        () => recovery.complete(
          challengeId: 'c-1',
          code: 'ABCDEF123456',
          newPin: '2468',
        ),
      ).thenAnswer((_) async => const Right(true));
      await open(tester);

      await submit(tester, 'ABCDEF123456', '2468');

      expect(result, isTrue);
      expect(find.text('PIN changed'), findsOneWidget);
    });
  });

  group('guardian panel', () {
    testWidgets('is hidden without open requests', (tester) async {
      when(
        () => recovery.pending('child-1'),
      ).thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(
        _app(const ChildPinRecoveryPanel(childUserId: 'child-1')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('child-pin-recovery-panel')),
        findsNothing,
      );
    });

    testWidgets('approving shows the one-time code in groups', (tester) async {
      when(
        () => recovery.pending('child-1'),
      ).thenAnswer((_) async => Right([_challenge]));
      when(
        () => recovery.approve('c-1'),
      ).thenAnswer((_) async => const Right('ABCDEF123456'));

      await tester.pumpWidget(
        _app(const ChildPinRecoveryPanel(childUserId: 'child-1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('PIN change request'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('child-pin-recovery-approve')),
      );
      await tester.pumpAndSettle();

      expect(find.text('ABCD-EF12-3456'), findsOneWidget);
      expect(find.textContaining('Valid until'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('ABCD-EF12-3456'), findsNothing);
    });
  });
}
