import 'dart:async';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/icons/talia_icons.dart';
import '../../../../../core/identity/record_owner_provider.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/seasons/season_calendar.dart';
import '../../../../../core/seasons/season_preferences.dart';
import '../../../../../core/services/notification_scheduler.dart';
import '../../../../../core/services/hijri_date_adjustment.dart';
import '../../../../../core/services/notification_service.dart';
import '../../../../../core/utils/locale_number_formatter.dart';
import '../../../../khatmah/domain/repositories/khatmah_repository.dart';
import '../../../../seasons/data/season_badge_store.dart';
import '../../../../seasons/data/season_flag_store.dart';
import '../../../../seasons/domain/last_ten_reminder.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/settings_hijri_adjustment_tile.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/settings_subpage_scaffold.dart';
import '../../widgets/settings_switch_tile.dart';

/// «المواسم والمناسبات»: one master switch, one switch per season, the shared
/// seasonal-reminders opt-in (off by default) and the Hijri adjustment the
/// windows follow. Turning the master switch off keeps every per-season
/// choice; nothing here deletes data.
class SeasonsSettingsPage extends StatefulWidget {
  const SeasonsSettingsPage({super.key});

  @override
  State<SeasonsSettingsPage> createState() => _SeasonsSettingsPageState();
}

class _SeasonsSettingsPageState extends State<SeasonsSettingsPage> {
  SeasonPreferences? get _store => getIt.isRegistered<SeasonPreferences>()
      ? getIt<SeasonPreferences>()
      : null;

