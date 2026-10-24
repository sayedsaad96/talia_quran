import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart' as file;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    hide DownloadProgress;
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    as cache
    show FileSystem;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/quran/domain/entities/quran_entities.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';
import '../constants/surah_names.dart';
import '../utils/talia_logger.dart';
import 'quran_audio_service.dart';
import 'quran_audio_download_models.dart';
import 'quran_reciter.dart';

export 'quran_audio_download_models.dart';

const _manifestKey = 'audio_downloads_manifest';
const _reserveBytes = 200 * 1024 * 1024;

/// True when [target] starts with an ID3 tag or an MPEG audio frame sync. A
/// captive portal or error page answered with HTTP 200 fails this check.
Future<bool> looksLikeMp3(File target) async {
  if (!await target.exists()) return false;
  final handle = await target.open();
  try {
    final head = await handle.read(3);
    if (head.length >= 3 &&
        head[0] == 0x49 &&
        head[1] == 0x44 &&
        head[2] == 0x33) {
      return true;
    }
    return head.length >= 2 && head[0] == 0xFF && (head[1] & 0xE0) == 0xE0;
  } finally {
    await handle.close();
  }
}

abstract interface class QuranAudioDurableLookup {
  Future<String?> getValidFilePath(
    int surahId,
    int ayahNumber, {
    QuranReciter? reciter,
  });
}

/// Keeps downloaded recitations in the app-support directory. The cache
/// manager's default lives in the temporary/Caches directory, which the OS
/// may purge and Android's "Clear cache" wipes, silently breaking offline
/// playback the user downloaded for.
class QuranAudioSupportFileSystem implements cache.FileSystem {
  QuranAudioSupportFileSystem(this._key, {Future<Directory> Function()? base})
    : _base = base ?? getApplicationSupportDirectory;

  final String _key;
  final Future<Directory> Function() _base;
  Future<file.Directory>? _dir;

  Future<file.Directory> _directory() async {
    final base = await _base();
    final directory = const LocalFileSystem().directory(
      '${base.path}${Platform.pathSeparator}$_key',
    );
    await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<file.File> createFile(String name) async {
    var directory = await (_dir ??= _directory());
    if (!await directory.exists()) directory = await (_dir = _directory());
    return directory.childFile(name);
  }
}

/// Per-reciter durable stores prevent one full reciter from evicting another.
class QuranAudioDurableCache implements QuranAudioDurableLookup {
  static final QuranAudioDurableCache instance = QuranAudioDurableCache();
  QuranAudioDurableCache({CacheManager Function(String key)? create})
    : _create =
          create ??
          ((key) => CacheManager(
            Config(
              key,
              stalePeriod: const Duration(days: 3650),
              maxNrOfCacheObjects: 7000,
              fileSystem: QuranAudioSupportFileSystem(key),
            ),
          ));

  final CacheManager Function(String key) _create;
  final Map<QuranReciter, CacheManager> _caches = {};

  CacheManager cacheFor(QuranReciter reciter) => _caches.putIfAbsent(
    reciter,
    () => _create('quran_audio_downloads_${reciter.id}'),
  );

  @override
  Future<String?> getValidFilePath(
    int surahId,
    int ayahNumber, {
    QuranReciter? reciter,
  }) async {
    final actual = reciter ?? QuranReciter.alafasy;
    actual.requireAvailable();
    final url = QuranAudioService.buildUrl(
      surahId,
      ayahNumber,
      reciter: reciter,
    );
    final info = await cacheFor(actual).getFileFromCache(url);
    return await _validPath(info?.file);
  }

  Future<File> fetch(QuranReciter reciter, int surahId, int ayahNumber) {
    reciter.requireAvailable();
    return cacheFor(reciter).getSingleFile(
      QuranAudioService.buildUrl(surahId, ayahNumber, reciter: reciter),
    );
  }

  Future<void> deleteReciter(QuranReciter reciter) =>
      cacheFor(reciter).emptyCache();

  /// Removes one ayah from the durable store (e.g. a non-audio response).
  Future<void> evict(QuranReciter reciter, int surahId, int ayahNumber) =>
      cacheFor(reciter).removeFile(
        QuranAudioService.buildUrl(surahId, ayahNumber, reciter: reciter),
      );

