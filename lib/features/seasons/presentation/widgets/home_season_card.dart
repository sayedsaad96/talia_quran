import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/experience/experience_feature_flags.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/seasons/season_calendar.dart';
import '../../../../core/seasons/season_preferences.dart';
import '../../../../core/services/hijri_date_adjustment.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/locale_number_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../../home/presentation/theme/home_skin.dart';
import '../../../home/presentation/widgets/glass_panel.dart';
import '../../../khatmah/domain/entities/khatmah_scheduling_engine.dart';
import '../../../khatmah/domain/repositories/khatmah_repository.dart';
import '../../../khatmah/presentation/khatmah_setup_prefill.dart';
import '../../data/friday_kahf_read_store.dart';
import '../../data/season_badge_store.dart';
import '../../data/season_card_dismiss_store.dart';
import '../../data/season_dua_loader.dart';
import '../../data/season_flag_store.dart';
import '../../data/shawwal_six_store.dart';
import '../../data/tarawih_log_store.dart';
import '../../domain/season_card_selection.dart';
import '../../domain/season_windows.dart';
import 'season_approved_line.dart';
import 'shawwal_log_sheet.dart';
import 'tarawih_log_sheet.dart';

/// The home card of the single highest-priority non-Ramadan season that is
/// visible today (Ramadan has its own card). Renders nothing when no season
/// applies, when the user hid it, or on a child profile (the caller mounts it
/// for adults only). Every dependency is injectable for tests; defaults come
/// from get_it.
class HomeSeasonCard extends StatefulWidget {
  const HomeSeasonCard({
    super.key,
    required this.skin,
    this.now,
    this.adjustmentDays,
    this.seasonPrefs,
    this.flags,
    this.tarawihStore,
    this.loadKhatmahCompletions,
    this.lineLoader,
    this.openRoute,
    this.onSeasonChanged,
    this.ignoreRolloutFlag = false,
  });

  final HomeSkin skin;
  final DateTime Function()? now;

  /// Overrides the Hijri adjustment (days) read from get_it.
  final int? adjustmentDays;
  final SeasonPreferences? seasonPrefs;
  final SeasonFlagStore? flags;
  final TarawihLogStore? tarawihStore;

  /// Completion dates of finished khatmahs.
  final Future<List<DateTime>> Function()? loadKhatmahCompletions;

  /// Replaces the azkar-datasource-backed line loader.
  final SeasonLineLoader? lineLoader;

  /// Replaces `context.push(route, extra: extra)`.
  final void Function(String route, {Object? extra})? openRoute;

  /// Runs after «إخفاء هذا الموسم» or its undo; defaults to rescheduling
  /// notifications.
  final void Function(BuildContext context)? onSeasonChanged;

  /// Tests that do not register [ExperienceFlags].
  final bool ignoreRolloutFlag;

  @override
  State<HomeSeasonCard> createState() => _HomeSeasonCardState();
}

class _HomeSeasonCardState extends State<HomeSeasonCard> {
  ActiveSeason? _season;
  late DateTime _today;
  int _adjustment = 0;
  bool _dismissed = false;
  bool _hidden = false;

  // Eid al-Fitr stats.
  int _nights = 0;
  int _pages = 0;
  int _khatmahs = 0;
  bool _statsLoaded = false;

  // Shawwal tracker.
  int _shawwalCount = 0;
  bool _shawwalToday = false;

  // Friday.
  bool _fridayRead = false;

  bool get _flagOn =>
      widget.ignoreRolloutFlag ||
      (getIt.isRegistered<ExperienceFlags>() &&
          getIt<ExperienceFlags>().isEnabled(
            ExperienceFeature.seasonalRamadan,
          ));

  SeasonPreferences? get _seasonPrefs =>
      widget.seasonPrefs ??
      (getIt.isRegistered<SeasonPreferences>()
          ? getIt<SeasonPreferences>()
          : null);

  SeasonFlagStore? get _flags =>
      widget.flags ??
      (getIt.isRegistered<SeasonFlagStore>()
          ? getIt<SeasonFlagStore>()
          : (getIt.isRegistered<SharedPreferences>() &&
                    getIt.isRegistered<RecordOwnerProvider>()
                ? SeasonFlagStore(
                    getIt<SharedPreferences>(),
                    getIt<RecordOwnerProvider>(),
                  )
                : null));

  TarawihLogStore? get _tarawih =>
      widget.tarawihStore ??
      (getIt.isRegistered<TarawihLogStore>() ? getIt<TarawihLogStore>() : null);

