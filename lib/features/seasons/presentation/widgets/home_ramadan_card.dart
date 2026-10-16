import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/experience/experience_feature_flags.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/seasons/season_calendar.dart';
import '../../../../core/services/hijri_date_adjustment.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/locale_number_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../home/presentation/theme/home_skin.dart';
import '../../../home/presentation/widgets/glass_panel.dart';
import '../../../khatmah/domain/repositories/khatmah_repository.dart';
import '../../data/ramadan_card_dismiss_store.dart';
import '../../data/tarawih_log_store.dart';
import 'tarawih_log_sheet.dart';

/// Ramadan card on the home page, by phase. Renders nothing unless the
/// seasonal-Ramadan flag is on and the phase has something to show. Every
/// dependency is injectable for tests; defaults come from get_it.
class HomeRamadanCard extends StatefulWidget {
  const HomeRamadanCard({
    super.key,
    required this.skin,
    this.now,
    this.info,
    this.dismissStore,
    this.tarawihStore,
    this.loadKhatmahCompletions,
    this.hasActiveKhatmah,
  });

  final HomeSkin skin;
  final DateTime Function()? now;

  /// Overrides the phase computed from [now] and the Hijri adjustment.
  final RamadanInfo? info;
  final RamadanCardDismissStore? dismissStore;
  final TarawihLogStore? tarawihStore;

  /// Completion dates of finished khatmahs.
  final Future<List<DateTime>> Function()? loadKhatmahCompletions;
  final Future<bool> Function()? hasActiveKhatmah;

  @override
  State<HomeRamadanCard> createState() => _HomeRamadanCardState();
}

class _HomeRamadanCardState extends State<HomeRamadanCard> {
  RamadanInfo? _info;
  int _year = 0;
  bool _dismissed = false;
  bool _activeKhatmah = false;
  int _nights = 0;
  int _pages = 0;
  int _khatmahs = 0;
  bool _summaryLoaded = false;

  static bool get _flagOn =>
      getIt.isRegistered<ExperienceFlags>() &&
      getIt<ExperienceFlags>().isEnabled(ExperienceFeature.seasonalRamadan);

  RamadanCardDismissStore? get _dismissStore =>
      widget.dismissStore ??
      (getIt.isRegistered<SharedPreferences>() &&
              getIt.isRegistered<RecordOwnerProvider>()
          ? RamadanCardDismissStore(
              getIt<SharedPreferences>(),
              getIt<RecordOwnerProvider>(),
            )
          : null);

  TarawihLogStore? get _tarawih =>
      widget.tarawihStore ??
      (getIt.isRegistered<TarawihLogStore>() ? getIt<TarawihLogStore>() : null);

  @override
  void initState() {
    super.initState();
    if (!_flagOn) return;
    final adjustment = getIt.isRegistered<HijriDateAdjustment>()
        ? getIt<HijriDateAdjustment>().days
        : 0;
    final now = (widget.now ?? DateTime.now)();
    final info = widget.info ?? ramadanInfoAt(now, adjustmentDays: adjustment);
    if (info.phase == RamadanPhase.none) return;
    _info = info;
    final first = info.firstDay;
    _year = first == null
        ? 0
        : HijriCalendar.fromDate(
            DateTime(first.year, first.month, first.day + adjustment),
          ).hYear;
    _dismissed = _dismissStore?.isDismissed(info.phase, _year) ?? false;
    if (_dismissed) return;
    if (info.phase == RamadanPhase.afterEid) {
      unawaited(_loadSummary(info));
    } else if (info.phase != RamadanPhase.invite) {
      unawaited(_loadActive());
    }
  }

  Future<void> _loadActive() async {
    try {
      final check =
          widget.hasActiveKhatmah ??
          (getIt.isRegistered<KhatmahRepository>()
              ? () async =>
                    (await getIt<KhatmahRepository>().getActivePlan()) != null
              : null);
      if (check == null) return;
      final active = await check();
      if (mounted) setState(() => _activeKhatmah = active);
    } catch (_) {
      // Falls back to the setup route.
    }
  }

