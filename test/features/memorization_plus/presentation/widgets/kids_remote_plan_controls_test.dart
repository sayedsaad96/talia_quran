import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_remote_plan.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_remote_plan_controls.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  testWidgets('guardian changes hint without clearing other policy fields', (
    tester,
  ) async {
    KidsRemotePlan? changed;
    await tester.pumpWidget(
      app(
        KidsRemotePlanControls(
          plan: const KidsRemotePlan(
            nextSurahId: 114,
            ayahsPerSession: 7,
            practiceDays: 65,
          ),
          onChanged: (value) => changed = value,
        ),
      ),
    );
    final days = tester.widget<FilterChip>(
      find.byKey(const Key('remote-plan-day-2')),
    );
    days.onSelected!(true);
    expect(
      changed,
      const KidsRemotePlan(
        nextSurahId: 114,
        ayahsPerSession: 7,
        practiceDays: 67,
      ),
    );
    final size = tester.widget<DropdownButton<int>>(
      find.byKey(const Key('remote-plan-size')),
    );
    size.onChanged!(3);
    expect(
      changed,
      const KidsRemotePlan(
        nextSurahId: 114,
        ayahsPerSession: 3,
        practiceDays: 65,
      ),
    );
    size.onChanged!(0);
    expect(changed!.ayahsPerSession, isNull);
  });

  testWidgets('disabled controls remain inert on narrow Arabic large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (_, child) => MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 1200),
            textScaler: TextScaler.linear(1.7),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: KidsRemotePlanControls(
              plan: const KidsRemotePlan(),
              enabled: false,
              onChanged: (_) => fail('disabled edit'),
            ),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<DropdownButton<int>>(
            find.byKey(const Key('remote-plan-size')),
          )
          .onChanged,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
