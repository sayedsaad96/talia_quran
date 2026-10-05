import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/kids_reading_receipt_store.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_daily_missions.dart';

void main() {
  final now = DateTime(2026, 10, 2, 9);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<KidsReadingReceiptStore> storeFor(
    String owner, {
    DateTime Function()? clock,
  }) async => KidsReadingReceiptStore(
    await SharedPreferences.getInstance(),
    FixedRecordOwnerProvider(owner),
    clock: clock ?? () => now,
  );

  test('the same page twice gives one page', () async {
    final store = await storeFor('a');
    await store.recordPage(12);
    expect(await store.recordPage(12), {12});
  });

  test('two pages give both', () async {
    final store = await storeFor('a');
    await store.recordPage(12);
    expect(await store.recordPage(13), {12, 13});
    expect(await store.pagesOn(kidsDayKey(now)), {12, 13});
  });

  test('pagesOn for another day is empty', () async {
    final store = await storeFor('a');
    await store.recordPage(12);
    expect(await store.pagesOn('2026-10-01'), isEmpty);
  });

  test('owner B sees nothing owner A recorded', () async {
    final a = await storeFor('a');
    await a.recordPage(12);
    final b = await storeFor('b');
    expect(await b.pagesOn(kidsDayKey(now)), isEmpty);
  });

  test('pages outside 1..604 throw ArgumentError', () async {
    final store = await storeFor('a');
    expect(() => store.recordPage(0), throwsArgumentError);
    expect(() => store.recordPage(605), throwsArgumentError);
    expect(await store.pagesOn(kidsDayKey(now)), isEmpty);
  });

  test('corrupt JSON reads empty and the next write cleans it', () async {
    SharedPreferences.setMockInitialValues({
      'kids_reading_receipts_a': '{not json',
    });
    final store = await storeFor('a');
    expect(await store.pagesOn(kidsDayKey(now)), isEmpty);
    expect(await store.recordPage(5), {5});
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('kids_reading_receipts_a')!), {
      kidsDayKey(now): [5],
    });
  });

  test('entries 61 days old are pruned, 60 days old kept', () async {
    final old61 = kidsDayKey(now.subtract(const Duration(days: 61)));
    final old60 = kidsDayKey(now.subtract(const Duration(days: 60)));
    SharedPreferences.setMockInitialValues({
      'kids_reading_receipts_a': jsonEncode({
        old61: [1],
        old60: [2],
      }),
    });
    final store = await storeFor('a');
    await store.recordPage(7);
    expect(await store.pagesOn(old61), isEmpty);
    expect(await store.pagesOn(old60), {2});
    expect(await store.pagesOn(kidsDayKey(now)), {7});
  });

  test('overlapping recordPage calls keep every page', () async {
    final store = await storeFor('a');
    await Future.wait([store.recordPage(1), store.recordPage(2)]);
    expect(await store.pagesOn(kidsDayKey(now)), {1, 2});
  });

  test('pages 1 and 604 are accepted', () async {
    final store = await storeFor('a');
    await store.recordPage(1);
    expect(await store.recordPage(604), {1, 604});
  });

  test('allPages unions every retained day', () async {
    final yesterday = kidsDayKey(now.subtract(const Duration(days: 1)));
    SharedPreferences.setMockInitialValues({
      'kids_reading_receipts_a': jsonEncode({
        yesterday: [3, 4],
      }),
    });
    final store = await storeFor('a');
    await store.recordPage(4);
    await store.recordPage(9);
    expect(await store.allPages(), {3, 4, 9});
  });

  test('onRecorded fires after a save and its failure is swallowed', () async {
    var calls = 0;
    final store = KidsReadingReceiptStore(
      await SharedPreferences.getInstance(),
      const FixedRecordOwnerProvider('a'),
      clock: () => now,
      onRecorded: () async {
        calls++;
        throw StateError('sync down');
      },
    );
    expect(await store.recordPage(12), {12});
    expect(calls, 1);
    expect(() => store.recordPage(0), throwsArgumentError);
    expect(calls, 1);
  });
}
