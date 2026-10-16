import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/experience/experience_feature_flags.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../azkar/domain/services/after_prayer_azkar_window.dart';
import '../theme/home_skin.dart';
import 'glass_panel.dart';

/// Device-level "done" key for one prayer window: one key per day and slot.
String afterPrayerAzkarDoneKey(DateTime day, PrayerSlot slot) =>
    '${_dayPrefix(day)}_${slot.name}';

String _dayPrefix(DateTime day) {
  final mm = day.month.toString().padLeft(2, '0');
  final dd = day.day.toString().padLeft(2, '0');
  return '$afterPrayerAzkarDonePrefix${day.year}-$mm-$dd';
}

const String afterPrayerAzkarDonePrefix = 'after_prayer_azkar_done_';

/// Maps the home prayer snapshot to today's five prayer times. Null when the
/// snapshot is missing or incomplete (prayer times are off).
Map<PrayerSlot, DateTime>? afterPrayerTimesFromSnapshot(
  PrayerTimesSnapshot? snapshot,
) {
  if (snapshot == null) return null;
  final times = {
    PrayerSlot.fajr: snapshot.fajr,
    PrayerSlot.dhuhr: snapshot.dhuhr,
    PrayerSlot.asr: snapshot.asr,
    PrayerSlot.maghrib: snapshot.maghrib,
    PrayerSlot.isha: snapshot.isha,
  };
  if (times.values.any((t) => t == null)) return null;
  return {for (final e in times.entries) e.key: e.value!};
}

String _prayerName(AppLocalizations l10n, PrayerSlot slot) => switch (slot) {
  PrayerSlot.fajr => l10n.prayerFajr,
  PrayerSlot.dhuhr => l10n.prayerDhuhr,
  PrayerSlot.asr => l10n.prayerAsr,
  PrayerSlot.maghrib => l10n.prayerMaghrib,
  PrayerSlot.isha => l10n.prayerIsha,
};

/// Home card offering the after-prayer adhkar right after a prayer. Hidden when
/// the experience flag is off, prayer times are unavailable, no window is
/// active, no approved records exist, or this prayer's adhkar were opened.
///
/// The window is recomputed every 30 seconds while the card is mounted, and
/// whenever the home rebuilds (including after an app resume reload).
class HomeAfterPrayerAzkarCard extends StatefulWidget {
  const HomeAfterPrayerAzkarCard({
    super.key,
    required this.skin,
    required this.snapshot,
    this.now,
    this.prefs,
    this.loadIds,
    this.bundle,
  });

  final HomeSkin skin;
  final PrayerTimesSnapshot? snapshot;
  final DateTime Function()? now;
  final SharedPreferences? prefs;
  final Future<List<String>> Function()? loadIds;
  final AssetBundle? bundle;

  @override
  State<HomeAfterPrayerAzkarCard> createState() =>
      _HomeAfterPrayerAzkarCardState();
}

class _HomeAfterPrayerAzkarCardState extends State<HomeAfterPrayerAzkarCard> {
  List<String> _ids = const [];
  Timer? _ticker;

  DateTime get _now => (widget.now ?? DateTime.now)();

  bool get _flagOn =>
      getIt.isRegistered<ExperienceFlags>() &&
      getIt<ExperienceFlags>().isEnabled(ExperienceFeature.afterPrayerAzkar);

  SharedPreferences? get _prefs =>
      widget.prefs ??
      (getIt.isRegistered<SharedPreferences>()
          ? getIt<SharedPreferences>()
          : null);

  @override
  void initState() {
    super.initState();
    if (!_flagOn) return;
    unawaited(_load());
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    final ids =
        await (widget.loadIds ??
            () => loadAfterPrayerAzkarIds(widget.bundle ?? rootBundle))();
    if (!mounted) return;
    setState(() => _ids = ids);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _open(AfterPrayerWindow window) async {
    final prefs = _prefs;
    final now = _now;
    if (prefs != null) {
      final today = afterPrayerAzkarDoneKey(now, window.prayer);
      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith(afterPrayerAzkarDonePrefix) &&
            !key.startsWith(_dayPrefix(now))) {
          await prefs.remove(key);
        }
      }
      await prefs.setBool(today, true);
    }
    if (!mounted) return;
    setState(() {});
    unawaited(
      context.push(
        '/azkar/general?sub=${Uri.encodeQueryComponent(afterPrayerAzkarSubcategory)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_flagOn || _ids.isEmpty) return const SizedBox.shrink();
    final times = afterPrayerTimesFromSnapshot(widget.snapshot);
    if (times == null) return const SizedBox.shrink();
    final now = _now;
    final window = activeAfterPrayerWindow(
      todayTimes: times,
      now: now,
      offsetMinutes: _offsetMinutes(),
    );
    if (window == null) return const SizedBox.shrink();
    final done =
        _prefs?.getBool(afterPrayerAzkarDoneKey(now, window.prayer)) ?? false;
    if (done) return const SizedBox.shrink();

    final l10n = context.l10n;
    final skin = widget.skin;
    return Padding(
      key: const ValueKey('home_after_prayer_azkar_card'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        0,
      ),
      child: GlassPanel(
        skin: skin,
        child: Row(
          children: [
            Icon(TaliaIcons.azkar, size: 24, color: skin.gold),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.afterPrayerAzkarTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: skin.textOnHero,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l10n.afterPrayerAzkarSubtitle(
                      _prayerName(l10n, window.prayer),
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: skin.textOnHeroMuted,
                    ),
                  ),
                ],
              ),
            ),
            AppButton(
              label: l10n.afterPrayerAzkarOpen,
              size: AppButtonSize.small,
              variant: AppButtonVariant.goldPrimary,
              onPressed: () => unawaited(_open(window)),
            ),
          ],
        ),
      ),
    );
  }

  int _offsetMinutes() => _prefs?.getInt('after_prayer_azkar_offset_min') ?? 10;
}
