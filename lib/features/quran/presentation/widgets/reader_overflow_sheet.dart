import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/services/quran_reciter.dart';
import '../../../../core/services/quran_reciter_service.dart';
import '../../../../core/theme/app_typography.dart';
import 'reciter_selector_sheet.dart';

/// Overflow sheet for the adult reader's secondary actions (presentation).
///
/// Keeps the top bar minimal: page navigation, reciter selection, tajweed
/// colouring and focus mode live here. Reading/audio state stays in the
/// existing cubits and services.
class ReaderOverflowSheet extends StatefulWidget {
  const ReaderOverflowSheet({
    super.key,
    required this.onEnterFocus,
    required this.onOpenNavigation,
    required this.tajweedEnabled,
    required this.onTajweedChanged,
    this.strengthOverlayEnabled,
    this.onStrengthOverlayChanged,
    this.onDownload,
  });

  final VoidCallback onEnterFocus;

  /// Opens the go-to page / surah / juz sheet (N14).
  final VoidCallback onOpenNavigation;

  /// Whether the Mushaf page is drawn with tajweed colours (N13).
  final bool tajweedEnabled;
  final ValueChanged<bool> onTajweedChanged;

  /// Memorization-strength overlay switch; shown only when both are non-null.
  final bool? strengthOverlayEnabled;
  final ValueChanged<bool>? onStrengthOverlayChanged;
  final VoidCallback? onDownload;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onEnterFocus,
    required VoidCallback onOpenNavigation,
    required bool tajweedEnabled,
    required ValueChanged<bool> onTajweedChanged,
    bool? strengthOverlayEnabled,
    ValueChanged<bool>? onStrengthOverlayChanged,
    VoidCallback? onDownload,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: SingleChildScrollView(
          child: ReaderOverflowSheet(
            onEnterFocus: onEnterFocus,
            onOpenNavigation: onOpenNavigation,
            tajweedEnabled: tajweedEnabled,
            onTajweedChanged: onTajweedChanged,
            strengthOverlayEnabled: strengthOverlayEnabled,
            onStrengthOverlayChanged: onStrengthOverlayChanged,
            onDownload: onDownload,
          ),
        ),
      ),
    );
  }

  @override
  State<ReaderOverflowSheet> createState() => _ReaderOverflowSheetState();
}

class _ReaderOverflowSheetState extends State<ReaderOverflowSheet> {
  late bool _tajweed = widget.tajweedEnabled;
  late bool _strength = widget.strengthOverlayEnabled ?? false;

  Widget _leadingIcon(IconData icon, Color primary) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: primary.withValues(alpha: 0.1),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: primary, size: 22),
  );

  Widget _actionTile({
    Key? key,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final primary = context.tokens.accent;
    return ListTile(
      key: key,
      leading: _leadingIcon(icon, primary),
      title: Text(
        title,
        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
      trailing: Icon(context.forwardChevron, size: 18, color: primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.tokens.surface;
    final primary = context.tokens.accent;
    final reciterService = getIt<QuranReciterService>();

    return Material(
      color: surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
              ),
              _actionTile(
                key: const Key('reader-open-navigation'),
                icon: TaliaIcons.mushaf,
                title: context.l10n.readerGoToPage,
                onTap: widget.onOpenNavigation,
              ),
              ValueListenableBuilder<QuranReciter>(
                valueListenable: reciterService.currentReciter,
                builder: (context, reciter, _) => _actionTile(
                  icon: TaliaIcons.recite,
                  title: context.l10n.selectReciter,
                  subtitle: context.isArabic ? reciter.nameAr : reciter.nameEn,
                  onTap: () => ReciterSelectorSheet.show(context),
                ),
              ),
              if (widget.onDownload != null)
                _actionTile(
                  icon: TaliaIcons.download,
                  title: context.l10n.audioDownloadsTitle,
                  onTap: widget.onDownload!,
                ),
              SwitchListTile(
                key: const Key('reader-tajweed-toggle'),
                secondary: _leadingIcon(TaliaIcons.palette, primary),
                title: Text(
                  context.l10n.readerTajweedColors,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  context.l10n.readerTajweedColorsHint,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                value: _tajweed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _tajweed = value);
                  widget.onTajweedChanged(value);
                },
              ),
              if (widget.strengthOverlayEnabled != null &&
                  widget.onStrengthOverlayChanged != null)
                SwitchListTile(
                  key: const Key('reader-strength-toggle'),
                  secondary: _leadingIcon(TaliaIcons.palette, primary),
                  title: Text(
                    context.l10n.strengthOverlayToggle,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  value: _strength,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _strength = value);
                    widget.onStrengthOverlayChanged!(value);
                  },
                ),
              _actionTile(
                icon: TaliaIcons.fullscreen,
                title: context.l10n.enterFocusMode,
                onTap: widget.onEnterFocus,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
