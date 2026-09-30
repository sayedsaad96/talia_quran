import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_profile.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/progress/domain/usecases/get_progress_usecase.dart';
import 'package:talia_quran/features/progress/presentation/cubits/progress_cubit.dart';

void main() {
  test(
    'ProgressCubit reloads on reviewRecord but ignores xp-only changes',
    () async {
      final bus = ProgressEventsBus();
      var loadCount = 0;
      final cubit = ProgressCubit(
        _CountingGetProgress(onCall: () => loadCount++),
        _FakePathResolver(),
        bus,
      );

      await cubit.load();
      expect(loadCount, 1);

      bus.notify(ProgressChangedReason.xp);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(loadCount, 1);

      bus.notify(ProgressChangedReason.reviewRecord);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(loadCount, 2);

      await cubit.close();
      bus.dispose();
    },
  );

  test('background reloads keep the loaded data on screen', () async {
    final bus = ProgressEventsBus();
    final cubit = ProgressCubit(
      _CountingGetProgress(onCall: () {}),
      _FakePathResolver(),
      bus,
    );
    await cubit.load();
    expect(cubit.state, isA<ProgressLoaded>());

    final states = <ProgressState>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.refresh();
    await Future<void>.delayed(Duration.zero);

    expect(states.whereType<ProgressLoading>(), isEmpty);
    expect(cubit.state, isA<ProgressLoaded>());

    await sub.cancel();
    await cubit.close();
    bus.dispose();
  });

  test(
    'a failed background reload does not replace data with an error',
    () async {
      final bus = ProgressEventsBus();
      final usecase = _CountingGetProgress(onCall: () {});
      final cubit = ProgressCubit(usecase, _FakePathResolver(), bus);
      await cubit.load();

      usecase.failNext = true;
      await cubit.refresh();

      expect(cubit.state, isA<ProgressLoaded>());
      await cubit.close();
      bus.dispose();
    },
  );

  test('a first-load failure shows the error state', () async {
    final bus = ProgressEventsBus();
    final usecase = _CountingGetProgress(onCall: () {})..failNext = true;
    final cubit = ProgressCubit(usecase, _FakePathResolver(), bus);

    await cubit.load();

    expect(cubit.state, isA<ProgressError>());
    await cubit.close();
    bus.dispose();
  });

  test('xp-only changes refresh the XP card without a full reload', () async {
    final bus = ProgressEventsBus();
    var loadCount = 0;
    final xp = _FakeXpService(totalXp: 10);
    final cubit = ProgressCubit(
      _CountingGetProgress(onCall: () => loadCount++),
      _FakePathResolver(),
      bus,
      null,
      xp,
    );
    await cubit.load();
    expect((cubit.state as ProgressLoaded).totalXp, 10);

    xp.totalXp = 25;
    bus.notify(ProgressChangedReason.xp);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(loadCount, 1);
    expect((cubit.state as ProgressLoaded).totalXp, 25);
    expect((cubit.state as ProgressLoaded).xpLevelProgress, 0.25);
    await cubit.close();
    bus.dispose();
  });

  test('an XP read failure does not block the page', () async {
    final bus = ProgressEventsBus();
    final cubit = ProgressCubit(
      _CountingGetProgress(onCall: () {}),
      _FakePathResolver(),
      bus,
      null,
      _FakeXpService(totalXp: 0, throws: true),
    );

    await cubit.load();

    expect(cubit.state, isA<ProgressLoaded>());
    expect((cubit.state as ProgressLoaded).totalXp, 0);
    await cubit.close();
    bus.dispose();
  });

  test('a slower older load cannot overwrite a newer one', () async {
    final bus = ProgressEventsBus();
    final first = Completer<void>();
    var call = 0;
    final usecase = _CountingGetProgress(
      onCall: () => call++,
      gate: () => call == 1 ? first.future : Future<void>.value(),
      memorizedAyahsFor: () => call,
    );
    final cubit = ProgressCubit(usecase, _FakePathResolver(), bus);

    final older = cubit.load(); // call 1, blocked
    await cubit.load(); // call 2, completes
    first.complete();
    await older;

    final state = cubit.state as ProgressLoaded;
    expect(state.progress.memorizedAyahs, 2);
    await cubit.close();
    bus.dispose();
  });
}

class _CountingGetProgress implements GetProgressUsecase {
  _CountingGetProgress({
    required this.onCall,
    this.gate,
    this.memorizedAyahsFor,
  });

  final void Function() onCall;
  final Future<void> Function()? gate;
  final int Function()? memorizedAyahsFor;
  bool failNext = false;

  @override
  Future<Either<Failure, OverallProgress>> call() async {
    onCall();
    final memorized = memorizedAyahsFor?.call() ?? 1;
    await gate?.call();
    if (failNext) {
      failNext = false;
      return const Left(CacheFailure('boom'));
    }
    return Right(
      OverallProgress(
        memorizedAyahs: memorized,
        totalAyahs: 6236,
        memorizedSurahs: 0,
        totalSurahs: 114,
        memorizedJuz: 0,
        totalJuz: 30,
        readAyahs: 0,
        readSurahs: 0,
        readJuz: 0,
        streakDays: 0,
        lastActiveDate: null,
        achievements: const [],
        readPagesCount: 0,
        totalQuranPages: 604,
        learningAyahs: 0,
        reviewAyahs: 0,
      ),
    );
  }
}

class _FakePathResolver implements MemorizationPathResolver {
  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<MemorizationProfile?> currentProfile() async => null;

  @override
  bool isKids(MemorizationProfile? profile) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeXpService implements XpService {
  _FakeXpService({required this.totalXp, this.throws = false});

  int totalXp;
  final bool throws;

  @override
  Future<int> getTotalXp() async {
    if (throws) throw StateError('isar closed');
    return totalXp;
  }

  @override
  double progressToNextLevel(int xp) => xp / 100;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
