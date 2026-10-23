import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/memorization_plus/data/hands_free/hands_free_review_source.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_profile.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

class _Records extends Mock implements MemorizationPlusRepository {}

class _Quran extends Mock implements QuranRepository {}

void main() {
  final now = DateTime.utc(2026, 10, 23);
  final record = AyahReviewRecord(
    surahId: 1,
    ayahNumber: 1,
    strengthLevel: 6,
    intervalDays: 1,
    lastReviewedAt: now,
    nextReviewDate: now,
    totalReviews: 1,
    lastRating: null,
    createdByMode: ReviewRecordCreatedByMode.v2Session,
  );
  late _Records records;
  late _Quran quran;
  late AccountDataBarrier barrier;
  late HandsFreeReviewSource source;
  SurahDetail detail(int ayahNumber) => SurahDetail(
    surah: const Surah(
      id: 1,
      nameAr: 'test',
      nameEn: 'test',
      ayahCount: 1,
      juz: 1,
      type: 'test',
      page: 1,
    ),
    ayahs: [
      Ayah(
        number: 1,
        surahId: 1,
        numberInSurah: ayahNumber,
        text: 'unmodified test target',
      ),
    ],
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const owner = FixedRecordOwnerProvider('owner-a');
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    records = _Records();
    quran = _Quran();
    when(() => records.getMemorizationProfile()).thenAnswer(
      (_) async => Right(
        MemorizationProfile.empty().copyWith(
          selectedPath: MemorizationPath.adult,
        ),
      ),
    );
    when(
      () => records.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
    ).thenAnswer((_) async => Right([record]));
    when(
      () => quran.getSurahDetail(1),
    ).thenAnswer((_) async => Right(detail(1)));
    source = HandsFreeReviewSource(
      records,
      quran,
      owner,
      barrier,
      MemorizationPathResolver(records),
    );
  });
  test(
    'loads exact corpus text with read-only adult repository calls',
    () async {
      final material = await source.load();
      expect(
        material.corpus.textOf(const ListeningAyahRef(1, 1)),
        'unmodified test target',
      );
      expect(material.isCurrent(), isTrue);
      verify(
        () => records.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
      ).called(1);
      verifyNever(() => records.saveReviewRecord(record));
    },
  );
  test('account invalidation discards a delayed corpus load', () async {
    final pending = Completer<SurahDetail>();
    when(
      () => quran.getSurahDetail(1),
    ).thenAnswer((_) async => Right(await pending.future));
    final loading = source.load();
    await Future<void>.delayed(Duration.zero);
    barrier.invalidate();
    pending.complete(detail(1));
    await expectLater(loading, throwsA(isA<AccountDataUnavailableException>()));
  });
  test('malformed ayah numbering fails closed rather than remapping', () async {
    when(
      () => quran.getSurahDetail(1),
    ).thenAnswer((_) async => Right(detail(2)));
    await expectLater(source.load(), throwsStateError);
  });
}
