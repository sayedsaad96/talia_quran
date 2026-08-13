import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy Hifz presentation files are gone from production', () {
    final root = Directory.current.path;
    final retired = [
      'lib/features/hifz/presentation/pages/hifz_page.dart',
      'lib/features/hifz/presentation/cubits/hifz_cubit.dart',
      'lib/features/hifz/presentation/cubits/hifz_state.dart',
    ];
    for (final rel in retired) {
      expect(
        File('$root/$rel').existsSync(),
        isFalse,
        reason: '$rel must not ship in production after IS-3',
      );
    }
  });

  test('practice-surah route builds PracticeSurahPage, not HifzPage', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    expect(router.contains('PracticeSurahPage'), isTrue);
    expect(router.contains('HifzPage'), isFalse);
    expect(router.contains("hifz/presentation/pages/hifz_page.dart"), isFalse);
  });

  test('DI registers PracticeSurahCubit instead of HifzCubit', () {
    final di = File('lib/core/di/injection.dart').readAsStringSync();
    expect(di.contains('PracticeSurahCubit'), isTrue);
    expect(di.contains('HifzCubit'), isFalse);
  });

  test('Hifz unlock rules shim is absent after IS-5', () {
    expect(
      File('lib/features/hifz/domain/hifz_unlock_rules.dart').existsSync(),
      isFalse,
    );
  });
}
