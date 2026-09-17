import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/home_skin.dart';
import 'home_prayer_times_sheet.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

enum _StationState { past, next, future }

class _StationData {
  const _StationData({
    required this.key,
    required this.name,
    required this.icon,
    required this.time,
    required this.state,
  });

  final String key;
  final String name;
  final IconData icon;
  final DateTime? time;
  final _StationState state;
}

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

class HomePrayerTimeline extends StatefulWidget {
  const HomePrayerTimeline({
    super.key,
    required this.snapshot,
    required this.skin,
    required this.hijriLabel,
    this.onTap,
    this.now,
  });

  final PrayerTimesSnapshot snapshot;
  final HomeSkin skin;
  final String hijriLabel;
  final VoidCallback? onTap;

  /// Injectable clock — defaults to [DateTime.now] when null. Used in tests
  /// to pin the current time without depending on the system clock.
  final DateTime Function()? now;

  /// Global flag for tests or goldens to disable repeating animations.
  static bool enableAnimations = true;

  @override
  State<HomePrayerTimeline> createState() => _HomePrayerTimelineState();
}

class _HomePrayerTimelineState extends State<HomePrayerTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (HomePrayerTimeline.enableAnimations &&
          !MediaQuery.disableAnimationsOf(context)) {
        _pulse.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // Build ordered list of stations with their resolved states.
  List<_StationData> _buildStations(BuildContext context) {
    final now = widget.now?.call() ?? DateTime.now();
    final s = widget.snapshot;
    final l10n = context.l10n;

    final raw = [
      ('fajr', l10n.prayerFajr, Icons.wb_twilight_rounded, s.fajr),
      ('sunrise', l10n.prayerSunrise, Icons.wb_sunny_outlined, s.sunrise),
      ('dhuhr', l10n.prayerDhuhr, Icons.wb_sunny_rounded, s.dhuhr),
      ('asr', l10n.prayerAsr, Icons.wb_cloudy_rounded, s.asr),
      ('maghrib', l10n.prayerMaghrib, Icons.nights_stay_outlined, s.maghrib),
      ('isha', l10n.prayerIsha, Icons.nights_stay_rounded, s.isha),
    ];

    return raw.map((r) {
      final key = r.$1;
      final time = r.$4;
      final _StationState st;
      if (key == s.nextName) {
        st = _StationState.next;
      } else if (time != null && now.isAfter(time)) {
        st = _StationState.past;
      } else {
        st = _StationState.future;
      }
      return _StationData(key: key, name: r.$2, icon: r.$3, time: time, state: st);
    }).toList();
  }

  String _headerText(BuildContext context) {
    final l10n = context.l10n;
    final s = widget.snapshot;
    if (s.nextName == 'sunrise') {
      return l10n.prayerTimelineSunriseNext(s.minutesUntil);
    }
    final name = switch (s.nextName) {
      'fajr' => l10n.prayerFajr,
      'dhuhr' => l10n.prayerDhuhr,
      'asr' => l10n.prayerAsr,
      'maghrib' => l10n.prayerMaghrib,
      'isha' => l10n.prayerIsha,
      _ => s.nextName,
    };
    return l10n.prayerTimelineNext(name, s.minutesUntil);
  }

  String _formattedTime(DateTime t, BuildContext context) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final min = t.minute.toString().padLeft(2, '0');
    final period = context.isArabic
        ? (t.hour >= 12 ? 'م' : 'ص')
        : (t.hour >= 12 ? 'PM' : 'AM');
    return '$hour12:$min $period';
  }

  void _openSheet(BuildContext context) {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    showHomePrayerTimesSheet(
      context,
      snapshot: widget.snapshot,
      hijriLabel: widget.hijriLabel,
      skin: widget.skin,
      now: widget.now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    final stations = _buildStations(context);
    final cityName = context.isArabic
        ? widget.snapshot.city.nameAr
        : widget.snapshot.city.nameEn;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Semantics(
        button: true,
        label: _headerText(context),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: skin.onHeroFill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: skin.onHeroBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header row ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _headerText(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          color: skin.textOnHero,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: skin.textOnHeroMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      cityName,
                      style: AppTypography.labelSmall.copyWith(
                        color: skin.textOnHeroMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // ── Timeline row ────────────────────────────────────────
                _TimelineRow(
                  stations: stations,
                  skin: skin,
                  pulse: _pulse,
                  minutesUntil: widget.snapshot.minutesUntil,
                  formatTime: (t) => _formattedTime(t, context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline row: orbital axis + 6 nodes
// ---------------------------------------------------------------------------

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.stations,
    required this.skin,
    required this.pulse,
    required this.minutesUntil,
    required this.formatTime,
  });

  final List<_StationData> stations;
  final HomeSkin skin;
  final AnimationController pulse;
  final int minutesUntil;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < stations.length; i++) ...[
          Expanded(
            child: _StationNode(
              data: stations[i],
              skin: skin,
              pulse: pulse,
              minutesUntil: minutesUntil,
              formatTime: formatTime,
            ),
          ),
          if (i < stations.length - 1)
            _AxisConnector(
              leftPast: stations[i].state == _StationState.past,
              rightPast: stations[i + 1].state == _StationState.past,
              skin: skin,
            ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Axis connector line between two adjacent nodes
// ---------------------------------------------------------------------------

class _AxisConnector extends StatelessWidget {
  const _AxisConnector({
    required this.leftPast,
    required this.rightPast,
    required this.skin,
  });

  final bool leftPast;
  final bool rightPast;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    // Align the connector with the icon center (icon is 22px, label is ~12px).
    // We push it down by roughly 10px so it bisects the icon vertically.
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: 6,
        height: 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (leftPast && rightPast)
                ? skin.textOnHeroMuted.withValues(alpha: 0.25)
                : skin.textOnHero.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual station node
// ---------------------------------------------------------------------------

class _StationNode extends StatelessWidget {
  const _StationNode({
    required this.data,
    required this.skin,
    required this.pulse,
    required this.minutesUntil,
    required this.formatTime,
  });

  final _StationData data;
  final HomeSkin skin;
  final AnimationController pulse;
  final int minutesUntil;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    final isPast = data.state == _StationState.past;
    final isNext = data.state == _StationState.next;
    final opacity = isPast ? 0.45 : (isNext ? 1.0 : 0.85);
    final iconSize = isNext ? 22.0 : 18.0;
    final iconColor = isPast
        ? skin.textOnHeroMuted
        : (isNext ? skin.gold : skin.textOnHero);

    final timeText = data.time != null ? formatTime(data.time!) : null;

    Widget iconWidget = Icon(data.icon, size: iconSize, color: iconColor);

    // Breathing glow only on the next node
    if (isNext) {
      iconWidget = AnimatedBuilder(
        animation: pulse,
        builder: (_, child) {
          // lerpDouble between 0.3 and 0.7 alpha for the halo
          final glowAlpha = 0.3 + 0.4 * pulse.value;
          return Container(
            width: iconSize + 14,
            height: iconSize + 14,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: skin.gold.withValues(alpha: glowAlpha),
                width: 1.5,
              ),
              color: skin.gold.withValues(alpha: glowAlpha * 0.18),
            ),
            child: child,
          );
        },
        child: iconWidget,
      );
    }

    return Semantics(
      label: '${data.name}${timeText != null ? " $timeText" : ""}'
          '${isNext ? " — ${context.l10n.homePrayerChip(data.name, minutesUntil)}" : ""}',
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 4),
            Text(
              data.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(
                color: isNext ? skin.gold : skin.textOnHero,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10,
              ),
            ),
            if (timeText != null) ...[
              const SizedBox(height: 2),
              Text(
                timeText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: skin.textOnHeroMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
