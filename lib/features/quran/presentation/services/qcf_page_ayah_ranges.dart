import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;

import 'strength_overlay_source.dart';

/// Production [PageAyahRanges] backed by qcf `getPageData`. Malformed entries
/// and out-of-range pages yield no ranges instead of throwing.
List<({int surah, int start, int end})> qcfPageAyahRanges(int page) {
  if (page < 1 || page > 604) return const [];
  final List<dynamic> raw;
  try {
    raw = qcf.getPageData(page);
  } catch (_) {
    return const [];
  }
  final out = <({int surah, int start, int end})>[];
  for (final e in raw) {
    if (e is! Map) continue;
    final s = e['surah'];
    final st = e['start'];
    final en = e['end'];
    if (s is! int || st is! int || en is! int) continue;
    if (s < 1 || st < 1 || en < st) continue;
    out.add((surah: s, start: st, end: en));
  }
  return out;
}
