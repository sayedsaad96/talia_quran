import '../../../../core/utils/arabic_normalizer.dart';
import '../entities/azkar_entities.dart';

/// A record list with repeated records removed, plus which ids were hidden.
class DedupedAzkar {
  const DedupedAzkar({required this.items, required this.aliases});

  /// Records to display, in dataset order.
  final List<Zikr> items;

  /// Canonical record id -> ids of later records with the same text and count.
  final Map<String, Set<String>> aliases;
}

/// Hides repeated records in the presentation layer. The release file is not
/// edited: two records are the same when their normalized text and required
/// count match, and the first one in dataset order is kept.
abstract class AzkarDedupe {
  /// Normalized text for comparison only. [ArabicNormalizer] already drops
  /// diacritics and letter variants; the Arabic comma (U+060C) and full stops
  /// are also punctuation, so two copies that differ only there still match.
  static String comparisonText(String text) => ArabicNormalizer.normalize(
    text.replaceAll('،', ' ').replaceAll('.', ' '),
  );

  static DedupedAzkar apply(List<Zikr> records) {
    final canonicalByKey = <String, Zikr>{};
    final items = <Zikr>[];
    final aliases = <String, Set<String>>{};

    for (final zikr in records) {
      final key = '${zikr.totalCount}|${comparisonText(zikr.text)}';
      final canonical = canonicalByKey[key];
      if (canonical == null) {
        canonicalByKey[key] = zikr;
        items.add(zikr);
      } else {
        aliases.putIfAbsent(canonical.id, () => <String>{}).add(zikr.id);
      }
    }

    return DedupedAzkar(
      items: List.unmodifiable(items),
      aliases: {
        for (final entry in aliases.entries)
          entry.key: Set.unmodifiable(entry.value),
      },
    );
  }
}
