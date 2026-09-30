import 'dart:async';

/// Shares review-record reads among the calls made inside one [run].
///
/// A single home load asks progress, the smart coach, the navigation
/// resolver and home itself for the same owner/audience records at once;
/// without a batch each of them did its own full Isar scan. Inside [run],
/// reads with the same key share one load. Every caller still receives its
/// own list, and once [run]'s body completes the batch closes, so callbacks
/// that outlive it (timers, stream listeners created in its zone) read fresh
/// data again. Outside a batch [read] always goes to the store.
///
/// Wrap read-only flows only: a write made inside the batch is not visible to
/// later reads of the same key within that batch.
class ReviewRecordReadBatch {
  ReviewRecordReadBatch._();

  static final Object _zoneKey = Object();

  final Map<String, Future<List<Object?>>> _reads = {};
  bool _closed = false;

  static Future<T> run<T>(Future<T> Function() body) async {
    final batch = ReviewRecordReadBatch._();
    try {
      return await runZoned(body, zoneValues: {_zoneKey: batch});
    } finally {
      batch._closed = true;
      batch._reads.clear();
    }
  }

  /// Loads the records for [key] (owner + audience), sharing the load with
  /// other reads of the same key in the current batch.
  static Future<List<R>> read<R>(
    String key,
    Future<List<R>> Function() load,
  ) async {
    final batch = Zone.current[_zoneKey] as ReviewRecordReadBatch?;
    if (batch == null || batch._closed) return load();
    final shared = batch._reads.putIfAbsent(key, load);
    return List<R>.of((await shared).cast<R>());
  }
}
