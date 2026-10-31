import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/home_widget/home_widget_pin.dart';
import '../../../../core/home_widget/home_widget_publisher.dart';
import '../../../../core/home_widget/widget_section_preferences.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_typography.dart';
import 'settings_switch_tile.dart';

/// Pin request, and — when the launcher cannot pin — a preview plus the
/// manual steps. Section switches are device display choices.
class HomeWidgetOptions extends StatefulWidget {
  const HomeWidgetOptions({super.key, this.pin, this.sections});

  final HomeWidgetPin? pin;
  final WidgetSectionPreferences? sections;

  @override
  State<HomeWidgetOptions> createState() => _HomeWidgetOptionsState();
}

class _HomeWidgetOptionsState extends State<HomeWidgetOptions> {
  bool? _pinSupported;
  var _busy = false;

  HomeWidgetPin get _pin => widget.pin ?? HomeWidgetPin();

  /// The pin sheet and the manual steps are Android launcher behavior.
  /// A test can still show them by passing [HomeWidgetOptions.pin].
  bool get _visible =>
      widget.pin != null || (!kIsWeb && Platform.isAndroid);

  WidgetSectionPreferences? get _sections {
    final provided = widget.sections;
    if (provided != null) return provided;
    if (getIt.isRegistered<SharedPreferences>()) {
      return WidgetSectionPreferences(getIt<SharedPreferences>());
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (_visible) unawaited(_loadPinSupport());
  }

  Future<void> _loadPinSupport() async {
    final supported = await _pin.isSupported();
    if (!mounted) return;
    setState(() => _pinSupported = supported);
  }

  Future<void> _pinWidget() async {
    if (_busy) return;
    setState(() => _busy = true);
    final accepted = await _pin.requestPin();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!accepted) _pinSupported = false;
    });
  }

  Future<void> _setSection(Future<void> Function() write) async {
    await write();
    if (!mounted) return;
    setState(() {});
    if (!getIt.isRegistered<HomeWidgetPublisher>()) return;
    try {
      await getIt<HomeWidgetPublisher>().refresh();
    } catch (_) {
      // The next resume republishes the same choices.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final l10n = context.l10n;
    final sections = _sections;
    final supported = _pinSupported;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (supported != false)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: FilledButton(
              onPressed: supported == true && !_busy ? _pinWidget : null,
              child: Text(l10n.settingsHomeWidgetAdd),
            ),
          ),
        if (supported == false) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.settingsHomeWidgetUnsupported,
              style: AppTypography.bodySmall.copyWith(
                color: context.tokens.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(
              l10n.settingsHomeWidgetManualSteps,
              style: AppTypography.bodySmall.copyWith(
                color: context.tokens.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _WidgetPreview(
            showPrayer: sections?.showPrayer ?? true,
            showReviews: sections?.showReviews ?? true,
            showWird: sections?.showWird ?? true,
          ),
        ),
        if (sections != null) ...[
          SettingsSwitchTile(
            icon: TaliaIcons.prayer,
            title: l10n.settingsHomeWidgetShowPrayer,
            value: sections.showPrayer,
            onChanged: (value) =>
                _setSection(() => sections.setShowPrayer(value)),
          ),
          SettingsSwitchTile(
            icon: TaliaIcons.hifz,
            title: l10n.settingsHomeWidgetShowReviews,
            value: sections.showReviews,
            onChanged: (value) =>
                _setSection(() => sections.setShowReviews(value)),
          ),
          SettingsSwitchTile(
            icon: TaliaIcons.mushaf,
            title: l10n.settingsHomeWidgetShowWird,
            value: sections.showWird,
            onChanged: (value) => _setSection(() => sections.setShowWird(value)),
          ),
        ],
      ],
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({
    required this.showPrayer,
    required this.showReviews,
    required this.showWird,
  });

  final bool showPrayer;
  final bool showReviews;
  final bool showWird;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = context.isDark;
    final background = dark ? const Color(0xFF15211C) : const Color(0xFFFCF8F2);
    final primary = dark ? const Color(0xFFE6F3ED) : const Color(0xFF173B32);
    final secondary = dark ? const Color(0xFFB7D0C6) : const Color(0xFF355C50);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.settingsHomeWidgetPreviewCaption,
          style: AppTypography.labelSmall.copyWith(
            color: context.tokens.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showPrayer)
                  Text(
                    l10n.settingsHomeWidgetPreviewPrayer,
                    style: AppTypography.titleSmall.copyWith(color: primary),
                  ),
                if (showReviews) ...[
                  if (showPrayer) const SizedBox(height: 6),
                  Text(
                    l10n.settingsHomeWidgetPreviewReview,
                    style: AppTypography.bodySmall.copyWith(color: secondary),
                  ),
                ],
                if (showWird) ...[
                  if (showPrayer || showReviews) const SizedBox(height: 6),
                  Text(
                    l10n.settingsHomeWidgetPreviewWird,
                    style: AppTypography.bodySmall.copyWith(color: secondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
