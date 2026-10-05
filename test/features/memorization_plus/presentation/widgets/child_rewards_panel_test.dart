import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/child_rewards_panel.dart';

ParentReward _reward(String id, ParentRewardStatus status) => ParentReward(
  id: id,
  title: 'gift $id',
  status: status,
  createdAt: DateTime.utc(2026, 10, 1),
);

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  final rewards = [
    _reward('claimed', ParentRewardStatus.claimed),
    _reward('locked', ParentRewardStatus.locked),
    _reward('unlocked', ParentRewardStatus.unlocked),
    _reward('requested', ParentRewardStatus.requested),
  ];

  testWidgets('lists requested gifts first and claimed gifts last', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ChildRewardsPanel(
          rewards: rewards,
          onUnlock: (_) async {},
          onApprove: (_) async {},
        ),
      ),
    );

    double top(String id) =>
        tester.getTopLeft(find.byKey(ValueKey('child-reward-$id'))).dy;
    expect(top('requested'), lessThan(top('unlocked')));
    expect(top('unlocked'), lessThan(top('locked')));
    expect(top('locked'), lessThan(top('claimed')));
    expect(find.text('The child is asking for it'), findsOneWidget);
    expect(find.text('Unlocked, waiting for the child to ask'), findsOneWidget);
  });

  testWidgets('only locked and requested gifts have an action', (tester) async {
    final unlocked = <String>[];
    final approved = <String>[];
    await tester.pumpWidget(
      _app(
        ChildRewardsPanel(
          rewards: rewards,
          onUnlock: (id) async => unlocked.add(id),
          onApprove: (id) async => approved.add(id),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('child-reward-action-unlocked')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('child-reward-action-claimed')),
      findsNothing,
    );
    await tester.tap(find.text('Unlock'));
    await tester.tap(find.text('Confirm hand-over'));
    await tester.pump();

    expect(unlocked, ['locked']);
    expect(approved, ['requested']);
  });

  testWidgets('a running step shows progress and blocks a second tap', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      _app(
        ChildRewardsPanel(
          rewards: [_reward('requested', ParentRewardStatus.requested)],
          onUnlock: (_) async {},
          onApprove: (_) {
            calls++;
            return pending.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('Confirm hand-over'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Confirm hand-over'), findsNothing);
    expect(calls, 1);

    pending.complete();
    await tester.pump();
    expect(find.text('Confirm hand-over'), findsOneWidget);
  });
}
