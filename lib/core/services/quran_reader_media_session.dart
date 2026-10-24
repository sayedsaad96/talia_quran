import 'package:audio_service/audio_service.dart';

import 'quran_background_audio_handler.dart';

/// Latest reader snapshot, including a load that outlives media initialization.
/// The playback generation is owned by the continuous player, not the platform.
class QuranReaderMediaSession {
  QuranBackgroundAudioHandler? _handler;
  List<MediaItem> _items = const [];
  int? _generation;
  int _index = 0;
  bool _loading = false;
  bool _hasNext = false;
  bool _hasPrevious = false;

  bool get isLoading => _loading;
  int? get generation => _generation;

  /// A validated in-session seek or rejected range keeps the existing queue.
  void retainForGeneration(int generation) {
    if (_generation != null && !_loading) _generation = generation;
  }

  void attach(QuranBackgroundAudioHandler handler) {
    _handler = handler;
    _publish();
  }

  void prepare({
    required int generation,
    required List<MediaItem> items,
    required int index,
    required bool hasNext,
    required bool hasPrevious,
  }) {
    _generation = generation;
    _items = List.unmodifiable(items);
    _index = index;
    _hasNext = hasNext;
    _hasPrevious = hasPrevious;
    _loading = true;
    _publish();
  }

  void commit(int generation) {
    if (_generation != generation) return;
    _loading = false;
    _handler?.commitQueue();
  }

  void updateIndex(
    int index, {
    required bool hasNext,
    required bool hasPrevious,
  }) {
    if (_generation == null || index < 0 || index >= _items.length) return;
    _index = index;
    _hasNext = hasNext;
    _hasPrevious = hasPrevious;
    _handler?.updateTransport(hasNext: hasNext, hasPrevious: hasPrevious);
  }

  void replaceItems(List<MediaItem> items) {
    if (_generation == null) return;
    _items = List.unmodifiable(items);
    _publish();
  }

  void _publish() {
    final handler = _handler;
    if (handler == null) return;
    if (_items.isEmpty) return handler.clearQueue();
    handler.prepareQueue(
      _items,
      initialIndex: _index,
      hasNext: _hasNext,
      hasPrevious: _hasPrevious,
    );
    if (!_loading) handler.commitQueue();
  }

  void clear() {
    _generation = null;
    _items = const [];
    _loading = false;
    _handler?.clearQueue();
  }
}
