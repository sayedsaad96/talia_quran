# Celestial Prayer Timeline — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy `HomePrayerChip` capsule in the home screen header with a full-width, animated Celestial Prayer Timeline that shows all 6 daily prayer stations on an ambient orbital axis.

**Architecture:** A new self-contained `StatefulWidget` (`HomePrayerTimeline`) is created in the home feature's widgets directory. It receives `PrayerTimesSnapshot`, `HomeSkin`, `hijriLabel`, an optional `onTap`, and an injectable clock (`DateTime Function()? now`) for testability. `HomeNightHeader` removes `HomePrayerChip` from its chips `Wrap` and adds `HomePrayerTimeline` below it. Zero changes to `HomeCubit`, `PrayerTimesService`, or the Isar database.

**Tech Stack:** Flutter (Dart), `flutter_bloc`, `package:flutter_test`, existing `HomeSkin` / `AppSpacing` / `AppTypography` tokens, `flutter_localizations` (AR + EN), `dart analyze`.

---

## Global Constraints

- All new Dart files must pass `dart analyze` with zero warnings or errors.
- Use `HomeSkin` tokens exclusively for colors — no hard-coded `Color(0xFF...)` values in `HomePrayerTimeline`.
- Respect `MediaQuery.disableAnimationsOf(context)` — no `AnimationController` ticks when disabled.
- Localized strings via `context.l10n` only — no hard-coded Arabic or English strings in widget code.
- `PrayerTimesSnapshot` individual station times (`fajr`, `sunrise`, etc.) are `DateTime?` — hide time label when null; never crash.
- Sunrise node never shows the word "أذان" / "Adhan" in the header countdown.
- RTL/LTR is handled by Flutter's `Directionality`; avoid fixed `TextDirection`.
- Target file for new widget: `lib/features/home/presentation/widgets/home_prayer_timeline.dart`.
- Target test file: `test/features/home/presentation/widgets/home_prayer_timeline_test.dart`.

---

## File Map

| Status | File | Role |
|--------|------|------|
| **CREATE** | `lib/features/home/presentation/widgets/home_prayer_timeline.dart` | New timeline widget + sub-widgets |
| **MODIFY** | `lib/core/l10n/app_ar.arb` | Add 2 new l10n keys |
| **MODIFY** | `lib/core/l10n/app_en.arb` | Add 2 new l10n keys |
| **MODIFY** | `lib/features/home/presentation/widgets/home_night_header.dart` | Remove `HomePrayerChip`, wire `HomePrayerTimeline` |
| **CREATE** | `test/features/home/presentation/widgets/home_prayer_timeline_test.dart` | Widget tests |

---

## Task 1: Add l10n keys for the timeline header

**Files:**
- Modify: `lib/core/l10n/app_ar.arb`
- Modify: `lib/core/l10n/app_en.arb`

**Interfaces:**
- Produces: `context.l10n.prayerTimelineNext(String name, int minutes)` — used for standard prayers (Fajr, Dhuhr, Asr, Maghrib, Isha).
- Produces: `context.l10n.prayerTimelineSunriseNext(int minutes)` — used when `nextName == 'sunrise'` (no "Adhan" prefix).

- [ ] **Step 1: Add Arabic keys to `app_ar.arb`**

  Open `lib/core/l10n/app_ar.arb` and add these two entries near the existing `homePrayerChip` entry (around line 2091):

  ```json
  "prayerTimelineNext": "أذان {name} خلال {minutes} دقيقة",
  "@prayerTimelineNext": {
    "placeholders": {
      "name": { "type": "String" },
      "minutes": { "type": "int" }
    }
  },
  "prayerTimelineSunriseNext": "الشروق خلال {minutes} دقيقة",
  "@prayerTimelineSunriseNext": {
    "placeholders": {
      "minutes": { "type": "int" }
    }
  },
  ```

