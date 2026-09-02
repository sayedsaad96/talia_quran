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
  });

  final String arabicText;
  final String source;
  final String sourceNote;
  final String tier;
  final Map<String, String> dedicationInserts;

  factory KhatmDuaData.fromJson(Map<String, dynamic> json) {
    return KhatmDuaData(
      arabicText: json['arabicText'] as String,
      source: json['source'] as String,
      sourceNote: json['sourceNote'] as String,
      tier: json['tier'] as String,
      dedicationInserts:
          Map<String, String>.from(json['dedicationInserts'] as Map),
    );
  }

  String getDedicationInsert(DedicationCondition condition, [String? name]) {
    final key = switch (condition) {
      DedicationCondition.alive => 'alive',
      DedicationCondition.deceased => 'deceased',
      DedicationCondition.sick => 'sick',
    };

    final template = dedicationInserts[key] ?? '';
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      return template.replaceAll('{name}', trimmedName);
    }

    return template
        .replaceAll(' لِعَبْدِكَ {name}', '')
        .replaceAll(' {name}', '');
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
