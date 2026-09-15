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
}
