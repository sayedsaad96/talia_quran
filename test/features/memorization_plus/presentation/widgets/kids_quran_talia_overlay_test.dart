import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_quran_row_layout.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_quran_talia_overlay.dart';

void main() {
  group('kidsQuranWalkOrigin', () {
    test('the nearest celebrated row below the current one wins', () {
      expect(
        kidsQuranWalkOrigin(celebratedIndexes: const [2], currentIndex: 3),
        2,
      );
    });

    test('no celebrated rows means no walk', () {
      expect(
        kidsQuranWalkOrigin(celebratedIndexes: const [], currentIndex: 3),
        isNull,
      );
    });

    test('standing on the celebrated row means no walk', () {
      expect(
        kidsQuranWalkOrigin(celebratedIndexes: const [3], currentIndex: 3),
        isNull,
      );
    });

    test('a celebrated row more than 3 rows away is ignored', () {
      expect(
        kidsQuranWalkOrigin(celebratedIndexes: const [10], currentIndex: 3),
        isNull,
      );
    });

    test('a tie walks from the smaller index', () {
      expect(
        kidsQuranWalkOrigin(celebratedIndexes: const [1, 5], currentIndex: 3),
        1,
      );
    });

    test('a negative current index means no walk', () {
      expect(
        kidsQuranWalkOrigin(celebratedIndexes: const [2], currentIndex: -1),
        isNull,
      );
    });
  });

  group('KidsQuranTaliaOverlay', () {
    // The harness viewport is 400 x 1000 and the row extent is 200, so a
    // row's taliaFoot is (96, 76) for even rows and (304, 76) for odd ones.
    // With the controller at offset 0 the absolute feet are row 2 -> (96,
    // 476) and row 3 -> (304, 676); Talia is 72 x 72 with her bottom-centre
    // on the foot.
    Widget harness({
      required int currentIndex,
      int? walkFromIndex,
      Object? walkKey,
      bool disableAnimations = false,
      ScrollController? controller,
    }) {
      // A caller-supplied controller may outlive this pumpWidget (the
      // walk-arrival tests rebuild the same overlay), so only a controller
      // created here is torn down here.
      final ownsController = controller == null;
      controller ??= ScrollController();
      if (ownsController) addTearDown(controller.dispose);
      return MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 1000,
            child: Stack(
              children: [
                ListView.builder(
                  controller: controller,
                  itemExtent: kKidsQuranJourneyItemExtent,
                  itemCount: 10,
                  itemBuilder: (_, _) => const SizedBox.shrink(),
                ),
                Positioned.fill(
                  child: KidsQuranTaliaOverlay(
                    controller: controller,
                    currentIndex: currentIndex,
                    walkFromIndex: walkFromIndex,
                    walkKey: walkKey,
                    direction: TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Future<void> pumpHarness(
      WidgetTester tester, {
      required int currentIndex,
      int? walkFromIndex,
      Object? walkKey,
      bool disableAnimations = false,
      ScrollController? controller,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        harness(
          currentIndex: currentIndex,
          walkFromIndex: walkFromIndex,
          walkKey: walkKey,
          disableAnimations: disableAnimations,
          controller: controller,
        ),
      );
    }

    Image taliaImage(WidgetTester tester, String pose) => tester.widget<Image>(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/images/talia/$pose',
      ),
    );

    Positioned taliaPosition(WidgetTester tester) => tester.widget<Positioned>(
      find
          .ancestor(
            of: find.byWidgetPredicate(
              (w) =>
                  w is Image &&
                  w.image is AssetImage &&
                  (w.image as AssetImage).assetName.startsWith(
                    'assets/images/talia/',
                  ),
            ),
            matching: find.byWidgetPredicate((w) => w is Positioned),
          )
          .first,
    );

    testWidgets('renders nothing when there is no current house', (
      tester,
    ) async {
      await pumpHarness(tester, currentIndex: -1);
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName.startsWith('assets/images/'),
        ),
        findsNothing,
      );
    });

    testWidgets('with animations disabled she stands on the current row and '
        'nothing animates', (tester) async {
      await pumpHarness(
        tester,
        currentIndex: 3,
        walkFromIndex: 2,
        disableAnimations: true,
      );
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
      taliaImage(tester, 'talia_reading_quran.png');
      final position = taliaPosition(tester);
      expect(position.left, 268); // row 3 foot x (304) - 36
      expect(position.top, 604); // 3 * 200 + 76 - 72
    });

    testWidgets('with animations allowed she breathes', (tester) async {
      await pumpHarness(tester, currentIndex: 3);
      await tester.pump(const Duration(seconds: 1));

      final transform = tester.widget<Transform>(
        find
            .ancestor(
              of: find.byWidgetPredicate(
                (w) =>
                    w is Image &&
                    w.image is AssetImage &&
                    (w.image as AssetImage).assetName ==
                        'assets/images/talia/talia_reading_quran.png',
              ),
              matching: find.byWidgetPredicate((w) => w is Transform),
            )
            .first,
      );
      final scale = transform.transform.storage[0];
      expect(scale, inInclusiveRange(0.98, 1.02));
      expect(scale, isNot(equals(1.0)));
    });

    testWidgets('she walks from the celebrated row to the current one', (
      tester,
    ) async {
      await pumpHarness(tester, currentIndex: 3, walkFromIndex: 2);

      // The walk starts after the star-pop's 600 ms delay. At walk t = 0 she
      // celebrates on row 2's foot.
      await tester.pump(const Duration(milliseconds: 600));
      taliaImage(tester, 'talia_celebrate.png');
      var position = taliaPosition(tester);
      expect(position.left, 60); // row 2 foot x (96) - 36
      expect(position.top, 404); // 2 * 200 + 76 - 72

      // 600 ms delay + 1500 ms walk < 2200 ms, so the walk has ended and she
      // reads on row 3's foot.
      await tester.pump(const Duration(milliseconds: 1600));
      taliaImage(tester, 'talia_reading_quran.png');
      position = taliaPosition(tester);
      expect(position.left, 268);
      expect(position.top, 604);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a walk origin arriving on a live overlay still plays the '
        'walk', (tester) async {
      // The map reloads its cubit while mounted, so the overlay receives
      // walkFromIndex on a widget update, not on first mount.
      final controller = ScrollController();
      await pumpHarness(tester, currentIndex: 3, controller: controller);
      await tester.pump();

      await tester.pumpWidget(
        harness(currentIndex: 3, walkFromIndex: 2, controller: controller),
      );

      // The walk starts after the star-pop's 600 ms delay. At walk t = 0 she
      // celebrates on row 2's foot.
      await tester.pump(const Duration(milliseconds: 700));
      taliaImage(tester, 'talia_celebrate.png');
      var position = taliaPosition(tester);
      expect(position.left, 60); // row 2 foot x (96) - 36
      expect(position.top, 404); // 2 * 200 + 76 - 72

      // 700 ms + 1500 ms walk < 2300 ms, so the walk has ended and she
      // reads on row 3's foot.
      await tester.pump(const Duration(milliseconds: 1600));
      taliaImage(tester, 'talia_reading_quran.png');
      position = taliaPosition(tester);
      expect(position.left, 268);
      expect(position.top, 604);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a repeated rebuild with the same walk origin does not '
        'replay the walk', (tester) async {
      final controller = ScrollController();
      await pumpHarness(tester, currentIndex: 3, controller: controller);
      await tester.pump();
      await tester.pumpWidget(
        harness(currentIndex: 3, walkFromIndex: 2, controller: controller),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 1600));
      taliaImage(tester, 'talia_reading_quran.png');

      // Same walkFromIndex again (no null -> set flip): no second walk.
      await tester.pumpWidget(
        harness(currentIndex: 3, walkFromIndex: 2, controller: controller),
      );
      await tester.pump(const Duration(milliseconds: 700));
      taliaImage(tester, 'talia_reading_quran.png');
      final position = taliaPosition(tester);
      expect(position.left, 268);
      expect(position.top, 604);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a second celebration on the same live overlay walks again', (
      tester,
    ) async {
      // The child finishes surah A, returns (walk), then finishes surah B
      // without leaving the map: each completion gets its own walk.
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final first = <int>{2};
      await pumpHarness(
        tester,
        currentIndex: 3,
        walkFromIndex: 2,
        walkKey: first,
        controller: controller,
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 1600));
      taliaImage(tester, 'talia_reading_quran.png');

      // A return with no completion: no origin, nothing replays.
      await tester.pumpWidget(
        harness(
          currentIndex: 3,
          walkKey: const <int>{},
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      taliaImage(tester, 'talia_reading_quran.png');

      final second = <int>{3};
      await tester.pumpWidget(
        harness(
          currentIndex: 4,
          walkFromIndex: 3,
          walkKey: second,
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      taliaImage(tester, 'talia_celebrate.png');
      var position = taliaPosition(tester);
      expect(position.left, 268); // row 3 foot x (304) - 36
      expect(position.top, 604); // 3 * 200 + 76 - 72

      await tester.pump(const Duration(milliseconds: 1600));
      taliaImage(tester, 'talia_reading_quran.png');
      position = taliaPosition(tester);
      expect(position.top, 804); // row 4: 4 * 200 + 76 - 72

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('without a walk origin she stands and reads on the current '
        'row from the start', (tester) async {
      await pumpHarness(tester, currentIndex: 3);
      await tester.pump();

      taliaImage(tester, 'talia_reading_quran.png');
      final position = taliaPosition(tester);
      expect(position.left, 268);
      expect(position.top, 604);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
