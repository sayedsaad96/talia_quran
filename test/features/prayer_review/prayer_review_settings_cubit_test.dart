import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_authority.dart';
import 'package:talia_quran/features/prayer_review/presentation/cubits/prayer_review_settings_cubit.dart';

void main() {
  test('loads only an enabled adult owner and keeps immutable lengths', () async {
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);
    final cubit = PrayerReviewSettingsCubit(
      isEnabled: () => true,
      captureAuthority: () => _authority('owner-a'),
      readAdultEligibility: () async => true,
      readLength: (owner, prayer) => prayer == PrayerKey.fajr ? 3 : 7,
      writeLength: (_, _, _, _) async {},
      accountChanges: changes.stream,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.isReady, isTrue);
    expect(cubit.state.lengths[PrayerKey.fajr], 3);
    expect(() => cubit.state.lengths[PrayerKey.fajr] = 15, throwsUnsupportedError);
  });

  test('child eligibility never reads stored preferences', () async {
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);
    var reads = 0;
    final cubit = PrayerReviewSettingsCubit(
      isEnabled: () => true,
      captureAuthority: () => _authority('owner-a'),
      readAdultEligibility: () async => false,
      readLength: (_, _) {
        reads++;
        return 7;
      },
      writeLength: (_, _, _, _) async {},
      accountChanges: changes.stream,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.isHidden, isTrue);
    expect(reads, 0);
  });

  test('capture failure hides settings instead of escaping load', () async {
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);
    final cubit = PrayerReviewSettingsCubit(
      isEnabled: () => true,
      captureAuthority: () => throw const AccountDataUnavailableException(),
      readAdultEligibility: () async => true,
      readLength: (_, _) => 7,
      writeLength: (_, _, _, _) async {},
      accountChanges: changes.stream,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.isHidden, isTrue);
  });

  test('failed save retains the prior selection', () async {
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);
    final cubit = PrayerReviewSettingsCubit(
      isEnabled: () => true,
      captureAuthority: () => _authority('owner-a'),
      readAdultEligibility: () async => true,
      readLength: (_, _) => 7,
      writeLength: (_, _, _, _) async => throw StateError('write failed'),
      accountChanges: changes.stream,
    );
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.changeLength(PrayerKey.fajr, 15);

    expect(cubit.state.lengths[PrayerKey.fajr], 7);
    expect(cubit.state.saveFailed, isTrue);
  });

  test('concurrent taps do not start a second write', () async {
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);
    final adult = Completer<bool>();
    var checkedLoad = false;
    var writes = 0;
    final cubit = PrayerReviewSettingsCubit(
      isEnabled: () => true,
      captureAuthority: () => _authority('owner-a'),
      readAdultEligibility: () async => checkedLoad ? adult.future : (checkedLoad = true),
      readLength: (_, _) => 7,
      writeLength: (_, _, _, _) async => writes++,
      accountChanges: changes.stream,
    );
    addTearDown(cubit.close);
    await cubit.load();

    final first = cubit.changeLength(PrayerKey.fajr, 15);
    final second = cubit.changeLength(PrayerKey.fajr, 3);
    adult.complete(true);
    await Future.wait([first, second]);

    expect(writes, 1);
    expect(cubit.state.lengths[PrayerKey.fajr], 15);
  });

  test('account change wipes state and stale load cannot restore it', () async {
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);
    final eligibility = Completer<bool>();
    final cubit = PrayerReviewSettingsCubit(
      isEnabled: () => true,
      captureAuthority: () => _authority('owner-a'),
      readAdultEligibility: () => eligibility.future,
      readLength: (_, _) => 7,
      writeLength: (_, _, _, _) async {},
      accountChanges: changes.stream,
    );
    addTearDown(cubit.close);

    final loading = cubit.load();
    changes.add(null);
    eligibility.complete(true);
    await loading;

    expect(cubit.state.isHidden, isTrue);
  });
}

PrayerReviewAuthority _authority(String ownerId) => PrayerReviewAuthority(
  ownerId: ownerId,
  lease: _Lease(),
);

class _Lease implements AccountDataLease {
  @override
  Stream<void> get changes => const Stream.empty();

  @override
  void check() {}

  @override
  void checkOwner(String ownerId) {}
}
