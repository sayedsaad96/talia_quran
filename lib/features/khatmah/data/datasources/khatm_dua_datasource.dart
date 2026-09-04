import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/khatmah_dedication.dart';

class KhatmDuaData {
  const KhatmDuaData({
    required this.arabicText,
    required this.source,
    required this.sourceNote,
    required this.tier,
    required this.dedicationInserts,
    this.reviewStatus = 'pendingReview',
    this.reviewer,
    this.sourceLocator,
    this.version,
  });

  final String arabicText;
  final String source;
  final String sourceNote;
  final String tier;
  final Map<String, String> dedicationInserts;
  final String reviewStatus;
  final String? reviewer;
  final String? sourceLocator;
  final String? version;

  factory KhatmDuaData.fromJson(Map<String, dynamic> json) {
    return KhatmDuaData(
      arabicText: json['arabicText'] as String,
      source: json['source'] as String,
      sourceNote: json['sourceNote'] as String,
      tier: json['tier'] as String,
      reviewStatus: json['reviewStatus'] as String? ?? 'pendingReview',
      reviewer: json['reviewer'] as String?,
      sourceLocator: json['sourceLocator'] as String?,
      version: json['version'] as String?,
      dedicationInserts: Map<String, String>.from(
        (json['quarantinedDedicationInserts'] ??
                json['dedicationInserts'] ??
                const {})
            as Map,
      ),
    );
  }

  /// Legacy templates are retained for review, never inferred from a name.
  /// No gender is modeled and no exact personalized wording is approved.
  String getDedicationInsert(DedicationCondition condition, [String? name]) =>
      '';
}

class KhatmDuaDatasource {
  KhatmDuaDatasource({AssetBundle? bundle}) : _bundle = bundle;

  final AssetBundle? _bundle;
  KhatmDuaData? _cached;

  Future<KhatmDuaData> loadDua() async {
    if (_cached != null) return _cached!;
    final bundle = _bundle ?? rootBundle;
    final raw = await bundle.loadString('assets/data/khatm_dua.json');
    _cached = KhatmDuaData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cached!;
  }
}
