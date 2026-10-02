import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_child_policy.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_policy_controller.dart';

void main() {
  test('starts with the default policy', () {
    final c = KidsPolicyController(load: () async => const KidsChildPolicy());
    expect(c.value, const KidsChildPolicy());
    c.dispose();
  });

  test('reload updates value and notifies', () async {
    const loaded = KidsChildPolicy(reduceMotion: true, version: 2);
    final c = KidsPolicyController(load: () async => loaded);
    var notified = 0;
    c.addListener(() => notified++);
    await c.reload();
    expect(c.value, loaded);
    expect(notified, 1);
    c.dispose();
  });

  test(
    'a throwing loader keeps the previous value and does not throw',
    () async {
      var fail = false;
      final c = KidsPolicyController(
        load: () async {
          if (fail) throw StateError('boom');
          return const KidsChildPolicy(maxDailySuggestions: 2);
        },
      );
      await c.reload();
      fail = true;
      await c.reload();
      expect(c.value.maxDailySuggestions, 2);
      c.dispose();
    },
  );

  test('a stale in-flight reload does not overwrite a newer result', () async {
    final first = Completer<KidsChildPolicy>();
    final second = Completer<KidsChildPolicy>();
    final queue = [first, second];
    final c = KidsPolicyController(load: () => queue.removeAt(0).future);
    final f1 = c.reload();
    final f2 = c.reload();
    second.complete(const KidsChildPolicy(version: 2));
    await f2;
    first.complete(const KidsChildPolicy(version: 1));
    await f1;
    expect(c.value.version, 2);
    c.dispose();
  });

  test('reload after dispose is a no-op', () async {
    final c = KidsPolicyController(
      load: () async => const KidsChildPolicy(version: 1),
    );
    c.dispose();
    await c.reload();
  });
}
