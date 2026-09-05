import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/extensions/context_extensions.dart';

void main() {
  testWidgets('showAutoDismissSnackBar configures persist: false and auto-dismisses', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  context.showAutoDismissSnackBar(
                    'Test message',
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(label: 'Undo', onPressed: () {}),
                  );
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Test message'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.persist, isFalse);

    // Advance time past duration and exit animation
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Test message'), findsNothing);
  });
}
