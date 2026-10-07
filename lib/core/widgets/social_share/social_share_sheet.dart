import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../constants/app_spacing.dart';
import '../../di/injection.dart';
import '../../extensions/context_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'social_share_card.dart';
import 'social_share_card_rasterizer.dart';
import 'social_share_copy.dart';
import '../../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';

/// Preserves the active locale when [child] is rendered outside the app tree.
Widget buildSocialShareCaptureTree({
  required BuildContext context,
  required Widget child,
}) {
  return Localizations.override(context: context, child: child);
}

/// Builds the one canonical logical canvas shared by preview and export.
/// Preview scales this finished composition; it never lays the card out at a
/// narrower width, so line breaks and character placement match the PNG.
Widget buildSocialShareCardCanvas({
  Key? key,
  required SocialShareData data,
  SocialShareMood mood = SocialShareMood.auto,
  required SocialShareFormat format,
  bool hideUserName = false,
}) {
  final size = format.exportLogicalSize;
  return SizedBox(
    key: key ?? const ValueKey('social-share-card-canvas'),
    width: size.width,
    height: size.height,
    child: SocialShareCard(
      data: data,
      mood: mood,
      format: format,
      width: size.width,
      hideUserName: hideUserName,
    ),
  );
}

/// Rasterizes the exact production card canvas used by the live preview.
Future<Uint8List> captureSocialShareCardImage({
  required BuildContext context,
  required SocialShareData data,
  SocialShareMood mood = SocialShareMood.auto,
  required SocialShareFormat format,
  bool hideUserName = false,
}) async {
  final size = format.exportLogicalSize;
  return rasterizeSocialShareCard(
    buildSocialShareCaptureTree(
      context: context,
      child: buildSocialShareCardCanvas(
        data: data,
        mood: mood,
        format: format,
        hideUserName: hideUserName,
      ),
    ),
    context: context,
    size: size,
  );
}

class SocialShareSheet extends StatefulWidget {
  final SocialShareData data;

  const SocialShareSheet({super.key, required this.data});

  static Future<void> show(BuildContext context, SocialShareData data) async {
    // Opening the sheet must never wait indefinitely for profile storage.
    // The default presentation is safe while a slow/unavailable profile read
    // falls back to the supplied data.
    final resolvedData = await _resolveAudience(
      data,
    ).timeout(const Duration(milliseconds: 300), onTimeout: () => data);
    if (!context.mounted) return;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SocialShareSheet(data: resolvedData),
    );
  }

  static Future<SocialShareData> _resolveAudience(SocialShareData data) async {
    try {
      final result = await getIt<MemorizationPlusRepository>()
          .getMemorizationProfile();
      final resolved = result.fold(
        (_) => data,
        (profile) => data.copyWith(
          audience: profile.isChild
              ? SocialShareAudience.kids
              : SocialShareAudience.adult,
        ),
      );
      return resolved;
    } catch (_) {
      return data;
    }
  }

  @override
  State<SocialShareSheet> createState() => _SocialShareSheetState();
}

