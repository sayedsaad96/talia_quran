import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/router/app_router.dart';

void main() {
  test('missing or disabled flag prevents trainer navigation', () {
    expect(similarAyahTrainerRedirect(null), AppRoutes.memorizationHub);
    expect(
      similarAyahTrainerRedirect(ExperienceFlags((_) => false)),
      AppRoutes.memorizationHub,
    );
    expect(similarAyahTrainerRedirect(ExperienceFlags((_) => true)), isNull);
  });

  test('invalid explicit ayah never silently opens historical list', () {
    for (final query in [
      {'surahId': '2'},
      {'ayah': '1'},
      {'surahId': '0', 'ayah': '1'},
      {'surahId': '2', 'ayah': '287'},
      {'surahId': '115', 'ayah': '1'},
      {'surahId': '2', 'ayah': 'x'},
      {'surahId': '2', 'ayah': '-1'},
    ]) {
      expect(similarAyahTargetRedirect(query), AppRoutes.quran);
    }
    expect(similarAyahTargetRedirect({}), isNull);
    expect(similarAyahTargetRedirect({'surahId': '2', 'ayah': '286'}), isNull);
  });

  test('invalid detected-pair params fall back to the plain list', () {
    const ok = {
      'surahId': '2',
      'ayah': '35',
      'otherSurahId': '7',
      'otherAyah': '19',
    };
    expect(similarAyahPairRedirect(ok), isNull);
    expect(similarAyahPairRedirect({'surahId': '2', 'ayah': '35'}), isNull);
    for (final bad in [
      {...ok, 'otherAyah': '300'},
      {...ok, 'otherSurahId': '0'},
      {...ok, 'otherAyah': 'x'},
      {...ok, 'otherSurahId': '2', 'otherAyah': '35'},
      {'otherSurahId': '7', 'otherAyah': '19'},
      {...ok, 'surahId': '999'},
      {'surahId': '2', 'ayah': '35', 'otherAyah': '19'},
    ]) {
      expect(similarAyahPairRedirect(bad), AppRoutes.similarAyahTrainer);
    }
  });
}
