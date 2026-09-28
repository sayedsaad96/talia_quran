import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/presentation/widgets/app_quran_page_view.dart';

void main() {
  testWidgets('long press reaches the Mushaf content gesture handler', (
    tester,
  ) async {
    var longPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MushafZoomablePage(
            child: GestureDetector(
              key: const Key('mushaf_content'),
              behavior: HitTestBehavior.opaque,
              onLongPress: () => longPressed = true,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.byKey(const Key('mushaf_content')));

    expect(longPressed, isTrue);
  });

  testWidgets('pinch and page swipe do not trigger a gesture assertion', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    final zoomed = ValueNotifier(false);
    addTearDown(zoomed.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: zoomed,
            builder: (context, isZoomed, child) => PageView(
              controller: controller,
              physics: isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              children: [
                MushafZoomablePage(
                  onZoomChanged: (value) => zoomed.value = value,
                  child: const ColoredBox(color: Colors.white),
                ),
                const MushafZoomablePage(
                  child: ColoredBox(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(InteractiveViewer), findsOneWidget);

    final center = tester.getCenter(find.byType(MushafZoomablePage).first);
    final first = await tester.startGesture(center + const Offset(-35, 0));
    final second = await tester.startGesture(center + const Offset(35, 0));
    await first.moveBy(const Offset(-55, 0));
    await second.moveBy(const Offset(55, 0));
    await tester.pump();
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );
    expect(zoomed.value, isTrue);
    await first.up();
    await second.moveBy(const Offset(-200, 0));
    await tester.pump();
    await second.up();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(controller.page, closeTo(0, 0.01));

    await tester.drag(
      find.byType(MushafZoomablePage).first,
      const Offset(-500, 0),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(controller.page, closeTo(0, 0.01));

    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      closeTo(1, 0.01),
    );
    expect(zoomed.value, isFalse);

    await tester.drag(
      find.byType(MushafZoomablePage).first,
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(controller.page, closeTo(1, 0.01));
  });
}
