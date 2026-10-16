import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/seasons/data/tarawih_log_store.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  TarawihLogStore storeFor(String owner) =>
      TarawihLogStore(prefs, FixedRecordOwnerProvider(owner));

  test('upsert replaces the same night; invalid ranges rejected', () async {
    final store = storeFor('a');
    await store.upsert(
      const TarawihEntry(nightKey: '2027-02-10', fromPage: 1, toPage: 5),
    );
    await store.upsert(
      const TarawihEntry(nightKey: '2027-02-10', fromPage: 6, toPage: 9),
    );
    final entries = await store.entries();
    expect(entries, hasLength(1));
    expect(entries.single.fromPage, 6);

    for (final bad in const [
      TarawihEntry(nightKey: '2027-02-11', fromPage: 0, toPage: 3),
      TarawihEntry(nightKey: '2027-02-11', fromPage: 5, toPage: 4),
      TarawihEntry(nightKey: '2027-02-11', fromPage: 1, toPage: 605),
    ]) {
      expect(() => store.upsert(bad), throwsArgumentError);
    }
    expect(await store.entries(), hasLength(1));

    await store.remove('2027-02-10');
    expect(await store.entries(), isEmpty);
  });

  test('totalPagesHeard counts overlapping pages once', () {
    final store = storeFor('a');
    expect(
      store.totalPagesHeard(const [
        TarawihEntry(nightKey: '2027-02-10', fromPage: 1, toPage: 5),
        TarawihEntry(nightKey: '2027-02-11', fromPage: 4, toPage: 8),
        TarawihEntry(nightKey: '2027-02-12', fromPage: 20, toPage: 20),
      ]),
      9,
    );
    expect(store.totalPagesHeard(const []), 0);
  });

  test('owner isolation: owner B sees none of owner A entries', () async {
    await storeFor('a').upsert(
      const TarawihEntry(nightKey: '2027-02-10', fromPage: 1, toPage: 5),
    );
    expect(await storeFor('b').entries(), isEmpty);
    expect(prefs.getString('ramadan_tarawih|a'), isNotNull);
  });

  test('corrupt stored data yields an empty list', () async {
    await prefs.setString('ramadan_tarawih|a', 'not json');
    expect(await storeFor('a').entries(), isEmpty);
  });
}
