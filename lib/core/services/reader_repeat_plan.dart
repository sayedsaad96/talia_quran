import 'package:equatable/equatable.dart';

/// Repeat/speed choices for continuous reader playback.
final class ReaderRepeatSettings extends Equatable {
  const ReaderRepeatSettings({
    this.perAyah = 1,
    this.rangeTimes = 1,
    this.speed = 1.0,
  });

  static const List<double> allowedSpeeds = [0.75, 1.0, 1.25, 1.5];

  /// 1..10
  final int perAyah;

  /// 1..10, or 0 = infinite (the caller sets loop mode).
  final int rangeTimes;

  /// One of [allowedSpeeds]; anything else is treated as 1.0.
  final double speed;

  bool get isDefault =>
      perAyah == 1 && rangeTimes == 1 && normalizedSpeed == 1.0;

  double get normalizedSpeed => allowedSpeeds.contains(speed) ? speed : 1.0;

  @override
  List<Object?> get props => [perAyah, rangeTimes, speed];
}

/// Expands [ayahs] (in order) into the playback queue. rangeTimes 0 gives one
/// pass (the caller sets loop mode). Values outside the ranges are clamped.
///
/// No silent gap is inserted between repeats: the service maps queue index to
/// ayah, and silence would break that mapping.
List<T> expandRepeatQueue<T>(List<T> ayahs, ReaderRepeatSettings s) {
  final per = s.perAyah.clamp(1, 10);
  final passes = s.rangeTimes == 0 ? 1 : s.rangeTimes.clamp(1, 10);
  final out = <T>[];
  for (var p = 0; p < passes; p++) {
    for (final a in ayahs) {
      for (var i = 0; i < per; i++) {
        out.add(a);
      }
    }
  }
  return out;
}

bool _eq<T>(T a, T b) => a == b;

/// Index of the first queue item of the next distinct ayah, or null.
///
/// Items are compared with `==` (Ayah is Equatable) unless [same] is given.
int? nextDistinctIndex<T>(
  List<T> queue,
  int current, {
  bool Function(T a, T b)? same,
}) {
  if (current < 0 || current >= queue.length) return null;
  final eq = same ?? _eq<T>;
  for (var i = current + 1; i < queue.length; i++) {
    if (!eq(queue[i], queue[current])) return i;
  }
  return null;
}

/// First queue index of the previous distinct ayah run, or null.
int? previousDistinctIndex<T>(
  List<T> queue,
  int current, {
  bool Function(T a, T b)? same,
}) {
  if (current < 0 || current >= queue.length) return null;
  final eq = same ?? _eq<T>;
  var i = current;
  while (i >= 0 && eq(queue[i], queue[current])) {
    i--;
  }
  if (i < 0) return null;
  final prev = queue[i];
  while (i > 0 && eq(queue[i - 1], prev)) {
    i--;
  }
  return i;
}
