import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_profile.dart';

class _Repository extends Mock implements MemorizationPlusRepository {}

void main() {
  tearDown(() => getIt.reset());
  for (final enabled in [false, true]) {
    for (final adult in [false, true]) {
      test('hands-free route enabled=$enabled adult=$adult', () {
        expect(
          handsFreeReviewRedirect(
            ExperienceFlags((_) => enabled),
            isAdult: adult,
          ),
          enabled && adult ? null : AppRoutes.memorizationHub,
        );
      });
    }
  }
  test('missing flags cannot enter hands-free', () {
    expect(
      handsFreeReviewRedirect(null, isAdult: true),
      AppRoutes.memorizationHub,
    );
  });
  for (final path in [null, MemorizationPath.child, MemorizationPath.adult]) {
    test('route resolves profile before entry: $path', () async {
      final repo = _Repository();
      when(() => repo.getMemorizationProfile()).thenAnswer(
        (_) async => Right(
          MemorizationProfile.empty().copyWith(selectedPath: path),
        ),
      );
      getIt.registerSingleton<MemorizationPlusRepository>(repo);
      expect(
        await MemorizationRouteGuard.handsFreeRedirect(
          ExperienceFlags((_) => true),
        ),
        path == MemorizationPath.adult ? null : AppRoutes.memorizationHub,
      );
    });
  }
  test('unavailable profile cannot open hands-free', () async {
    expect(
      await MemorizationRouteGuard.handsFreeRedirect(
        ExperienceFlags((_) => true),
      ),
      AppRoutes.memorizationHub,
    );
  });
}