  Future<String?> _validPath(File? file) async {
    if (file == null || !await file.exists() || await file.length() <= 0) {
      return null;
    }
    return file.path;
  }
}

/// Local-only durable Quran recitation downloads. Network type and free space
/// come from injected probes; either may be unknown (null), in which case the
/// caller must confirm before an unverified download starts.
class QuranAudioDownloadManager {
  QuranAudioDownloadManager(
    this._prefs,
    this._quran, {
    QuranAudioDurableCache? cache,
    Future<int?> Function()? freeBytes,
    Future<bool?> Function()? unmeteredNetwork,
    this.estimatedBytesPerAyah = 80 * 1024,
    this.fetchTimeout = const Duration(seconds: 60),
  }) : _cache = cache ?? QuranAudioDurableCache(),
       _freeBytes = freeBytes ?? _unknownFreeBytes,
       _unmeteredNetwork = unmeteredNetwork ?? _unknownNetwork {
    _manifest = _readManifest(_prefs.getString(_manifestKey));
  }

  final SharedPreferences _prefs;
  final QuranRepository _quran;
  final QuranAudioDurableCache _cache;
  final Future<int?> Function() _freeBytes;
  static Future<int?> _unknownFreeBytes() async => null;
  final Future<bool?> Function() _unmeteredNetwork;
  static Future<bool?> _unknownNetwork() async => null;
  final int estimatedBytesPerAyah;

  /// Upper bound for one ayah request, so a stalled connection can neither
  /// hang the queue nor [cancel].
  final Duration fetchTimeout;

  /// A run stops after this many failed ayahs in a row (usually the network
  /// is down) instead of trying every remaining ayah.
  static const maxConsecutiveFailures = 3;
  late final Map<String, Map<String, _SurahManifest>> _manifest;
  final Set<String> _unverifiedReciters = {};
  Future<void> _tail = Future.value();
  final Set<Future<void>> _activeWork = {};
  int _generation = 0;
  bool _dirty = false;

  Stream<DownloadProgress> downloadSurahs(
    QuranReciter reciter,
    List<int> surahIds, {
    bool wifiOnly = true,
    bool allowUnverifiedNetwork = false,
  }) => _track(
    _download(
      reciter,
      () async {
        final refs = <_AyahRef>[];
        for (final surahId in surahIds.toSet()) {
          final detail = await _detail(surahId);
          refs.addAll(
            detail.ayahs.map((a) => _AyahRef(surahId, a.numberInSurah)),
          );
        }
        return refs;
      },
      wifiOnly: wifiOnly,
      allowUnverifiedNetwork: allowUnverifiedNetwork,
    ),
  );

  Stream<DownloadProgress> downloadJuz(
    QuranReciter reciter,
    int juz, {
    bool wifiOnly = true,
    bool allowUnverifiedNetwork = false,
  }) => _track(
    _download(
      reciter,
      () async {
        if (juz < 1 || juz > 30) throw ArgumentError.value(juz, 'juz');
        final refs = <_AyahRef>[];
        for (var surahId = 1; surahId <= 114; surahId++) {
          final detail = await _detail(surahId);
          refs.addAll(
            detail.ayahs
                .where((ayah) => ayah.juz == juz)
                .map((ayah) => _AyahRef(surahId, ayah.numberInSurah)),
          );
        }
        return refs;
      },
      wifiOnly: wifiOnly,
      allowUnverifiedNetwork: allowUnverifiedNetwork,
    ),
  );

  Stream<DownloadProgress> downloadJuzAmma(
    QuranReciter reciter, {
    bool wifiOnly = true,
    bool allowUnverifiedNetwork = false,
  }) => downloadJuz(
    reciter,
    30,
    wifiOnly: wifiOnly,
    allowUnverifiedNetwork: allowUnverifiedNetwork,
  );

  Future<void> cancel() async {
    _generation++;
    await Future.wait(_activeWork.toList(growable: false));
    await _tail;
  }

  Future<void> deleteReciter(QuranReciter reciter) async {
    _generation++;
    await _enqueue(() async {
      await _cache.deleteReciter(reciter);
      _manifest.remove(reciter.id);
      _unverifiedReciters.remove(reciter.id);
      await _writeManifest();
    });
  }

