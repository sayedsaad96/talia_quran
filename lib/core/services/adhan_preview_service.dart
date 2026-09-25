import 'dart:io';

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
  AdhanPreviewService();

  static const MethodChannel _channel = MethodChannel('talia/adhan_preview');

  static const String _assetPrefix = 'res/raw/';

  bool _nativePlaying = false;
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
    final effective = p.startsWith(prefix) ? p.substring(prefix.length).trim() : p;
    if (effective.isEmpty || effective == MuezzinCatalog.defaultId) return 'adhan';
    if (!MuezzinCatalog.isSupported(effective)) return 'adhan';
    return 'adhan_$effective';
  }

  /// Starts preview playback for [muezzinId]. Stops any current preview
  /// first. Returns true when playback actually started.
  Future<bool> start(String muezzinId) async {
    await stop();
    if (Platform.isAndroid) {
      try {
        final started = await _channel.invokeMethod<bool>('previewStart', {
          'soundProfile': muezzinId,
        });
        _nativePlaying = started ?? false;
        return _nativePlaying;
      } on PlatformException catch (e, stack) {
        TaliaLogger.w('[AdhanPreview] native preview failed', e, stack);
        return false;
      }
    }
    if (Platform.isIOS) {
      final asset = await _iosAssetFor(muezzinId);
      if (asset == null) return false;
      try {
        final player = AudioPlayer();
        await player.setAsset(asset);
        await player.play();
        _iosPlayer = player;
        return true;
      } catch (e, stack) {
        TaliaLogger.w('[AdhanPreview] ios preview failed', e, stack);
        await _disposeIos();
        return false;
      }
    }
    return false;
  }

  /// Stops any running preview (native or Dart player).
  Future<void> stop() async {
    if (Platform.isAndroid && _nativePlaying) {
      try {
        await _channel.invokeMethod<void>('previewStop');
      } on PlatformException catch (e, stack) {
        TaliaLogger.w('[AdhanPreview] native stop failed', e, stack);
      }
      _nativePlaying = false;
      return;
    }
    if (Platform.isIOS) {
      await _disposeIos();
    }
  }

  Future<void> _disposeIos() async {
    final player = _iosPlayer;
    _iosPlayer = null;
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
    } catch (_) {}
  }
}
