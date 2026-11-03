import 'dart:convert';
import 'dart:io';
import 'package:talia_quran/features/quran_study/data/datasources/approved_study_bundle_source.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/content/validate_quran_study_bundle.dart <manifest.json> <bundle.json>',
    );
    exitCode = 64;
    return;
  }
  try {
    final manifest = (jsonDecode(await File(args[0]).readAsString()) as Map)
        .cast<String, Object?>();
    final surahs =
        jsonDecode(await File('assets/data/surahs.json').readAsString())
            as List;
    final counts = <int, int>{
      for (final s in surahs) s['id'] as int: s['ayahCount'] as int,
    };
    final result = validateStudyBundle(
      bytes: await File(args[1]).readAsBytes(),
      manifestEntry: manifest,
      canonicalAyahCounts: counts,
    );
    if (!result.isValid) {
      for (final error in result.errors) {
        stderr.writeln(error);
      }
      exitCode = 1;
      return;
    }
    stdout.writeln(
      'Valid: ${result.blocks.length} blocks; all ${counts.values.fold<int>(0, (a, b) => a + b)} ayahs covered; hash and bounds verified.',
    );
  } catch (error) {
    stderr.writeln('Validation failed: $error');
    exitCode = 1;
  }
}