- [ ] **Step 2: Add English keys to `app_en.arb`**

  Open `lib/core/l10n/app_en.arb` and add near the existing `homePrayerChip` entry (around line 2151):

  ```json
  "prayerTimelineNext": "{name} in {minutes} min",
  "@prayerTimelineNext": {
    "placeholders": {
      "name": { "type": "String" },
      "minutes": { "type": "int" }
    }
  },
  "prayerTimelineSunriseNext": "Sunrise in {minutes} min",
  "@prayerTimelineSunriseNext": {
    "placeholders": {
      "minutes": { "type": "int" }
    }
  },
  ```

- [ ] **Step 3: Regenerate localizations**

  ```powershell
  flutter gen-l10n
  ```

  Expected: no errors, new methods `prayerTimelineNext` and `prayerTimelineSunriseNext` appear in `lib/core/l10n/app_localizations.dart`.

- [ ] **Step 4: Verify generated methods exist**

  ```powershell
  Select-String -Pattern "prayerTimelineNext|prayerTimelineSunriseNext" lib/core/l10n/app_localizations.dart
  ```

  Expected: 2 lines found (one per method abstract declaration).

- [ ] **Step 5: Commit**

  ```powershell
  git add lib/core/l10n/app_ar.arb lib/core/l10n/app_en.arb lib/core/l10n/app_localizations.dart lib/core/l10n/app_localizations_ar.dart lib/core/l10n/app_localizations_en.dart
  git commit -m "feat(l10n): add prayerTimelineNext and prayerTimelineSunriseNext keys"
  ```

---

## Task 2: Create `HomePrayerTimeline` widget

**Files:**
- Create: `lib/features/home/presentation/widgets/home_prayer_timeline.dart`

