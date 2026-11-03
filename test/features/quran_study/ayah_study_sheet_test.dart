import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/quran_study/domain/entities/study_entry.dart';
import 'package:talia_quran/features/quran_study/domain/repositories/quran_study_repository.dart';
import 'package:talia_quran/features/quran_study/domain/usecases/get_ayah_study.dart';
import 'package:talia_quran/features/quran_study/presentation/widgets/ayah_study_sheet.dart';

class FixtureRepository implements QuranStudyRepository {
  @override
  Future<StudyLoadResult> getAyahStudy({
    required int surahId,
    required int ayahNumber,
    required StudyKind kind,
  }) async => StudyLoadResult(
    StudyLoadStatus.ready,
    source: const StudySource(
      id: 'test',
      title: 'Synthetic work',
      publisher: 'Fixture',
      edition: 'v1',
      url: 'https://example.test',
      language: 'ar',
      attribution: 'Fixture attribution',
    ),
    entries: [
      StudyBlock(
        sourceId: 'test',
        blockId: 'a',
        surahId: 1,
        fromAyah: 1,
        toAyah: 2,
        kind: kind,
        language: 'ar',
        text: '<b>fixture</b>',
        footnotes: ['fixture note'],
      ),
    ],
  );
}

void main() {
  for (final locale in ['ar', 'en']) {
    testWidgets('study content remains readable at 200% in $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: AyahStudySheet(
              surahId: 1,
              ayahNumber: 1,
              getAyahStudy: GetAyahStudy(FixtureRepository()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('<b>fixture</b>'), findsOneWidget);
      expect(find.text('fixture note'), findsOneWidget);
    });
  }
  testWidgets('shows source, range, literal text and footnote', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AyahStudySheet(
            surahId: 1,
            ayahNumber: 1,
            getAyahStudy: GetAyahStudy(FixtureRepository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1:1–2'), findsOneWidget);
    expect(find.text('<b>fixture</b>'), findsOneWidget);
    expect(find.text('fixture note'), findsOneWidget);
    expect(find.textContaining('Synthetic work'), findsOneWidget);
  });
}
