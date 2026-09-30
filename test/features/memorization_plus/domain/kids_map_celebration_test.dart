import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/kids_map_celebration_store.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_map_celebration.dart';

KidsJourneyStage _stage(
  int number, {
  KidsJourneyStageStatus status = KidsJourneyStageStatus.current,
}) => KidsJourneyStage(
  stageNumber: number,
  surahId: 114,
  startAyah: number,
  endAyah: number,
  completedAyahs: status == KidsJourneyStageStatus.current
      ? const []
      : [number],
  status: status,
);

const _done = KidsJourneyStageStatus.completed;

void main() {
  group('kidsHousesToCelebrate (K37)', () {
    final stages = [
      _stage(1, status: _done),
      _stage(2, status: KidsJourneyStageStatus.needsReview),
      _stage(3),
    ];

    test('the first visit celebrates nothing', () {
      expect(
        kidsHousesToCelebrate(seenCompleted: null, stages: stages),
        isEmpty,
      );
    });

    test('a house completed since the last visit glows', () {
      expect(kidsHousesToCelebrate(seenCompleted: {1}, stages: stages), {2});
    });

    test('nothing new, nothing glows', () {
      expect(
        kidsHousesToCelebrate(seenCompleted: {1, 2}, stages: stages),
        isEmpty,
      );
    });
  });

  group('KidsMapCelebrationStore (K37)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<KidsMapCelebrationStore> storeFor(String owner) async =>
        KidsMapCelebrationStore(
          await SharedPreferences.getInstance(),
          FixedRecordOwnerProvider(owner),
        );

    test('each new completion glows exactly once', () async {
      final store = await storeFor('owner-a');

      expect(
        await store.takeNewlyCompleted(114, [_stage(1, status: _done)]),
        isEmpty,
      );
      expect(
        await store.takeNewlyCompleted(114, [
          _stage(1, status: _done),
          _stage(2, status: _done),
        ]),
        {2},
      );
      expect(
        await store.takeNewlyCompleted(114, [
          _stage(1, status: _done),
          _stage(2, status: _done),
        ]),
        isEmpty,
      );
    });

    test('unreadable stored data means no glow (fails closed)', () async {
      SharedPreferences.setMockInitialValues({
        'kids_map_seen_completed_owner-a_114': <String>['not-a-number'],
      });
      final store = await storeFor('owner-a');

      expect(
        await store.takeNewlyCompleted(114, [
          _stage(1, status: _done),
          _stage(2, status: _done),
        ]),
        isEmpty,
      );
    });

    test('another account on the device starts fresh', () async {
      final a = await storeFor('owner-a');
      await a.takeNewlyCompleted(114, [_stage(1, status: _done)]);
      final b = await storeFor('owner-b');

      expect(
        await b.takeNewlyCompleted(114, [
          _stage(1, status: _done),
          _stage(2, status: _done),
        ]),
        isEmpty, // b's first visit
      );
    });
  });
}
