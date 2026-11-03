import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/backup/restore_request_store.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  test(
    'request stores only an opaque ID and consumes it exactly once',
    () async {
      final store = RestoreRequestStore(prefs);
      final id = await store.schedule();
      expect(id, matches(RegExp(r'^[a-f0-9-]{36}$')));
      expect(prefs.getKeys(), {RestoreRequestStore.key});
      expect(await store.pendingId(), id);
      expect(await store.consume(id), isTrue);
      expect(await store.consume(id), isFalse);
      expect(await store.pendingId(), isNull);
    },
  );
  test('a stale screen cannot consume a newer request', () async {
    final store = RestoreRequestStore(prefs);
    final old = await store.schedule();
    final current = await store.schedule();
    expect(await store.consume(old), isFalse);
    expect(await store.pendingId(), current);
  });
  test(
    'malformed marker blocks instead of silently starting normal runtime',
    () async {
      await prefs.setInt(RestoreRequestStore.key, 1);
      expect(RestoreRequestStore(prefs).pendingId(), throwsFormatException);
    },
  );
}
