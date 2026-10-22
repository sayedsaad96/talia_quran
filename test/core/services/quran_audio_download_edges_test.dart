import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:dartz/dartz.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    hide DownloadProgress;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/services/audio_cache_service.dart';
import 'package:talia_quran/core/services/quran_audio_download_manager.dart';
import 'package:talia_quran/core/services/quran_audio_service.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

void main() {
  late io.Directory directory;
  late SharedPreferences prefs;
  late _Repository repository;
  late _Durable durable;

  File file(String name) =>
      const LocalFileSystem().file('${directory.path}/$name');
  QuranAudioDownloadManager manager() => QuranAudioDownloadManager(
    prefs,
    repository,
    cache: durable,
    estimatedBytesPerAyah: 1,
  );

  setUp(() async {
    directory = await io.Directory.systemTemp.createTemp('talia_audio_edges_');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = _Repository();
    durable = _Durable(file('saved.mp3'));
  });
  tearDown(() async {
    final parent = io.Directory.systemTemp.absolute.path;
    expect(
      directory.absolute.path.startsWith(
        '$parent${io.Platform.pathSeparator}talia_audio_edges_',
      ),
      isTrue,
    );
    await directory.delete(recursive: true);
  });

  test(
    'cancellation during final metadata cannot publish completion',
    () async {
      repository.pauseCall = 2;
      final service = manager();
      final events = <DownloadProgress>[];
      final finished = service
          .downloadSurahs(QuranReciter.alafasy, [
            1,
          ], allowUnverifiedNetwork: true)
          .forEach(events.add);
      await repository.paused.future;
      var stopped = false;
      final cancellation = service.cancel().then((_) => stopped = true);
      await Future<void>.delayed(Duration.zero);
      expect(stopped, isFalse);
      repository.release.complete();
      await Future.wait([cancellation, finished]);
      expect(events.last.phase, DownloadPhase.cancelled);
      expect(events.where((e) => e.phase == DownloadPhase.completed), isEmpty);
    },
  );

  test('a missing physical file invalidates persisted completion', () async {
    final service = manager();
    await service.downloadSurahs(QuranReciter.alafasy, [
      1,
    ], allowUnverifiedNetwork: true).drain<void>();
    expect(await service.isDownloaded(QuranReciter.alafasy, 1), isTrue);
    await durable.saved.delete();
    expect(await manager().isDownloaded(QuranReciter.alafasy, 1), isFalse);
  });

  test('an empty fetched file fails without completing its surah', () async {
    durable.empty = true;
    final service = manager();
    final events = await service.downloadSurahs(QuranReciter.alafasy, [
      1,
    ], allowUnverifiedNetwork: true).toList();
    expect(events.last.phase, DownloadPhase.failed);
    expect(await service.isDownloaded(QuranReciter.alafasy, 1), isFalse);
  });

  test(
    'failed manifest persistence never reports a completed download',
    () async {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = _FailedWrites();
      prefs = await SharedPreferences.getInstance();
      final service = manager();
      final events = await service.downloadSurahs(QuranReciter.alafasy, [
        1,
      ], allowUnverifiedNetwork: true).toList();
      expect(events.last.phase, DownloadPhase.failed);
      expect(await service.isDownloaded(QuranReciter.alafasy, 1), isFalse);
    },
  );

  test(
    'one corrupt manifest row preserves valid readers and unknown-size recovery',
    () async {
      await durable.saved.writeAsBytes([1, 2, 3]);
      await prefs.setString(
        'audio_downloads_manifest',
        jsonEncode({
          'alafasy': {'1': 'invalid'},
          'sudais': {
            '1': {
              'completed': true,
              'ayahs': [1],
            },
          },
        }),
      );
      final service = manager();
      expect(await service.usedBytes(reciter: QuranReciter.sudais), 3);
      // Corrupt rows are dropped and the size is recomputed from the files
      // instead of throwing until the reciter is deleted.
      expect(
        await service.usedBytes(reciter: QuranReciter.alafasy),
        greaterThan(0),
      );
      expect(await manager().usedBytes(reciter: QuranReciter.alafasy),
          greaterThan(0));
      await service.deleteReciter(QuranReciter.alafasy);
      expect(await manager().usedBytes(reciter: QuranReciter.alafasy), 0);
    },
  );

  test(
    'production durable lookup rejects empty files and uses exact reciter namespaces',
    () async {
      final caches = <String, _Cache>{};
      final store = QuranAudioDurableCache(
        create: (key) => caches.putIfAbsent(key, _Cache.new),
      );
      final saved = file('production.mp3');
      await saved.writeAsBytes([]);
      final url = QuranAudioService.buildUrl(
        1,
        1,
        reciter: QuranReciter.sudais,
      );
      final backend = store.cacheFor(QuranReciter.sudais) as _Cache;
      backend.files[url] = FileInfo(
        saved,
        FileSource.Cache,
        DateTime(2030),
        url,
      );
      expect(
        await store.getValidFilePath(1, 1, reciter: QuranReciter.sudais),
        isNull,
      );
      await saved.writeAsBytes([1]);
      expect(
        await store.getValidFilePath(1, 1, reciter: QuranReciter.sudais),
        saved.path,
      );
      expect(await store.getValidFilePath(1, 1), isNull);
      expect(
        caches.keys,
        containsAll([
          'quran_audio_downloads_sudais',
          'quran_audio_downloads_alafasy',
        ]),
      );
      expect(
        caches['quran_audio_downloads_alafasy']!.lookups.single,
        QuranAudioService.buildUrl(1, 1),
      );
    },
  );

  test('durable lookup failure falls back to the transient source', () async {
    final saved = file('fallback.mp3');
    await saved.writeAsBytes([1]);
    final transient = _Cache()..downloaded = saved;
    final service = AudioCacheService(
      cacheManager: transient,
      durableLookup: _BrokenLookup(),
    );
    expect(
      await service.getAudioPath(1, 1, reciter: QuranReciter.husary),
      saved.path,
    );
    expect(
      transient.downloads.single,
      QuranAudioService.buildUrl(1, 1, reciter: QuranReciter.husary),
    );
  });

  test('transient fetch cannot return an empty file to playback', () async {
    final saved = file('empty.mp3');
    await saved.writeAsBytes([]);
    final service = AudioCacheService(
      cacheManager: _Cache()..downloaded = saved,
      durableLookup: _BrokenLookup(),
    );
    await expectLater(service.getAudioPath(1, 1), throwsStateError);
  });
}

