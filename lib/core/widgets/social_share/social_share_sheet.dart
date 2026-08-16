import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../constants/app_spacing.dart';
import '../../di/injection.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'social_share_card.dart';
import 'social_share_copy.dart';
import '../../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';

class SocialShareSheet extends StatefulWidget {
  final SocialShareData data;

  const SocialShareSheet({super.key, required this.data});

  static Future<void> show(BuildContext context, SocialShareData data) async {
    // Opening the sheet must never wait indefinitely for profile storage.
    // The default presentation is safe while a slow/unavailable profile read
    // falls back to the supplied data.
    final resolvedData = await _resolveAudience(data).timeout(
      const Duration(milliseconds: 300),
      onTimeout: () => data,
    );
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
      return result.fold(
        (_) => data,
        (profile) => data.copyWith(
          audience: profile.isChild
              ? SocialShareAudience.kids
              : SocialShareAudience.adult,
          // A character supports the playful kids track but does not dominate
          // the refined adult variants.
          showCharacter: profile.isChild && data.category != SocialShareCategory.quranAyah,
        ),
      );
    } catch (_) {
      return data;
    }
  }

  @override
  State<SocialShareSheet> createState() => _SocialShareSheetState();
}

class _SocialShareSheetState extends State<SocialShareSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  late SocialShareThemeType _selectedThemeType;
  SocialShareFormat _selectedFormat = SocialShareFormat.portrait;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Content-driven default: the share type (and audience) picks the
    // opening style; the user can still switch to any palette.
    _selectedThemeType = SocialShareThemeType.defaultFor(
      widget.data.category,
      audience: widget.data.audience,
    );
  }

  SocialShareTheme get _currentTheme => SocialShareTheme.get(_selectedThemeType);

  Future<Uint8List?> _captureCardImage() async {
    try {
      final size = _selectedFormat.exportLogicalSize;
      return await _screenshotController.captureFromWidget(
        SizedBox(
          width: size.width,
          height: size.height,
          child: SocialShareCard(
            data: widget.data,
            theme: _currentTheme,
            format: _selectedFormat,
            width: size.width,
          ),
        ),
        context: context,
        delay: const Duration(milliseconds: 200),
        pixelRatio: 3.0,
        targetSize: size,
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
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = SocialShareCopy.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth - AppSpacing.md * 2).clamp(0.0, 360.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
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
                    Row(
                      children: [
                        const Icon(
                          Icons.share_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          copy.sheetTitle,
                          style: AppTypography.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: SocialShareCard(
                        key: ValueKey('$_selectedThemeType-$_selectedFormat'),
                        data: widget.data,
                        theme: _currentTheme,
                        format: _selectedFormat,
                        width: cardWidth,
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
                      child: ChoiceChip(
                        avatar: Icon(
                          fmt.icon,
                          size: 14,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        label: Text(copy.formatName(fmt)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            unawaited(HapticFeedback.selectionClick());
                            setState(() => _selectedFormat = fmt);
                          }
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.18),
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                        ),
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

          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: SocialShareThemeType.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final themeType = SocialShareThemeType.values[index];
                final isSelected = themeType == _selectedThemeType;
                final themeObj = SocialShareTheme.get(themeType);

                return _ThemePreviewTile(
                  theme: themeObj,
                  displayName: copy.themeName(themeType),
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    setState(() => _selectedThemeType = themeType);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.md),

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
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
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
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
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

/// Rich theme preview tile widget showing mini gradient + accent border
class _ThemePreviewTile extends StatelessWidget {
  final SocialShareTheme theme;
  final String displayName;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemePreviewTile({
    required this.theme,
    required this.displayName,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.backgroundGradient,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.accentColor
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.accentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.accentColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              displayName,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
