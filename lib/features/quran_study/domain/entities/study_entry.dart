enum StudyKind { tafsir, meaningTranslation }

class StudySource {
  const StudySource({
    required this.id,
    required this.title,
    required this.publisher,
    required this.edition,
    required this.url,
    required this.language,
    required this.attribution,
  });
  final String id, title, publisher, edition, url, language, attribution;
}

class StudyBlock {
  StudyBlock({
    required this.sourceId,
    required this.blockId,
    required this.surahId,
    required this.fromAyah,
    required this.toAyah,
    required this.kind,
    required this.language,
    required this.text,
    required List<String> footnotes,
  }) : footnotes = List.unmodifiable(footnotes);
  final String sourceId, blockId, language, text;
  final int surahId, fromAyah, toAyah;
  final StudyKind kind;
  final List<String> footnotes;
}

enum StudyLoadStatus { ready, unavailable, invalidReference, invalidBundle }

class StudyLoadResult {
  StudyLoadResult(
    this.status, {
    List<StudyBlock> entries = const [],
    this.source,
  }) : entries = List.unmodifiable(entries);
  final StudyLoadStatus status;
  final List<StudyBlock> entries;
  final StudySource? source;
}
