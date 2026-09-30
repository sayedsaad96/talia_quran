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
    this.templatesEnabled = false,
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

  /// `dedicationTemplatesReview` is approved and enabled.
  final bool templatesEnabled;

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
      templatesEnabled: switch (json['dedicationTemplatesReview']) {
        {'reviewStatus': 'approved', 'enabled': true} => true,
        _ => false,
      },
      // Quarantined templates are never read as approved inserts.
      dedicationInserts: Map<String, String>.from(
        (json['dedicationInserts'] ?? const {}) as Map,
      ),
    );
  }

  bool get isApproved => reviewStatus == 'approved';

  bool get templatesApproved => isApproved && templatesEnabled;

  /// Approved insert for [condition] and [gender]; '' when not approved, the
  /// gender is unknown, or no reviewed template exists. A legacy flat key is
  /// masculine and therefore serves only [DedicationGender.male].
  String getDedicationInsert(
    DedicationCondition condition,
    DedicationGender? gender, [
    String? name,
  ]) {
    if (!templatesApproved || gender == null) return '';
    final template =
        dedicationInserts['${condition.name}_${gender.name}'] ??
        (gender == DedicationGender.male
            ? dedicationInserts[condition.name]
            : null);
    if (template == null || template.isEmpty) return '';
    if (name != null && name.trim().isNotEmpty) {
      return template.replaceAll('{name}', name.trim());
    }
    return template.replaceAll('{name}', '').replaceAll('  ', ' ').trim();
  }
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
