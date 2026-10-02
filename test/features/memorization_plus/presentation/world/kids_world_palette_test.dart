import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_world_phase.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_palette.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  for (final phase in KidsWorldPhase.values) {
    test(
      '${phase.name} palette text contrast >= 4.5 on every scene colour',
      () {
        final p = KidsWorldPalette.forPhase(phase);
        for (final c in [...p.skyStops, ...p.hills]) {
          expect(_contrast(p.onScene, c), greaterThanOrEqualTo(4.5));
          expect(_contrast(p.onSceneMuted, c), greaterThanOrEqualTo(4.5));
        }
      },
    );
  }

  testWidgets('of() follows the scope and defaults to night', (tester) async {
    late KidsWorldPalette inDay;
    late KidsWorldPalette bare;
    await tester.pumpWidget(
      Column(
        children: [
          KidsWorldPhaseScope(
            phase: KidsWorldPhase.day,
            child: Builder(
              builder: (c) {
                inDay = KidsWorldPalette.of(c);
                return const SizedBox();
              },
            ),
          ),
          Builder(
            builder: (c) {
              bare = KidsWorldPalette.of(c);
              return const SizedBox();
            },
          ),
        ],
      ),
    );
    expect(inDay, same(KidsWorldPalette.day));
    expect(bare, same(KidsWorldPalette.night));
  });
}
