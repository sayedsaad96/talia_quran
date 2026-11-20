import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/home_widget/home_widget_pin.dart';
import '../../../../core/home_widget/home_widget_publisher.dart';
import '../../../../core/home_widget/widget_preview_palette.dart';
import '../../../../core/home_widget/widget_section_preferences.dart';
import '../../../../core/home_widget/widget_snapshot.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/locale_number_formatter.dart';
import 'settings_switch_tile.dart';

enum _PreviewSize { small, medium, large }

/// Pin request, installed status, live size-aware preview, and section
/// toggles for the Android home-screen widget.
class HomeWidgetOptions extends StatefulWidget {
  const HomeWidgetOptions({
    super.key,
    this.pin,
    this.sections,
    this.previewSnapshot,
  });

  final HomeWidgetPin? pin;
  final WidgetSectionPreferences? sections;
  final WidgetSnapshot? previewSnapshot;

  @override
  State<HomeWidgetOptions> createState() => _HomeWidgetOptionsState();
}

class _HomeWidgetOptionsState extends State<HomeWidgetOptions>
    with WidgetsBindingObserver {
  bool? _pinSupported;
  var _installedCount = 0;
  var _busy = false;
  var _previewSize = _PreviewSize.medium;

  HomeWidgetPin get _pin => widget.pin ?? HomeWidgetPin();

  /// The pin sheet and the manual steps are Android launcher behavior.
  /// A test can still show them by passing [HomeWidgetOptions.pin].
  bool get _visible => widget.pin != null || (!kIsWeb && Platform.isAndroid);

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
    WidgetsBinding.instance.addObserver(this);
    if (_visible) unawaited(_loadLauncherState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _visible) {
      unawaited(_loadLauncherState());
    }
  }

  Future<void> _loadLauncherState() async {
    final results = await Future.wait<Object>([
      _pin.isSupported(),
      _pin.installedCount(),
    ]);
    if (!mounted) return;
    setState(() {
      _pinSupported = results[0] as bool;
      _installedCount = results[1] as int;
    });
  }

  Future<void> _pinWidget() async {
    if (_busy) return;
    setState(() => _busy = true);
    if (getIt.isRegistered<HomeWidgetPublisher>()) {
      try {
        await getIt<HomeWidgetPublisher>().refresh();
      } catch (_) {
        // Proceed: MainActivity also ensures the receiver is enabled.
      }
    }
    final accepted = await _pin.requestPin();
    if (!mounted) return;
    if (accepted) {
      final count = await _pin.installedCount();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _installedCount = count;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.settingsHomeWidgetPinRequested),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final stillSupported = await _pin.isSupported();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pinSupported = stillSupported;
    });
  }

  Future<void> _toggleSection(
    WidgetSectionPreferences sections, {
    required bool currentValue,
    required bool nextValue,
    required Future<void> Function(bool) write,
  }) async {
    if (currentValue && !nextValue && sections.visibleCount <= 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.settingsHomeWidgetMinOneSection),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await write(nextValue);
    if (!mounted) return;
    setState(() {});
    if (!getIt.isRegistered<HomeWidgetPublisher>()) return;
    try {
      await getIt<HomeWidgetPublisher>().refresh();
    } catch (_) {
      // The next resume republishes the same choices.
    }
  }

  Widget _buildPreview(WidgetSectionPreferences? sections) {
    final showPrayer = sections?.showPrayer ?? true;
    final showReviews = sections?.showReviews ?? true;
    final showWird = sections?.showWird ?? true;
    final showHijri = sections?.showHijri ?? true;
    final override = widget.previewSnapshot;
    if (override != null || !getIt.isRegistered<HomeWidgetPublisher>()) {
      return _WidgetPreview(
        size: _previewSize,
        snapshot: override,
        showPrayer: showPrayer,
        showReviews: showReviews,
        showWird: showWird,
        showHijri: showHijri,
        onSizeChanged: (next) => setState(() => _previewSize = next),
      );
    }
    return ValueListenableBuilder<WidgetSnapshot?>(
      valueListenable: getIt<HomeWidgetPublisher>().latestSnapshot,
      builder: (context, snapshot, _) => _WidgetPreview(
        size: _previewSize,
        snapshot: snapshot,
        showPrayer: showPrayer,
        showReviews: showReviews,
        showWird: showWird,
        showHijri: showHijri,
        onSizeChanged: (next) => setState(() => _previewSize = next),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final l10n = context.l10n;
    final sections = _sections;
    final supported = _pinSupported;
    final installed = _installedCount > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (installed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.tokens.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    TaliaIcon(
                      TaliaIcons.checkCircle,
                      size: 18,
                      color: context.tokens.accent,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.settingsHomeWidgetInstalled,
                        style: AppTypography.bodySmall.copyWith(
                          color: context.tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (supported != false)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: installed
                ? OutlinedButton.icon(
                    onPressed: supported == true && !_busy ? _pinWidget : null,
                    icon: const TaliaIcon(TaliaIcons.add, size: 18),
                    label: Text(l10n.settingsHomeWidgetAddAnother),
                  )
                : FilledButton.icon(
                    onPressed: supported == true && !_busy ? _pinWidget : null,
                    icon: const TaliaIcon(TaliaIcons.add, size: 18),
                    label: Text(l10n.settingsHomeWidgetAdd),
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
          child: _buildPreview(sections),
        ),
        if (sections != null) ...[
          SettingsSwitchTile(
            icon: TaliaIcons.prayer,
            title: l10n.settingsHomeWidgetShowPrayer,
            value: sections.showPrayer,
            onChanged: (value) => _toggleSection(
              sections,
              currentValue: sections.showPrayer,
              nextValue: value,
              write: sections.setShowPrayer,
            ),
          ),
          SettingsSwitchTile(
            icon: TaliaIcons.hifz,
            title: l10n.settingsHomeWidgetShowReviews,
            value: sections.showReviews,
            onChanged: (value) => _toggleSection(
              sections,
              currentValue: sections.showReviews,
              nextValue: value,
              write: sections.setShowReviews,
            ),
          ),
          SettingsSwitchTile(
            icon: TaliaIcons.mushaf,
            title: l10n.settingsHomeWidgetShowWird,
            value: sections.showWird,
            onChanged: (value) => _toggleSection(
              sections,
              currentValue: sections.showWird,
              nextValue: value,
              write: sections.setShowWird,
            ),
          ),
          SettingsSwitchTile(
            icon: TaliaIcons.calendar,
            title: l10n.settingsHomeWidgetShowHijri,
            value: sections.showHijri,
            onChanged: (value) => _toggleSection(
              sections,
              currentValue: sections.showHijri,
              nextValue: value,
              write: sections.setShowHijri,
            ),
          ),
        ],
      ],
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({
    required this.size,
    required this.snapshot,
    required this.showPrayer,
    required this.showReviews,
    required this.showWird,
    required this.showHijri,
    required this.onSizeChanged,
  });

  final _PreviewSize size;
  final WidgetSnapshot? snapshot;
  final bool showPrayer;
  final bool showReviews;
  final bool showWird;
  final bool showHijri;
  final ValueChanged<_PreviewSize> onSizeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = context.isArabic;
    final palette = HomeWidgetPreviewPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final live = snapshot != null && !snapshot!.clearsNative;
    final model = _PreviewContent.resolve(
      l10n: l10n,
      isArabic: isArabic,
      snapshot: live ? snapshot : null,
      showPrayer: showPrayer,
      showReviews: showReviews,
      showWird: showWird,
      showHijri: showHijri,
      size: size,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.settingsHomeWidgetPreviewCaption,
                style: AppTypography.labelSmall.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.tokens.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  live
                      ? l10n.settingsHomeWidgetPreviewLiveBadge
                      : l10n.settingsHomeWidgetPreviewSampleBadge,
                  style: AppTypography.labelSmall.copyWith(
                    color: context.tokens.accent,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<_PreviewSize>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: _PreviewSize.small,
              label: Text(l10n.settingsHomeWidgetSizeSmall),
            ),
            ButtonSegment(
              value: _PreviewSize.medium,
              label: Text(l10n.settingsHomeWidgetSizeMedium),
            ),
            ButtonSegment(
              value: _PreviewSize.large,
              label: Text(l10n.settingsHomeWidgetSizeLarge),
            ),
          ],
          selected: {size},
          onSelectionChanged: (selection) => onSizeChanged(selection.single),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(
              HomeWidgetPreviewPalette.radius,
            ),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: model.isEmpty
                ? Text(
                    l10n.settingsHomeWidgetPreviewEmpty,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: palette.secondary,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (model.hijri != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            model.hijri!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: palette.secondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if (model.prayer != null)
                        _PreviewIconRow(
                          icon: TaliaIcons.prayer,
                          iconSize: 16,
                          color: palette.progress,
                          child: Text(
                            model.prayer!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (model.review != null) ...[
                        if (model.prayer != null) const SizedBox(height: 6),
                        _PreviewIconRow(
                          icon: TaliaIcons.hifz,
                          iconSize: 14,
                          color: palette.progress,
                          child: Text(
                            model.review!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: palette.secondary,
                            ),
                          ),
                        ),
                      ],
                      if (model.wird != null) ...[
                        if (model.prayer != null || model.review != null)
                          const SizedBox(height: 6),
                        _PreviewIconRow(
                          icon: TaliaIcons.mushaf,
                          iconSize: 14,
                          color: palette.progress,
                          child: Text(
                            model.wird!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: palette.secondary,
                            ),
                          ),
                        ),
                      ],
                      if (model.wirdRange != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          model.wirdRange!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: palette.secondary,
                          ),
                        ),
                      ],
                      if (model.wirdProgress != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: model.wirdProgress,
                            minHeight: 7,
                            backgroundColor: palette.progressTrack,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              palette.progress,
                            ),
                          ),
                        ),
                      ],
                      if (model.showWirdAction) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: palette.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              child: Text(
                                l10n.settingsHomeWidgetPreviewWirdAction,
                                style: AppTypography.labelSmall.copyWith(
                                  color: palette.background,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
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

class _PreviewIconRow extends StatelessWidget {
  const _PreviewIconRow({
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final double iconSize;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TaliaIcon(icon, size: iconSize, color: color),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

final class _PreviewContent {
  const _PreviewContent({
    this.hijri,
    this.prayer,
    this.review,
    this.wird,
    this.wirdRange,
    this.wirdProgress,
    this.showWirdAction = false,
  });

  final String? hijri;
  final String? prayer;
  final String? review;
  final String? wird;
  final String? wirdRange;
  final double? wirdProgress;
  final bool showWirdAction;

  bool get isEmpty =>
      hijri == null && prayer == null && review == null && wird == null;

  static _PreviewContent resolve({
    required AppLocalizations l10n,
    required bool isArabic,
    required WidgetSnapshot? snapshot,
    required bool showPrayer,
    required bool showReviews,
    required bool showWird,
    required bool showHijri,
    required _PreviewSize size,
  }) {
    final full = snapshot == null
        ? _sample(
            l10n: l10n,
            showPrayer: showPrayer,
            showReviews: showReviews,
            showWird: showWird,
            showHijri: showHijri,
          )
        : _fromSnapshot(
            l10n: l10n,
            isArabic: isArabic,
            snapshot: snapshot,
            showPrayer: showPrayer,
            showReviews: showReviews,
            showWird: showWird,
            showHijri: showHijri,
          );

    return switch (size) {
      _PreviewSize.small => _applySmall(full),
      _PreviewSize.medium => _PreviewContent(
        hijri: full.hijri,
        prayer: full.prayer,
        review: full.review,
        wird: full.wird,
      ),
      _PreviewSize.large => full,
    };
  }

  static _PreviewContent _applySmall(_PreviewContent full) {
    final prayer = full.prayer;
    final review = prayer == null ? full.review : null;
    final wird = prayer == null && review == null ? full.wird : null;
    final hijri = prayer == null && review == null && wird == null
        ? full.hijri
        : null;
    return _PreviewContent(
      hijri: hijri,
      prayer: prayer,
      review: review,
      wird: wird,
    );
  }

  static _PreviewContent _sample({
    required AppLocalizations l10n,
    required bool showPrayer,
    required bool showReviews,
    required bool showWird,
    required bool showHijri,
  }) {
    return _PreviewContent(
      hijri: showHijri ? l10n.settingsHomeWidgetPreviewHijri : null,
      prayer: showPrayer ? l10n.settingsHomeWidgetPreviewPrayer : null,
      review: showReviews ? l10n.settingsHomeWidgetPreviewReview : null,
      wird: showWird ? l10n.settingsHomeWidgetPreviewWird : null,
      wirdRange: showWird ? l10n.settingsHomeWidgetPreviewWirdRange : null,
      wirdProgress: showWird ? 1 / 3 : null,
      showWirdAction: showWird,
    );
  }

  static _PreviewContent _fromSnapshot({
    required AppLocalizations l10n,
    required bool isArabic,
    required WidgetSnapshot snapshot,
    required bool showPrayer,
    required bool showReviews,
    required bool showWird,
    required bool showHijri,
  }) {
    final locale = isArabic ? 'ar' : 'en';
    String numText(int value) => LocaleNumberFormatter.number(value, locale);

    final hijri = showHijri && snapshot.hijriLabel != null
        ? snapshot.hijriLabel
        : null;

    String? prayer;
    if (showPrayer) {
      final key = snapshot.nextPrayerKey;
      final at = snapshot.nextPrayerAt;
      if (key != null && at != null) {
        final name = _prayerName(l10n, key);
        if (name != null) {
          prayer = '$name · ${_formatTime12(at, isArabic: isArabic)}';
        }
      } else if (snapshot.prayerUnset) {
        prayer = l10n.settingsHomeWidgetLivePrayerUnset;
      }
    }

    String? review;
    if (showReviews) {
      if (snapshot.dueReviewCount > 0) {
        review = l10n.settingsHomeWidgetLiveReviewsDue(
          snapshot.dueReviewCount,
          numText(snapshot.dueReviewCount),
        );
      } else if (snapshot.reviewsSettled) {
        review = l10n.settingsHomeWidgetPreviewReview;
      }
    }

    String? wird;
    String? wirdRange;
    double? wirdProgress;
    var showWirdAction = false;
    if (showWird) {
      final from = snapshot.wirdFromPage;
      final to = snapshot.wirdToPage;
      final done = snapshot.wirdDonePages;
      final surahName = _surahDisplayName(snapshot, isArabic: isArabic);
      if (from != null &&
          to != null &&
          done != null &&
          surahName != null &&
          from >= 1 &&
          to >= from &&
          to <= 604) {
        final total = to - from + 1;
        final clampedDone = done.clamp(0, total);
        wird = l10n.settingsHomeWidgetLiveWird(
          surahName,
          numText(clampedDone),
          numText(total),
        );
        wirdRange = l10n.settingsHomeWidgetLiveWirdRange(
          numText(from),
          numText(to),
        );
        wirdProgress = clampedDone / total;
        showWirdAction = clampedDone < total;
      } else if (snapshot.noKhatmahPlan) {
        wird = l10n.settingsHomeWidgetLiveNoKhatmah;
      }
    }

    return _PreviewContent(
      hijri: hijri,
      prayer: prayer,
      review: review,
      wird: wird,
      wirdRange: wirdRange,
      wirdProgress: wirdProgress,
      showWirdAction: showWirdAction,
    );
  }

  static String? _prayerName(AppLocalizations l10n, String key) =>
      switch (key) {
        'fajr' => l10n.prayerFajr,
        'dhuhr' => l10n.prayerDhuhr,
        'asr' => l10n.prayerAsr,
        'maghrib' => l10n.prayerMaghrib,
        'isha' => l10n.prayerIsha,
        _ => null,
      };

  static String? _surahDisplayName(
    WidgetSnapshot snapshot, {
    required bool isArabic,
  }) {
    final number = snapshot.wirdSurahNumber;
    if (number != null && number >= 1 && number <= 114) {
      return isArabic ? SurahNames.nameAr(number) : SurahNames.nameEn(number);
    }
    return snapshot.wirdSurahName;
  }

  static String _formatTime12(DateTime time, {required bool isArabic}) {
    final local = time.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = isArabic
        ? (local.hour >= 12 ? 'م' : 'ص')
        : (local.hour >= 12 ? 'PM' : 'AM');
    final text = '$hour12:$minute $period';
    return isArabic ? LocaleNumberFormatter.format(text, 'ar') : text;
  }
}