  Future<void> _loadSummary(RamadanInfo info) async {
    var nights = 0;
    var pages = 0;
    var khatmahs = 0;
    final first = info.firstDay;
    final last = info.lastDay;
    try {
      final store = _tarawih;
      if (store != null && first != null && last != null) {
        final lo = tarawihNightKey(first);
        final hi = tarawihNightKey(last);
        final inRange = (await store.entries())
            .where(
              (e) =>
                  e.nightKey.compareTo(lo) >= 0 &&
                  e.nightKey.compareTo(hi) <= 0,
            )
            .toList();
        nights = inRange.length;
        pages = store.totalPagesHeard(inRange);
      }
    } catch (_) {
      // Summary simply omits the tarawih lines.
    }
    try {
      final loader =
          widget.loadKhatmahCompletions ??
          (getIt.isRegistered<KhatmahRepository>()
              ? () async => [
                  for (final h in await getIt<KhatmahRepository>().getHistory())
                    h.completedDate,
                ]
              : null);
      if (loader != null && first != null && last != null) {
        final lo = DateTime(first.year, first.month, first.day);
        final hi = DateTime(last.year, last.month, last.day + 1);
        khatmahs = (await loader())
            .map((d) => d.toLocal())
            .where((d) => !d.isBefore(lo) && d.isBefore(hi))
            .length;
      }
    } catch (_) {
      // Summary simply omits the khatmah line.
    }
    if (!mounted) return;
    setState(() {
      _nights = nights;
      _pages = pages;
      _khatmahs = khatmahs;
      _summaryLoaded = true;
    });
  }

  Future<void> _dismiss() async {
    final info = _info;
    if (info == null) return;
    setState(() => _dismissed = true);
    await _dismissStore?.dismiss(info.phase, _year);
  }

  void _openKhatmah() {
    unawaited(
      context.push(
        _activeKhatmah ? AppRoutes.khatmahDashboard : AppRoutes.khatmahSetup,
      ),
    );
  }

  void _logTarawih() {
    final store = _tarawih;
    if (store == null) return;
    unawaited(showTarawihLogSheet(context, store, now: widget.now));
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    if (info == null || _dismissed) return const SizedBox.shrink();
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final skin = widget.skin;

    final String title;
    String? body;
    final actions = <Widget>[];
    switch (info.phase) {
      case RamadanPhase.invite:
        title = l10n.ramadanInviteTitle;
        body = l10n.ramadanInviteBody;
        actions.add(_button(l10n.ramadanOpenKhatmah, _openKhatmah, 'khatmah'));
      case RamadanPhase.ramadan:
      case RamadanPhase.lastTen:
        title = l10n.ramadanDayTitle(
          LocaleNumberFormatter.number(info.day ?? 0, lang),
        );
        if (info.phase == RamadanPhase.lastTen) body = l10n.ramadanLastTen;
        actions
          ..add(_button(l10n.ramadanOpenKhatmah, _openKhatmah, 'khatmah'))
          ..add(const SizedBox(width: AppSpacing.xs))
          ..add(_button(l10n.ramadanLogTarawih, _logTarawih, 'tarawih'));
      case RamadanPhase.afterEid:
        if (!_summaryLoaded) return const SizedBox.shrink();
        title = l10n.ramadanSummaryTitle;
        body = [
          l10n.ramadanSummaryNights(
            _nights,
            LocaleNumberFormatter.number(_nights, lang),
          ),
          if (_pages > 0)
            l10n.tarawihTotal(
              _pages,
              LocaleNumberFormatter.number(_pages, lang),
            ),
          if (_khatmahs > 0)
            l10n.ramadanSummaryKhatmah(
              _khatmahs,
              LocaleNumberFormatter.number(_khatmahs, lang),
            ),
        ].join('\n');
      case RamadanPhase.none:
        return const SizedBox.shrink();
    }

    return Padding(
      key: const ValueKey('home_ramadan_card'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        0,
      ),
      child: GlassPanel(
        skin: skin,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(TaliaIcons.reading, size: 24, color: skin.gold),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: skin.textOnHero,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                style: AppTypography.bodySmall.copyWith(
                  color: skin.textOnHeroMuted,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                ...actions,
                const Spacer(),
                TextButton(
                  key: const ValueKey('home_ramadan_dismiss'),
                  onPressed: () => unawaited(_dismiss()),
                  child: Text(
                    l10n.ramadanDismiss,
                    style: AppTypography.labelSmall.copyWith(
                      color: skin.textOnHeroMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(String label, VoidCallback onPressed, String id) => Flexible(
    child: AppButton(
      key: ValueKey('home_ramadan_$id'),
      label: label,
      size: AppButtonSize.small,
      variant: AppButtonVariant.goldPrimary,
      onPressed: onPressed,
    ),
  );
}