**Interfaces:**
- Consumes (Task 1): `context.l10n.prayerTimelineNext(name, minutes)`, `context.l10n.prayerTimelineSunriseNext(minutes)`
- Consumes: `PrayerTimesSnapshot` (fields: `nextName`, `nextTime`, `minutesUntil`, `city`, `fajr`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`), `HomeSkin`, `String hijriLabel`, `VoidCallback? onTap`, `DateTime Function()? now`
- Consumes: `showHomePrayerTimesSheet(context, snapshot: snapshot, hijriLabel: hijriLabel, skin: skin)` from `home_prayer_times_sheet.dart`
- Produces: `class HomePrayerTimeline extends StatefulWidget` — public, exported from this file.

- [ ] **Step 1: Create the file with the full widget implementation**

  Create `lib/features/home/presentation/widgets/home_prayer_timeline.dart` with the content below. Read it fully before creating — it defines the data model, the animation, the header row, the orbital axis line, and each station node.

  ```dart
  import 'dart:math' as math;

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
        if (!MediaQuery.disableAnimationsOf(context)) {
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
        ('fajr',    l10n.prayerFajr,    Icons.wb_twilight_rounded,     s.fajr),
        ('sunrise', l10n.prayerSunrise,  Icons.wb_sunny_outlined,       s.sunrise),
        ('dhuhr',   l10n.prayerDhuhr,   Icons.wb_sunny_rounded,        s.dhuhr),
        ('asr',     l10n.prayerAsr,     Icons.wb_cloudy_rounded,       s.asr),
        ('maghrib', l10n.prayerMaghrib, Icons.nights_stay_outlined,    s.maghrib),
        ('isha',    l10n.prayerIsha,    Icons.nights_stay_rounded,     s.isha),
      ];

      return raw.map((r) {
        final key  = r.$1;
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
        'fajr'    => l10n.prayerFajr,
        'dhuhr'   => l10n.prayerDhuhr,
        'asr'     => l10n.prayerAsr,
        'maghrib' => l10n.prayerMaghrib,
        'isha'    => l10n.prayerIsha,
        _         => s.nextName,
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
      showHomePrayerTimesSheet(
        context,
        snapshot: widget.snapshot,
        hijriLabel: widget.hijriLabel,
        skin: widget.skin,
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
      required this.formatTime,
    });

    final List<_StationData> stations;
    final HomeSkin skin;
    final AnimationController pulse;
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
      required this.formatTime,
    });

    final _StationData data;
    final HomeSkin skin;
    final AnimationController pulse;
    final String Function(DateTime) formatTime;

    @override
    Widget build(BuildContext context) {
      final isPast   = data.state == _StationState.past;
      final isNext   = data.state == _StationState.next;
      final opacity  = isPast ? 0.45 : (isNext ? 1.0 : 0.85);
      final iconSize = isNext ? 22.0 : 18.0;
      final iconColor = isPast ? skin.textOnHeroMuted : (isNext ? skin.gold : skin.textOnHero);

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
            '${isNext ? " — ${context.l10n.homePrayerChip(data.name, 0)}" : ""}',
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
  ```

- [ ] **Step 2: Run static analysis on the new file**

  ```powershell
  dart analyze lib/features/home/presentation/widgets/home_prayer_timeline.dart
  ```

  Expected: `No issues found!`

- [ ] **Step 3: Commit**

  ```powershell
  git add lib/features/home/presentation/widgets/home_prayer_timeline.dart
  git commit -m "feat(home): add HomePrayerTimeline widget with animated orbital axis"
  ```

---

## Task 3: Wire `HomePrayerTimeline` into `HomeNightHeader`

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_night_header.dart` (lines 1-78 affected)

**Interfaces:**
- Consumes (Task 2): `HomePrayerTimeline({required snapshot, required skin, required hijriLabel})`
- The existing `HomePrayerChip` class remains in the file (it may still be used by `HomeContextBar` — which is dead code — so we keep the class to avoid removing a potentially imported symbol; we only stop instantiating it from `HomeNightHeader.build`).

- [ ] **Step 1: Add import for `HomePrayerTimeline`**

  In `lib/features/home/presentation/widgets/home_night_header.dart`, the file already imports from the same directory. Add the import below the existing `home_prayer_times_sheet.dart` import:

  ```dart
  import 'home_prayer_timeline.dart';
  ```

- [ ] **Step 2: Remove `HomePrayerChip` from the chips list and add `HomePrayerTimeline` after the `Wrap`**

  Locate the `build` method of `HomeNightHeader` (roughly lines 26-78). Replace the existing body of `HomeNightHeader.build`:

  **Before:**
  ```dart
  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (state.occasion != HomeOccasion.none)
        _OccasionChip(occasion: state.occasion, skin: skin),
      if (state.prayerSnapshot != null)
        HomePrayerChip(
          snapshot: state.prayerSnapshot!,
          skin: skin,
          hijriLabel: state.hijriLabel,
        ),
      HomeAchievementChip(
        progress: state.progress,
        isKids: state.isKids,
        totalXp: state.totalXp,
        foreground: skin.textOnHero,
        background: skin.onHeroFill,
        border: skin.onHeroBorder,
      ),
    ];

    return HomeHeroBanner(
      skin: skin,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.4,
                child: _TopRow(state: state, skin: skin),
              ),
              const SizedBox(height: AppSpacing.sm),
              _BrandLockup(skin: skin),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: chips,
              ),
            ],
          ),
        ),
      ),
    );
  }
  ```

  **After:**
  ```dart
  @override
  Widget build(BuildContext context) {
    // Prayer chip is now the full-width HomePrayerTimeline below the Wrap.
    // Only occasion and achievement chips remain in the Wrap.
    final chips = <Widget>[
      if (state.occasion != HomeOccasion.none)
        _OccasionChip(occasion: state.occasion, skin: skin),
      HomeAchievementChip(
        progress: state.progress,
        isKids: state.isKids,
        totalXp: state.totalXp,
        foreground: skin.textOnHero,
        background: skin.onHeroFill,
        border: skin.onHeroBorder,
      ),
    ];

    return HomeHeroBanner(
      skin: skin,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.4,
                child: _TopRow(state: state, skin: skin),
              ),
              const SizedBox(height: AppSpacing.sm),
              _BrandLockup(skin: skin),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: chips,
              ),
              if (state.prayerSnapshot != null) ...[
                const SizedBox(height: AppSpacing.md),
                HomePrayerTimeline(
                  snapshot: state.prayerSnapshot!,
                  skin: skin,
                  hijriLabel: state.hijriLabel,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  ```

- [ ] **Step 3: Run static analysis on the modified file**

  ```powershell
  dart analyze lib/features/home/presentation/widgets/home_night_header.dart
  ```

  Expected: `No issues found!`

- [ ] **Step 4: Run full project analysis**

  ```powershell
  dart analyze lib/
  ```

  Expected: `No issues found!`

- [ ] **Step 5: Commit**

  ```powershell
  git add lib/features/home/presentation/widgets/home_night_header.dart
  git commit -m "feat(home): replace HomePrayerChip with HomePrayerTimeline in HomeNightHeader"
  ```

---

## Task 4: Write widget tests for `HomePrayerTimeline`

**Files:**
- Create: `test/features/home/presentation/widgets/home_prayer_timeline_test.dart`

**Interfaces:**
- Consumes (Task 2): `HomePrayerTimeline({required snapshot, required skin, required hijriLabel, now})`
- Consumes (Task 1): Arabic localized strings `الفجر`, `الشروق`, `الظهر`, `العصر`, `المغرب`, `العشاء`

- [ ] **Step 1: Create the test file**

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_localizations/flutter_localizations.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:talia_quran/core/l10n/app_localizations.dart';
  import 'package:talia_quran/core/services/prayer_times_service.dart';
  import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
  import 'package:talia_quran/features/home/presentation/widgets/home_prayer_timeline.dart';

  void main() {
    // ── shared fixtures ────────────────────────────────────────────────────────
    const city = PrayerCity(
      id: 'cairo',
      nameAr: 'القاهرة',
      nameEn: 'Cairo',
      latitude: 30.0444,
      longitude: 31.2357,
    );

    // now = 11:30 → Fajr (04:15) and Sunrise (05:40) are past; Dhuhr is next.
    final fixedNow = DateTime(2026, 9, 12, 11, 30);
    final snapshot = PrayerTimesSnapshot(
      city: city,
      nextName: 'dhuhr',
      nextTime: DateTime(2026, 9, 12, 11, 55),
      minutesUntil: 25,
      fajr: DateTime(2026, 9, 12, 4, 15),
      sunrise: DateTime(2026, 9, 12, 5, 40),
      dhuhr: DateTime(2026, 9, 12, 11, 55),
      asr: DateTime(2026, 9, 12, 15, 25),
      maghrib: DateTime(2026, 9, 12, 18, 5),
      isha: DateTime(2026, 9, 12, 19, 25),
    );

    Widget buildHarness({
      PrayerTimesSnapshot? snap,
      Locale locale = const Locale('ar'),
      DateTime Function()? now,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        locale: locale,
        home: Scaffold(
          body: HomePrayerTimeline(
            snapshot: snap ?? snapshot,
            skin: HomeSkin.forBrightness(Brightness.dark),
            hijriLabel: '٢٤ ربيع الأول ١٤٤٨',
            now: now ?? () => fixedNow,
          ),
        ),
      );
    }

    // ── tests ──────────────────────────────────────────────────────────────────

    testWidgets('renders all 6 station names in Arabic', (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pump();

      expect(find.text('الفجر'),   findsOneWidget);
      expect(find.text('الشروق'), findsOneWidget);
      expect(find.text('الظهر'),   findsOneWidget);
      expect(find.text('العصر'),   findsOneWidget);
      expect(find.text('المغرب'),  findsOneWidget);
      expect(find.text('العشاء'),  findsOneWidget);
    });

    testWidgets('renders all 6 station names in English', (tester) async {
      await tester.pumpWidget(buildHarness(locale: const Locale('en')));
      await tester.pump();

      expect(find.text('Fajr'),    findsOneWidget);
      expect(find.text('Sunrise'), findsOneWidget);
      expect(find.text('Dhuhr'),   findsOneWidget);
      expect(find.text('Asr'),     findsOneWidget);
      expect(find.text('Maghrib'), findsOneWidget);
      expect(find.text('Isha'),    findsOneWidget);
    });

    testWidgets('city name is visible', (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pump();
      expect(find.text('القاهرة'), findsOneWidget);
    });

    testWidgets('header shows next prayer countdown (dhuhr, 25 min)', (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pump();
      // prayerTimelineNext AR: "أذان الظهر خلال 25 دقيقة"
      expect(find.textContaining('الظهر'), findsWidgets);
      expect(find.textContaining('25'), findsWidgets);
    });

    testWidgets('header uses sunrise-specific text when nextName is sunrise',
        (tester) async {
      final sunriseSnap = PrayerTimesSnapshot(
        city: city,
        nextName: 'sunrise',
        nextTime: DateTime(2026, 9, 12, 5, 40),
        minutesUntil: 10,
        fajr: DateTime(2026, 9, 12, 4, 15),
        sunrise: DateTime(2026, 9, 12, 5, 40),
        dhuhr: DateTime(2026, 9, 12, 11, 55),
        asr: DateTime(2026, 9, 12, 15, 25),
        maghrib: DateTime(2026, 9, 12, 18, 5),
        isha: DateTime(2026, 9, 12, 19, 25),
      );
      // now = 05:30, sunrise is next
      await tester.pumpWidget(
        buildHarness(snap: sunriseSnap, now: () => DateTime(2026, 9, 12, 5, 30)),
      );
      await tester.pump();
      // Header should NOT contain "أذان" for sunrise
      final headerWidgets = tester.widgetList<Text>(find.textContaining('الشروق'));
      for (final t in headerWidgets) {
        expect(t.data?.contains('أذان'), isFalse,
            reason: 'Sunrise header must not contain "أذان"');
      }
    });

    testWidgets('past stations are rendered with low opacity', (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pump();

      // Fajr and Sunrise are past. Find their Opacity widgets.
      // We look for Opacity widgets with value 0.45 — there should be exactly 2
      // (one for Fajr, one for Sunrise).
      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .where((o) => (o.opacity - 0.45).abs() < 0.01)
          .toList();
      expect(opacities.length, 2,
          reason: 'Fajr and Sunrise should be the only past stations');
    });

    testWidgets('tapping the timeline does not crash', (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pump();

      // The widget is wrapped in a GestureDetector; tapping it opens the sheet.
      // In test environment Navigator.push is unavailable by default — we simply
      // verify no exception is thrown on tap.
      await tester.tap(find.byType(HomePrayerTimeline));
      await tester.pumpAndSettle();
      // No exception = pass
    });

    testWidgets('renders without overflow on narrow screen (320 px wide)',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(buildHarness());
      await tester.pump();

      // Expect no RenderFlex overflow errors logged
      expect(tester.takeException(), isNull);
    });

    testWidgets('no AnimationController errors when animations are disabled',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: buildHarness(),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
  ```

- [ ] **Step 2: Run the tests (expect all to pass)**

  ```powershell
  flutter test test/features/home/presentation/widgets/home_prayer_timeline_test.dart --reporter expanded
  ```

  Expected: all tests pass (`All tests passed!`). Fix any failures before continuing.

- [ ] **Step 3: Commit**

  ```powershell
  git add test/features/home/presentation/widgets/home_prayer_timeline_test.dart
  git commit -m "test(home): add widget tests for HomePrayerTimeline"
  ```

---

## Task 5: Final static analysis & verification

**Files:** (none new — read-only pass)

- [ ] **Step 1: Full project analysis**

  ```powershell
  dart analyze lib/
  ```

  Expected: `No issues found!`

- [ ] **Step 2: Run all home widget tests**

  ```powershell
  flutter test test/features/home/ --reporter expanded
  ```

  Expected: all pass.

- [ ] **Step 3: Hot-reload or run app and verify visually**

  Connect to the running device / emulator and confirm:
  - The home header shows the new celestial timeline strip below the chips row.
  - The next prayer node glows with a pulsing gold halo.
  - Past prayer nodes appear dimmed.
  - Tapping the strip opens the `HomePrayerTimesSheet`.
  - The `HomePrayerChip` capsule is gone from the chips row.

- [ ] **Step 4: Final commit (tag if desired)**

  ```powershell
  git add -A
  git commit -m "feat(home): celestial prayer timeline — all tasks complete"
  ```
