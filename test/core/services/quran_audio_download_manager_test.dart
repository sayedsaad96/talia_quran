import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/services/quran_audio_download_manager.dart';
import 'package:talia_quran/core/services/audio_cache_service.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

void main() {
  late _QuranRepository repository;
  late _DurableCache cache;
  late QuranAudioDownloadManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = _QuranRepository();
    cache = _DurableCache();
    manager = QuranAudioDownloadManager(
      await SharedPreferences.getInstance(),
      repository,
      cache: cache,
      freeBytes: () async => 500 * 1024 * 1024,
      estimatedBytesPerAyah: 1,
    );
  });

  test(
    'new reciters download completely into independent durable stores',
    () async {
      for (final reciter in [QuranReciter.maher, QuranReciter.basfar]) {
        final result = await manager.downloadSurahs(reciter, [
          1,
        ], allowUnverifiedNetwork: true).toList();
        expect(result.last.phase, DownloadPhase.completed);
        expect(await manager.isDownloaded(reciter, 1), isTrue);
        expect(await manager.usedBytes(reciter: reciter), greaterThan(0));
      }
      expect(cache.fetchCalls, 4);
      final maher = await cache.getValidFilePath(
        1,
        1,
        reciter: QuranReciter.maher,
      );
      final basfar = await cache.getValidFilePath(
        1,
        1,
        reciter: QuranReciter.basfar,
      );
      expect(maher, isNotNull);
      expect(basfar, isNotNull);
      expect(maher, isNot(basfar));
    },
  );

  test('new reciter cached sources use their own durable files', () async {
    await manager.downloadSurahs(QuranReciter.maher, [
      1,
    ], allowUnverifiedNetwork: true).drain();
    await manager.downloadSurahs(QuranReciter.basfar, [
      1,
    ], allowUnverifiedNetwork: true).drain();
    final audio = AudioCacheService(durableLookup: cache);
    final maher = await audio.getAudioSource(1, 1, reciter: QuranReciter.maher);
    final basfar = await audio.getAudioSource(
      1,
      1,
      reciter: QuranReciter.basfar,
    );
    expect(maher, isNot(basfar));
    expect(await audio.getAudioPath(1, 1, reciter: QuranReciter.maher), maher);
    expect(
      await audio.getCachedFilePath(1, 1, reciter: QuranReciter.basfar),
      basfar,
    );
  });

  test(
    'waits for an explicit decision when Wi-Fi type is unavailable',
    () async {
      final progress = await manager.downloadSurahs(QuranReciter.alafasy, [
        1,
      ]).toList();
      expect(progress.last.phase, DownloadPhase.waitingForNetworkConfirmation);
      expect(cache.fetchCalls, 0);
    },
  );

  test(
    'a metered network waits for Wi-Fi even when unverified is allowed',
    () async {
      final metered = QuranAudioDownloadManager(
        await SharedPreferences.getInstance(),
        repository,
        cache: cache,
        freeBytes: () async => 500 * 1024 * 1024,
        unmeteredNetwork: () async => false,
        estimatedBytesPerAyah: 1,
      );
      final progress = await metered.downloadSurahs(QuranReciter.alafasy, [
        1,
      ], allowUnverifiedNetwork: true).toList();
      expect(progress.last.phase, DownloadPhase.waitingForWifi);
      expect(cache.fetchCalls, 0);
    },
  );

  test('a detected unmetered network downloads without confirmation', () async {
    final wifi = QuranAudioDownloadManager(
      await SharedPreferences.getInstance(),
      repository,
      cache: cache,
      freeBytes: () async => 500 * 1024 * 1024,
      unmeteredNetwork: () async => true,
      estimatedBytesPerAyah: 1,
    );
    final progress = await wifi.downloadSurahs(QuranReciter.alafasy, [
      1,
    ]).toList();
    expect(progress.last.phase, DownloadPhase.completed);
  });

  test('low measured space refuses before any fetch; a failing probe is '
      'treated as unknown', () async {
    final low = QuranAudioDownloadManager(
      await SharedPreferences.getInstance(),
      repository,
      cache: cache,
      freeBytes: () async => 1024,
      unmeteredNetwork: () async => true,
    );
    final refused = await low.downloadSurahs(QuranReciter.alafasy, [
      1,
    ]).toList();
    expect(refused.last.phase, DownloadPhase.insufficientSpace);
    expect(cache.fetchCalls, 0);

    final unknown = QuranAudioDownloadManager(
      await SharedPreferences.getInstance(),
      repository,
      cache: cache,
      freeBytes: () async => throw StateError('statfs failed'),
      unmeteredNetwork: () async => throw StateError('no service'),
      estimatedBytesPerAyah: 1,
    );
    final progress = await unknown.downloadSurahs(QuranReciter.alafasy, [
      1,
    ], allowUnverifiedNetwork: true).toList();
    expect(progress.last.phase, DownloadPhase.completed);
    expect(progress.last.spaceUnknown, isTrue);
  });

  test('marks a full surah only after every canonical ayah is valid', () async {
    final progress = await manager.downloadSurahs(QuranReciter.alafasy, [
      1,
    ], allowUnverifiedNetwork: true).toList();
    expect(progress.last.phase, DownloadPhase.completed);
    expect(await manager.isDownloaded(QuranReciter.alafasy, 1), isTrue);
    expect(cache.fetchCalls, 2);
  });

  test(
    'skips valid files and recovers a missing file after a restart',
    () async {
      await manager.downloadSurahs(QuranReciter.alafasy, [
        1,
      ], allowUnverifiedNetwork: true).drain();
      expect(cache.fetchCalls, 2);
      await manager.downloadSurahs(QuranReciter.alafasy, [
        1,
      ], allowUnverifiedNetwork: true).drain();
      expect(cache.fetchCalls, 2);

      cache.remove(QuranReciter.alafasy, 1, 1);
      manager = QuranAudioDownloadManager(
        await SharedPreferences.getInstance(),
        repository,
        cache: cache,
        freeBytes: () async => 500 * 1024 * 1024,
        estimatedBytesPerAyah: 1,
      );
      await manager.downloadSurahs(QuranReciter.alafasy, [
        1,
      ], allowUnverifiedNetwork: true).drain();
      expect(cache.fetchCalls, 3);
      expect(await manager.isDownloaded(QuranReciter.alafasy, 1), isTrue);
    },
  );

  test('an HTML 200 (captive portal) is evicted and never recorded', () async {
    cache.payload = '<html>login</html>'.codeUnits;
    final progress = await manager.downloadSurahs(QuranReciter.alafasy, [
      1,
    ], allowUnverifiedNetwork: true).toList();
    expect(progress.last.phase, DownloadPhase.failed);
    expect(cache.evicted, hasLength(2));
    expect(await manager.isDownloaded(QuranReciter.alafasy, 1), isFalse);
    expect(await manager.usedBytes(reciter: QuranReciter.alafasy), 0);
  });

  test('ID3 tagged audio is accepted', () async {
    cache.payload = [0x49, 0x44, 0x33, 4];
    final progress = await manager.downloadSurahs(QuranReciter.alafasy, [
      1,
    ], allowUnverifiedNetwork: true).toList();
    expect(progress.last.phase, DownloadPhase.completed);
  });

  test('manifest is persisted once per surah, not per ayah', () async {
    final prefs = await SharedPreferences.getInstance();
    var writes = 0;
    final counting = _CountingPrefs(prefs, () => writes++);
    final m = QuranAudioDownloadManager(
      counting,
      repository,
      cache: cache,
      freeBytes: () async => 500 * 1024 * 1024,
      estimatedBytesPerAyah: 1,
    );
    await m.downloadSurahs(QuranReciter.alafasy, [
      1,
    ], allowUnverifiedNetwork: true).drain();
    // one flush at the end of the surah + one after completion marking.
    expect(writes, lessThanOrEqualTo(2));
  });

  test('a split juz keeps its partial surah resumable, not complete', () async {
    final progress = await manager
        .downloadJuz(QuranReciter.alafasy, 1, allowUnverifiedNetwork: true)
        .toList();
    expect(progress.last.phase, DownloadPhase.completed);
    expect(await manager.isDownloaded(QuranReciter.alafasy, 1), isFalse);
  });

  test('reports actual bytes and keeps reciter stores independent', () async {
    await manager.downloadSurahs(QuranReciter.alafasy, [
      1,
    ], allowUnverifiedNetwork: true).drain();
    await manager.downloadSurahs(QuranReciter.sudais, [
      1,
    ], allowUnverifiedNetwork: true).drain();
    expect(await manager.usedBytes(reciter: QuranReciter.alafasy), 4);
    await manager.deleteReciter(QuranReciter.alafasy);
    expect(await manager.isDownloaded(QuranReciter.alafasy, 1), isFalse);
    expect(await manager.isDownloaded(QuranReciter.sudais, 1), isTrue);
  });

  test('refuses known-low space and flags unknown free space', () async {
    final low = QuranAudioDownloadManager(
      await SharedPreferences.getInstance(),
      repository,
      cache: cache,
      freeBytes: () async => 0,
      estimatedBytesPerAyah: 1,
    );
    expect(
      (await low.downloadSurahs(QuranReciter.alafasy, [
        1,
      ], allowUnverifiedNetwork: true).toList()).last.phase,
      DownloadPhase.insufficientSpace,
    );
    final unknown = QuranAudioDownloadManager(
      await SharedPreferences.getInstance(),
      repository,
      cache: _DurableCache(),
      freeBytes: () async => null,
      estimatedBytesPerAyah: 1,
    );
    final progress = await unknown.downloadSurahs(QuranReciter.sudais, [
      1,
    ], allowUnverifiedNetwork: true).toList();
    expect(progress.last.spaceUnknown, isTrue);
  });

  test(
    'cancel awaits a pending fetch and prevents a late completion',
    () async {
      cache.pending = Completer<File>();
      final stream = manager.downloadSurahs(QuranReciter.alafasy, [
        1,
      ], allowUnverifiedNetwork: true).drain();
      await cache.started.future;
      final cancelled = manager.cancel();
      var completed = false;
      unawaited(cancelled.then((_) => completed = true));
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      await cache.completePending();
      await cancelled;
      await stream;
      expect(await manager.isDownloaded(QuranReciter.alafasy, 1), isFalse);
      final reopened = QuranAudioDownloadManager(
        await SharedPreferences.getInstance(),
        repository,
        cache: cache,
      );
      expect(await reopened.usedBytes(reciter: QuranReciter.alafasy), 2);
    },
  );

  test('delete waits for a pending fetch and cannot be resurrected', () async {
    cache.pending = Completer<File>();
    final stream = manager.downloadSurahs(QuranReciter.alafasy, [
      1,
    ], allowUnverifiedNetwork: true).drain();
    await cache.started.future;
    final deleted = manager.deleteReciter(QuranReciter.alafasy);
    await cache.completePending();
    await deleted;
    await stream;
    expect(await manager.isDownloaded(QuranReciter.alafasy, 1), isFalse);
  });

  test(
    'one failed ayah request does not abort the rest of the queue',
    () async {
      cache.failingAyahs = {1};
      final progress = await manager.downloadSurahs(QuranReciter.alafasy, [
        1,
      ], allowUnverifiedNetwork: true).toList();
      expect(cache.fetchCalls, 2);
      expect(progress.last.phase, DownloadPhase.failed);
      expect(progress.last.completedAyahs, 1);
      expect(await manager.isDownloaded(QuranReciter.alafasy, 1), isFalse);
    },
  );

  test('three failures in a row stop the run', () async {
    repository.surahOneAyahs = 6;
    cache.failingAyahs = {1, 2, 3, 4, 5, 6};
    final progress = await manager.downloadSurahs(QuranReciter.alafasy, [
      1,
    ], allowUnverifiedNetwork: true).toList();
    expect(cache.fetchCalls, QuranAudioDownloadManager.maxConsecutiveFailures);
    expect(progress.last.phase, DownloadPhase.failed);
  });

  test('a stalled request times out instead of hanging cancel', () async {
    cache.pending = Completer<File>();
    final stalled = QuranAudioDownloadManager(
      await SharedPreferences.getInstance(),
      repository,
      cache: cache,
      freeBytes: () async => 500 * 1024 * 1024,
      estimatedBytesPerAyah: 1,
      fetchTimeout: const Duration(milliseconds: 20),
    );
    final finished = stalled.downloadSurahs(QuranReciter.alafasy, [
      1,
    ], allowUnverifiedNetwork: true).toList();
    await cache.started.future;
    await stalled.cancel().timeout(const Duration(seconds: 2));
    final progress = await finished.timeout(const Duration(seconds: 2));
    expect(progress.last.phase, DownloadPhase.cancelled);
  });

  test(
    'durable audio wins for every lookup with explicit and default reciters',
    () async {
      final durable = _Lookup('/durable/audio.mp3');
      final service = AudioCacheService(durableLookup: durable);
      expect(
        await service.getAudioPath(1, 1, reciter: QuranReciter.sudais),
        '/durable/audio.mp3',
      );
      expect(await service.getAudioSource(1, 1), '/durable/audio.mp3');
      expect(await service.getCachedFilePath(1, 1), '/durable/audio.mp3');
      expect(durable.reciters, [QuranReciter.sudais, null, null]);
    },
  );
}

