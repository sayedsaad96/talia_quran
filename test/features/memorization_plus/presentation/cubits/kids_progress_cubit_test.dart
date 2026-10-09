import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_progress_snapshot.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_progress_cubit.dart';

KidsProgressSnapshot _snapshot(int ayahs) => KidsProgressSnapshot(
  level: 1,
  levelProgress: 0,
  points: 0,
  stars: 0,
  currentStreak: 0,
  longestStreak: 0,
  memorizedAyahs: ayahs,
  weekPages: 0,
  achievements: const [],
  certificates: const [],
  recentActivity: const [],
);

void main() {
  test('loads the snapshot', () async {
    final cubit = KidsProgressCubit(
      () async => _snapshot(3),
      ProgressEventsBus(),
    );

    await cubit.load();

    expect(cubit.state, KidsProgressLoaded(_snapshot(3)));
    await cubit.close();
  });

  test(
    'loads and normalizes the local child nickname with the snapshot',
    () async {
      final cubit = KidsProgressCubit(
        () async => _snapshot(3),
        ProgressEventsBus(),
        childNameLoader: () async => '  مريم  ',
      );

      await cubit.load();

      expect(cubit.state, KidsProgressLoaded(_snapshot(3), childName: 'مريم'));
      await cubit.close();
    },
  );

  test(
    'keeps progress available when the child nickname cannot load',
    () async {
      final cubit = KidsProgressCubit(
        () async => _snapshot(3),
        ProgressEventsBus(),
        childNameLoader: () async => throw StateError('settings unavailable'),
      );

      await cubit.load();

      expect(cubit.state, KidsProgressLoaded(_snapshot(3)));
      await cubit.close();
    },
  );

  test('a failed load shows an error', () async {
    final cubit = KidsProgressCubit(
      () async => throw StateError('boom'),
      ProgressEventsBus(),
    );

    await cubit.load();

    expect(cubit.state, isA<KidsProgressError>());
    await cubit.close();
  });

  test('reloads when kids progress or activity changes', () async {
    var ayahs = 1;
    final bus = ProgressEventsBus();
    final cubit = KidsProgressCubit(() async => _snapshot(ayahs), bus);
    await cubit.load();

    ayahs = 2;
    bus.notify(ProgressChangedReason.kidsProgress);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect((cubit.state as KidsProgressLoaded).snapshot.memorizedAyahs, 2);

    ayahs = 3;
    bus.notify(ProgressChangedReason.xp);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect((cubit.state as KidsProgressLoaded).snapshot.memorizedAyahs, 2);
    await cubit.close();
  });
}
