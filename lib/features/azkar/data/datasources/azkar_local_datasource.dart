import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../../core/error/app_failure.dart';
import '../../domain/entities/azkar_entities.dart';
import '../models/zikr_model.dart';

abstract class AzkarLocalDatasource {
  Future<List<ZikrModel>> getAzkar(AzkarCategory category);
}

class AzkarLocalDatasourceImpl implements AzkarLocalDatasource {
  Map<String, dynamic>? _cache;

  @override
  Future<List<ZikrModel>> getAzkar(AzkarCategory category) async {
    try {
      if (_cache == null) {
        final jsonStr = await rootBundle.loadString(
          'assets/data/azkar_release.json',
        );
        _cache = await compute(
          (String str) => jsonDecode(str) as Map<String, dynamic>,
          jsonStr,
        );
        _validateUniqueReleaseIds(_cache!);
      }

      final key = switch (category) {
        AzkarCategory.morning => 'morning',
        AzkarCategory.evening => 'evening',
        AzkarCategory.general => 'general',
        AzkarCategory.duas => 'duas',
      };

      final list = _cache![key] as List<dynamic>;
      return list
          .map((e) => ZikrModel.fromJson(e as Map<String, dynamic>, category))
          .toList();
    } catch (e) {
      throw CacheFailure('Failed to load azkar: $e');
    }
  }

  void _validateUniqueReleaseIds(Map<String, dynamic> source) {
    final ids = <String>{};
    for (final key in const ['morning', 'evening', 'general', 'duas']) {
      final records = source[key];
      if (records is! List<dynamic>) continue;
      for (final record in records) {
        if (record is! Map<String, dynamic>) continue;
        final id = record['id'];
        if (id is String && id.trim().isNotEmpty && !ids.add(id)) {
          throw FormatException('Duplicate release record id: $id');
        }
      }
    }
  }
}
