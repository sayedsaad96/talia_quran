import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/hifz/data/datasources/hifz_local_datasource.dart';
import 'package:talia_quran/features/hifz/data/repositories/hifz_repository_impl.dart';
import 'package:talia_quran/features/hifz/domain/entities/hifz_entities.dart';
import 'package:talia_quran/features/quran/data/datasources/quran_local_datasource.dart';

class _NoopHifzDs extends Fake implements HifzLocalDatasource {}

class _NoopQuranDs extends Fake implements QuranLocalDatasource {}

void main() {
  test('HifzRepository write APIs reject after IS-5 retirement', () async {
    final repo = HifzRepositoryImpl(_NoopHifzDs(), _NoopQuranDs());
    final now = DateTime.utc(2026, 8, 8);

    final saveProgress = await repo.saveAyahProgress(
      AyahProgress(
        surahId: 1,
        ayahNumber: 1,
        status: AyahStatus.learning,
        repetitions: 1,
        nextReviewDate: now,
        lastReviewDate: now,
      ),
    );
    expect(saveProgress.isLeft(), isTrue);
    expect(
      saveProgress.fold((f) => f, (_) => null),
      isA<CacheFailure>(),
    );

    final savePath = await repo.saveHifzPath('forward');
    expect(savePath.isLeft(), isTrue);
  });

  test('presentation and router no longer call Hifz saveAyahProgress', () {
    final roots = [
      Directory('lib/features/memorization_plus/presentation'),
      Directory('lib/core/router'),
    ];
    for (final dir in roots) {
      if (!dir.existsSync()) continue;
      for (final file in dir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final source = file.readAsStringSync();
        expect(
          source.contains('saveAyahProgress'),
          isFalse,
          reason: '${file.path} must not call retired Hifz writes',
        );
      }
    }
  });
}
