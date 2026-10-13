import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_world_growth_snapshot.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_world_phase.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_ui.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_growth_controller.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_scene.dart';

const _grown = KidsWorldGrowthSnapshot(plants: 12, blossoms: 3);

Widget _scene(
  KidsWorldPhase phase, {
  KidsWorldGrowthSnapshot growth = _grown,
  TextDirection direction = TextDirection.rtl,
  bool disableAnimations = false,
}) => MediaQuery(
  data: MediaQueryData(
    size: const Size(320, 640),
    disableAnimations: disableAnimations,
  ),
  child: Directionality(
    textDirection: direction,
    child: KidsWorldScene(
      phase: phase,
      growth: growth,
      child: const SizedBox(),
    ),
  ),
);

void main() {
  testWidgets('a fully grown world paints in both phases and directions', (
    tester,
  ) async {
    for (final phase in KidsWorldPhase.values) {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(_scene(phase, direction: direction));
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('growth adds no motion under reduced motion', (tester) async {
    await tester.pumpWidget(
      _scene(KidsWorldPhase.day, disableAnimations: true),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the background passes the controller growth to the scene', (
    tester,
  ) async {
    final controller = KidsWorldGrowthController(
      unlockedAchievements: () => {'firstAyah': DateTime.utc(2026, 10, 1)},
      enabled: () => true,
    );
    getIt.registerSingleton<KidsWorldGrowthController>(controller);
    addTearDown(() async {
      await getIt.unregister<KidsWorldGrowthController>();
      controller.dispose();
    });

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: KidsBackground(child: SizedBox()),
        ),
      ),
    );
    await tester.pump();

    final scene = tester.widget<KidsWorldScene>(find.byType(KidsWorldScene));
    expect(scene.growth, const KidsWorldGrowthSnapshot(plants: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a controller the background shows no growth', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: KidsBackground(child: SizedBox()),
        ),
      ),
    );

    final scene = tester.widget<KidsWorldScene>(find.byType(KidsWorldScene));
    expect(scene.growth, KidsWorldGrowthSnapshot.none);
  });
}