class _DurableCache extends QuranAudioDurableCache {
  _DurableCache();
  final _files = <String, File>{};
  int fetchCalls = 0;
  Completer<File>? pending;
  Completer<void> started = Completer<void>();
  List<int>? payload;
  final evicted = <String>[];

  /// Ayahs whose request throws, as a network error would.
  Set<int> failingAyahs = {};

  String _key(int surah, int ayah, QuranReciter? reciter) =>
      '${reciter?.id}:$surah:$ayah';

  @override
  Future<String?> getValidFilePath(
    int surahId,
    int ayahNumber, {
    QuranReciter? reciter,
  }) async => _files[_key(surahId, ayahNumber, reciter)]?.path;

  @override
  Future<File> fetch(QuranReciter reciter, int surahId, int ayahNumber) async {
    fetchCalls++;
    if (!started.isCompleted) started.complete();
    if (failingAyahs.contains(ayahNumber)) {
      throw const SocketException('offline');
    }
    final waiting = pending;
    if (waiting != null) return waiting.future;
    return _create(reciter, surahId, ayahNumber);
  }

  Future<void> completePending() async {
    final waiting = pending;
    if (waiting == null || waiting.isCompleted) return;
    waiting.complete(await _create(QuranReciter.alafasy, 1, 1));
  }

