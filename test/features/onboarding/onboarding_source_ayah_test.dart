import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/onboarding/presentation/widgets/onboarding_source_ayah.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

const _surah = Surah(
  id: 1,
  nameAr: 'الفاتحة',
  nameEn: 'Al-Fatihah',
  ayahCount: 7,
  juz: 1,
  type: 'meccan',
  page: 1,
);

class _Repo implements QuranRepository {
  _Repo(this.ayahs);
  final List<Ayah> ayahs;
  int calls = 0;

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async {
    calls++;
    return Right(SurahDetail(surah: _surah, ayahs: ayahs));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('not used');
}

Widget _host(Widget child) => MaterialApp(
  home: Directionality(textDirection: TextDirection.rtl, child: child),
);

void main() {
  setUp(() async {
    await getIt.reset();
    OnboardingSourceAyah.resetCacheForTest();
  });
  tearDown(() => getIt.reset());

  testWidgets('shows the ayah verbatim from the source, BOM stripped', (
    tester,
  ) async {
    getIt.registerSingleton<QuranRepository>(
      _Repo(const [
        Ayah(number: 1, surahId: 1, text: '﻿نص المصدر', numberInSurah: 1),
        Ayah(number: 2, surahId: 1, text: 'آية ثانية', numberInSurah: 2),
      ]),
    );

    await tester.pumpWidget(
      _host(
        OnboardingSourceAyah(
          surah: 1,
          ayah: 1,
          builder: (context, text) => Text('[$text]'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('[نص المصدر]'), findsOneWidget);
  });

  testWidgets('renders nothing when the Quran source is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        OnboardingSourceAyah(
          surah: 1,
          ayah: 1,
          builder: (context, text) => Text('[$text]'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('['), findsNothing);
  });

  testWidgets('renders nothing when the ayah does not exist', (tester) async {
    getIt.registerSingleton<QuranRepository>(_Repo(const []));

    await tester.pumpWidget(
      _host(
        OnboardingSourceAyah(
          surah: 1,
          ayah: 9,
          builder: (context, text) => Text('[$text]'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('['), findsNothing);
  });

  testWidgets('loads each surah once across rebuilds', (tester) async {
    final repo = _Repo(const [
      Ayah(number: 1, surahId: 1, text: 'أ', numberInSurah: 1),
      Ayah(number: 2, surahId: 1, text: 'ب', numberInSurah: 2),
    ]);
    getIt.registerSingleton<QuranRepository>(repo);

    await tester.pumpWidget(
      _host(
        Column(
          children: [
            OnboardingSourceAyah(surah: 1, ayah: 1, builder: (_, t) => Text(t)),
            OnboardingSourceAyah(surah: 1, ayah: 2, builder: (_, t) => Text(t)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('أ'), findsOneWidget);
    expect(find.text('ب'), findsOneWidget);
    expect(repo.calls, 1);
  });
}
