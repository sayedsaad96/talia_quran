import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../domain/entities/study_entry.dart';

class StudyBundleValidation {
  StudyBundleValidation(
    List<String> errors,
    List<StudyBlock> blocks,
    this.source,
  ) : errors = List.unmodifiable(errors),
      blocks = List.unmodifiable(blocks);
  final List<String> errors;
  final List<StudyBlock> blocks;
  final StudySource? source;
  bool get isValid => errors.isEmpty;
}

StudyBundleValidation validateStudyBundle({
  required List<int> bytes,
  required Map<String, Object?> manifestEntry,
  required Map<int, int> canonicalAyahCounts,
}) {
  final errors = <String>[];
  final blocks = <StudyBlock>[];
  if (canonicalAyahCounts.isEmpty ||
      canonicalAyahCounts.entries.any((e) => e.key < 1 || e.value < 1)) {
    errors.add('Invalid canonical counts');
  }
  const requiredFields = [
    'sourceId',
    'kind',
    'language',
    'workTitle',
    'publisher',
    'edition',
    'sourceUrl',
    'retrievedAt',
    'licenseEvidence',
    'licenseCheckedAt',
    'reuseScope',
    'attributionText',
    'updateObligation',
    'reviewEvidence',
    'reviewedBy',
    'reviewedAt',
    'reviewDecision',
    'sha256',
    'footnoteFormat',
    'coverage',
  ];
  for (final field in requiredFields) {
    final value = manifestEntry[field];
    if (value is! String || value.trim().isEmpty || value == 'unknown') {
      errors.add('Missing $field');
    }
  }
  if (manifestEntry['reviewDecision'] != 'approved') errors.add('Not approved');
  if (manifestEntry['sha256'] != sha256.convert(bytes).toString()) {
    errors.add('Hash mismatch');
  }
  final kindName = manifestEntry['kind'];
  final kind = kindName == 'tafsir'
      ? StudyKind.tafsir
      : kindName == 'meaningTranslation'
      ? StudyKind.meaningTranslation
      : null;
  if (kind == null) errors.add('Unknown kind');
  if ((kind == StudyKind.tafsir && manifestEntry['language'] != 'ar') ||
      (kind == StudyKind.meaningTranslation &&
          manifestEntry['language'] != 'en')) {
    errors.add('Unexpected content language');
  }
  if (manifestEntry['footnoteFormat'] != 'plain') {
    errors.add('Unknown footnote format');
  }
  if (manifestEntry['coverage'] != 'complete') {
    errors.add('Unsupported coverage');
  }
  final url = Uri.tryParse('${manifestEntry['sourceUrl']}');
  if (url == null || url.scheme != 'https' || url.host.isEmpty) {
    errors.add('Invalid source URL');
  }
  final ids = <String>{};
  final covered = <String>{};
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map || decoded['blocks'] is! List) {
      throw const FormatException();
    }
    for (final value in decoded['blocks'] as List) {
      if (value is! Map) throw const FormatException();
      final id = value['blockId'];
      final surah = value['surahId'];
      final from = value['fromAyah'];
      final to = value['toAyah'];
      final text = value['text'];
      final notes = value['footnotes'];
      if (id is! String ||
          id.trim().isEmpty ||
          !ids.add(id) ||
          surah is! int ||
          from is! int ||
          to is! int ||
          from < 1 ||
          to < from ||
          canonicalAyahCounts[surah] == null ||
          to > canonicalAyahCounts[surah]! ||
          text is! String ||
          text.trim().isEmpty ||
          notes is! List ||
          notes.any((n) => n is! String) ||
          kind == null) {
        errors.add('Invalid block');
        continue;
      }
      for (var ayah = from; ayah <= to; ayah++) {
        covered.add('$surah:$ayah');
      }
      blocks.add(
        StudyBlock(
          sourceId: '${manifestEntry['sourceId']}',
          blockId: id,
          surahId: surah,
          fromAyah: from,
          toAyah: to,
          kind: kind,
          language: '${manifestEntry['language']}',
          text: text,
          footnotes: notes.cast<String>(),
        ),
      );
    }
  } catch (_) {
    errors.add('Invalid bundle JSON');
  }
  for (final entry in canonicalAyahCounts.entries) {
    for (var ayah = 1; ayah <= entry.value; ayah++) {
      if (!covered.contains('${entry.key}:$ayah')) {
        errors.add('Missing ${entry.key}:$ayah');
      }
    }
  }
  final source = errors.isEmpty
      ? StudySource(
          id: manifestEntry['sourceId'] as String,
          title: manifestEntry['workTitle'] as String,
          publisher: manifestEntry['publisher'] as String,
          edition: manifestEntry['edition'] as String,
          url: manifestEntry['sourceUrl'] as String,
          language: manifestEntry['language'] as String,
          attribution: manifestEntry['attributionText'] as String,
        )
      : null;
  return StudyBundleValidation(errors, blocks, source);
}
