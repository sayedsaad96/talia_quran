import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/learning_launch_context.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/memorization_navigation_resolver.dart';

void main() {
  test('weak-link location opens a V2 review of exactly that ayah', () {
    final uri = Uri.parse(
      MemorizationNavigationResolver.reviewAyahLocation(36, 12),
    );

    expect(uri.path, AppRoutes.memorizationV2Session);
    final context = LearningLaunchContext.fromRouteValues(
      surahId: int.parse(uri.queryParameters['surahId']!),
      startAyah: int.parse(uri.queryParameters['startAyah']!),
      intent: uri.queryParameters['intent'],
      origin: uri.queryParameters['origin'],
    );
    expect(context.ayah.surahId, 36);
    expect(context.ayah.ayahNumber, 12);
    expect(context.intent, LearningIntent.review);
    expect(context.origin, LearningOrigin.review);
    expect(uri.queryParameters.containsKey('blockSize'), isFalse);
  });
}
