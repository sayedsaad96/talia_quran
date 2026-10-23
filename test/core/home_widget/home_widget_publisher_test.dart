import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/home_widget/home_widget_publisher.dart';
import 'package:talia_quran/core/home_widget/widget_snapshot.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';

class _Owner implements RecordOwnerProvider {
  @override
  String currentOwnerId = 'a';
  bool signedIn = true;
  @override
  bool get isSignedIn => signedIn;
}

class _Bridge implements HomeWidgetBridge {
  String? value;
  final events = <String>[];
  Completer<void>? saving;
  bool fail = false;
  @override
  Future<void> save(String key, String? json) async {
    if (fail) throw StateError('unavailable bridge');
    if (json != null) await saving?.future;
    value = json;
    events.add(json == null ? 'clear' : 'save');
  }

  @override
  Future<void> requestUpdate() async {
    events.add('update');
  }
}

void main() {
  late _Owner owner;
  late _Bridge bridge;
  late AccountDataBarrier barrier;
  late HomeWidgetPublisher publisher;
  Completer<WidgetSnapshot>? reading;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    owner = _Owner();
    bridge = _Bridge();
    barrier = AccountDataBarrier.forPreferences(
      await SharedPreferences.getInstance(),
    )..owner = owner;
    reading = null;
    publisher = HomeWidgetPublisher(
      bridge: bridge,
      owner: owner,
      barrier: barrier,
      load: (lease, id) async => reading == null
          ? const WidgetSnapshot(dueReviewCount: 3)
          : reading!.future,
    );
    await publisher.start();
    bridge.events.clear();
  });
  tearDown(() async {
    final saving = bridge.saving;
    if (saving != null && !saving.isCompleted) saving.complete();
    await publisher.dispose();
  });
  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('refresh saves only the snapshot then requests a redraw', () async {
    await publisher.refresh();
    expect(jsonDecode(bridge.value!)['dueReviewCount'], 3);
    expect(bridge.events, ['save', 'update']);
  });
  test(
    'account invalidation clears without waiting for a source read',
    () async {
      await publisher.refresh();
      reading = Completer<WidgetSnapshot>();
      final refresh = publisher.refresh();
      await settle();
      barrier.prepareOwner('b');
      await settle();
      expect(bridge.value, isNull);
      reading!.complete(const WidgetSnapshot(dueReviewCount: 99));
      await refresh;
      expect(bridge.value, isNull);
    },
  );
  test(
    'in-flight save finishes before clear and new-owner publication',
    () async {
      bridge.saving = Completer<void>();
      final refresh = publisher.refresh();
      await settle();
      barrier.prepareOwner('b');
      owner.currentOwnerId = 'b';
      var ready = false;
      final readyOwner = barrier.markOwnerReady('b').then((_) => ready = true);
      await settle();
      expect(
        ready,
        isFalse,
        reason: 'Native clear must finish before account readiness',
      );
      final newOwner = publisher.refresh();
      bridge.saving!.complete();
      await refresh;
      await readyOwner;
      // A refresh requested while blocked cannot authorize publication.
      await newOwner;
      await publisher.refresh();
      expect(
        bridge.events,
        containsAllInOrder([
          'save',
          'update',
          'clear',
          'update',
          'save',
          'update',
        ]),
      );
    },
  );
  test('signed-out refresh empties the native snapshot', () async {
    await publisher.refresh();
    owner.signedIn = false;
    await publisher.refresh();
    expect(bridge.value, isNull);
  });
  test(
    'resume failures are contained and strict transition failure is observable',
    () async {
      bridge.fail = true;
      await publisher.refresh();
      await expectLater(
        publisher.clearForAccountTransition(),
        throwsStateError,
      );
      bridge.fail = false;
      await publisher.clearForAccountTransition();
      expect(bridge.value, isNull);
    },
  );
  test(
    'failed native transition cannot mark an owner ready and can retry',
    () async {
      bridge.fail = true;
      barrier.prepareOwner('b');
      owner.currentOwnerId = 'b';
      await expectLater(barrier.markOwnerReady('b'), throwsStateError);
      expect(barrier.isReady, isFalse);
      bridge.fail = false;
      barrier.prepareOwner('b');
      await barrier.markOwnerReady('b');
      expect(barrier.isReady, isTrue);
    },
  );
}
