import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/learning_launch_context.dart';

void main() {
  test('parses a typed learning launch context from route values', () {
    final context = LearningLaunchContext.fromRouteValues(
      surahId: 36,
      startAyah: 3,
      intent: 'review',
      origin: 'smartCoach',
    );

    expect(context.ayah.surahId, 36);
    expect(context.ayah.ayahNumber, 3);
    expect(context.intent, LearningIntent.review);
    expect(context.origin, LearningOrigin.smartCoach);
  });

  test('preserves the Quran reader entry point in the learning route payload', () {
    const context = LearningLaunchContext(
      ayah: AyahReference(surahId: 2, ayahNumber: 255),
      intent: LearningIntent.memorize,
      origin: LearningOrigin.quranReader,
    );

    expect(context.toRouteQuery(), {
      'surahId': '2',
      'startAyah': '255',
      'intent': 'memorize',
      'origin': 'quranReader',
    });
  });
}
