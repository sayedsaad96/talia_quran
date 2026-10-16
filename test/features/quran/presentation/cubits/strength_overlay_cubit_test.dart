import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/strength_band.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/strength_overlay_cubit.dart';
import 'package:talia_quran/features/quran/presentation/services/strength_overlay_source.dart';

class _MockRepo extends Mock implements MemorizationPlusRepository {}

final _now = DateTime.utc(2026, 10, 16, 12);

AyahReviewRecord _rec(int surah, int ayah, int level) => AyahReviewRecord(
  surahId: surah,
  ayahNumber: ayah,
  strengthLevel: level,
  intervalDays: 1,
  lastReviewedAt: _now.subtract(const Duration(days: 1)),
  nextReviewDate: _now.add(const Duration(days: 3)),
  totalReviews: 2,
  lastRating: PerformanceRating.average,
);

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  late _MockRepo repo;
  late ProgressEventsBus bus;
  late String owner;
  late List<AyahReviewRecord> adult;
  late int adultReads;
  const key = 'reader_strength_overlay_on';

  StrengthOverlayCubit build(SharedPreferences prefs) => StrengthOverlayCubit(
    repository: repo,
    events: bus,
    source: StrengthOverlaySource(
      pageRanges: (page) => page == 2 ? [(surah: 2, start: 1, end: 4)] : [],
    ),
    prefs: prefs,
    clock: () => _now,
    currentOwnerId: () => owner,
  );

  setUpAll(() => registerFallbackValue(ReviewRecordReadScope.adult));

  setUp(() {
    repo = _MockRepo();
    bus = ProgressEventsBus();
    owner = 'owner-a';
    adult = [_rec(2, 1, 1)];
    adultReads = 0;
    when(() => repo.getAllReviewRecords(scope: any(named: 'scope'))).thenAnswer(
      (inv) async {
        final scope = inv.namedArguments[#scope] as ReviewRecordReadScope;
        if (scope != ReviewRecordReadScope.adult) {
          return Right([_rec(2, 2, 6)]);
        }
        adultReads++;
        return Right(List.of(adult));
      },
    );
  });

  tearDown(() => bus.dispose());

  test('off: bandsForPage empty and no records read', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = build(await SharedPreferences.getInstance());
    await cubit.init();
    expect(cubit.state.enabled, isFalse);
    expect(cubit.bandsForPage(2), isEmpty);
    expect(adultReads, 0);
    await cubit.close();
  });

  test('on: bands come from adult records only', () async {
    SharedPreferences.setMockInitialValues({key: true});
    final cubit = build(await SharedPreferences.getInstance());
    await cubit.init();
    expect(cubit.bandsForPage(2), {(surah: 2, ayah: 1): StrengthBand.weak});
    await cubit.close();
  });

  test('reviewRecord event reloads and bumps revision', () async {
    SharedPreferences.setMockInitialValues({key: true});
    final cubit = build(await SharedPreferences.getInstance());
    await cubit.init();
    final before = cubit.state.revision;
    adult = [_rec(2, 1, 6)];
    bus.notify(ProgressChangedReason.reviewRecord);
    await _pump();
    expect(cubit.state.revision, greaterThan(before));
    expect(cubit.bandsForPage(2), {(surah: 2, ayah: 1): StrengthBand.solid});
    await cubit.close();
  });

  test('cloudPull reloads; unrelated events do not', () async {
    SharedPreferences.setMockInitialValues({key: true});
    final cubit = build(await SharedPreferences.getInstance());
    await cubit.init();
    final reads = adultReads;
    bus.notify(ProgressChangedReason.xp);
    await _pump();
    expect(adultReads, reads);
    bus.notify(ProgressChangedReason.cloudPull);
    await _pump();
    expect(adultReads, reads + 1);
    await cubit.close();
  });

  test('owner switch: empty map now, reloaded for the new owner', () async {
    SharedPreferences.setMockInitialValues({key: true});
    final cubit = build(await SharedPreferences.getInstance());
    await cubit.init();
    owner = 'owner-b';
    adult = [_rec(2, 3, 6)];
    expect(cubit.bandsForPage(2), isEmpty);
    await _pump();
    expect(cubit.bandsForPage(2), {(surah: 2, ayah: 3): StrengthBand.solid});
    await cubit.close();
  });

  test('toggle persists across cubit instances; off clears', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = build(prefs);
    await first.init();
    await first.setEnabled(true);
    expect(first.bandsForPage(2), isNotEmpty);
    await first.close();

    final second = build(prefs);
    await second.init();
    expect(second.state.enabled, isTrue);
    expect(second.bandsForPage(2), isNotEmpty);
    await second.setEnabled(false);
    expect(second.bandsForPage(2), isEmpty);
    expect(prefs.getBool(key), isFalse);
    await second.close();
  });

  test(
    'off then on during an in-flight reload ends enabled with bands',
    () async {
      SharedPreferences.setMockInitialValues({key: true});
      final cubit = build(await SharedPreferences.getInstance());
      await cubit.init();
      final gate = Completer<Either<Failure, List<AyahReviewRecord>>>();
      when(
        () => repo.getAllReviewRecords(scope: any(named: 'scope')),
      ).thenAnswer((_) => gate.future);
      bus.notify(ProgressChangedReason.reviewRecord);
      await _pump();
      await cubit.setEnabled(false);
      await cubit.setEnabled(true);
      gate.complete(Right([_rec(2, 1, 6)]));
      await _pump();
      await _pump();
      expect(cubit.state.enabled, isTrue);
      expect(cubit.bandsForPage(2), isNotEmpty);
      await cubit.close();
    },
  );

  test('close cancels the bus subscription', () async {
    SharedPreferences.setMockInitialValues({key: true});
    final cubit = build(await SharedPreferences.getInstance());
    await cubit.init();
    await cubit.close();
    final reads = adultReads;
    bus.notify(ProgressChangedReason.reviewRecord);
    await _pump();
    expect(adultReads, reads);
  });
}