  Future<bool> isDownloaded(QuranReciter reciter, int surahId) async {
    if (!reciter.isAvailable) return false;
    final row = _manifest[reciter.id]?[surahId.toString()];
    if (row?.completed != true) return false;
    final expected = (await _detail(surahId)).ayahs;
    return expected.isNotEmpty &&
        await _hasAllFiles(
          reciter,
          surahId,
          expected.map((e) => e.numberInSurah),
        );
  }

  Future<int> usedBytes({QuranReciter? reciter}) async {
    if (reciter != null && !reciter.isAvailable) return 0;
    final reciters = reciter == null ? QuranReciter.availableValues : [reciter];
    for (final value in reciters) {
      if (_unverifiedReciters.contains(value.id)) {
        await _recoverFromFiles(value);
      }
    }
    var bytes = 0;
    for (final value in reciters) {
      for (final entry
          in _manifest[value.id]?.entries ??
              const <MapEntry<String, _SurahManifest>>[]) {
        final surahId = int.tryParse(entry.key);
        if (surahId == null) continue;
        for (final ayah in entry.value.ayahs) {
          final path = await _cache.getValidFilePath(
            surahId,
            ayah,
            reciter: value,
          );
          if (path != null) bytes += await File(path).length();
        }
      }
    }
    return bytes;
  }

  /// A corrupt manifest must not make the size unknown forever. The corrupt
  /// rows were already dropped when it was read, so rebuild the reciter's rows
  /// from the files that are actually present in the durable store.
  Future<void> _recoverFromFiles(QuranReciter reciter) => _enqueue(() async {
    if (!_unverifiedReciters.contains(reciter.id)) return;
    TaliaLogger.w('Audio manifest for ${reciter.id} was corrupt; rebuilding');
    for (var surahId = 1; surahId <= 114; surahId++) {
      for (var ayah = 1; ayah <= SurahNames.ayahCount(surahId); ayah++) {
        final path = await _cache.getValidFilePath(
          surahId,
          ayah,
          reciter: reciter,
        );
        if (path != null) _record(reciter, _AyahRef(surahId, ayah));
      }
    }
    _unverifiedReciters.remove(reciter.id);
    _dirty = true;
    await _writeManifest();
  });

  Stream<DownloadProgress> _track(Stream<DownloadProgress> source) async* {
    final done = Completer<void>();
    final work = done.future;
    _activeWork.add(work);
    try {
      yield* source;
    } finally {
      if (!done.isCompleted) done.complete();
      _activeWork.remove(work);
    }
  }

  /// True on an unmetered (Wi-Fi-like) network, false on a metered one, and
  /// null when the device cannot tell.
  Future<bool?> isOnUnmeteredNetwork() async {
    try {
      return await _unmeteredNetwork();
    } catch (_) {
      return null;
    }
  }

  Stream<DownloadProgress> _download(
    QuranReciter reciter,
    Future<List<_AyahRef>> Function() refs, {
    required bool wifiOnly,
    required bool allowUnverifiedNetwork,
  }) async* {
    reciter.requireAvailable();
    final run = _DownloadRun(reciter, ++_generation);
    yield run.progress(DownloadPhase.checking);
    try {
      if (wifiOnly) {
        final unmetered = await isOnUnmeteredNetwork();
        _checkGeneration(run.generation);
        if (unmetered == false) {
          yield run.progress(DownloadPhase.waitingForWifi);
          return;
        }
        if (unmetered == null && !allowUnverifiedNetwork) {
          yield run.progress(DownloadPhase.waitingForNetworkConfirmation);
          return;
        }
      }
      run.queue = (await refs()).toSet().toList(growable: false);
      _checkGeneration(run.generation);
      int? free;
      try {
        free = await _freeBytes();
      } catch (_) {
        free = null;
      }
      _checkGeneration(run.generation);
      run.spaceUnknown = free == null;
      if (free != null &&
          free < run.queue.length * estimatedBytesPerAyah + _reserveBytes) {
        yield run.progress(DownloadPhase.insufficientSpace);
        return;
      }
      await for (final progress in _downloadQueue(run)) {
        yield progress;
      }
    } on _DownloadCancelled {
      yield run.progress(DownloadPhase.cancelled);
    } catch (_) {
      yield run.progress(DownloadPhase.failed, error: DownloadError.download);
    }
  }

