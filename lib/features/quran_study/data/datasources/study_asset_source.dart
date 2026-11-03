import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/study_entry.dart';

/// Reads only assets shipped with the application; it never fetches network data.
/// A missing manifest is an unavailable feature, while malformed data is invalid.
class ApprovedStudyBundleSource {
  const ApprovedStudyBundleSource(this.assets);
  final AssetBundle assets;

  Future<({List<int> bytes, Map<String, Object?> manifest})?> load(
    StudyKind kind,
  ) async {
    String manifestJson;
    try {
      manifestJson = await assets.loadString(
        'assets/data/quran_study/study_manifest.json',
      );
    } on FlutterError {
      return null;
    }
    final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
    final key = kind == StudyKind.tafsir ? 'tafsir' : 'meaningTranslation';
    final entry = (manifest[key] as Map).cast<String, Object?>();
    final path = kind == StudyKind.tafsir
        ? 'assets/data/quran_study/tafsir_ar.json'
        : 'assets/data/quran_study/translation_en.json';
    final data = await assets.load(path);
    return (
      bytes: List<int>.unmodifiable(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      ),
      manifest: Map<String, Object?>.unmodifiable(entry),
    );
  }
}
