import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/kids_family_practice_store.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_family_practice_receipt.dart';

KidsFamilyPracticeReceipt _receipt(String id, {int day = 1}) =>
    KidsFamilyPracticeReceipt(
      id: id,
      surahId: 114,
      ayahNumber: 1,
      confirmedAt: DateTime.utc(2026, 10, day),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<KidsFamilyPracticeStore> storeFor(String owner) async =>
      KidsFamilyPracticeStore(
        await SharedPreferences.getInstance(),
        FixedRecordOwnerProvider(owner),
      );

  test('starts empty and keeps a recorded receipt', () async {
    final store = await storeFor('a');
    expect(store.receipts(), isEmpty);

    expect(await store.record(_receipt('r1')), isTrue);

    expect(store.receipts(), [_receipt('r1')]);
  });

  test('a new receipt notifies once; a repeated one does not', () async {
    var notified = 0;
    final store = KidsFamilyPracticeStore(
      await SharedPreferences.getInstance(),
      const FixedRecordOwnerProvider('a'),
      onRecorded: () => notified++,
    );

    await store.record(_receipt('r1'));
    await store.record(_receipt('r1'));

    expect(notified, 1);
  });

  test('recording the same receipt twice keeps one', () async {
    final store = await storeFor('a');

    await store.record(_receipt('r1'));
    expect(await store.record(_receipt('r1')), isTrue);

    expect(store.receipts(), hasLength(1));
  });

  test('receipts belong to their owner', () async {
    await (await storeFor('a')).record(_receipt('r1'));

    expect((await storeFor('b')).receipts(), isEmpty);
  });

  test('only the newest receipts are kept', () async {
    final store = await storeFor('a');
    for (var i = 0; i < KidsFamilyPracticeStore.maxReceipts + 3; i++) {
      await store.record(
        KidsFamilyPracticeReceipt(
          id: 'r$i',
          surahId: 114,
          ayahNumber: 1,
          confirmedAt: DateTime.utc(2026).add(Duration(minutes: i)),
        ),
      );
    }

    final kept = store.receipts();
    expect(kept, hasLength(KidsFamilyPracticeStore.maxReceipts));
    expect(kept.first.id, 'r3');
  });

  test('malformed entries are skipped, valid ones survive', () async {
    SharedPreferences.setMockInitialValues({
      '${KidsFamilyPracticeStore.keyPrefix}a':
          '[{"id":"ok","surahId":1,"ayahNumber":2,'
          '"confirmedAt":"2026-10-01T00:00:00.000Z"},{"id":3},"junk"]',
    });

    expect((await storeFor('a')).receipts().map((r) => r.id), ['ok']);
  });

  test('a save racing an account reset writes nothing', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = await storeFor('a');
    final barrier = AccountDataBarrier.forPreferences(prefs)..invalidate();
    addTearDown(() => barrier.clear(() async {}));

    expect(await store.record(_receipt('r1')), isFalse);
    expect(prefs.getString('${KidsFamilyPracticeStore.keyPrefix}a'), isNull);
  });

  test('its key is cleared with the account data', () {
    expect(
      AccountDataReset.clearedPreferencePrefixes,
      contains(KidsFamilyPracticeStore.keyPrefix),
    );
  });
}
