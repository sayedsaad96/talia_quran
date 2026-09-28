import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet against design-token drift (docs/audits/TALIA_UI_UX_AUDIT.md D10).
///
/// Counts hardcoded styling in UI code and fails if any file has more than
/// its recorded baseline. Counts may only go down; new files start at zero,
/// so new UI must use `context.tokens`, the text theme and `AppSpacing`.
///
/// After migrating a screen, lower the baseline:
///   UPDATE_DESIGN_BASELINE=1 flutter test test/design_system/design_token_guard_test.dart
/// Regenerating can only ever shrink entries — raising one is refused.

const _baselinePath = 'test/design_system/design_token_baseline.json';

const _roots = ['lib/features', 'lib/core/widgets'];

final _metrics = <String, RegExp>{
  'hexColor': RegExp(r'Color\(0x'),
  'fontSizeLiteral': RegExp(r'fontSize:\s*[0-9]'),
  'radiusLiteral': RegExp(r'BorderRadius\.circular\(\s*[0-9]'),
  'isDarkBranch': RegExp(r'isDark\s*\?'),
};

/// Files that legitimately own a fixed palette (exported images).
bool _isExempt(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('_palette.dart') ||
    path.endsWith('talia_share_tokens.dart');

bool _inScope(String path) =>
    path.startsWith('lib/core/widgets/') || path.contains('/presentation/');

Map<String, Map<String, int>> _scan() {
  final result = <String, Map<String, int>>{};
  for (final root in _roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!_inScope(path) || _isExempt(path)) continue;
      final source = entity
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      final counts = <String, int>{};
      _metrics.forEach((name, re) {
        final n = re.allMatches(source).length;
        if (n > 0) counts[name] = n;
      });
      if (counts.isNotEmpty) result[path] = counts;
    }
  }
  return result;
}

Map<String, Map<String, int>> _readBaseline() {
  final file = File(_baselinePath);
  if (!file.existsSync()) return {};
  final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return raw.map(
    (path, counts) => MapEntry(path, (counts as Map<String, dynamic>).cast()),
  );
}

void main() {
  test('UI code does not add hardcoded colors, sizes, radii or isDark '
      'branches beyond the baseline', () {
    final current = _scan();
    var baseline = _readBaseline();

    if (Platform.environment['UPDATE_DESIGN_BASELINE'] == '1') {
      final next = <String, Map<String, int>>{};
      for (final entry in current.entries) {
        final old = baseline[entry.key];
        final merged = <String, int>{};
        entry.value.forEach((metric, n) {
          // Shrink-only: the initial baseline records what exists; after
          // that, nothing (including a brand-new file) may grow.
          final allowed = baseline.isEmpty ? n : (old?[metric] ?? 0);
          if (allowed > 0) merged[metric] = n < allowed ? n : allowed;
        });
        if (merged.isNotEmpty) next[entry.key] = merged;
      }
      final sorted = Map.fromEntries(
        next.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      File(_baselinePath).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
      );
      baseline = sorted;
    }

    final violations = <String>[];
    for (final entry in current.entries) {
      final allowed = baseline[entry.key] ?? const <String, int>{};
      entry.value.forEach((metric, n) {
        final max = allowed[metric] ?? 0;
        if (n > max) {
          violations.add('${entry.key}: $metric $n > baseline $max');
        }
      });
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use context.tokens / textTheme / AppSpacing instead of literals. '
          'See docs/audits/TALIA_UI_UX_AUDIT.md §6.',
    );
  });
}
