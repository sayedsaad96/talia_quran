import 'package:flutter/material.dart';

import '../../domain/services/kids_world_phase.dart';

/// Colours of the kids world scene per phase. Text drawn directly on the
/// scene must use [onScene] / [onSceneMuted] (contrast >= 4.5:1 on every
/// sky and hill colour, in both phases).
final class KidsWorldPalette {
  const KidsWorldPalette._({
    required this.skyStops,
    required this.hills,
    required this.onScene,
    required this.onSceneMuted,
  });

  static const day = KidsWorldPalette._(
    skyStops: [Color(0xFF5AB6E5), Color(0xFFA8E0F0), Color(0xFF88D2B4)],
    hills: [Color(0xFF8FD18F), Color(0xFF6CBF73)],
    onScene: Color(0xFF1F2937),
    onSceneMuted: Color(0xFF374151),
  );

  static const night = KidsWorldPalette._(
    skyStops: [Color(0xFF0B1437), Color(0xFF1A2E5A), Color(0xFF16384A)],
    hills: [Color(0xFF0F3D35), Color(0xFF0A2925)],
    onScene: Color(0xFFF8FAFC),
    onSceneMuted: Color(0xFFCBD5E1),
  );

  /// Sun glow (day) and moon disc (night); identical in both palettes.
  static const sunGlow = Color(0xFFFFF3C4);
  static const moon = Color(0xFFFDE68A);

  /// Cloud fill; identical in both palettes.
  static const cloud = Color(0xD8FFFFFF);

  final List<Color> skyStops;
  final List<Color> hills;
  final Color onScene;
  final Color onSceneMuted;

  static KidsWorldPalette forPhase(KidsWorldPhase phase) =>
      phase == KidsWorldPhase.day ? day : night;

  /// Phase from the nearest [KidsWorldPhaseScope]; night when absent.
  static KidsWorldPalette of(BuildContext context) =>
      forPhase(KidsWorldPhaseScope.phaseOf(context));
}

/// Publishes the current [KidsWorldPhase] to descendants.
class KidsWorldPhaseScope extends InheritedWidget {
  const KidsWorldPhaseScope({
    super.key,
    required this.phase,
    required super.child,
  });

  final KidsWorldPhase phase;

  /// Night when no scope is present.
  static KidsWorldPhase phaseOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<KidsWorldPhaseScope>()
          ?.phase ??
      KidsWorldPhase.night;

  @override
  bool updateShouldNotify(KidsWorldPhaseScope oldWidget) =>
      oldWidget.phase != phase;
}
