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
import '../../../../core/seasons/season_preferences.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/hijri_date_adjustment.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/locale_number_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../home/presentation/theme/home_skin.dart';
import '../../../home/presentation/widgets/glass_panel.dart';
import '../../../khatmah/domain/repositories/khatmah_repository.dart';
import '../../data/ramadan_card_dismiss_store.dart';
import '../../data/tarawih_log_store.dart';
import '../../data/season_dua_loader.dart';
import '../../domain/iftar_countdown.dart';
import '../../domain/last_ten_reminder.dart';
import 'season_approved_line.dart';
import 'tarawih_log_sheet.dart';

/// Fajr and Maghrib of [fajrToday]'s day, plus the next day's Fajr.
class RamadanPrayerTimes {
  const RamadanPrayerTimes({
    required this.fajrToday,
    required this.maghribToday,
    required this.fajrTomorrow,
  });

  final DateTime? fajrToday;
  final DateTime? maghribToday;
  final DateTime? fajrTomorrow;
}

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
    this.prefs,
    this.onReminderChanged,
    this.seasonPrefs,
    this.loadPrayerTimes,
    this.lineLoader,
    this.countdownInterval = const Duration(minutes: 1),
  });

  final HomeSkin skin;
  final DateTime Function()? now;

  /// Overrides the phase computed from [now] and the Hijri adjustment.
  final RamadanInfo? info;
  final RamadanCardDismissStore? dismissStore;
  final TarawihLogStore? tarawihStore;

  /// The user's seasons on/off choices; defaults to get_it.
  final SeasonPreferences? seasonPrefs;

  /// Fajr and Maghrib around a civil day, or null without prayer times (no
  /// city). Drives the iftar/suhoor line; defaults to the prayer times
  /// service from get_it.
  final Future<RamadanPrayerTimes?> Function(DateTime day)? loadPrayerTimes;

  /// Replaces the azkar-datasource-backed loader of the approved line.
  final SeasonLineLoader? lineLoader;

  /// How often the countdown re-reads the clock.
  final Duration countdownInterval;

  /// Completion dates of finished khatmahs.
  final Future<List<DateTime>> Function()? loadKhatmahCompletions;
  final Future<bool> Function()? hasActiveKhatmah;

  /// Holds the last-ten reminder opt-in; defaults to get_it.
  final SharedPreferences? prefs;

  /// Runs after the opt-in changes; defaults to rescheduling notifications.
  final void Function(BuildContext context)? onReminderChanged;

  @override
  State<HomeRamadanCard> createState() => _HomeRamadanCardState();
}

class _HomeRamadanCardState extends State<HomeRamadanCard> {
  RamadanInfo? _info;
  int _year = 0;
  bool _dismissed = false;
  bool _seasonHidden = false;
  bool _activeKhatmah = false;
  int _nights = 0;
  int _pages = 0;
  int _khatmahs = 0;
  bool _summaryLoaded = false;
  bool _reminderOn = false;
  Timer? _ticker;
  RamadanPrayerTimes? _times;
  DateTime? _timesDay;
  IftarCountdown? _countdown;

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

  SeasonPreferences? get _seasonPrefs =>
      widget.seasonPrefs ??
      (getIt.isRegistered<SeasonPreferences>() ? getIt<SeasonPreferences>() : null);

