import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a same-owner lease from a different barrier cannot authorize work',
    () async {
      SharedPreferences.setMockInitialValues({});
      final firstPrefs = await SharedPreferences.getInstance();
      final first = AccountDataBarrier.forPreferences(firstPrefs)
        ..owner = const FixedRecordOwnerProvider('owner-a');
      final foreignLease = first.capture();
      SharedPreferences.setMockInitialValues({});
      final secondPrefs = await SharedPreferences.getInstance();
      expect(identical(firstPrefs, secondPrefs), isFalse);
      final second = AccountDataBarrier.forPreferences(secondPrefs)
        ..owner = const FixedRecordOwnerProvider('owner-a');
      var executed = false;
      expect(
        () => second.run((_) async {
          executed = true;
        }, authority: foreignLease),
        throwsA(isA<AccountDataUnavailableException>()),
      );
      expect(executed, isFalse);
      final local = second.capture();
      await second.run((lease) async {
        lease.checkOwner('owner-a');
        executed = true;
      }, authority: local);
      expect(executed, isTrue);
    },
  );

  group('a failing invalidation participant', () {
    late AccountDataBarrier barrier;
    late _MutableOwner owner;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      owner = _MutableOwner('owner-a');
      barrier = AccountDataBarrier.forPreferences(
        await SharedPreferences.getInstance(),
      )..owner = owner;
    });

    test('still lets clear wipe the stores, then fails closed', () async {
      var failing = true;
      final remove = barrier.addInvalidationParticipant(() async {
        if (failing) throw StateError('native widget unavailable');
      });
      addTearDown(remove);
      var wiped = false;

      await expectLater(
        barrier.clear(() async => wiped = true),
        throwsStateError,
      );

      expect(wiped, isTrue, reason: 'Account data must be wiped regardless');
      expect(barrier.isReady, isFalse, reason: 'Owner stays blocked');
      expect(() => barrier.capture(), throwsA(isA<AccountDataUnavailableException>()));

      // markOwnerReady is refused for the failed generation, and succeeds only
      // after a later invalidation whose participants all succeed.
      owner.currentOwnerId = 'owner-b';
      barrier.prepareOwner('owner-b');
      await expectLater(barrier.markOwnerReady('owner-b'), throwsStateError);
      expect(barrier.isReady, isFalse);

      failing = false;
      barrier.prepareOwner('owner-b');
      await barrier.markOwnerReady('owner-b');
      expect(barrier.isReady, isTrue);
    });

    test('a store wipe failure is still surfaced', () async {
      final remove = barrier.addInvalidationParticipant(() async {
        throw StateError('participant');
      });
      addTearDown(remove);

      await expectLater(
        barrier.clear(() async => throw ArgumentError('store')),
        throwsArgumentError,
      );
      expect(barrier.isReady, isFalse);
    });

    test('a bounded retry unblocks only after the participant succeeds', () async {
      var failing = true;
      final remove = barrier.addInvalidationParticipant(() async {
        if (failing) throw StateError('native widget unavailable');
      });
      addTearDown(remove);
      await expectLater(barrier.clear(() async {}), throwsStateError);
      expect(barrier.isReady, isFalse);

      expect(await barrier.retryFailedClear(), isFalse);
      expect(barrier.isReady, isFalse);

      failing = false;
      expect(await barrier.retryFailedClear(), isTrue);
      expect(barrier.isReady, isTrue);
      expect(barrier.capture().check, returnsNormally);
      expect(await barrier.retryFailedClear(), isFalse, reason: 'nothing left');
    });

    test('a projection-only clear failure surfaces its cause and can retry', () async {
      await expectLater(
        barrier.clear(
          () async => throw AccountProjectionClearFailure(
            StateError('widget'),
            StackTrace.current,
          ),
        ),
        throwsStateError,
      );
      expect(barrier.isReady, isFalse);

      var projectionFails = true;
      Future<void> projection() async {
        if (projectionFails) throw StateError('still down');
      }

      expect(await barrier.retryFailedClear(projection: projection), isFalse);
      expect(barrier.isReady, isFalse);
      projectionFails = false;
      expect(await barrier.retryFailedClear(projection: projection), isTrue);
      expect(barrier.isReady, isTrue);
    });

    test('a store wipe failure is never recoverable by retry', () async {
      await expectLater(
        barrier.clear(() async => throw ArgumentError('store')),
        throwsArgumentError,
      );
      expect(await barrier.retryFailedClear(), isFalse);
      expect(barrier.isReady, isFalse);
    });

    test('a newer invalidation supersedes a pending retry', () async {
      await expectLater(
        barrier.clear(
          () async => throw AccountProjectionClearFailure(
            StateError('widget'),
            StackTrace.current,
          ),
        ),
        throwsStateError,
      );
      owner.currentOwnerId = 'owner-b';
      barrier.prepareOwner('owner-b');
      expect(await barrier.retryFailedClear(), isFalse);
      expect(barrier.isReady, isFalse);
      await barrier.markOwnerReady('owner-b');
      expect(barrier.isReady, isTrue);
    });
  });
}

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => true;
}