  @override
  void initState() {
    super.initState();
    final now = (widget.now ?? DateTime.now)();
    _today = DateTime(now.year, now.month, now.day);
    if (!_flagOn) return;
    _adjustment =
        widget.adjustmentDays ??
        (getIt.isRegistered<HijriDateAdjustment>()
            ? getIt<HijriDateAdjustment>().days
            : 0);
    final prefs = _seasonPrefs;
    final season = selectSeasonCard(
      now,
      adjustmentDays: _adjustment,
      isVisible: prefs?.isSeasonVisible ?? (_) => true,
    );
    if (season == null) return;
    final flags = _flags;
    if (flags != null &&
        SeasonCardDismissStore(flags).isDismissed(season, _today)) {
      _dismissed = true;
      return;
    }
    _season = season;
    _loadState(season, flags);
  }

  void _loadState(ActiveSeason season, SeasonFlagStore? flags) {
    final year = season.hijriYear;
    switch (season.id) {
      case SeasonId.eidFitr:
        if (year != null) unawaited(_loadStats(year));
        if (_eidShowsShawwal(season)) _loadShawwal(year, flags);
      case SeasonId.shawwalSix:
        _loadShawwal(year, flags);
      case SeasonId.friday:
        if (flags != null) {
          _fridayRead = FridayKahfReadStore(flags).isRead(_today);
        }
      default:
        break;
    }
  }

  /// From the 2nd of Shawwal the Eid card also carries the six-days tracker,
  /// unless the user hid that season.
  bool _eidShowsShawwal(ActiveSeason season) {
    final day = season.day;
    if (day == null || day < 2 || season.hijriYear == null) return false;
    return _seasonPrefs?.isSeasonVisible(SeasonId.shawwalSix) ?? true;
  }

  void _loadShawwal(int? year, SeasonFlagStore? flags) {
    if (flags == null || year == null) return;
    final store = ShawwalSixStore(flags);
    _shawwalCount = store.count(year);
    _shawwalToday = store.isMarked(year, _today);
  }

