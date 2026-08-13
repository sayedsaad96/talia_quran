import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;

import '../data/datasources/bookmark_service.dart';

/// Mushaf reader location for a saved bookmark (page of the ayah, not surah start).
String bookmarkReaderLocation(BookmarkEntry entry) {
  final pageNumber = qcf.getPageNumber(entry.surahId, entry.ayahNumber);
  return '/quran/page/$pageNumber';
}
