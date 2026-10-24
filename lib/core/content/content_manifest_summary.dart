import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

import '../utils/talia_logger.dart';

/// Read-only digest of `assets/data/content_manifest.json`: which dataset
/// version ships and how many governed data files it lists. The manifest itself
/// is never modified.
final class ContentManifestSummary extends Equatable {
  const ContentManifestSummary({
    required this.datasetVersion,
    required this.datasetCount,
  });

  static const assetPath = 'assets/data/content_manifest.json';

  final String? datasetVersion;
  final int datasetCount;

  /// Returns null when [json] is malformed or has no `items` list.
  static ContentManifestSummary? parse(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) return null;
      final items = decoded['items'];
      if (items is! List) return null;
      final version = decoded['datasetVersion'];
      return ContentManifestSummary(
        datasetVersion: version is String ? version : null,
        datasetCount: items.length,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [datasetVersion, datasetCount];
}

/// Loads the bundled manifest summary; any failure yields null.
Future<ContentManifestSummary?> loadContentManifestSummary(
  AssetBundle bundle,
) async {
  try {
    final raw = await bundle.loadString(ContentManifestSummary.assetPath);
    return ContentManifestSummary.parse(raw);
  } catch (e, st) {
    TaliaLogger.w('Content manifest summary unavailable', e, st);
    return null;
  }
}
