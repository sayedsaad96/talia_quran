import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

/// Centralized manager that pauses every registered [AudioPlayer] the moment
/// the app leaves the foreground (home button, task switcher, phone call, etc.)
///
/// ### Usage
/// Call [AudioLifecycleManager.instance.register] when creating a player and
/// [AudioLifecycleManager.instance.unregister] in dispose / cubit close.
class AudioLifecycleManager {
  AudioLifecycleManager._() {
    _listener = AppLifecycleListener(
      onHide: _pauseAll,     // Android: home / recents
      onPause: _pauseAll,    // iOS: home / lock screen
      onInactive: _pauseAll, // incoming call / task switcher overlay
    );
  }

  static final AudioLifecycleManager instance = AudioLifecycleManager._();

  late final AppLifecycleListener _listener;

  final Set<AudioPlayer> _players = {};

  /// Register a player to be paused on background.
  void register(AudioPlayer player) => _players.add(player);

  /// Unregister when the player is disposed.
  void unregister(AudioPlayer player) => _players.remove(player);

  void _pauseAll() {
    for (final p in List<AudioPlayer>.from(_players)) {
      if (p.playing) {
        p.pause();
      }
    }
  }

  /// Dispose the lifecycle listener. Call only on app shutdown.
  void dispose() {
    _listener.dispose();
    _players.clear();
  }
}
