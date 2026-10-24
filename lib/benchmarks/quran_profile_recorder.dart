/// Configuration is intentionally fixed for comparable thirty-turn runs.
final class QuranProfileConfig {
  const QuranProfileConfig._(this.spread);

  factory QuranProfileConfig.parse(String mode) => switch (mode) {
    'single' => const QuranProfileConfig._(false),
    'spread' => const QuranProfileConfig._(true),
    _ => throw ArgumentError.value(mode, 'QURAN_PROFILE_MODE'),
  };

  final bool spread;
  int get turns => 30;
}

final class QuranFrameSample {
  const QuranFrameSample(
    this.vsyncUs,
    this.buildUs,
    this.rasterUs,
    this.totalUs,
  );

  final int vsyncUs;
  final int buildUs;
  final int rasterUs;
  final int totalUs;

  Map<String, int> toJson() => {
    'vsyncUs': vsyncUs,
    'buildUs': buildUs,
    'rasterUs': rasterUs,
    'totalUs': totalUs,
  };
}

/// Bounded raw evidence. No automatic performance verdict is produced.
final class QuranProfileRecorder {
  final Map<int, QuranFrameSample> _frames = {};
  bool overflowed = false;

  void add(QuranFrameSample sample) {
    if (_frames.length >= 20000) {
      overflowed = true;
      return;
    }
    _frames.putIfAbsent(sample.vsyncUs, () => sample);
  }

  Map<String, Object?> report({required int startUs, required int endUs}) {
    final samples =
        _frames.values
            .where((s) => s.vsyncUs >= startUs && s.vsyncUs < endUs)
            .toList()
          ..sort((a, b) => a.vsyncUs.compareTo(b.vsyncUs));
    final totals = samples.map((s) => s.totalUs).toList()..sort();
    return {
      'startUs': startUs,
      'endUs': endUs,
      'hasSamples': samples.isNotEmpty,
      'overflowed': overflowed,
      'validFrameWindow': samples.isNotEmpty && !overflowed && endUs > startUs,
      'sampleCount': samples.length,
      'over50ms': totals.where((t) => t > 50000).length,
      'over16ms': totals.where((t) => t >= 16000).length,
      ..._metrics('Total', totals),
      ..._metrics('Build', samples.map((s) => s.buildUs).toList()),
      ..._metrics('Raster', samples.map((s) => s.rasterUs).toList()),
      'frames': samples.map((s) => s.toJson()).toList(),
    };
  }

  Map<String, Object?> _metrics(String name, List<int> values) {
    values.sort();
    return {
      'mean${name}Us': values.isEmpty
          ? null
          : values.reduce((a, b) => a + b) / values.length,
      'max${name}Us': values.isEmpty ? null : values.last,
      'p95${name}Us': values.isEmpty
          ? null
          : values[(values.length * .95).ceil() - 1],
    };
  }
}
