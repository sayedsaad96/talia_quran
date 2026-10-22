import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/v2/self_grade.dart';
import 'package:talia_quran/core/prayer_review/manual_prayer_review_committer.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_offer_service.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_authority.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_selection.dart';
import 'package:talia_quran/features/prayer_review/presentation/cubits/prayer_review_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  late AccountDataBarrier barrier;
  late PrayerReviewOffer offer;
  late PrayerReviewCubit cubit;
  var writes = 0;
  final occurrence = PrayerOccurrence(
    ownerId: 'owner',
    localDate: DateTime(2026, 10, 20),
    prayerKey: PrayerKey.dhuhr,
    scheduledAt: DateTime.utc(2026, 10, 20, 12),
  );
  final bodies = [
    for (var n = 1; n <= 3; n++)
      Ayah(
        number: n,
        surahId: 1,
        numberInSurah: n,
        page: 1,
        text: 'original $n   exact',
      ),
  ];
  Future<PrayerReviewOffer?> Function()? load;
  Future<List<Ayah>> Function()? passage;
  var failSave = false;

  PrayerReviewAuthority capture() =>
      PrayerReviewAuthority(ownerId: 'owner', lease: barrier.capture());
  PrayerReviewCubit create() => PrayerReviewCubit(
    captureAuthority: capture,
    accountChanges: barrier.changes,
    loadOffer: (_, {bool allowSelection = true}) =>
        load?.call() ?? Future.value(offer),
    readPassage: (_) => passage?.call() ?? Future.value(bodies),
    saveGrade: (selected, grade) async {
      expect(identical(selected, offer), isTrue);
      writes++;
      if (failSave) throw StateError('storage failed');
      return ManualPrayerReviewResult(
        alreadyCommitted: false,
        receipt: PrayerReviewReceipt(
          ownerId: 'owner',
          localDayKey: '2026-10-20',
          surahId: 1,
          startAyah: 1,
          endAyah: 3,
          gradeIndex: grade.index,
          committedAt: DateTime.utc(2026, 10, 20, 12),
          eventIds: ['e1', 'e2', 'e3'],
        ),
      );
    },
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    barrier = AccountDataBarrier.forPreferences(prefs)
      ..owner = const FixedRecordOwnerProvider('owner');
    offer = PrayerReviewOffer(
      authority: capture(),
      selection: PrayerReviewSelection(
        ownerId: 'owner',
        localDayKey: '2026-10-20',
        prayerKey: PrayerKey.dhuhr,
        scheduledAt: DateTime.utc(2026, 10, 20, 12),
        selectedAt: DateTime.utc(2026, 10, 20, 11),
        surahId: 1,
        startAyah: 1,
        endAyah: 3,
      ),
    );
    writes = 0;
    load = null;
    passage = null;
    failSave = false;
    cubit = create();
  });
  tearDown(() => cubit.close());

  test('loads exact original passage then saves one manual grade', () async {
    await cubit.load(occurrence);
    expect(cubit.state.status, PrayerReviewStatus.ready);
    expect(cubit.state.ayahs.map((a) => a.text), bodies.map((a) => a.text));
    expect(() => cubit.state.ayahs.clear(), throwsUnsupportedError);
    await cubit.grade(V2SelfGrade.hesitated);
    expect(cubit.state.status, PrayerReviewStatus.saved);
    await cubit.grade(V2SelfGrade.mastered);
    expect(writes, 1);
  });

  test(
    'failed save can retry the same offer without loading a new passage',
    () async {
      await cubit.load(occurrence);
      failSave = true;
      await cubit.grade(V2SelfGrade.forgot);
      expect(cubit.state.status, PrayerReviewStatus.saveFailed);
      expect(identical(cubit.state.offer, offer), isTrue);
      failSave = false;
      await cubit.grade(V2SelfGrade.forgot);
      expect(cubit.state.status, PrayerReviewStatus.saved);
      expect(writes, 2);
    },
  );

  test(
    'invalidation while loading clears private data without resurrection',
    () async {
      final pending = Completer<List<Ayah>>();
      final started = Completer<void>();
      passage = () {
        started.complete();
        return pending.future;
      };
      final loading = cubit.load(occurrence);
      await started.future;
      barrier.invalidate();
      pending.complete(bodies);
      await loading;
      expect(cubit.state.status, PrayerReviewStatus.unavailable);
      expect(cubit.state.offer, isNull);
      expect(cubit.state.ayahs, isEmpty);
      expect(writes, 0);
    },
  );

  test(
    'ordinary progress notification retains a valid loaded passage',
    () async {
      await cubit.load(occurrence);
      barrier.notifyChanged();
      expect(cubit.state.status, PrayerReviewStatus.ready);
      expect(cubit.state.ayahs, bodies);
    },
  );

  test(
    'missing or misnumbered canonical passage fails without partial display',
    () async {
      passage = () async => bodies.take(2).toList();
      await cubit.load(occurrence);
      expect(cubit.state.status, PrayerReviewStatus.loadFailed);
      expect(cubit.state.ayahs, isEmpty);
      expect(writes, 0);
    },
  );
}
