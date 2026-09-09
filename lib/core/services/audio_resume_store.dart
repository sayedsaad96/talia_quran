import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../identity/account_data_barrier.dart';
import 'quran_continuous_player_service.dart';
import 'quran_reciter.dart';

class AudioResumePosition {
  const AudioResumePosition({
    required this.surahId,
    required this.ayahNumber,
    this.pageNumber,
    this.reciterId,
    this.scope = PlayScope.surah,
  });

  final int surahId;
  final int ayahNumber;
  final int? pageNumber;
  final String? reciterId;
  final PlayScope scope;

  QuranReciter? get reciter {
    if (reciterId == null) return null;
    for (final reciter in QuranReciter.values) {
      if (reciter.id == reciterId) return reciter;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'surahId': surahId,
    'ayahNumber': ayahNumber,
    'pageNumber': pageNumber,
    'reciterId': reciterId,
    'scope': scope.name,
  };

  factory AudioResumePosition.fromJson(Map<String, dynamic> json) {
    return AudioResumePosition(
      surahId: json['surahId'] as int,
      ayahNumber: json['ayahNumber'] as int,
      pageNumber: json['pageNumber'] as int?,
      reciterId: json['reciterId'] as String?,
      scope: PlayScope.values.firstWhere(
        (value) => value.name == json['scope'],
        orElse: () => PlayScope.surah,
      ),
    );
  }
}

/// Persists the last Quran playback position across process restarts.
class AudioResumeStore {
  AudioResumeStore(this._prefs);

  static const _key = 'audio_resume_position';

  final SharedPreferences _prefs;
  VoidCallback? _listener;
  QuranContinuousPlayerService? _player;
  AccountDataLease? _attachmentAuthority;
  StreamSubscription<void>? _authorityChanges;

  AccountDataBarrier get _barrier => AccountDataBarrier.forPreferences(_prefs);

  AudioResumePosition? get position {
    if (!_barrier.isReady) return null;
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return AudioResumePosition.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  void attach(QuranContinuousPlayerService player) {
    detach();
    _player = player;
    _listener = _onPlayerChanged;
    player.stateNotifier.addListener(_listener!);
    _authorityChanges = _barrier.changes.listen(_onAuthorityChanged);
    _armForCurrentAuthority();
  }

  void detach() {
    final listener = _listener;
    final player = _player;
    if (listener != null && player != null) {
      player.stateNotifier.removeListener(listener);
    }
    _listener = null;
    _player = null;
    _attachmentAuthority = null;
    unawaited(_authorityChanges?.cancel());
    _authorityChanges = null;
  }

  Future<void> save(AudioResumePosition position) async {
    final authority = _barrier.capture();
    await _save(position, authority);
  }

  Future<void> clear() => _prefs.remove(_key);

  /// Stops old-account playback before its persisted state is cleared.
  Future<void> stopPlaybackForAccountReset() async {
    _attachmentAuthority = null;
    await _player?.stop();
  }

  void _onPlayerChanged() {
    final state = _player?.state;
    if (state == null || !state.hasActiveAudio) return;
    final surahId = state.currentSurahId;
    final ayahNumber = state.currentAyahNumber;
    if (surahId == null || ayahNumber == null) return;
    final authority = _attachmentAuthority;
    if (authority == null) return;
    unawaited(
      _save(
        AudioResumePosition(
          surahId: surahId,
          ayahNumber: ayahNumber,
          pageNumber: state.currentPageNumber,
          reciterId: state.reciter?.id,
          scope: state.scope,
        ),
        authority,
      ).onError((Object error, StackTrace stackTrace) {
        if (error is AccountDataUnavailableException) return;
        Error.throwWithStackTrace(error, stackTrace);
      }),
    );
  }

  Future<void> _save(
    AudioResumePosition position,
    AccountDataLease authority,
  ) => _barrier.run<void>((lease) async {
    await _prefs.setString(_key, jsonEncode(position.toJson()));
    lease.check();
  }, authority: authority);

  void _onAuthorityChanged(void _) {
    if (!_barrier.isReady) {
      _attachmentAuthority = null;
      return;
    }
    if (_player?.state.hasActiveAudio ?? false) return;
    _armForCurrentAuthority();
  }

  void _armForCurrentAuthority() {
    try {
      _attachmentAuthority = _barrier.capture();
    } on AccountDataUnavailableException {
      _attachmentAuthority = null;
    }
  }
}
