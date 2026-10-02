import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_world_phase.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_scene.dart';

Widget _host(
  KidsWorldPhase phase, {
  bool animate = true,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: KidsWorldScene(
        phase: phase,
        animate: animate,
        child: const SizedBox(),
      ),
    ),
  );
}

void main() {
  testWidgets('night scene never animates under reduced motion', (t) async {
    await t.pumpWidget(_host(KidsWorldPhase.night, disableAnimations: true));
    await t.pump(const Duration(seconds: 1));
    expect(t.hasRunningAnimations, isFalse);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('day scene drifts when animate is true', (t) async {
    await t.pumpWidget(_host(KidsWorldPhase.day));
    await t.pump(const Duration(seconds: 1));
    expect(t.hasRunningAnimations, isTrue);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('animate: false freezes both phases', (t) async {
    for (final phase in KidsWorldPhase.values) {
      await t.pumpWidget(_host(phase, animate: false));
      await t.pump(const Duration(seconds: 1));
      expect(t.hasRunningAnimations, isFalse, reason: phase.name);
    }
    await t.pumpWidget(const SizedBox());
  });
}
