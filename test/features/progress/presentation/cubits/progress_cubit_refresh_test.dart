import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_profile.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/progress/domain/usecases/get_progress_usecase.dart';
import 'package:talia_quran/features/progress/presentation/cubits/progress_cubit.dart';

void main() {
  test('ProgressCubit reloads on reviewRecord but ignores xp-only changes', () async {
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
  });
}

class _CountingGetProgress implements GetProgressUsecase {
  _CountingGetProgress({required this.onCall});

  final void Function() onCall;

  @override
  Future<Either<Failure, OverallProgress>> call() async {
    onCall();
    return const Right(
      OverallProgress(
        memorizedAyahs: 1,
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
        achievements: [],
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
