import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/presentation/widgets/quran_audio_equalizer.dart';

void main() {
  testWidgets('renders 4 equalizer bars', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuranAudioEqualizer(
            isPlaying: true,
            color: Colors.green,
          ),
        ),
      ),
    );

    // Fast-forward animation frames
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(QuranAudioEqualizer), findsOneWidget);
    // Find all bar containers (4 bars)
    final rowFinder = find.descendant(
      of: find.byType(QuranAudioEqualizer),
      matching: find.byType(Row),
    );
    expect(rowFinder, findsOneWidget);

    final containers = find.descendant(
      of: rowFinder,
      matching: find.byType(Container),
    );
    expect(containers, findsNWidgets(4));
  });

  testWidgets('updates gracefully when isPlaying changes from true to false', (tester) async {
    bool isPlaying = true;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  QuranAudioEqualizer(
                    isPlaying: isPlaying,
                    color: Colors.amber,
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => isPlaying = false),
                    child: const Text('Toggle'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Toggle'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(QuranAudioEqualizer), findsOneWidget);
  });
}