  Stream<DownloadProgress> _downloadQueue(_DownloadRun run) async* {
    try {
      var failedInARow = 0;
      for (var i = 0; i < run.queue.length; i++) {
        final ref = run.queue[i];
        if (await _downloadAyah(run, ref)) {
          run.completed++;
          failedInARow = 0;
        } else {
          run.failed++;
          failedInARow++;
        }
        final lastOfSurah =
            i == run.queue.length - 1 ||
            run.queue[i + 1].surahId != ref.surahId;
        // Persist at most once per surah instead of twice per ayah.
        final stopping = failedInARow >= maxConsecutiveFailures;
        if (lastOfSurah || stopping) await _enqueue(_writeManifest);
        yield run.progress(DownloadPhase.downloading, surahId: ref.surahId);
        if (stopping) break;
      }
      await _enqueue(() async {
        _checkGeneration(run.generation);
        await _markCompleteSurahs(run.reciter, run.queue, run.generation);
        _checkGeneration(run.generation);
        await _writeManifest();
        _checkGeneration(run.generation);
      });
      _checkGeneration(run.generation);
      if (run.failed > 0) {
        yield run.progress(DownloadPhase.failed, error: DownloadError.download);
      } else {
        yield run.progress(DownloadPhase.completed);
      }
    } finally {
      // Cancellation or failure: keep references of fetched files discoverable.
      if (_dirty) {
        try {
          await _enqueue(_writeManifest);
        } catch (error) {
          TaliaLogger.w('Audio manifest flush failed', error);
        }
      }
    }
  }

  /// Returns false when the request failed or the response was not audio (it
  /// is evicted and the ayah is not recorded as downloaded). Cancellation
  /// still propagates.
  Future<bool> _downloadAyah(_DownloadRun run, _AyahRef ref) async {
    _checkGeneration(run.generation);
    final existing = await _cache.getValidFilePath(
      ref.surahId,
      ref.ayahNumber,
      reciter: run.reciter,
    );
    _checkGeneration(run.generation);
    if (existing == null) {
      // Record in memory before file I/O so a completed fetch remains
      // discoverable after cancellation; flushed per surah and on exit.
      await _enqueue(() async {
        _checkGeneration(run.generation);
        _record(run.reciter, ref);
      });
      File? fetched;
      try {
        fetched = await _enqueue(() {
          _checkGeneration(run.generation);
          return _cache
              .fetch(run.reciter, ref.surahId, ref.ayahNumber)
              .timeout(fetchTimeout);
        });
      } on _DownloadCancelled {
        rethrow;
      } catch (error) {
        TaliaLogger.w('Ayah download failed', error);
      }
      _checkGeneration(run.generation);
      if (fetched == null || !await looksLikeMp3(fetched)) {
        await _enqueue(() async {
          try {
            await _cache.evict(run.reciter, ref.surahId, ref.ayahNumber);
          } catch (error) {
            TaliaLogger.w('Could not evict a failed download', error);
          }
          _unrecord(run.reciter, ref);
        });
        return false;
      }
      _checkGeneration(run.generation);
    }
    await _enqueue(() async {
      _checkGeneration(run.generation);
      _record(run.reciter, ref);
    });
    return true;
  }

  void _checkGeneration(int generation) {
    if (generation != _generation) throw const _DownloadCancelled();
  }

  Future<SurahDetail> _detail(int surahId) async =>
      (await _quran.getSurahDetail(surahId)).fold(
        (failure) => throw StateError(failure.message),
        (detail) => detail,
      );

  void _record(QuranReciter reciter, _AyahRef ref) {
    final bySurah = _manifest.putIfAbsent(reciter.id, () => {});
    final row = bySurah.putIfAbsent(ref.surahId.toString(), _SurahManifest.new);
    if (row.ayahs.add(ref.ayahNumber)) _dirty = true;
  }

  void _unrecord(QuranReciter reciter, _AyahRef ref) {
    final row = _manifest[reciter.id]?[ref.surahId.toString()];
    if (row != null && row.ayahs.remove(ref.ayahNumber)) {
      row.completed = false;
      _dirty = true;
    }
  }