class _SocialShareSheetState extends State<SocialShareSheet> {
  // Auto follows the content type (and audience); night/day force one look.
  SocialShareMood _selectedMood = SocialShareMood.auto;
  SocialShareFormat _selectedFormat = SocialShareFormat.portrait;
  bool _isExporting = false;
  bool _logoPrecached = false;
  // Name toggle: shown by default since personalization is a core marketing
  // hook — "رحلة [اسم المستخدم] مع القرآن" differentiates each share.
  bool _showUserName = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Offscreen capture must not race the logo decode.
    if (_logoPrecached) return;
    _logoPrecached = true;
    // Warm the exact (resized) images the card paints, for every format the
    // user can switch to; the full-size asset is a different cache entry.
    for (final format in SocialShareFormat.values) {
      final metrics = TaliaShareMetrics.of(format);
      unawaited(
        precacheImage(
          ShareSignatureBar.logoProvider(metrics.logoSize),
          context,
          onError: (_, _) {},
        ),
      );
      if (widget.data.audience == SocialShareAudience.kids &&
          widget.data.showCharacter) {
        unawaited(
          precacheImage(
            TaliaCharacterHero.imageProvider(
              widget.data.effectiveCharacterAssetPath,
              metrics.characterHeight,
            ),
            context,
            onError: (_, _) {},
          ),
        );
      }
    }
  }

  Widget _buildChoiceChip({
    Key? key,
    required Widget avatar,
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      key: key,
      avatar: avatar,
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        if (!value) return;
        unawaited(HapticFeedback.selectionClick());
        onSelected();
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      backgroundColor: context.tokens.surfaceVariant,
      labelStyle: TextStyle(
        color: selected
            ? AppColors.primary
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        fontSize: 11,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : Colors.transparent,
      ),
    );
  }

  Future<Uint8List?> _captureCardImage() async {
    try {
      return await captureSocialShareCardImage(
        context: context,
        data: widget.data,
        mood: _selectedMood,
        format: _selectedFormat,
        hideUserName: !_showUserName,
      );
    } catch (e) {
      debugPrint('Error capturing social card image: $e');
      return null;
    }
  }

  Future<void> _shareAsImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final copy = SocialShareCopy.of(context);

    try {
      final imageBytes = await _captureCardImage();
      if (imageBytes == null) {
        if (mounted) {
          _showSnackBar(copy.errorCapture);
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/talia_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(imageBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: widget.data.toPlainShareText(footer: copy.plainShareFooter),
        ),
      );
    } catch (e) {
      debugPrint('Error sharing social image: $e');
      if (mounted) {
        _showSnackBar(copy.errorShare);
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _saveToGallery() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final copy = SocialShareCopy.of(context);

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) {
            _showSnackBar(copy.permissionNeeded);
          }
          return;
        }
      }

      final imageBytes = await _captureCardImage();
      if (imageBytes == null) {
        if (mounted) {
          _showSnackBar(copy.errorCaptureForSave);
        }
        return;
      }

      await Gal.putImageBytes(
        imageBytes,
        name: 'talia_card_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      if (mounted) {
        unawaited(HapticFeedback.mediumImpact());
        _showSnackBar(copy.savedToGallery);
      }
    } catch (e) {
      debugPrint('Error saving social card image: $e');
      if (mounted) {
        _showSnackBar(copy.errorSave);
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _shareAsText() {
    final copy = SocialShareCopy.of(context);
    unawaited(HapticFeedback.lightImpact());
    unawaited(
      SharePlus.instance.share(
        ShareParams(
          text: widget.data.toPlainShareText(footer: copy.plainShareFooter),
        ),
      ),
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = SocialShareCopy.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth - AppSpacing.md * 2).clamp(0.0, 360.0);
    final canonicalSize = _selectedFormat.exportLogicalSize;
    final previewHeight =
        cardWidth * canonicalSize.height / canonicalSize.width;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.tokens.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: AppSpacing.md,
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.tokens.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.share_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              copy.sheetTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Card Preview Area.  The live preview is a plain render: the
              // export re-renders offscreen on a fixed 360-logical canvas, so
              // no capture boundary is needed around the preview itself.
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        key: ValueKey(
                          '$_selectedMood-$_selectedFormat-$_showUserName',
                        ),
                        width: cardWidth,
                        height: previewHeight,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: buildSocialShareCardCanvas(
                            data: widget.data,
                            mood: _selectedMood,
                            format: _selectedFormat,
                            hideUserName: !_showUserName,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Format Picker (Aspect Ratio Selector with Horizontal Scroll Safety)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: SocialShareFormat.values.map((fmt) {
                    final isSelected = fmt == _selectedFormat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildChoiceChip(
                        avatar: Icon(
                          fmt.icon,
                          size: 14,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                        ),
                        label: copy.formatName(fmt),
                        selected: isSelected,
                        isDark: isDark,
                        onSelected: () => setState(() => _selectedFormat = fmt),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Theme Selector Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    copy.chooseStyle,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: SocialShareMood.values.map((mood) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildChoiceChip(
                        key: ValueKey('share-mood-${mood.name}'),
                        avatar: _MoodSwatch(
                          palette: SharePalettes.resolve(widget.data, mood),
                        ),
                        label: copy.moodName(mood),
                        selected: mood == _selectedMood,
                        isDark: isDark,
                        onSelected: () => setState(() => _selectedMood = mood),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // ─── Name visibility toggle (only if a name was provided) ─────────
              if (widget.data.userName != null &&
                  widget.data.userName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        copy.showNameLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _showUserName,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) {
                            unawaited(HapticFeedback.selectionClick());
                            setState(() => _showUserName = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.sm),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    // Primary Share Image Button
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isExporting ? null : _shareAsImage,
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            _isExporting ? copy.preparing : copy.shareAsImage,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.xs),

                    // Save to Gallery
                    IconButton.filledTonal(
                      onPressed: _isExporting ? null : _saveToGallery,
                      icon: const Icon(Icons.download_rounded, size: 20),
                      tooltip: copy.saveToGalleryTooltip,
                      style: IconButton.styleFrom(
                        backgroundColor: context.tokens.surfaceVariant,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.xs),

                    // Share as Text
                    IconButton.filledTonal(
                      onPressed: _isExporting ? null : _shareAsText,
                      icon: const Icon(Icons.short_text_rounded, size: 20),
                      tooltip: copy.shareAsTextTooltip,
                      style: IconButton.styleFrom(
                        backgroundColor: context.tokens.surfaceVariant,
                        foregroundColor: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiny sky swatch previewing a mood's palette.
class _MoodSwatch extends StatelessWidget {
  const _MoodSwatch({required this.palette});

  final SharePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.skyTop, palette.skyBase, palette.glow],
        ),
        border: Border.all(color: palette.archLine),
      ),
    );
  }
}