  List<SeasonBadge> _badges = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadBadges());
  }

  /// Earned badges, after deriving the khatmah ones from finished khatmahs.
  /// A failure leaves whatever is already stored.
  Future<void> _loadBadges() async {
    if (!getIt.isRegistered<SharedPreferences>() ||
        !getIt.isRegistered<RecordOwnerProvider>()) {
      return;
    }
    final flags = getIt.isRegistered<SeasonFlagStore>()
        ? getIt<SeasonFlagStore>()
        : SeasonFlagStore(
            getIt<SharedPreferences>(),
            getIt<RecordOwnerProvider>(),
          );
    final store = SeasonBadgeStore(flags);
    try {
      if (getIt.isRegistered<KhatmahRepository>()) {
        final adjustment = getIt.isRegistered<HijriDateAdjustment>()
            ? getIt<HijriDateAdjustment>().days
            : 0;
        final history = await getIt<KhatmahRepository>().getHistory();
        await store.syncFromKhatmahs([
          for (final h in history)
            (start: h.startDate.toLocal(), completed: h.completedDate.toLocal()),
        ], adjustmentDays: adjustment);
      }
    } catch (_) {
      // Stored badges still show.
    }
    if (!mounted) return;
    setState(() => _badges = store.earned());
  }

  String _badgeLabel(AppLocalizations l10n, String lang, SeasonBadge badge) {
    final year = LocaleNumberFormatter.number(badge.hijriYear, lang);
    return switch (badge.kind) {
      SeasonBadgeKind.ramadanKhatmah => l10n.seasonBadgeRamadanKhatmah(year),
      SeasonBadgeKind.shawwalSix => l10n.seasonBadgeShawwalSix(year),
      SeasonBadgeKind.dhulHijjahKhatmah => l10n.seasonBadgeHajjKhatmah(year),
    };
  }

  Widget _badgesRow(AppLocalizations l10n) {
    final lang = Localizations.localeOf(context).languageCode;
    return SettingsGroup(
      title: l10n.seasonBadgesTitle,
      children: [
        Padding(
          key: const ValueKey('seasons_badges_row'),
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final badge in _badges)
                Chip(
                  avatar: const Icon(TaliaIcons.trophy, size: 18),
                  label: Text(_badgeLabel(l10n, lang, badge)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = _store;
    final master = store?.masterEnabled ?? true;

    return SettingsSubpageScaffold(
      title: l10n.settingsSeasonsPageTitle,
      children: [
        if (_badges.isNotEmpty) _badgesRow(l10n),
        SettingsGroup(
          children: [
            SettingsSwitchTile(
              icon: TaliaIcons.moon,
              title: l10n.settingsSeasonsMasterTitle,
              subtitle: l10n.settingsSeasonsMasterSubtitle,
              value: master,
              onChanged: store == null
                  ? null
                  : (value) => _set(() => store.setMasterEnabled(value)),
            ),
          ],
        ),
        SettingsGroup(
          title: l10n.hijriAdjustmentTitle,
          children: const [HijriAdjustmentTile()],
        ),
        SettingsGroup(
          title: l10n.settingsSeasonsYearGroup,
          children: _rows(
            context,
            master: master,
            rows: const [
              (_SeasonRow.shaban, TaliaIcons.moon),
              (_SeasonRow.ramadan, TaliaIcons.moon),
              (_SeasonRow.eid, TaliaIcons.moon),
              (_SeasonRow.hajj, TaliaIcons.moon),
              (_SeasonRow.newYear, TaliaIcons.moon),
              (_SeasonRow.ashura, TaliaIcons.moon),
            ],
          ),
        ),
        SettingsGroup(
          title: l10n.settingsSeasonsWeeklyGroup,
          children: _rows(
            context,
            master: master,
            rows: const [
              (_SeasonRow.friday, TaliaIcons.calendar),
              (_SeasonRow.whiteDays, TaliaIcons.calendar),
              (_SeasonRow.monThu, TaliaIcons.calendar),
            ],
          ),
        ),
        SettingsGroup(
          title: l10n.settingsSeasonsRemindersGroup,
          children: [
            SettingsSwitchTile(
              icon: TaliaIcons.bell,
              title: l10n.settingsSeasonsRemindersTitle,
              subtitle: l10n.settingsSeasonsRemindersHint,
              value: store?.remindersEnabled ?? false,
              onChanged: store == null ? null : (value) => _setReminders(value),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextButton(
            onPressed: store == null ? null : () => _set(_resetDefaults),
            child: Text(l10n.settingsRestoreDefaults),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  List<Widget> _rows(
    BuildContext context, {
    required bool master,
    required List<(_SeasonRow, IconData)> rows,
  }) {
    final l10n = context.l10n;
    final store = _store;
    final isDark = context.isDark;
    return [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) SettingsDivider(isDark: isDark, indent: 0),
        SettingsSwitchTile(
          icon: rows[i].$2,
          title: rows[i].$1.name(l10n),
          value: store != null && rows[i].$1.ids.every(store.isSeasonEnabled),
          enabled: master,
          onChanged: master && store != null
              ? (value) => _set(
                  () => Future.wait(
                    rows[i].$1.ids.map(
                      (id) => store.setSeasonEnabled(id, value),
                    ),
                  ),
                )
              : null,
        ),
      ],
    ];
  }

  /// Writes a choice, redraws, and reschedules notifications: the Ramadan
  /// reminder depends on the master and Ramadan switches.
  Future<void> _set(FutureOr<void> Function() write) async {
    final l10n = context.l10n;
    await write();
    if (!mounted) return;
    setState(() {});
    _refreshNotifications(l10n);
  }

  Future<void> _resetDefaults() async {
    await _store?.resetToDefaults();
  }

  void _refreshNotifications(AppLocalizations l10n) {
    if (!getIt.isRegistered<NotificationScheduler>()) return;
    unawaited(
      getIt<NotificationScheduler>().refreshNotifications(l10n, force: true),
    );
  }

  /// Opting in asks for notification permission first (Android 13+), then
  /// notifications are rescheduled; opting out only reschedules.
  Future<void> _setReminders(bool value) async {
    final store = _store;
    if (store == null) return;
    final l10n = context.l10n;
    await store.setRemindersEnabled(value);
    // Off means every seasonal reminder is off, including the Ramadan card's
    // last-ten opt-in; turning the switch on never enables that one.
    if (!value && getIt.isRegistered<SharedPreferences>()) {
      await getIt<SharedPreferences>().setBool(
        lastTenReminderPreferenceKey,
        false,
      );
    }
    if (!mounted) return;
    setState(() {});
    if (value && getIt.isRegistered<TaliaNotificationService>()) {
      try {
        await getIt<TaliaNotificationService>().requestPermissions();
      } catch (_) {
        // Scheduling below still runs; a denied permission shows nothing.
      }
    }
    _refreshNotifications(l10n);
  }
}

/// One switch row; [ids] share a single switch (the Eid row drives both the
/// Eid days and the six of Shawwal).
enum _SeasonRow {
  shaban([SeasonId.shabanPrep]),
  ramadan([SeasonId.ramadan]),
  eid([SeasonId.eidFitr, SeasonId.shawwalSix]),
  hajj([SeasonId.dhulHijjahTen, SeasonId.eidAdha]),
  newYear([SeasonId.hijriNewYear]),
  ashura([SeasonId.ashura]),
  friday([SeasonId.friday]),
  whiteDays([SeasonId.whiteDays]),
  monThu([SeasonId.monThu]);

  const _SeasonRow(this.ids);

  final List<SeasonId> ids;

  String name(AppLocalizations l10n) => switch (this) {
    _SeasonRow.shaban => l10n.settingsSeasonsShaban,
    _SeasonRow.ramadan => l10n.settingsSeasonsRamadan,
    _SeasonRow.eid => l10n.settingsSeasonsEid,
    _SeasonRow.hajj => l10n.settingsSeasonsHajj,
    _SeasonRow.newYear => l10n.settingsSeasonsNewYear,
    _SeasonRow.ashura => l10n.settingsSeasonsAshura,
    _SeasonRow.friday => l10n.settingsSeasonsFriday,
    _SeasonRow.whiteDays => l10n.settingsSeasonsWhiteDays,
    _SeasonRow.monThu => l10n.settingsSeasonsMonThu,
  };
}