  Future<void> _markCompleteSurahs(
    QuranReciter reciter,
    List<_AyahRef> refs,
    int generation,
  ) async {
    final grouped = <int, Set<int>>{};
    for (final ref in refs) {
      grouped.putIfAbsent(ref.surahId, () => {}).add(ref.ayahNumber);
    }
    for (final entry in grouped.entries) {
      final row = _manifest[reciter.id]?[entry.key.toString()];
      if (row == null) continue;
      final expected = (await _detail(
        entry.key,
      )).ayahs.map((ayah) => ayah.numberInSurah).toList(growable: false);
      if (generation != _generation) throw const _DownloadCancelled();
      final valid = await _hasAllFiles(reciter, entry.key, expected);
      _checkGeneration(generation);
      row.completed = expected.isNotEmpty && valid;
    }
  }

  Future<bool> _hasAllFiles(
    QuranReciter reciter,
    int surahId,
    Iterable<int> ayahs,
  ) async {
    for (final ayah in ayahs) {
      if (await _cache.getValidFilePath(surahId, ayah, reciter: reciter) ==
          null) {
        return false;
      }
    }
    return true;
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  Future<void> _writeManifest() async {
    final saved = await _prefs.setString(
      _manifestKey,
      jsonEncode({
        if (_unverifiedReciters.isNotEmpty)
          '_unverifiedReciters': _unverifiedReciters.toList()..sort(),
        for (final reciter in _manifest.entries)
          reciter.key: {
            for (final s in reciter.value.entries) s.key: s.value.toJson(),
          },
      }),
    );
    if (!saved) throw StateError('audio download manifest was not persisted');
    _dirty = false;
  }

  Map<String, Map<String, _SurahManifest>> _readManifest(String? raw) {
    if (raw == null) return {};
    final result = <String, Map<String, _SurahManifest>>{};
    try {
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final knownIds = QuranReciter.values.map((r) => r.id).toSet();
      final uncertain = root['_unverifiedReciters'];
      if (uncertain is List) {
        _unverifiedReciters.addAll(
          uncertain.whereType<String>().where(knownIds.contains),
        );
      }
      for (final reciter in knownIds) {
        final rows = root[reciter];
        if (rows == null) continue;
        if (rows is! Map<String, dynamic>) {
          _unverifiedReciters.add(reciter);
          continue;
        }
        final parsed = result[reciter] = {};
        for (final row in rows.entries) {
          try {
            final surah = int.parse(row.key);
            if (surah < 1 || surah > 114) throw const FormatException();
            parsed[row.key] = _SurahManifest.fromJson(
              row.value,
              maxAyah: SurahNames.ayahCount(surah),
            );
          } catch (_) {
            _unverifiedReciters.add(reciter);
          }
        }
      }
    } catch (_) {
      _unverifiedReciters.addAll(QuranReciter.values.map((r) => r.id));
    }
    return result;
  }
}

class _SurahManifest {
  _SurahManifest();
  _SurahManifest.fromJson(Object? value, {required int maxAyah}) {
    final map = value as Map<String, dynamic>;
    if (map['completed'] is! bool ||
        map['ayahs'] is! List ||
        (map['ayahs'] as List).any((n) => n is! int || n < 1 || n > maxAyah)) {
      throw const FormatException('Invalid audio manifest');
    }
    completed = map['completed'] == true;
    ayahs.addAll(
      (map['ayahs'] as List? ?? const []).whereType<num>().map(
        (n) => n.toInt(),
      ),
    );
  }
  final Set<int> ayahs = {};
  bool completed = false;
  Map<String, Object> toJson() => {
    'completed': completed,
    'ayahs': ayahs.toList()..sort(),
  };
}

class _AyahRef {
  const _AyahRef(this.surahId, this.ayahNumber);
  final int surahId;
  final int ayahNumber;
  @override
  bool operator ==(Object other) =>
      other is _AyahRef &&
      other.surahId == surahId &&
      other.ayahNumber == ayahNumber;
  @override
  int get hashCode => Object.hash(surahId, ayahNumber);
}

class _DownloadCancelled implements Exception {
  const _DownloadCancelled();
}

class _DownloadRun {
  _DownloadRun(this.reciter, this.generation);
  final QuranReciter reciter;
  final int generation;
  List<_AyahRef> queue = const [];
  int completed = 0;
  int failed = 0;
  bool spaceUnknown = true;

  DownloadProgress progress(
    DownloadPhase phase, {
    int? surahId,
    DownloadError? error,
  }) => DownloadProgress(
    phase: phase,
    completedAyahs: completed,
    totalAyahs: queue.length,
    reciter: reciter,
    surahId: surahId,
    error: error,
    spaceUnknown: spaceUnknown,
  );
}
