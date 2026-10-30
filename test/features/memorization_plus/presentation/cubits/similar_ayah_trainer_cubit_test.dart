import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/similar_ayah/similar_ayah_attempt_service.dart';
import 'package:talia_quran/core/memorization/similar_ayah/similar_ayah_confusion_detector.dart';
import 'package:talia_quran/core/memorization/learning_launch_context.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/confusion_pair.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/similar_ayah_reference_pair.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/similar_ayah_browsing_source.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/similar_ayah_trainer_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SimilarAyahTrainerCubit', () {
    late AccountDataBarrier barrier;
    late _QuranFake quran;
    late SimilarAyahAttemptService authority;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = const FixedRecordOwnerProvider('adult');
      quran = _QuranFake();
      authority = SimilarAyahAttemptService(
        owner: const FixedRecordOwnerProvider('adult'),
        barrier: barrier,
        isEnabled: () => true,
        readAdultEligibility: () async => true,
        candidates: const UnavailableSimilarAyahCandidateSource(),
      );
    });

    test('flag and adult gates prevent pair and Quran reads', () async {
      var pairReads = 0;
      final disabled = _cubit(
        quran: quran,
        authority: authority,
        readPairs: () async {
          pairReads++;
          return [];
        },
        enabled: false,
      );
      await disabled.load();
      expect(pairReads, 0);
      expect(quran.calls, 0);
      expect(disabled.state.gated, isTrue);
      await disabled.close();
    });

    test(
      'approved browsing works with empty history and in both orientations',
      () async {
        final cubit = _cubit(
          quran: quran,
          authority: authority,
          readPairs: () async => [],
          candidates: _BrowseSource(),
        );
        await cubit.load();
        expect(cubit.state.browsing, hasLength(1));
        expect(cubit.state.pairs, isEmpty);
        await cubit.chooseReference(cubit.state.browsing.single);
        expect(cubit.state.target!.ayah.text, 'text 2 1');
        expect(cubit.state.other!.ayah.text, 'text 2 2');
        await cubit.loadRelated(const AyahReference(surahId: 2, ayahNumber: 2));
        expect(cubit.state.related.single.otherAyahNumber, 1);
        await cubit.close();
      },
    );

    test(
      'enabled child profile cannot read historical pairs or corpus',
      () async {
        var reads = 0;
        final cubit = _cubit(
          quran: quran,
          authority: authority,
          adult: false,
          readPairs: () async {
            reads++;
            return [_pair];
          },
        );
        await cubit.load();
        await cubit.choose(_pair);
        expect(cubit.state.gated, isTrue);
        expect(reads, 0);
        expect(quran.calls, 0);
        await cubit.close();
      },
    );

    test(
      'related lookup reads no history and resolves either pair orientation',
      () async {
        var historyReads = 0;
        final cubit = _cubit(
          quran: quran,
          authority: authority,
          readPairs: () async {
            historyReads++;
            return [_pair];
          },
          candidates: _Candidates(
            (_) async => const [
              SimilarAyahCandidate(key: '2:1', text: 'original body'),
            ],
          ),
        );
        await cubit.loadRelated(const AyahReference(surahId: 2, ayahNumber: 2));
        expect(historyReads, 0);
        expect(quran.calls, 0);
        expect(cubit.state.pairs, isEmpty);
        await cubit.chooseReference(cubit.state.related.single);
        expect(cubit.state.target!.ayah.text, 'text 2 2');
        expect(cubit.state.other!.ayah.text, 'text 2 1');
        expect(cubit.state.other!.previous, isNull);
        expect(quran.calls, 1);
        cubit.showPairs();
        expect(cubit.state.selected, isNull);
        expect(cubit.state.target, isNull);
        expect(cubit.state.related, hasLength(1));
        await cubit.close();
      },
    );

    test(
      'unavailable related source never substitutes historical data',
      () async {
        var historyReads = 0;
        final cubit = _cubit(
          quran: quran,
          authority: authority,
          readPairs: () async {
            historyReads++;
            return [_pair];
          },
          candidates: const UnavailableSimilarAyahCandidateSource(),
        );
        await cubit.loadRelated(const AyahReference(surahId: 2, ayahNumber: 2));
        // An eligible adult is told the list is not approved, never that the
        // account is ineligible (found on a device).
        expect(cubit.state.indexUnavailable, isTrue);
        expect(cubit.state.gated, isFalse);
        expect(cubit.state.available, isTrue);
        expect(historyReads, 0);
        await cubit.close();
      },
    );

    test('retry reuses the selected pair after a corpus failure', () async {
      var reads = 0;
      final cubit = _cubit(
        quran: quran,
        authority: authority,
        readPairs: () async {
          reads++;
          return [_pair];
        },
      );
      await cubit.load();
      quran.failNext = true;
      await cubit.choose(_pair);
      expect(cubit.state.failed, isTrue);
      await cubit.retry();
      expect(cubit.state.failed, isFalse);
      expect(cubit.state.target!.ayah.text, 'text 2 2');
      expect(reads, 1);
      await cubit.close();
    });

    test('ordinary account notification retains loaded passages', () async {
      final cubit = _cubit(quran: quran, authority: authority);
      await cubit.load();
      await cubit.choose(_pair);
      final target = cubit.state.target;
      barrier.notifyChanged();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.available, isTrue);
      expect(cubit.state.target, target);
      await cubit.close();
    });

    test('invalidation during a corpus load clears exact passages', () async {
      final pending = Completer<Either<Failure, SurahDetail>>();
      quran.pending = pending;
      final cubit = _cubit(quran: quran, authority: authority);
      await cubit.load();
      final choosing = cubit.choose(_pair);
      await Future<void>.delayed(Duration.zero);
      barrier.invalidate();
      pending.complete(Right(_detail(2)));
      await choosing;
      expect(cubit.state.available, isFalse);
      expect(cubit.state.target, isNull);
      expect(cubit.state.other, isNull);
      await cubit.close();
    });

    test(
      'loads only same-surah previous context and never crosses a first ayah',
      () async {
        final cubit = _cubit(quran: quran, authority: authority);
        await cubit.load();
        await cubit.choose(_pair);
        expect(cubit.state.target!.previous!.numberInSurah, 1);
        await cubit.choose(_pair.copyWith(targetAyahNumber: 1));
        expect(cubit.state.target!.previous, isNull);
        await cubit.close();
      },
    );
  });
}