  Future<File> _create(
    QuranReciter reciter,
    int surahId,
    int ayahNumber,
  ) async {
    final file = File(
      '${Directory.systemTemp.path}/talia_d3_${reciter.id}_${surahId}_$ayahNumber.mp3',
    );
    await file.writeAsBytes(payload ?? [0xFF, 0xFB]);
    _files[_key(surahId, ayahNumber, reciter)] = file;
    return file;
  }

  void remove(QuranReciter reciter, int surahId, int ayahNumber) {
    _files.remove(_key(surahId, ayahNumber, reciter));
  }

  @override
  Future<void> evict(QuranReciter reciter, int surahId, int ayahNumber) async {
    evicted.add(_key(surahId, ayahNumber, reciter));
    await _files.remove(_key(surahId, ayahNumber, reciter))?.delete();
  }

  @override
  Future<void> deleteReciter(QuranReciter reciter) async {
    _files.removeWhere((key, _) => key.startsWith('${reciter.id}:'));
  }
}

class _CountingPrefs extends Fake implements SharedPreferences {
  _CountingPrefs(this._inner, this._onWrite);
  final SharedPreferences _inner;
  final void Function() _onWrite;
  @override
  String? getString(String key) => _inner.getString(key);
  @override
  Future<bool> setString(String key, String value) {
    _onWrite();
    return _inner.setString(key, value);
  }
}

