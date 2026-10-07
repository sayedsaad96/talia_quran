import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_chunky_button.dart';

void main() {
  Widget host(Widget child, {bool disableAnimations = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  group('KidsChunkyButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          KidsChunkyButton(
            label: 'Start',
            icon: TaliaIcons.play,
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(find.byIcon(TaliaIcons.play), findsOneWidget);
    });

    testWidgets('a disabled button stays visible and ignores taps', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const KidsChunkyButton(label: 'Locked', onPressed: null)),
      );

      await tester.tap(find.text('Locked'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Locked'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(KidsChunkyButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
    });

    testWidgets('the face sinks while pressed and rises on release', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(KidsChunkyButton(label: 'Press', onPressed: () {})),
      );
      final restTop = tester.getTopLeft(find.text('Press')).dy;

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Press')),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Press')).dy, greaterThan(restTop));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Press')).dy, restTop);
    });

    testWidgets('fits a long Arabic label on a 320px screen', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          KidsChunkyButton(
            label: 'استمع إلى الآية مرتين قبل أن تسجّل صوتك، ثم حاول من جديد',
            icon: TaliaIcons.listen,
            maxLines: 3,
            onPressed: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('KidsRoundActionButton', () {
    testWidgets('pulses only while active', (tester) async {
      await tester.pumpWidget(
        host(
          KidsRoundActionButton(
            icon: TaliaIcons.play,
            label: 'Listen',
            onPressed: () {},
          ),
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(
        host(
          KidsRoundActionButton(
            icon: TaliaIcons.stop,
            label: 'Listen',
            onPressed: () {},
            active: true,
          ),
        ),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('stays still when active under reduced motion', (tester) async {
      await tester.pumpWidget(
        host(
          KidsRoundActionButton(
            icon: TaliaIcons.mic,
            label: 'Record',
            onPressed: () {},
            active: true,
          ),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('is announced as a button with its label', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          KidsRoundActionButton(
            icon: TaliaIcons.mic,
            label: 'Record',
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.bySemanticsLabel('Record'), findsOneWidget);
      await tester.tap(find.byType(KidsRoundActionButton));
      expect(taps, 1);
    });
  });
}