final _pair = ConfusionPair(
  targetSurahId: 2,
  targetAyahNumber: 2,
  otherSurahId: 3,
  otherAyahNumber: 1,
  count: 2,
  firstAt: DateTime.utc(2026),
  lastAt: DateTime.utc(2026),
);

SimilarAyahTrainerCubit _cubit({
  required _QuranFake quran,
  required SimilarAyahAttemptService authority,
  Future<List<ConfusionPair>> Function()? readPairs,
  bool enabled = true,
  bool adult = true,
  SimilarAyahCandidateSource? candidates,
}) => SimilarAyahTrainerCubit(
  readPairs: readPairs ?? () async => [_pair],
  quran: quran,
  captureAuthority: () =>
      authority.captureAuthority() ??
      (throw const AccountDataUnavailableException()),
  accountChanges: authority.accountChanges,
  readAdultEligibility: () async => adult,
  isEnabled: () => enabled,
  candidateSource: candidates,
);

SurahDetail _detail(int id) => SurahDetail(
  surah: Surah(
    id: id,
    nameAr: 'x',
    nameEn: 'x',
    ayahCount: 3,
    juz: 1,
    type: 'x',
    page: 1,
  ),
  ayahs: [
    for (var number = 1; number <= 3; number++)
      Ayah(
        number: number,
        surahId: id,
        text: 'text $id $number',
        numberInSurah: number,
      ),
  ],
);

final class _QuranFake implements QuranRepository {
  int calls = 0;
  bool failNext = false;
  Completer<Either<Failure, SurahDetail>>? pending;
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int id) {
    calls++;
    if (failNext) {
      failNext = false;
      return Future.value(const Left(CacheFailure()));
    }
    final wait = pending;
    return wait?.future ?? Future.value(Right(_detail(id)));
  }

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() async => const Right([]);
  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int page) async =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) async =>
      const Right([]);
  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) async =>
      const Right([]);
}

final class _Candidates implements SimilarAyahCandidateSource {
  const _Candidates(this.load);
  final Future<List<SimilarAyahCandidate>?> Function(String) load;
  @override
  Future<List<SimilarAyahCandidate>?> loadCandidates(String targetKey) =>
      load(targetKey);
}

final class _BrowseSource
    implements SimilarAyahCandidateSource, SimilarAyahBrowsingSource {
  @override
  Future<List<SimilarAyahCandidate>?> loadCandidates(String targetKey) async =>
      [];
  @override
  Future<List<SimilarAyahReferencePair>?> loadBrowsingPairs() async => const [
    SimilarAyahReferencePair(
      targetSurahId: 2,
      targetAyahNumber: 1,
      otherSurahId: 2,
      otherAyahNumber: 2,
    ),
  ];
}

extension on ConfusionPair {
  ConfusionPair copyWith({int? targetAyahNumber}) => ConfusionPair(
    targetSurahId: targetSurahId,
    targetAyahNumber: targetAyahNumber ?? this.targetAyahNumber,
    otherSurahId: otherSurahId,
    otherAyahNumber: otherAyahNumber,
    count: count,
    firstAt: firstAt,
    lastAt: lastAt,
  );
}
