import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Progress surfaces must not compute memorization metrics locally.
///
/// Invariant:
/// Widget → Cubit → Repository → ProgressMetricsService → ReviewRecordFilters
///
/// This test fails CI when review-record filtering or progress calculators
/// appear in presentation code for Home, Progress, Parent, Certificates, or Kids.
void main() {
  group('presentation progress calculation guard', () {
    test(
      'progress surfaces do not filter review records or compute metrics',
      () {
        final violations = <String>[];

        for (final file in _progressSurfaceDartFiles()) {
          final relativePath = _relativePath(file);
          final isUiLayer = _isUiLayer(relativePath);
          final isCubitLayer = relativePath.contains('/presentation/cubits/');

          if (!_isInScope(relativePath)) continue;

          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            final lineNo = i + 1;
            final trimmed = line.trim();

            if (trimmed.isEmpty || trimmed.startsWith('//')) continue;

            if (isUiLayer) {
              for (final pattern in _forbiddenUiTokens) {
                if (trimmed.contains(pattern)) {
                  violations.add(
                    '$relativePath:$lineNo uses `$pattern` in UI layer',
                  );
                }
              }
            }

            if (isCubitLayer) {
              for (final pattern in _forbiddenCubitTokens) {
                if (trimmed.contains(pattern)) {
                  violations.add(
                    '$relativePath:$lineNo uses `$pattern` in cubit layer',
                  );
                }
              }
            }

            if (_isForbiddenReviewRecordWhere(trimmed)) {
              violations.add(
                '$relativePath:$lineNo filters review records via `.where(`',
              );
            }

            if (_isForbiddenInlineMetricComparison(trimmed)) {
              violations.add(
                '$relativePath:$lineNo compares raw review-record metric fields',
              );
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Presentation must not compute progress metrics locally.\n'
              'Move logic to Repository / ProgressMetricsService / UseCase.\n\n'
              '${violations.join('\n')}',
        );
      },
    );
  });
}

const _scopedDirectorySuffixes = [
  '/home/presentation/',
  '/progress/presentation/',
  '/certificate/presentation/',
  '/memorization_plus/presentation/pages/',
  '/memorization_plus/presentation/navigation/',
  '/memorization_plus/presentation/cubits/parent_dashboard_cubit.dart',
];

const _forbiddenUiTokens = [
  'getAllReviewRecords',
  'ReviewRecordFilters',
  'ProgressMetricsService',
];

const _forbiddenCubitTokens = ['ReviewRecordFilters', 'ProgressMetricsService'];

Iterable<File> _progressSurfaceDartFiles() sync* {
  final libDir = Directory('lib/features');
  if (!libDir.existsSync()) return;

  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.contains('.g.dart') ||
        entity.path.contains('.freezed.dart')) {
      continue;
    }
    yield entity;
  }
}

String _relativePath(File file) =>
    file.path.replaceAll('\\', '/').replaceFirst(RegExp(r'^.*?/lib/'), 'lib/');

bool _isInScope(String relativePath) {
  if (relativePath.contains('/presentation/pages/kids_')) return true;
  return _scopedDirectorySuffixes.any(relativePath.contains);
}

bool _isUiLayer(String relativePath) {
  return relativePath.contains('/presentation/pages/') ||
      relativePath.contains('/presentation/widgets/') ||
      relativePath.contains('/presentation/navigation/');
}

bool _isForbiddenReviewRecordWhere(String line) {
  if (!line.contains('.where(')) return false;

  if (_isAllowedUiCollectionWhere(line)) return false;

  if (RegExp(r'\brecords\.where\s*\(').hasMatch(line)) return true;
  if (RegExp(r'\breviewRecords\.where\s*\(').hasMatch(line)) return true;
  if (RegExp(r'\.where\s*\(\s*\(\s*record\b').hasMatch(line)) return true;

  if (RegExp(r'\.where\s*\(\s*\(\s*r\b').hasMatch(line)) {
    if (line.contains('RecommendationPriority') ||
        line.contains('RecommendationType')) {
      return false;
    }
    if (line.contains('totalReviews') ||
        line.contains('strengthLevel') ||
        line.contains('lastReviewedAt') ||
        line.contains('surahId')) {
      return true;
    }
  }

  return line.contains('AyahReviewRecord') ||
      line.contains('ReviewRecordFilters');
}

bool _isAllowedUiCollectionWhere(String line) {
  return RegExp(
    r'\.where\s*\(\s*\(\s*(a|log|cat|section|sub|status|part|child)\b',
  ).hasMatch(line);
}

bool _isForbiddenInlineMetricComparison(String line) {
  if (line.contains('RecommendationPriority') ||
      line.contains('RecommendationType') ||
      line.contains('PerformanceRating')) {
    return false;
  }

  return RegExp(r'\bstrengthLevel\s*[><=!]').hasMatch(line) ||
      RegExp(r'\btotalReviews\s*[><=!]').hasMatch(line);
}
