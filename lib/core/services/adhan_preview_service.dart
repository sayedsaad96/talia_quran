import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'prayer_sound.dart';
import '../utils/talia_logger.dart';

/// Plays a short preview of a bundled muezzin clip from the settings UI.
///
/// - iOS: clips live in the app bundle (`<clip>.caf`), loaded directly by
///   just_audio from assets via rootBundle.
/// - Android: the native `talia/adhan_preview` channel resolves the raw
///   resource into a playable source (native MediaPlayer preview). The
///   native side owns the player lifecycle for reliability.
class AdhanPreviewService {
  AdhanPreviewService({
    TargetPlatform? platform,
    MethodChannel? channel,
    AudioPlayer Function()? createIosPlayer,
    Future<String?> Function(String)? resolveIosAsset,
  }) : _platform = platform ?? defaultTargetPlatform,
       _channel = channel ?? const MethodChannel('talia/adhan_preview'),
       _createIosPlayer = createIosPlayer ?? AudioPlayer.new,
       _resolveIosAsset = resolveIosAsset;

  static const String _assetPrefix = 'res/raw/';

  final TargetPlatform _platform;
  final MethodChannel _channel;
  final AudioPlayer Function() _createIosPlayer;
  final Future<String?> Function(String)? _resolveIosAsset;
  Future<void> _nativeQueue = Future<void>.value();
  int _request = 0;
  AudioPlayer? _iosPlayer;

  /// Resolves the playable asset path for a muezzin profile (iOS only —
  /// Android uses the native channel). Returns null when unavailable.
  Future<String?> _iosAssetFor(String soundProfile) async {
    final clip = _clipNameFor(soundProfile);
    final assetPath = '$_assetPrefix$clip.caf';
    try {
      // Confirm the clip is bundled before handing it to the player.
      await rootBundle.load(assetPath);
      return assetPath;
    } on Exception {
      return null;
    }
  }

  String _clipNameFor(String soundProfile) {
    // Preview always demos the general (non-fajr) clip of the profile;
    // `fajr:x` previews the x recording itself.
    final p = soundProfile.trim();
    const prefix = MuezzinCatalog.fajrOverridePrefix;
    final effective = p.startsWith(prefix)
        ? p.substring(prefix.length).trim()
        : p;
    if (effective.isEmpty || effective == MuezzinCatalog.defaultId) {
      return 'adhan';
    }
    if (!MuezzinCatalog.isSupported(effective)) return 'adhan';
    return 'adhan_$effective';
  }

  /// Starts preview playback for [muezzinId]. Stops any current preview
  /// first. Returns true when playback actually started.
  Future<bool> start(String muezzinId) async {
    final request = ++_request;
    if (_platform == TargetPlatform.android) {
      return _queueNative(() async {
        await _stopNative();
        if (request != _request) return false;
        try {
          final started = await _channel.invokeMethod<bool>('previewStart', {
            'soundProfile': muezzinId,
          });
          if (request != _request) {
            await _stopNative();
            return false;
          }
          return started ?? false;
        } on PlatformException catch (error, stack) {
          TaliaLogger.w('[AdhanPreview] native preview failed', error, stack);
          return false;
        }
      });
    }
    if (_platform == TargetPlatform.iOS) {
      await _disposeIos();
      if (request != _request) return false;
      final asset =
          await (_resolveIosAsset?.call(muezzinId) ?? _iosAssetFor(muezzinId));
      if (asset == null || request != _request) return false;
      final player = _createIosPlayer();
      _iosPlayer = player;
      try {
        await player.setAsset(asset);
        if (request != _request || !identical(_iosPlayer, player)) return false;
        unawaited(_playIos(player));
        return true;
      } catch (error, stack) {
        TaliaLogger.w('[AdhanPreview] ios preview failed', error, stack);
        await _disposeIosPlayer(player);
        return false;
      }
    }
    return false;
  }

  /// Stops any running preview (native or Dart player).
  Future<void> stop() async {
    ++_request;
    if (_platform == TargetPlatform.android) {
      await _queueNative(_stopNative);
    } else if (_platform == TargetPlatform.iOS) {
      await _disposeIos();
    }
  }

  Future<T> _queueNative<T>(Future<T> Function() action) {
    final operation = _nativeQueue.then((_) => action());
    _nativeQueue = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  Future<void> _stopNative() async {
    try {
      await _channel.invokeMethod<void>('previewStop');
    } on PlatformException catch (error, stack) {
      TaliaLogger.w('[AdhanPreview] native stop failed', error, stack);
    }
  }

  Future<void> _playIos(AudioPlayer player) async {
    try {
      await player.play();
    } catch (error, stack) {
      TaliaLogger.w('[AdhanPreview] ios preview failed', error, stack);
    } finally {
      await _disposeIosPlayer(player);
    }
  }

  Future<void> _disposeIos() async {
    final player = _iosPlayer;
    if (player == null) return;
    await _disposeIosPlayer(player);
  }

  Future<void> _disposeIosPlayer(AudioPlayer player) async {
    if (!identical(_iosPlayer, player)) return;
    _iosPlayer = null;
    try {
      await player.stop();
      await player.dispose();
    } catch (_) {}
  }
}
