import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/hands_free_media_owner.dart';
import 'package:talia_quran/core/services/quran_background_audio_handler.dart';

class _Delegate implements HandsFreeMediaDelegate {
  @override
  void onPrimary() {}
  @override
  void onSecondary() {}
  @override
  void onInterrupted() {}
  @override
  void onHardwareButton({required bool primary}) {}
}

void main() {
  test(
    'cancelled lazy acquisition unblocks reader before init finishes',
    () async {
      final owner = HandsFreeMediaOwner();
      final delegate = _Delegate();
      final pending = Completer<QuranBackgroundAudioHandler?>();
      final acquisition = owner.acquire(
        delegate,
        stopReader: () async {},
        initialize: () => pending.future,
      );
      await Future<void>.delayed(Duration.zero);
      owner.cancelPending(delegate);
      expect(owner.isReserved, isFalse);
      pending.complete(null);
      expect(await acquisition, isNull);
    },
  );
  test('stalled initialization has a bounded reservation', () async {
    final owner = HandsFreeMediaOwner(
      acquisitionTimeout: const Duration(milliseconds: 5),
    );
    final pending = Completer<QuranBackgroundAudioHandler?>();
    expect(
      await owner.acquire(
        _Delegate(),
        stopReader: () async {},
        initialize: () => pending.future,
      ),
      isNull,
    );
    expect(owner.isReserved, isFalse);
    pending.complete(null);
  });
  for (final cancel in [false, true]) {
    test('pending reader stop stays guarded (cancel: $cancel)', () async {
      final owner = HandsFreeMediaOwner(
        acquisitionTimeout: const Duration(milliseconds: 5),
      );
      final stopping = Completer<void>();
      final delegate = _Delegate();
      var initialized = false;
      final acquisition = owner.acquire(
        delegate,
        stopReader: () => stopping.future,
        initialize: () async {
          initialized = true;
          return null;
        },
      );
      if (cancel) owner.cancelPending(delegate);
      expect(await acquisition, isNull);
      expect(owner.isReserved, isTrue);
      expect(initialized, isFalse);
      stopping.complete();
      await Future<void>.delayed(Duration.zero);
      expect(owner.isReserved, isFalse);
      expect(initialized, isFalse);
    });
  }
  test('a failed reader stop releases the reservation', () async {
    final owner = HandsFreeMediaOwner();
    var initialized = false;
    final lease = await owner.acquire(
      _Delegate(),
      stopReader: () async => throw StateError('Reader did not stop'),
      initialize: () async {
        initialized = true;
        return null;
      },
    );
    expect(lease, isNull);
    expect(owner.isReserved, isFalse);
    expect(initialized, isFalse);
    // A later acquisition is not locked out.
    expect(
      await owner.acquire(
        _Delegate(),
        stopReader: () async {},
        initialize: () async => null,
      ),
      isNull,
    );
    expect(owner.isReserved, isFalse);
  });
  test('a late reader stop failure also releases a timed-out wait', () async {
    final owner = HandsFreeMediaOwner(
      acquisitionTimeout: const Duration(milliseconds: 5),
    );
    final stopping = Completer<void>();
    expect(
      await owner.acquire(
        _Delegate(),
        stopReader: () => stopping.future,
        initialize: () async => null,
      ),
      isNull,
    );
    expect(owner.isReserved, isTrue);
    stopping.completeError(StateError('late failure'));
    await Future<void>.delayed(Duration.zero);
    expect(owner.isReserved, isFalse);
  });
}