class _Lookup implements QuranAudioDurableLookup {
  _Lookup(this.path);
  final String path;
  final reciters = <QuranReciter?>[];
  @override
  Future<String?> getValidFilePath(
    int surahId,
    int ayahNumber, {
    QuranReciter? reciter,
  }) async {
    reciters.add(reciter);
    return path;
  }
}

class _QuranRepository implements QuranRepository {
  int surahOneAyahs = 2;

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async {
    if (surahId != 1) return Right(_detail(surahId, const []));
    return Right(
      _detail(1, [
        for (var n = 1; n <= surahOneAyahs; n++)
          // Ayah 1 is in juz 1 and the rest in juz 2, so juz 1 splits it.
          Ayah(
            number: n,
            surahId: 1,
            text: '',
            numberInSurah: n,
            juz: n == 1 ? 1 : 2,
          ),
      ]),
    );
  }

  SurahDetail _detail(int id, List<Ayah> ayahs) => SurahDetail(
    surah: Surah(
      id: id,
      nameAr: '',
      nameEn: '',
      ayahCount: ayahs.length,
      juz: 1,
      type: 'meccan',
      page: 1,
    ),
    ayahs: ayahs,
  );

  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, List<Surah>>> getSurahs() =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) =>
      throw UnimplementedError();
}
