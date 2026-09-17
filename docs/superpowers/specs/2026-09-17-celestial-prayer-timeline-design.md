# Celestial Prayer Timeline Design

**Date:** 2026-09-17  
**Status:** Approved  
**Topic:** Reimagining Prayer Times display on Home Screen (Celestial Sun-Path Timeline)

---

## 1. Overview & Problem Statement

Currently, the Talia Quran home screen displays prayer times as a small, compact chip (`HomePrayerChip`) inside a `Wrap` alongside occasion and achievement badges in `HomeNightHeader`. This legacy presentation has several limitations:
1. **Limited Context:** It only displays the next upcoming prayer and its remaining minutes, offering zero awareness of previous or remaining prayers in the day without opening a modal bottom sheet.
2. **Generic Container Feel:** It resembles a static tag rather than a prominent, spiritual, and aesthetic focal point of the daily Muslim rhythm.
3. **Aesthetic Potential:** The home screen header (`HomeHeroBanner` / `HomeNightHeader`) has a celestial night theme that naturally accommodates an astronomical, sun-path timeline.

The goal of this design is to replace the legacy prayer chip with a dedicated, aesthetic **Celestial Prayer Timeline** (`HomePrayerTimeline`) that displays the 6 stations of the day (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) connected across an ambient astronomical axis.

---

## 2. Visual & Interaction Design

### 2.1 Timeline Anatomy
The `HomePrayerTimeline` consists of:

1. **Header Row (Next Prayer & Countdown):**
   - Leading (RTL Start): Next prayer title with countdown highlight.
     - Standard prayers: e.g., `أذان العصر خلال 25 دقيقة`.
     - Sunrise (no Adhan): e.g., `الشروق خلال 12 دقيقة` — no "أذان" prefix used.
   - Trailing (RTL End): Current city name (`snapshot.city.nameAr` / `.nameEn`) and a subtle icon to open the detailed sheet.

2. **The Celestial Axis (Orbital Path):**
   - A delicate horizontal connection line between the 6 prayer nodes:
     - **Passed Segment:** Muted/translucent styling indicating elapsed time.
     - **Active Highlight:** Subtle glowing accent at the next prayer station.
     - **Upcoming Segment:** Crisp, softly illuminated path.

3. **Six Prayer Stations (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha):**
   - Each station displays:
     - Prayer station icon (`Icons.wb_twilight_rounded` for Fajr, `Icons.wb_sunny_outlined` for Sunrise, `Icons.wb_sunny_rounded` for Dhuhr, `Icons.wb_cloudy_rounded` for Asr, `Icons.nights_stay_outlined` for Maghrib, `Icons.nights_stay_rounded` for Isha).
     - Station name (localized via `context.l10n`).
     - Formatted 12-hour time (e.g., `3:45`) — null-safe, hidden if station time is null.
   - **Station States** (determined by comparing station time to `DateTime.now()`):
     - `past`: Muted icon and text, dimmed opacity (0.45), indicating prayer has passed.
     - `next`: Enlarged node with soft glowing halo border (uses `skin.gold`), full opacity (1.0), bold text.
     - `future`: Standard active styling, normal opacity (0.85).

4. **Ambient Color Palette (V1):**
   - The timeline uses `HomeSkin` tokens throughout — `skin.textOnHero`, `skin.onHeroFill`, `skin.onHeroBorder`, `skin.gold`, `skin.textOnHeroMuted` — ensuring automatic adaptation to both dark and light themes.
   - **Time-of-day gradient backgrounds** (mapping period colors such as dawn-blue → noon-gold → sunset-rose → night-navy) are **deferred to V2** to keep V1 scope minimal and testable.

### 2.2 Micro-Interactions & Ambient Motion
- **Breathing Glow:** The `next` prayer node features a gentle, periodic breathing pulse implemented with an `AnimationController` (repeat + reverse).
- **Accessibility Respect:** When `MediaQuery.disableAnimationsOf(context)` is `true`, all animations and pulses are disabled, rendering clean static styling.
- **Full Sheet Navigation:** Tapping anywhere on the timeline (or any individual station node) invokes `showHomePrayerTimesSheet(context, snapshot: snapshot, hijriLabel: hijriLabel, skin: skin)`, preserving full compatibility with notifications, settings, and Azkar shortcuts.

### 2.3 Responsiveness & Accessibility
- Uses `Row` with `Expanded` equal-weight distribution across the 6 nodes.
- On narrow devices or when `MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3`, the timeline constrains text scaling via `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.2)` to prevent `RenderFlex` overflow.
- Full `Semantics` coverage: the widget wraps each node in a `Semantics` label describing the prayer name, its time, and its state (next / past / upcoming).

---

## 3. Architecture & Data Flow

### 3.1 Component Boundaries

- **New Widget:** `lib/features/home/presentation/widgets/home_prayer_timeline.dart`
  - Encapsulates layout, animations, node state determination, and styling.
  - Constructor parameters:
    ```dart
    HomePrayerTimeline({
      required PrayerTimesSnapshot snapshot,
      required HomeSkin skin,
      required String hijriLabel,
      VoidCallback? onTap,
      DateTime Function()? now,   // injectable clock for testability
    })
    ```
  - Determines past/next/future state internally using `now?.call() ?? DateTime.now()`.

- **Modified Widget:** `lib/features/home/presentation/widgets/home_night_header.dart`
  - `HomePrayerChip` is **removed** from the chips `Wrap` in `HomeNightHeader`.
  - The `Wrap` continues to show non-prayer chips only (occasion chip, achievement chip).
  - `HomePrayerTimeline` is added as a new child **after** the chips `Wrap` inside the existing `Column`, separated by `SizedBox(height: AppSpacing.md)`.

- **`HomeContextBar` (`_PrayerCapsule`) — no changes needed:**
  - `HomeContextBar` and its private `_PrayerCapsule` widget exist in `home_context_bar.dart` but are **not used anywhere** in `home_page.dart` or any other page. They will be left untouched by this feature; a separate cleanup task can remove the dead code if desired.

- **Data Source:**
  - Uses the existing `state.prayerSnapshot` (`PrayerTimesSnapshot?`) from `HomeLoaded`, calculated by `PrayerTimesService`. Fields used: `nextName`, `nextTime`, `minutesUntil`, `city`, `fajr`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`.
  - **Zero changes** required to `HomeCubit`, `HomeSkin`, `PrayerTimesService`, or any Isar collection.

### 3.2 Error & Null Handling
- If `state.prayerSnapshot == null`, the call site in `HomeNightHeader` simply skips rendering the timeline (`if (state.prayerSnapshot != null) HomePrayerTimeline(...)`), taking no space.
- Individual station times (`fajr`, `dhuhr`, etc.) are `DateTime?` — if null, the station hides its time label rather than crashing.
- Localized strings are sourced exclusively from `context.l10n`.
- Handles both RTL (Arabic) and LTR (English) layouts naturally via `Directionality`.

---

## 4. Verification & Testing

1. **Widget Tests** — `test/features/home/presentation/widgets/home_prayer_timeline_test.dart`:
   - Correct rendering of all 6 station nodes.
   - Accurate `next` state highlighting when `snapshot.nextName == 'asr'` etc.
   - `past` dimming for stations whose time is before the injected `now`.
   - Tapping the timeline triggers the `showHomePrayerTimesSheet` callback.
   - Graceful rendering under constrained widths (e.g., `SizedBox(width: 320)`).
   - No animation controller errors when `MediaQuery.disableAnimationsOf` is `true`.

2. **Static Analysis:**
   - Run `dart analyze` to ensure zero warnings or lint errors after the change.
