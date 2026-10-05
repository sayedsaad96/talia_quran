import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/kids_inbound_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_inbound_refresher.dart';

class _Repo implements KidsInboundRepository {
  int calls = 0;
  Either<Failure, void> result = const Right(null);
  Completer<void>? gate;

  @override
  Future<Either<Failure, void>> pullKidsInboundFromCloud() async {
    calls++;
    await gate?.future;
    return result;
  }
}

void main() {
  late _Repo repo;
  late DateTime now;
  late KidsInboundRefresher refresher;

  setUp(() {
    repo = _Repo();
    now = DateTime(2026, 10, 5, 8);
    refresher = KidsInboundRefresher(repo, clock: () => now);
  });

  test('the first resume pulls', () async {
    expect(await refresher.refresh(), isTrue);
    expect(repo.calls, 1);
  });

  test('resume within 5 minutes of a pull is skipped', () async {
    await refresher.refresh(force: true);
    now = now.add(const Duration(minutes: 4, seconds: 59));

    expect(await refresher.refresh(), isFalse);
    expect(repo.calls, 1);
  });

  test('resume after 5 minutes pulls again', () async {
    await refresher.refresh(force: true);
    now = now.add(const Duration(minutes: 5));

    expect(await refresher.refresh(), isTrue);
    expect(repo.calls, 2);
  });

  test('force ignores the throttle', () async {
    await refresher.refresh();
    expect(await refresher.refresh(force: true), isTrue);
    expect(repo.calls, 2);
  });

  test('a failed pull does not start the throttle', () async {
    repo.result = const Left(NetworkFailure('offline'));
    expect(await refresher.refresh(), isFalse);

    repo.result = const Right(null);
    expect(await refresher.refresh(), isTrue);
    expect(repo.calls, 2);
  });

  test('concurrent calls share one pull', () async {
    repo.gate = Completer<void>();
    final a = refresher.refresh(force: true);
    final b = refresher.refresh(force: true);
    repo.gate!.complete();

    expect(await Future.wait([a, b]), [true, true]);
    expect(repo.calls, 1);
  });
}
