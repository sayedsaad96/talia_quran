import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../../core/constants/surah_names.dart';
import '../../../../core/memorization/similar_ayah/similar_ayah_attempt_service.dart';
import '../../../../core/memorization/similar_ayah/similar_ayah_confusion_detector.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/repositories/quran_repository.dart';

/// Reads only a checksum-verified, explicitly approved derived index.
/// Missing approval is normal unavailability, with no corpus or speech logs.
final class ApprovedSimilarAyahCandidateSource
    implements SimilarAyahCandidateSource {
  ApprovedSimilarAyahCandidateSource({
    required this._quran,
    required this._readBytes,
  });
  static const indexPath = 'assets/data/similar_ayah_index.json';
  static const manifestPath = 'assets/data/content_manifest.json';
  final QuranRepository _quran;
  final Future<List<int>> Function(String path) _readBytes;
  Future<Map<String, Set<String>>?>? _index;

  @override
  Future<List<SimilarAyahCandidate>?> loadCandidates(String targetKey) async {
    try {
      _parseKey(targetKey);
      final index = await (_index ??= _loadApprovedIndex());
      if (index == null) return null;
      final keys = (index[targetKey] ?? const <String>{}).toList()
        ..sort(_compareKeys);
      final details = <int, SurahDetail>{};
      final candidates = <SimilarAyahCandidate>[];
      for (final key in keys) {
        final (surah, ayah) = _parseKey(key);
        if (!details.containsKey(surah)) {
          final result = await _quran.getSurahDetail(surah);
          final detail = result.fold((_) => null, (value) => value);
          if (detail == null || detail.surah.id != surah) return null;
          details[surah] = detail;
        }
        final matches = details[surah]!.ayahs
            .where(
              (item) => item.surahId == surah && item.numberInSurah == ayah,
            )
            .toList();
        if (matches.length != 1 || matches.single.text.isEmpty) return null;
        candidates.add(
          SimilarAyahCandidate(key: key, text: matches.single.text),
        );
      }
      return List.unmodifiable(candidates);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, Set<String>>?> _loadApprovedIndex() async {
    try {
      final manifest = jsonDecode(utf8.decode(await _readBytes(manifestPath)));
      if (manifest is! Map<String, dynamic> || manifest['items'] is! List) {
        return null;
      }
      final items = (manifest['items'] as List)
          .whereType<Map<String, dynamic>>();
      final entries = items.where((item) => item['path'] == indexPath).toList();
      final corpus = items
          .where((item) => item['path'] == 'assets/data/quran.json')
          .toList();
      if (entries.length != 1 || corpus.length != 1) return null;
      final entry = entries.single;
      if (entry['role'] != 'derived' ||
          entry['reviewStatus'] != 'approved' ||
          entry['generatorVersion'] != 1 ||
          entry['sourceCorpusSha256'] != corpus.single['sha256'] ||
          !_hasReviewEvidence(entry)) {
        return null;
      }
      final bytes = await _readBytes(indexPath);
      if (bytes.any((byte) => byte > 127) ||
          sha256.convert(bytes).toString() != entry['sha256']) {
        return null;
      }
      return _decodeIndex(
        jsonDecode(utf8.decode(bytes)),
        corpus.single['sha256'],
      );
    } catch (_) {
      return null;
    }
  }

  /// Human-review evidence (policy section 5), same names as the azkar
  /// promotion: reviewedBy and reviewedAt, plus the review set identifier.
  bool _hasReviewEvidence(Map<String, dynamic> entry) {
    final by = entry['reviewedBy'];
    final at = entry['reviewedAt'];
    final set = entry['reviewSetId'];
    return by is String &&
        by.trim().isNotEmpty &&
        set is String &&
        set.trim().isNotEmpty &&
        at is String &&
        RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(at) &&
        DateTime.tryParse(at) != null;
  }

  Map<String, Set<String>> _decodeIndex(Object? raw, Object? corpusSha) {
    if (raw is! Map<String, dynamic> ||
        raw['version'] != 1 ||
        raw['pairs'] is! List ||
        raw['provenance'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid derived index');
    }
    final provenance = raw['provenance'] as Map<String, dynamic>;
    if (provenance['corpusSha256'] != corpusSha ||
        provenance['tokenPolicy'] != 'normalized-recitable-whitespace-v1') {
      throw const FormatException('Invalid derived provenance');
    }
    for (final field in [
      'corpusSha256',
      'normalizerSha256',
      'splitterSha256',
      'generatorSha256',
      'recitablePredicateSha256',
      'surahMetadataSha256',
    ]) {
      if (provenance[field] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(provenance[field] as String)) {
        throw const FormatException('Invalid derived source hash');
      }
    }
    final adjacency = <String, Set<String>>{};
    final seen = <String>{};
    for (final pair in raw['pairs'] as List) {
      _addPair(pair, adjacency, seen);
    }
    return Map.unmodifiable({
      for (final entry in adjacency.entries)
        entry.key: Set<String>.unmodifiable(entry.value),
    });
  }

  void _addPair(
    Object? raw,
    Map<String, Set<String>> result,
    Set<String> seen,
  ) {
    const fields = {'a', 'b', 'score', 'sharedRun', 'kind'};
    if (raw is! Map<String, dynamic> ||
        raw.length != fields.length ||
        !fields.every(raw.containsKey) ||
        raw['a'] is! String ||
        raw['b'] is! String) {
      throw const FormatException('Invalid pair');
    }
    final a = raw['a'] as String;
    final b = raw['b'] as String;
    _parseKey(a);
    _parseKey(b);
    final score = raw['score'];
    if (_compareKeys(a, b) >= 0 ||
        !seen.add('$a|$b') ||
        score is! num ||
        !score.isFinite ||
        score < 0 ||
        score > 1 ||
        raw['sharedRun'] is! int ||
        (raw['sharedRun'] as int) < 1 ||
        !{'identical', 'prefix', 'suffix', 'partial'}.contains(raw['kind'])) {
      throw const FormatException('Invalid pair relation');
    }
    result.putIfAbsent(a, () => {}).add(b);
    result.putIfAbsent(b, () => {}).add(a);
  }

  (int, int) _parseKey(String key) {
    final parts = key.split(':');
    if (parts.length != 2) throw const FormatException('Invalid ayah key');
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null ||
        ayah == null ||
        key != '$surah:$ayah' ||
        surah < 1 ||
        surah > 114 ||
        ayah < 1 ||
        ayah > SurahNames.ayahCount(surah)) {
      throw const FormatException('Invalid ayah key');
    }
    return (surah, ayah);
  }

  int _compareKeys(String a, String b) {
    final left = _parseKey(a);
    final right = _parseKey(b);
    return left.$1 != right.$1
        ? left.$1.compareTo(right.$1)
        : left.$2.compareTo(right.$2);
  }
}
