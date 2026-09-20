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

  final Map<AudioPlayer, bool Function()?> _players = {};

  /// Register a player to be paused on background.
  /// If [shouldPause] is provided, it is evaluated when the app enters the background;
  /// returning `false` will exempt this player from being paused (e.g. for background Quran playback).
  void register(AudioPlayer player, {bool Function()? shouldPause}) {
    _players[player] = shouldPause;
  }

  /// Unregister when the player is disposed.
  void unregister(AudioPlayer player) => _players.remove(player);

  void _pauseAll() {
    for (final entry in Map<AudioPlayer, bool Function()?>.from(_players).entries) {
      final player = entry.key;
      final shouldPause = entry.value;
      if (shouldPause != null && !shouldPause()) {
        continue;
      }
      if (player.playing) {
        player.pause();
      }
    }
  }

  /// Manually triggers pausing for all eligible registered players.
  void pauseAll() => _pauseAll();

  /// Dispose the lifecycle listener. Call only on app shutdown.
  void dispose() {
    _listener.dispose();
    _players.clear();
  }
}
