import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/home_widget/home_widget_publisher.dart';
import 'package:talia_quran/core/home_widget/widget_snapshot.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/review_record_identity.dart';

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
  final scheduled = <List<DateTime>>[];
  final receiverStates = <bool>[];
  int cancels = 0;
  Completer<void>? saving;
  Completer<void>? hangingClear;
  bool fail = false;
  bool failScheduling = false;
  int failClears = 0;
  @override
  Future<void> save(String key, String? json) async {
    if (fail) throw StateError('unavailable bridge');
    if (json == null && failClears > 0) {
      failClears--;
      throw StateError('transient clear failure');
    }
    if (json != null) await saving?.future;
    if (json == null) await hangingClear?.future;
    value = json;
    events.add(json == null ? 'clear' : 'save');
  }

  @override
  Future<void> requestUpdate() async {
    events.add('update');
  }

  @override
  Future<void> scheduleUpdates(List<DateTime> times) async {
    if (failScheduling) throw StateError('alarm unavailable');
    scheduled.add(times);
  }

  @override
  Future<void> cancelScheduledUpdates() async {
    cancels++;
  }

  @override
  Future<void> setReceiverEnabled(bool enabled) async {
    receiverStates.add(enabled);
  }
}

void main() {
  late _Owner owner;
  late _Bridge bridge;
  late AccountDataBarrier barrier;
  late HomeWidgetPublisher publisher;
  Completer<WidgetSnapshot>? reading;
  var loads = 0;
  var snapshot = const WidgetSnapshot(dueReviewCount: 3);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    owner = _Owner();
    bridge = _Bridge();
    barrier = AccountDataBarrier.forPreferences(
      await SharedPreferences.getInstance(),
    )..owner = owner;
    reading = null;
    loads = 0;
    snapshot = const WidgetSnapshot(dueReviewCount: 3);
    publisher = HomeWidgetPublisher(
      bridge: bridge,
      owner: owner,
      barrier: barrier,
      load: (lease, id) async {
        loads++;
        return reading == null ? snapshot : reading!.future;
      },
    );
    await publisher.start();
    bridge.events.clear();
  });
  tearDown(() async {
    final saving = bridge.saving;
    if (saving != null && !saving.isCompleted) saving.complete();
    final hanging = bridge.hangingClear;
    if (hanging != null && !hanging.isCompleted) hanging.complete();
    await publisher.dispose();
  });
  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
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
  test(
    'a guest owner is published, and signing out clears before any refresh',
    () async {
      owner
        ..signedIn = false
        ..currentOwnerId = ReviewRecordIdentity.localOwnerId;
      barrier.prepareOwner(ReviewRecordIdentity.localOwnerId);
      await barrier.markOwnerReady(ReviewRecordIdentity.localOwnerId);
      await publisher.refresh();
      expect(jsonDecode(bridge.value!)['dueReviewCount'], 3);

      // Next owner arrives: the old snapshot is gone before they are ready.
      owner
        ..signedIn = true
        ..currentOwnerId = 'next';
      barrier.prepareOwner('next');
      await settle();
      expect(bridge.value, isNull);
      expect(barrier.isReady, isFalse);
    },
  );
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

  group('redraw scheduling', () {
    final at = DateTime(2030, 1, 1, 12);
    test('schedules a redraw per upcoming prayer and at expiry', () async {
      final expiry = DateTime(2030, 1, 2);
      snapshot = WidgetSnapshot(
        nextPrayerKey: 'dhuhr',
        nextPrayerAt: at,
        upcomingPrayers: [
          (key: 'dhuhr', at: at),
          (key: 'asr', at: at.add(const Duration(hours: 3))),
          (key: 'fajr', at: at.add(const Duration(hours: 17))),
        ],
        expiresAt: expiry,
      );
      final scheduled = HomeWidgetPublisher(
        bridge: bridge,
        owner: owner,
        barrier: barrier,
        load: (lease, id) async => snapshot,
        now: () => DateTime(2030, 1, 1, 8),
      );
      await scheduled.start();
      addTearDown(scheduled.dispose);
      await scheduled.refresh();

      expect(bridge.scheduled.last, [
        at,
        at.add(const Duration(hours: 3)),
        expiry,
        at.add(const Duration(hours: 17)),
      ]);
    });

    test('past times are never scheduled', () async {
      snapshot = WidgetSnapshot(
        upcomingPrayers: [(key: 'fajr', at: DateTime(2000))],
        dueReviewCount: 1,
        expiresAt: DateTime(2000, 1, 2),
      );
      bridge.cancels = 0;
      await publisher.refresh();
      expect(bridge.scheduled, isEmpty);
      expect(bridge.cancels, 1);
    });

    test('clearing cancels the alarms', () async {
      bridge.cancels = 0;
      await publisher.clearForAccountTransition();
      expect(bridge.cancels, 1);
    });

    test('a scheduling failure never discards a saved snapshot', () async {
      bridge.failScheduling = true;
      snapshot = WidgetSnapshot(
        dueReviewCount: 2,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      await publisher.refresh();
      expect(jsonDecode(bridge.value!)['dueReviewCount'], 2);
    });
  });

  group('empty and adult-without-data snapshots', () {
    test('a cleared audience removes the native key', () async {
      await publisher.refresh();
      snapshot = const WidgetSnapshot.empty();
      await publisher.refresh();
      expect(bridge.value, isNull);
    });

    test('an adult with nothing stores the localizable empty state', () async {
      snapshot = const WidgetSnapshot(adultNoData: true, languageCode: 'ar');
      await publisher.refresh();
      expect(jsonDecode(bridge.value!), {
        'schemaVersion': 1,
        'isEmpty': true,
        'adultNoData': true,
        'locale': 'ar',
      });
    });
  });

  group('bounded native clear', () {
    // The default publisher would also join barrier invalidations.
    setUp(() => publisher.dispose());
    HomeWidgetPublisher make({
      Duration timeout = const Duration(milliseconds: 40),
      bool Function()? isEnabled,
      List<Stream<void>> flagChanges = const [],
      List<Stream<void>> authorityChanges = const [],
      Future<Object?> Function()? audience,
    }) => HomeWidgetPublisher(
      bridge: bridge,
      owner: owner,
      barrier: barrier,
      load: (lease, id) async => snapshot,
      clearTimeout: timeout,
      isEnabled: isEnabled ?? () => true,
      flagChanges: flagChanges,
      authorityChanges: authorityChanges,
      audience: audience,
    );

    test('a hung clear times out, stays queued and blocks readiness', () async {
      final bounded = make();
      await bounded.start();
      addTearDown(bounded.dispose);
      bridge.hangingClear = Completer<void>();
      await expectLater(
        bounded.clearForAccountTransition(),
        throwsA(isA<TimeoutException>()),
      );
      barrier.prepareOwner('b');
      owner.currentOwnerId = 'b';
      await expectLater(
        barrier.markOwnerReady('b'),
        throwsA(isA<TimeoutException>()),
      );
      expect(barrier.isReady, isFalse);
      bridge.hangingClear!.complete();
    });

    test('one transient clear failure is retried', () async {
      final bounded = make();
      await bounded.start();
      addTearDown(bounded.dispose);
      await bounded.refresh();
      bridge.failClears = 1;
      await bounded.clearForAccountTransition();
      expect(bridge.value, isNull);
    });

    test('a disabled flag never blocks start on native code', () async {
      bridge.hangingClear = Completer<void>();
      final disabled = make(isEnabled: () => false);
      await disabled.start().timeout(const Duration(seconds: 1));
      addTearDown(disabled.dispose);
      await disabled.refresh().timeout(const Duration(seconds: 1));
      expect(bridge.events.where((event) => event == 'save'), isEmpty);
    });

    test('flag off clears and disables the receiver, on re-enables', () async {
      var enabled = true;
      final changes = StreamController<void>.broadcast();
      addTearDown(changes.close);
      final flagged = make(
        timeout: const Duration(seconds: 1),
        isEnabled: () => enabled,
        flagChanges: [changes.stream],
      );
      await flagged.start();
      addTearDown(flagged.dispose);
      await flagged.refresh();
      expect(bridge.value, isNotNull);
      expect(bridge.receiverStates.last, isTrue);

      enabled = false;
      changes.add(null);
      await settle();
      expect(bridge.value, isNull);
      expect(bridge.receiverStates.last, isFalse);

      enabled = true;
      changes.add(null);
      await settle();
      expect(bridge.receiverStates.last, isTrue);
      expect(jsonDecode(bridge.value!)['dueReviewCount'], 3);
    });

    test('flag changes are also noticed on the next refresh', () async {
      var enabled = true;
      final flagged = make(
        timeout: const Duration(seconds: 1),
        isEnabled: () => enabled,
      );
      await flagged.start();
      addTearDown(flagged.dispose);
      await flagged.refresh();
      enabled = false;
      await flagged.refresh();
      expect(bridge.value, isNull);
      expect(bridge.receiverStates.last, isFalse);
    });

    test(
      'a path event for an unchanged owner and audience does not blank the widget',
      () async {
        var audience = 'adult';
        final changes = StreamController<void>.broadcast();
        addTearDown(changes.close);
        final steady = make(
          timeout: const Duration(seconds: 1),
          authorityChanges: [changes.stream],
          audience: () async => audience,
        );
        await steady.start();
        addTearDown(steady.dispose);
        await steady.refresh();
        bridge.events.clear();

        changes.add(null);
        await settle();
        expect(bridge.events, isNot(contains('clear')));
        expect(bridge.value, isNotNull);

        audience = 'kids';
        changes.add(null);
        await settle();
        expect(bridge.events, contains('clear'));
      },
    );
  });

  test(
    'concurrent refreshes collapse into one run plus one trailing run',
    () async {
      reading = Completer<WidgetSnapshot>();
      final first = publisher.refresh();
      final second = publisher.refresh();
      final third = publisher.refresh();
      await settle();
      expect(loads, 1);
      reading!.complete(const WidgetSnapshot(dueReviewCount: 5));
      reading = null;
      await Future.wait([first, second, third]);
      expect(loads, 2);
      expect(jsonDecode(bridge.value!)['dueReviewCount'], 3);
    },
  );
}