class _Cache extends Fake implements CacheManager {
  final files = <String, FileInfo>{};
  final lookups = <String>[];
  final downloads = <String>[];
  File? downloaded;
  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    lookups.add(key);
    return files[key];
  }

  @override
  Future<File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    downloads.add(url);
    return downloaded!;
  }
}

class _BrokenLookup implements QuranAudioDurableLookup {
  @override
  Future<String?> getValidFilePath(
    int surahId,
    int ayahNumber, {
    QuranReciter? reciter,
  }) async => throw StateError('Unavailable durable cache');
}

class _Durable extends QuranAudioDurableCache {
  _Durable(this.saved);
  final File saved;
  bool empty = false;
  @override
  Future<String?> getValidFilePath(
    int surahId,
    int ayahNumber, {
    QuranReciter? reciter,
  }) async =>
      await saved.exists() && await saved.length() > 0 ? saved.path : null;
  @override
  Future<File> fetch(QuranReciter reciter, int surahId, int ayahNumber) async =>
      saved.writeAsBytes(empty ? [] : [0xFF, 0xFB]);
  @override
  Future<void> evict(QuranReciter reciter, int surahId, int ayahNumber) async {
    if (await saved.exists()) await saved.delete();
  }
  @override
  Future<void> deleteReciter(QuranReciter reciter) async {
    if (await saved.exists()) await saved.delete();
  }
}

class _FailedWrites extends InMemorySharedPreferencesStore {
  _FailedWrites() : super.withData({});
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}

class _Repository extends Fake implements QuranRepository {
  int calls = 0;
  int? pauseCall;
  final paused = Completer<void>();
  final release = Completer<void>();
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async {
    calls++;
    if (calls == pauseCall) {
      paused.complete();
      await release.future;
    }
    return const Right(
      SurahDetail(
        surah: Surah(
          id: 1,
          nameAr: '',
          nameEn: '',
          ayahCount: 1,
          juz: 1,
          type: 'meccan',
          page: 1,
        ),
        ayahs: [
          Ayah(number: 1, surahId: 1, text: '', numberInSurah: 1, juz: 1),
        ],
      ),
    );
  }
}