  Future<void> _loadStats(int year) async {
    var nights = 0;
    var pages = 0;
    var khatmahs = 0;
    final DateTime first;
    final DateTime last;
    try {
      final range = ramadanCivilRange(year, _adjustment);
      first = range.first;
      last = range.last;
    } catch (_) {
      if (mounted) setState(() => _statsLoaded = true);
      return;
    }
    try {
      final store = _tarawih;
      if (store != null) {
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
      // The card simply omits the tarawih lines.
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
      if (loader != null) {
        final lo = DateTime(first.year, first.month, first.day);
        final hi = DateTime(last.year, last.month, last.day + 1);
        khatmahs = (await loader())
            .map((d) => d.toLocal())
            .where((d) => !d.isBefore(lo) && d.isBefore(hi))
            .length;
      }
    } catch (_) {
      // The card simply omits the khatmah line.
    }
    if (!mounted) return;
    setState(() {
      _nights = nights;
      _pages = pages;
      _khatmahs = khatmahs;
      _statsLoaded = true;
    });
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _open(String route, {Object? extra}) {
    final custom = widget.openRoute;
    if (custom != null) {
      custom(route, extra: extra);
    } else {
      unawaited(context.push(route, extra: extra));
    }
  }

  Future<void> _dismiss() async {
    final season = _season;
    final flags = _flags;
    if (season == null) return;
    setState(() => _dismissed = true);
    if (flags != null) {
      await SeasonCardDismissStore(flags).dismiss(season, _today);
    }
  }

  /// «إخفاء هذا الموسم» turns the season's switch in the seasons settings off
  /// (unlike [_dismiss], which hides this card for this period only). A
  /// bottom notice offers undo and the path back.
  Future<void> _hideSeason() async {
    final season = _season;
    final store = _seasonPrefs;
    if (season == null || store == null) return;
    final group = seasonSwitchGroup(season.id);
    setState(() => _hidden = true);
    for (final id in group) {
      await store.setSeasonEnabled(id, false);
    }
    if (!mounted) return;
    final l10n = context.l10n;
    _seasonChanged(l10n, context: context);
    context.showAutoDismissSnackBar(
      l10n.ramadanHideSeasonDone,
      action: SnackBarAction(
        label: l10n.undo,
        onPressed: () async {
          for (final id in group) {
            await store.setSeasonEnabled(id, true);
          }
          // Reschedule even if the card is gone by now.
          _seasonChanged(l10n, context: mounted ? context : null);
          if (!mounted) return;
          setState(() => _hidden = false);
        },
      ),
    );
  }

  void _seasonChanged(AppLocalizations l10n, {BuildContext? context}) {
    final custom = widget.onSeasonChanged;
    if (custom != null && context != null) {
      custom(context);
      return;
    }
    if (!getIt.isRegistered<NotificationScheduler>()) return;
    unawaited(
      getIt<NotificationScheduler>().refreshNotifications(l10n, force: true),
    );
  }

  Future<void> _toggleShawwal() async {
    final season = _season;
    final flags = _flags;
    final year = season?.hijriYear;
    if (flags == null || year == null) return;
    final store = ShawwalSixStore(flags);
    await store.toggle(year, _today);
    await _afterShawwalChange(store, flags, year);
  }

  Future<void> _afterShawwalChange(
    ShawwalSixStore store,
    SeasonFlagStore flags,
    int year,
  ) async {
    if (store.isDone(year)) {
      await SeasonBadgeStore(flags).award(SeasonBadgeKind.shawwalSix, year);
    }
    if (!mounted) return;
    setState(() {
      _shawwalCount = store.count(year);
      _shawwalToday = store.isMarked(year, _today);
    });
  }

  void _logShawwalDay() {
    final season = _season;
    final flags = _flags;
    final year = season?.hijriYear;
    final day = season?.day;
    if (flags == null || year == null || day == null) return;
    final store = ShawwalSixStore(flags);
    unawaited(
      showShawwalLogSheet(
        context,
        store: store,
        hijriYear: year,
        today: _today,
        hijriDay: day,
        onChanged: () => _afterShawwalChange(store, flags, year),
      ),
    );
  }

  /// Progress line, circles and actions of the six days of Shawwal; the
  /// progress line is returned for the caller to place.
  String _addShawwalTracker(
    AppLocalizations l10n,
    String Function(int) num,
    HomeSkin skin,
    List<Widget> actions,
    List<Widget> extras,
  ) {
    final done = _shawwalCount >= ShawwalSixStore.target;
    extras.add(_shawwalCircles(skin));
    if (_flags != null && (!done || _shawwalToday)) {
      actions.add(
        _button(
          _shawwalToday ? l10n.seasonShawwalUnmark : l10n.seasonShawwalMark,
          () => unawaited(_toggleShawwal()),
          'shawwal_mark',
        ),
      );
    }
    if (_flags != null) {
      actions.add(_button(l10n.seasonShawwalLogDay, _logShawwalDay, 'shawwal_log'));
    }
    return done
        ? l10n.seasonShawwalDone
        : l10n.seasonShawwalProgress(
            num(_shawwalCount),
            num(ShawwalSixStore.target),
          );
  }

  Future<void> _toggleFridayRead() async {
    final flags = _flags;
    if (flags == null) return;
    final next = !_fridayRead;
    await FridayKahfReadStore(flags).setRead(_today, next);
    if (!mounted) return;
    setState(() => _fridayRead = next);
  }

  void _shareEid(AppLocalizations l10n, String lang, int year, String stats) {
    unawaited(
      SocialShareSheet.show(
        context,
        SocialShareData(
          category: SocialShareCategory.achievement,
          title: l10n.seasonEidShareTitle(
            LocaleNumberFormatter.number(year, lang),
          ),
          content: stats,
          showCharacter: false,
          achievementUnlocked: true,
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final season = _season;
    if (season == null || _dismissed || _hidden) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final skin = widget.skin;
    String num(int n) => LocaleNumberFormatter.number(n, lang);

    String? title;
    String? body;
    final actions = <Widget>[];
    final extras = <Widget>[];
    final year = season.hijriYear;

    String daysPhrase(SeasonId target) {
      final until = daysUntilSeasonActive(
        target,
        _today,
        adjustmentDays: _adjustment,
      );
      return until == null || until < 1
          ? ''
          : ' ${l10n.seasonDaysUntil(until, num(until))}';
    }

    switch (season.id) {
      case SeasonId.shabanPrep:
        title = '${l10n.seasonNameRamadan}${daysPhrase(SeasonId.ramadan)}';
        actions.add(
          _button(
            l10n.seasonShabanOpenKhatmah,
            () => _open(AppRoutes.khatmahSetup),
            'khatmah',
          ),
        );
      case SeasonId.eidFitr:
        if (!_statsLoaded) return const SizedBox.shrink();
        title = l10n.seasonEidGreeting;
        final stats = [
          if (_nights > 0) l10n.ramadanSummaryNights(_nights, num(_nights)),
          if (_pages > 0) l10n.tarawihTotal(_pages, num(_pages)),
          if (_khatmahs > 0)
            l10n.ramadanSummaryKhatmah(_khatmahs, num(_khatmahs)),
        ].join('\n');
        if (stats.isNotEmpty) {
          body = stats;
          if (year != null) {
            actions.add(
              _button(
                l10n.seasonEidShare,
                () => _shareEid(l10n, lang, year, stats),
                'share',
              ),
            );
          }
        }
        if (_khatmahs > 0) {
          extras.add(_line(SeasonLineIds.khatmahDua));
        }
        extras.add(_line(SeasonLineIds.eidFitrDua));
        if (_eidShowsShawwal(season)) {
          final progress = _addShawwalTracker(l10n, num, skin, actions, extras);
          extras.add(
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                progress,
                key: const ValueKey('home_season_shawwal_progress'),
                style: AppTypography.bodySmall.copyWith(
                  color: skin.textOnHeroMuted,
                ),
              ),
            ),
          );
        }
      case SeasonId.shawwalSix:
        title = l10n.seasonShawwalTitle;
        body = _addShawwalTracker(l10n, num, skin, actions, extras);
      case SeasonId.dhulHijjahTen:
        final day = season.day;
        if (season.stage == SeasonStage.invite || day == null) {
          title = '${l10n.seasonHajjName}${daysPhrase(SeasonId.dhulHijjahTen)}';
        } else {
          title = l10n.seasonHajjDay(num(day));
          if (day == 8) body = l10n.seasonArafahTomorrow;
          if (day == 9) body = l10n.seasonArafahToday;
        }
        actions.add(
          _button(
            l10n.seasonHajjKhatmah,
            () => _open(
              AppRoutes.khatmahSetup,
              extra: KhatmahSetupPrefill(
                pagesPerDay: (KhatmahSchedulingEngine.totalPages / 10).ceil(),
                targetDays: 10,
              ),
            ),
            'khatmah',
          ),
        );
      case SeasonId.eidAdha:
        title = l10n.seasonEidGreeting;
      case SeasonId.hijriNewYear:
        if (year == null) return const SizedBox.shrink();
        title = l10n.seasonNewYearTitle(num(year));
        extras.add(_line(SeasonLineIds.newYearDua));
        actions.add(
          _button(
            l10n.seasonNewYearPlan,
            () => _open(AppRoutes.khatmahSetup),
            'khatmah',
          ),
        );
      case SeasonId.ashura:
        if (season.stage == SeasonStage.invite) {
          title = '${l10n.seasonAshuraName}${daysPhrase(SeasonId.ashura)}';
        } else {
          title = l10n.seasonAshuraTitle;
          body = season.day == 10
              ? l10n.seasonAshuraDay10
              : l10n.seasonAshuraDay9;
        }
      case SeasonId.whiteDays:
        title = l10n.seasonWhiteDaysTitle;
        final day = season.day;
        body = season.stage == SeasonStage.invite || day == null
            ? l10n.seasonWhiteDaysInvite(num(13), num(14), num(15))
            : l10n.seasonWhiteDaysToday(num(day));
      case SeasonId.friday:
        title = l10n.seasonFridayTitle;
        actions.add(
          _button(
            l10n.seasonFridayOpen,
            () => _open('/quran/surah/18'),
            'open_kahf',
          ),
        );
        if (_flags != null) {
          actions.add(
            FilterChip(
              key: const ValueKey('home_season_friday_read'),
              selected: _fridayRead,
              onSelected: (_) => unawaited(_toggleFridayRead()),
              label: Text(l10n.seasonFridayRead),
              showCheckmark: true,
            ),
          );
        }
        extras.add(_line(SeasonLineIds.fridayDua));
      case SeasonId.monThu:
        title = l10n.seasonMonThuTitle;
        body = l10n.seasonMonThuBody;
      case SeasonId.ramadan:
        return const SizedBox.shrink();
    }

    return Padding(
      key: const ValueKey('home_season_card'),
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
                Icon(TaliaIcons.moon, size: 24, color: skin.gold),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    key: const ValueKey('home_season_title'),
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
                key: const ValueKey('home_season_body'),
                style: AppTypography.bodySmall.copyWith(
                  color: skin.textOnHeroMuted,
                  height: 1.4,
                ),
              ),
            ],
            ...extras,
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...actions,
                if (_seasonPrefs != null)
                  TextButton(
                    key: const ValueKey('home_season_hide_season'),
                    onPressed: () => unawaited(_hideSeason()),
                    child: Text(
                      l10n.ramadanHideSeason,
                      style: AppTypography.labelSmall.copyWith(
                        color: skin.textOnHeroMuted,
                      ),
                    ),
                  ),
                TextButton(
                  key: const ValueKey('home_season_dismiss'),
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

  Widget _line(String id) =>
      SeasonApprovedLine(id: id, skin: widget.skin, loader: widget.lineLoader);

  Widget _shawwalCircles(HomeSkin skin) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Row(
      key: const ValueKey('home_season_shawwal_circles'),
      children: [
        for (var i = 0; i < ShawwalSixStore.target; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _shawwalCount ? skin.gold : Colors.transparent,
                border: Border.all(color: skin.gold, width: 1.5),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _button(String label, VoidCallback onPressed, String id) => AppButton(
    key: ValueKey('home_season_$id'),
    label: label,
    size: AppButtonSize.small,
    variant: AppButtonVariant.goldPrimary,
    onPressed: onPressed,
  );
}
