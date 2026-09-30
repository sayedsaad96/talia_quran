import '../../domain/entities/azkar_entities.dart';

/// The one format for copying a zikr: the verbatim text, its reference when
/// there is one, then [footer]. Used by the reader and the library so both
/// copy the same thing.
String zikrCopyText(Zikr zikr, {required String footer}) => [
  zikr.text,
  if (zikr.reference.isNotEmpty) zikr.reference,
  footer,
].join('\n\n');
