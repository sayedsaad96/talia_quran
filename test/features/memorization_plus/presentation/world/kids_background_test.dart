import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_child_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_world_phase.dart';
import 'package:talia_quran/features/memorization_plus/presentation/theme/kids_theme.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_ui.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_policy_controller.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_palette.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_phase_controller.dart';

void main() {
  tearDown(() async {
    if (getIt.isRegistered<KidsWorldPhaseController>()) {
      getIt.unregister<KidsWorldPhaseController>();
    }
    if (getIt.isRegistered<KidsPolicyController>()) {
      getIt.unregister<KidsPolicyController>();
    }
  });

  KidsWorldPhase? seen;
  Widget probe() => Builder(
    builder: (context) {
      seen = KidsWorldPhaseScope.phaseOf(context);
      return const SizedBox.shrink();
    },
  );

  testWidgets('without a registered controller the background is night', (
    tester,
  ) async {
    seen = null;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: KidsBackground(child: probe()),
      ),
    );
    expect(seen, KidsWorldPhase.night);
  });

  testWidgets('with a controller at day the background is day and flips live', (
    tester,
  ) async {
    final controller = KidsWorldPhaseController(
      prayerTimes: () async => (
        fajr: DateTime(2026, 10, 2, 4, 30),
        maghrib: DateTime(2026, 10, 2, 17, 40),
      ),
      clock: () => DateTime(2026, 10, 2, 10),
    );
    getIt.registerSingleton<KidsWorldPhaseController>(controller);
    seen = null;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: KidsBackground(child: probe()),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(seen, KidsWorldPhase.day);

    controller.value = KidsWorldPhase.night;
    await tester.pump();
    expect(seen, KidsWorldPhase.night);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  group('guardian reduce-motion policy', () {
    bool? disabled;
    Widget motionProbe() => Builder(
      builder: (context) {
        disabled = MediaQuery.disableAnimationsOf(context);
        return const SizedBox.shrink();
      },
    );

    testWidgets('reduceMotion disables animations below and flips live', (
      tester,
    ) async {
      final controller = KidsPolicyController(
        load: () async => const KidsChildPolicy(reduceMotion: true),
      );
      getIt.registerSingleton<KidsPolicyController>(controller);
      await controller.reload();
      disabled = null;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: KidsBackground(child: motionProbe()),
          ),
        ),
      );
      expect(disabled, isTrue);

      controller.value = const KidsChildPolicy();
      await tester.pump();
      expect(disabled, isFalse);
    });

    testWidgets('cold start: the background loads reduceMotion itself and '
        'nothing animates', (tester) async {
      // No home cubit and no prior reload: a deep link straight into a kids
      // screen must still honour the guardian's reduce-motion.
      final controller = KidsPolicyController(
        load: () async => const KidsChildPolicy(reduceMotion: true),
      );
      getIt.registerSingleton<KidsPolicyController>(controller);
      disabled = null;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: KidsBackground(animate: true, child: motionProbe()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(controller.value.reduceMotion, isTrue);
      expect(disabled, isTrue);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('without reduceMotion the animated scene does run', (
      tester,
    ) async {
      final controller = KidsPolicyController(
        load: () async => const KidsChildPolicy(),
      );
      getIt.registerSingleton<KidsPolicyController>(controller);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: KidsBackground(animate: true, child: motionProbe()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('without a registered policy the OS setting is kept', (
      tester,
    ) async {
      disabled = null;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: KidsBackground(child: motionProbe()),
          ),
        ),
      );
      expect(disabled, isFalse);
    });
  });

  for (final phase in KidsWorldPhase.values) {
    testWidgets('top bar title sits on the band in $phase', (tester) async {
      final controller = KidsWorldPhaseController(
        prayerTimes: () async => (
          fajr: DateTime(2026, 10, 2, 4, 30),
          maghrib: DateTime(2026, 10, 2, 17, 40),
        ),
        clock: () => phase == KidsWorldPhase.day
            ? DateTime(2026, 10, 2, 10)
            : DateTime(2026, 10, 2, 22),
      );
      getIt.registerSingleton<KidsWorldPhaseController>(controller);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KidsBackground(
              child: KidsTopBar(title: 'Title', onBack: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final band = find.ancestor(
        of: find.text('Title'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).gradient ==
                  KidsTheme.heroCardGradient,
        ),
      );
      expect(band, findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }
}
