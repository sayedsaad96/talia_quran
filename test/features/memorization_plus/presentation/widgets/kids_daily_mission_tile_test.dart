import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_daily_missions.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_daily_mission_tile.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester,
    KidsDailyMission mission,
    VoidCallback onTap,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: KidsDailyMissionTile(mission: mission, onTap: onTap),
          ),
        ),
      ),
    );
  }

  testWidgets('two-page goal fits narrow Arabic and opens the reader', (
    tester,
  ) async {
    var opened = 0;
    await pumpTile(
      tester,
      const KidsDailyMission(
        id: 'reading',
        kind: KidsDailyMissionKind.reading,
        suggestion: KidsDailySuggestion.readTwoPages,
        targetCount: 2,
        status: KidsDailyMissionStatus.available,
      ),
      () => opened++,
    );
    expect(find.text('اقرأ صفحتين من المصحف وأكّد قراءتهما'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(InkWell));
    expect(opened, 1);
  });

  testWidgets('completed practice cannot launch a different learning task', (
    tester,
  ) async {
    var opened = 0;
    await pumpTile(
      tester,
      const KidsDailyMission(
        id: 'practice',
        kind: KidsDailyMissionKind.practice,
        suggestion: KidsDailySuggestion.listenAndRecite,
        status: KidsDailyMissionStatus.completed,
      ),
      () => opened++,
    );
    expect(find.text('استمع وردّد ثم سمّع آيتك'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(InkWell));
    expect(opened, 0);
  });
}
