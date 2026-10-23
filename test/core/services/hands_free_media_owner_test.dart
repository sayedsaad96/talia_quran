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
}