  @override
  void initState() {
    super.initState();
    if (!_flagOn) return;
    final seasonPrefs = _seasonPrefs;
    // The user turned the season (or all seasons) off from its card or the
    // seasons settings; nothing of the season shows.
    if (seasonPrefs != null && !seasonPrefs.isSeasonVisible(SeasonId.ramadan)) {
      return;
    }
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
    // Reminder on = the card's own opt-in while the season is visible (a
    // hidden season returned above).
    _reminderOn =
        (_prefs?.getBool(lastTenReminderPreferenceKey) ?? false) &&
        (seasonPrefs?.isSeasonVisible(SeasonId.ramadan) ?? true);
    if (info.phase == RamadanPhase.afterEid) {
      unawaited(_loadSummary(info));
    } else if (info.phase != RamadanPhase.invite) {
      unawaited(_loadActive());
      unawaited(_startCountdown());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  DateTime _clock() => (widget.now ?? DateTime.now)();

  Future<RamadanPrayerTimes?> _defaultPrayerTimes(DateTime day) async {
    if (!getIt.isRegistered<PrayerTimesService>()) return null;
    final service = getIt<PrayerTimesService>();
    final today = await service.timesForDate(day);
    if (today.isEmpty) return null;
    final tomorrow = await service.timesForDate(
      DateTime(day.year, day.month, day.day + 1),
    );
    DateTime? at(List<({String key, String nameAr, String nameEn, DateTime time})> l, String key) =>
        l.where((p) => p.key == key).firstOrNull?.time;
    return RamadanPrayerTimes(
      fajrToday: at(today, 'fajr'),
      maghribToday: at(today, 'maghrib'),
      fajrTomorrow: at(tomorrow, 'fajr'),
    );
  }

  /// Loads the day's prayer times and ticks every [countdownInterval]. No
  /// prayer times (no city) means no line and no timer.
  Future<void> _startCountdown() async {
    await _refreshCountdown();
    if (!mounted || _times == null) return;
    _ticker = Timer.periodic(
      widget.countdownInterval,
      (_) => unawaited(_refreshCountdown()),
    );
  }

  Future<void> _refreshCountdown() async {
    try {
      final now = _clock();
      final day = DateTime(now.year, now.month, now.day);
      if (_timesDay != day) {
        final loader = widget.loadPrayerTimes ?? _defaultPrayerTimes;
        _times = await loader(day);
        _timesDay = day;
      }
      final times = _times;
      final next = times == null
          ? null
          : iftarCountdownAt(
              now,
              fajrToday: times.fajrToday,
              maghribToday: times.maghribToday,
              fajrTomorrow: times.fajrTomorrow,
              lastRamadanDay: _isLastRamadanDay(_info),
            );
      if (!mounted) return;
      setState(() => _countdown = next);
    } catch (_) {
      if (mounted) setState(() => _countdown = null);
    }
  }

  static bool _isLastRamadanDay(RamadanInfo? info) =>
      info != null &&
      info.day != null &&
      info.monthLength > 0 &&
      info.day! >= info.monthLength;

  String? _countdownText(AppLocalizations l10n, String lang) {
    final c = _countdown;
    if (c == null) return null;
    if (c.phase == FastPhase.untilSuhoorEnd) {
      final fajr = c.fajr;
      if (fajr == null) return null;
      final time = context.digitText(
        TimeOfDay.fromDateTime(fajr).format(context),
      );
      return l10n.ramadanSuhoorUntil(time);
    }
    final minutes = (c.remaining ?? Duration.zero).inMinutes;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    String hours() => l10n.ramadanHoursPart(h, LocaleNumberFormatter.number(h, lang));
    String mins(int n) =>
        l10n.ramadanMinutesPart(n, LocaleNumberFormatter.number(n, lang));
    final duration = h > 0 && m > 0
        ? l10n.ramadanDurationJoin(hours(), mins(m))
        : h > 0
        ? hours()
        : mins(m < 1 ? 1 : m);
    return l10n.ramadanIftarIn(duration);
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

  /// «إخفاء هذا الموسم» turns the Ramadan switch in the seasons settings off
  /// — unlike [_dismiss], which hides this card for this Hijri year only.
  /// A bottom notice offers undo and the path back.
  Future<void> _hideSeason() async {
    final store = _seasonPrefs;
    if (store == null) return;
    setState(() => _seasonHidden = true);
    await store.setSeasonEnabled(SeasonId.ramadan, false);
    if (!mounted) return;
    final l10n = context.l10n;
    // The last-ten reminder needs the season visible: cancel it now.
    _applyReminder(l10n, askPermission: false);
    context.showAutoDismissSnackBar(
      l10n.ramadanHideSeasonDone,
      action: SnackBarAction(
        label: l10n.undo,
        onPressed: () async {
          await store.setSeasonEnabled(SeasonId.ramadan, true);
          // Reschedule even if the card is gone by now.
          _applyReminder(l10n, askPermission: false);
          if (!mounted) return;
          setState(() => _seasonHidden = false);
        },
      ),
    );
  }

  void _openKhatmah() {
    unawaited(
      context.push(
        _activeKhatmah ? AppRoutes.khatmahDashboard : AppRoutes.khatmahSetup,
      ),
    );
  }

  SharedPreferences? get _prefs =>
      widget.prefs ??
      (getIt.isRegistered<SharedPreferences>()
          ? getIt<SharedPreferences>()
          : null);

  Future<void> _toggleReminder() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final on = !_reminderOn;
    if (!await prefs.setBool(lastTenReminderPreferenceKey, on)) return;
    if (!mounted) return;
    setState(() => _reminderOn = on);
    final custom = widget.onReminderChanged;
    if (custom != null) {
      custom(context);
    } else {
      _applyReminder(context.l10n, askPermission: on);
    }
  }

  /// Opting in asks for notification permission first (Android 13+), so the
  /// reminder can actually arrive; either way notifications are rescheduled.
  static void _applyReminder(
    AppLocalizations l10n, {
    required bool askPermission,
  }) {
    if (!getIt.isRegistered<NotificationScheduler>()) return;
    Future<void> apply() async {
      if (askPermission && getIt.isRegistered<TaliaNotificationService>()) {
        try {
          await getIt<TaliaNotificationService>().requestPermissions();
        } catch (_) {
          // Scheduling below still runs; a denied permission shows nothing.
        }
      }
      await getIt<NotificationScheduler>().refreshNotifications(
        l10n,
        force: true,
      );
    }

    unawaited(apply());
  }

  void _logTarawih() {
    final store = _tarawih;
    if (store == null) return;
    unawaited(showTarawihLogSheet(context, store, now: widget.now));
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    if (info == null || _dismissed || _seasonHidden) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final skin = widget.skin;
    final countdownLine =
        info.phase == RamadanPhase.ramadan || info.phase == RamadanPhase.lastTen
        ? _countdownText(l10n, lang)
        : null;

    final String title;
    String? body;
    final actions = <Widget>[];
    switch (info.phase) {
      case RamadanPhase.invite:
        title = l10n.ramadanInviteTitle;
        body = l10n.ramadanInviteBody;
        actions.add(_button(l10n.ramadanOpenKhatmah, _openKhatmah, 'khatmah'));
        _addReminderToggle(actions, info, skin, l10n);
      case RamadanPhase.ramadan:
      case RamadanPhase.lastTen:
        title = l10n.ramadanDayTitle(
          LocaleNumberFormatter.number(info.day ?? 0, lang),
        );
        body = _lastTenLine(context, info, lang);
        actions
          ..add(_button(l10n.ramadanOpenKhatmah, _openKhatmah, 'khatmah'))
          ..add(_button(l10n.ramadanLogTarawih, _logTarawih, 'tarawih'));
        _addReminderToggle(actions, info, skin, l10n);
      case RamadanPhase.afterEid:
        if (!_summaryLoaded) return const SizedBox.shrink();
        title = l10n.ramadanSummaryTitle;
        // Nothing logged and nothing completed: no card rather than "0 nights".
        if (_nights == 0 && _pages == 0 && _khatmahs == 0) {
          return const SizedBox.shrink();
        }
        body = [
          if (_nights > 0)
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
            if (countdownLine != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                countdownLine,
                key: const ValueKey('home_ramadan_countdown'),
                style: AppTypography.bodySmall.copyWith(
                  color: skin.textOnHero,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (info.phase == RamadanPhase.lastTen)
              SeasonApprovedLine(
                id: SeasonLineIds.lastTenDua,
                skin: skin,
                loader: widget.lineLoader,
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...actions,
                if (_seasonPrefs != null)
                  TextButton(
                    key: const ValueKey('home_ramadan_hide_season'),
                    onPressed: () => unawaited(_hideSeason()),
                    child: Text(
                      l10n.ramadanHideSeason,
                      style: AppTypography.labelSmall.copyWith(
                        color: skin.textOnHeroMuted,
                      ),
                    ),
                  ),
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

  /// Opt-in for the evening the last ten nights begin, offered only while
  /// that evening is still ahead.
  void _addReminderToggle(
    List<Widget> actions,
    RamadanInfo info,
    HomeSkin skin,
    AppLocalizations l10n,
  ) {
    if (lastTenEveDate(info) == null || _prefs == null) return;
    actions.add(
      Semantics(
        toggled: _reminderOn,
        hint: _reminderOn ? l10n.ramadanLastTenReminderOnHint : null,
        child: TextButton.icon(
          key: const ValueKey('home_ramadan_last_ten_reminder'),
          onPressed: () => unawaited(_toggleReminder()),
          icon: Icon(TaliaIcons.bell, size: 18, color: skin.gold),
          label: Text(
            _reminderOn ? l10n.ramadanLastTenReminderOn : l10n.ramadanLastTenRemind,
            style: AppTypography.labelSmall.copyWith(color: skin.textOnHero),
          ),
        ),
      ),
    );
  }

  /// Countdown to the last ten nights during days 1–20, then the day within
  /// them. Calendar only: no religious text.
  static String? _lastTenLine(
    BuildContext context,
    RamadanInfo info,
    String lang,
  ) {
    final l10n = context.l10n;
    final inLastTen = lastTenDayNumber(info);
    if (inLastTen != null) {
      return l10n.ramadanLastTenDay(
        LocaleNumberFormatter.number(inLastTen, lang),
      );
    }
    final until = daysUntilLastTenEve(info);
    if (until == null) return null;
    if (until == 0) return l10n.ramadanLastTenTonight;
    return l10n.ramadanLastTenCountdown(
      until,
      LocaleNumberFormatter.number(until, lang),
    );
  }

  Widget _button(String label, VoidCallback onPressed, String id) => AppButton(
    key: ValueKey('home_ramadan_$id'),
    label: label,
    size: AppButtonSize.small,
    variant: AppButtonVariant.goldPrimary,
    onPressed: onPressed,
  );
}
