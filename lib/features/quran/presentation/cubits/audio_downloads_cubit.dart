import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/quran_audio_download_manager.dart';
import '../../../../core/services/quran_reciter.dart';

class AudioDownloadsState {
  const AudioDownloadsState({
    this.progress,
    this.bytes = const {},
    this.busy = false,
    this.failed = false,
  });

  final DownloadProgress? progress;
  final Map<QuranReciter, int> bytes;
  final bool busy;
  final bool failed;
}

class AudioDownloadsCubit extends Cubit<AudioDownloadsState> {
  AudioDownloadsCubit(this._manager) : super(const AudioDownloadsState());

  final QuranAudioDownloadManager _manager;
  StreamSubscription<DownloadProgress>? _subscription;

  Future<void> loadStorage() async {
    if (isClosed) return;
    emit(AudioDownloadsState(bytes: state.bytes, busy: true));
    try {
      final bytes = <QuranReciter, int>{};
      for (final reciter in QuranReciter.values) {
        bytes[reciter] = await _manager.usedBytes(reciter: reciter);
      }
      if (!isClosed) emit(AudioDownloadsState(bytes: bytes));
    } catch (_) {
      if (!isClosed) {
        emit(AudioDownloadsState(bytes: state.bytes, failed: true));
      }
    }
  }

  /// Network type as the device reports it; null when unknown.
  Future<bool?> probeUnmeteredNetwork() => _manager.isOnUnmeteredNetwork();

  Future<void> start({
    required QuranReciter reciter,
    required bool wifiOnly,
    required bool allowUnverifiedNetwork,
    int? surah,
    int? juz,
  }) async {
    if (isClosed || state.busy) return;
    emit(AudioDownloadsState(bytes: state.bytes, busy: true));
    await _subscription?.cancel();
    if (isClosed) return;
    final stream = juz != null
        ? _manager.downloadJuz(
            reciter,
            juz,
            wifiOnly: wifiOnly,
            allowUnverifiedNetwork: allowUnverifiedNetwork,
          )
        : _manager.downloadSurahs(
            reciter,
            [surah!],
            wifiOnly: wifiOnly,
            allowUnverifiedNetwork: allowUnverifiedNetwork,
          );
    _subscription = stream.listen(
      _onProgress,
      onError: (Object _) {
        if (!isClosed) {
          emit(AudioDownloadsState(bytes: state.bytes, failed: true));
        }
      },
    );
  }

  void _onProgress(DownloadProgress progress) {
    if (isClosed) return;
    final busy =
        progress.phase == DownloadPhase.checking ||
        progress.phase == DownloadPhase.downloading;
    emit(
      AudioDownloadsState(
        bytes: state.bytes,
        progress: progress,
        busy: busy,
        failed: progress.phase == DownloadPhase.failed,
      ),
    );
  }

  Future<void> cancel() => _manager.cancel();

  Future<void> deleteReciter(QuranReciter reciter) async {
    if (state.busy) return;
    emit(AudioDownloadsState(bytes: state.bytes, busy: true));
    try {
      await _manager.deleteReciter(reciter);
      await loadStorage();
    } catch (_) {
      if (!isClosed) {
        emit(AudioDownloadsState(bytes: state.bytes, failed: true));
      }
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
