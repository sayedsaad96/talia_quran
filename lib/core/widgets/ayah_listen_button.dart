import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../services/audio_cache_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A self-contained listen button that plays a single Quran ayah.
///
/// Manages its own [AudioPlayer] lifecycle — no cubit required.
/// Uses [AudioCacheService] for cached/offline playback.
///
/// Usage:
/// ```dart
/// AyahListenButton(surahId: 1, ayahNumber: 5)
/// ```
class AyahListenButton extends StatefulWidget {
  const AyahListenButton({
    super.key,
    required this.surahId,
    required this.ayahNumber,
    this.size = AyahListenButtonSize.normal,
    this.label,
  });

  final int surahId;
  final int ayahNumber;
  final AyahListenButtonSize size;

  /// Optional label shown below the button. Defaults to 'استمع' for normal size.
  final String? label;

  @override
  State<AyahListenButton> createState() => _AyahListenButtonState();
}

enum AyahListenButtonSize { small, normal }

class _AyahListenButtonState extends State<AyahListenButton> {
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _stateSub;

  bool _isPlaying = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.playerStateStream.listen(_onPlayerState);
  }

  void _onPlayerState(PlayerState ps) {
    if (!mounted) return;
    if (ps.processingState == ProcessingState.completed) {
      setState(() {
        _isPlaying = false;
        _isLoading = false;
      });
    } else if (ps.processingState == ProcessingState.buffering ||
        ps.processingState == ProcessingState.loading) {
      setState(() => _isLoading = true);
    } else if (ps.processingState == ProcessingState.ready) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle() async {
    if (_isLoading) return;

    if (_isPlaying) {
      await _player.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    setState(() {
      _isPlaying = true;
      _isLoading = true;
      _error = null;
    });

    try {
      final source = await AudioCacheService.instance.getAudioSource(
        widget.surahId,
        widget.ayahNumber,
      );
      await AudioCacheService.playFromSource(_player, source);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isLoading = false;
          _error = 'تعذّر تشغيل الصوت';
        });
        // Auto-clear error after 3s
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _error = null);
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant AyahListenButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Stop audio if the ayah changed (e.g. quiz moved to next question)
    if (oldWidget.surahId != widget.surahId ||
        oldWidget.ayahNumber != widget.ayahNumber) {
      _player.stop();
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmall = widget.size == AyahListenButtonSize.small;

    final buttonColor = _error != null
        ? AppColors.error
        : _isPlaying
        ? AppColors.gold
        : (isDark ? AppColors.primaryLight : AppColors.primary);

    final containerSize = isSmall ? 36.0 : 48.0;
    final iconSize = isSmall ? 18.0 : 24.0;

    return Semantics(
      button: true,
      label: _isPlaying ? 'إيقاف تلاوة الآية' : 'استماع للآية',
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isPlaying
                        ? AppColors.gold.withValues(alpha: 0.15)
                        : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    border: Border.all(
                      color: buttonColor.withValues(alpha: _isPlaying ? 1.0 : 0.6),
                      width: 2,
                    ),
                    boxShadow: _isPlaying
                        ? [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: buttonColor,
                          ),
                        )
                      : Icon(
                          _error != null
                              ? Icons.wifi_off_rounded
                              : _isPlaying
                              ? Icons.pause_rounded
                              : Icons.headphones_rounded,
                          color: _isPlaying ? AppColors.gold : buttonColor,
                          size: iconSize,
                        ),
                ),
                if (!isSmall) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.label ??
                        (_error != null
                            ? 'خطأ'
                            : _isPlaying
                            ? 'إيقاف'
                            : 'استمع'),
                    style: AppTypography.labelSmall.copyWith(
                      color: _isPlaying
                          ? AppColors.gold
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      fontWeight: _isPlaying ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
