import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/seasons/season_calendar.dart';
import '../../../../core/seasons/season_preferences.dart';
import '../../../../core/services/hijri_date_adjustment.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/locale_number_formatter.dart';

/// Subtitle of the seasons hub tile: the season running now, or the next one
/// with its countdown («Ramadan in 12 days»). Pure presentation helper; null
/// when nothing notable runs or starts soon, or when the user turned the
/// seasons master switch off. Seasons the user hid are skipped. The scan
/// probes the calendar day by day, so its result is cached per civil day,
/// Hijri adjustment and visibility choices instead of recomputed on each hub
/// build.
String? seasonsNavSubtitle(BuildContext context) {
  final l10n = context.l10n;
  final lang = Localizations.localeOf(context).languageCode;
  final prefs = getIt.isRegistered<SeasonPreferences>()
      ? getIt<SeasonPreferences>()
      : null;
  if (prefs != null && !prefs.masterEnabled) return null;
  bool visible(SeasonId id) => prefs?.isSeasonVisible(id) ?? true;
  final adjustment = getIt.isRegistered<HijriDateAdjustment>()
      ? getIt<HijriDateAdjustment>().days
      : 0;
  final now = DateTime.now();
  final key =
      '${now.year}-${now.month}-${now.day}|$adjustment|'
      '${_priority.map((id) => visible(id) ? 1 : 0).join()}';
  if (_cacheKey != key) {
    _cache = _compute(now, adjustment, visible);
    _cacheKey = key;
  }
  final found = _cache;
  if (found == null) return null;
  final name = _name(l10n, found.id);
  final days = found.daysUntil;
  if (days == null) return l10n.settingsSeasonsNow(name);
  return l10n.settingsSeasonsInDays(
    name,
    days,
    LocaleNumberFormatter.number(days, lang),
  );
}

String? _cacheKey;
({SeasonId id, int? daysUntil})? _cache;

({SeasonId id, int? daysUntil})? _compute(
  DateTime now,
  int adjustment,
  bool Function(SeasonId) visible,
) {
  final active = seasonsAt(now, adjustmentDays: adjustment);
  for (final id in _priority) {
    if (!visible(id)) continue;
    if (active.any((s) => s.id == id && s.stage == SeasonStage.active)) {
      return (id: id, daysUntil: null);
    }
  }
  for (final id in _priority) {
    if (!visible(id)) continue;
    final days = daysUntilSeasonActive(id, now, adjustmentDays: adjustment);
    if (days != null && days > 0) return (id: id, daysUntil: days);
  }
  return null;
}

const List<SeasonId> _priority = [
  SeasonId.ramadan,
  SeasonId.eidFitr,
  SeasonId.eidAdha,
  SeasonId.dhulHijjahTen,
  SeasonId.hijriNewYear,
  SeasonId.ashura,
  SeasonId.shabanPrep,
  SeasonId.whiteDays,
];

String _name(AppLocalizations l10n, SeasonId id) => switch (id) {
  SeasonId.ramadan => l10n.settingsSeasonsRamadan,
  SeasonId.eidFitr || SeasonId.shawwalSix => l10n.settingsSeasonsEid,
  SeasonId.dhulHijjahTen || SeasonId.eidAdha => l10n.settingsSeasonsHajj,
  SeasonId.hijriNewYear => l10n.settingsSeasonsNewYear,
  SeasonId.ashura => l10n.settingsSeasonsAshura,
  SeasonId.shabanPrep => l10n.settingsSeasonsShaban,
  SeasonId.whiteDays => l10n.settingsSeasonsWhiteDays,
  SeasonId.friday => l10n.settingsSeasonsFriday,
  SeasonId.monThu => l10n.settingsSeasonsMonThu,
};
