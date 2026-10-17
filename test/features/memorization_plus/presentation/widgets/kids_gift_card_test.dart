import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_gift_card.dart';

ParentReward _reward(ParentRewardStatus status, {int? surah}) => ParentReward(
  id: 'g1',
  title: 'نزهة',
  status: status,
  createdAt: DateTime.utc(2026, 10, 1),
  milestoneSurahId: surah,
);

Future<void> _pump(WidgetTester tester, KidsGiftCard card) =>
    tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: card),
      ),
    );

void main() {
  const progressKey = ValueKey('kids-gift-progress-g1');

  testWidgets('a locked promise shows the saved ayahs of its surah', (
    tester,
  ) async {
    await _pump(
      tester,
      KidsGiftCard(
        reward: _reward(ParentRewardStatus.locked, surah: 114),
        milestoneProgress: (done: 3, total: 6),
      ),
    );

    expect(find.text('٣ من ٦ آيات'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: find.byKey(progressKey),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(bar.value, 0.5);
  });

  testWidgets('a gift without a condition shows no progress', (tester) async {
    await _pump(
      tester,
      KidsGiftCard(reward: _reward(ParentRewardStatus.locked)),
    );

    expect(find.byKey(progressKey), findsNothing);
  });

  testWidgets('no progress is drawn once the gift is open', (tester) async {
    await _pump(
      tester,
      KidsGiftCard(
        reward: _reward(ParentRewardStatus.unlocked, surah: 114),
        milestoneProgress: (done: 6, total: 6),
      ),
    );

    expect(find.byKey(progressKey), findsNothing);
  });

  testWidgets('a promise that just came true says so', (tester) async {
    await _pump(
      tester,
      KidsGiftCard(
        reward: _reward(ParentRewardStatus.unlocked, surah: 114),
        promiseJustKept: true,
      ),
    );

    expect(find.text('تحقق الوعد!'), findsOneWidget);
  });
}
