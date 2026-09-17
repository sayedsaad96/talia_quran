# Celestial Prayer Timeline Design

**Date:** 2026-09-17  
**Status:** Approved  
**Topic:** Reimagining Prayer Times display on Home Screen (Celestial Sun-Path Timeline)

---

## 1. Overview & Problem Statement

Currently, the Talia Quran home screen displays prayer times as a small, compact chip (`HomePrayerChip`) inside a `Wrap` alongside occasion and achievement badges. This legacy presentation has several limitations:
1. **Limited Context:** It only displays the next upcoming prayer and its remaining minutes, offering zero awareness of previous or remaining prayers in the day without opening a modal bottom sheet.
2. **Generic Container Feel:** It resembles a static tag rather than a prominent, spiritual, and aesthetic focal point of the daily Muslim rhythm.
3. **Aesthetic Potential:** The home screen header (`HomeHeroBanner` / `HomeNightHeader`) has a celestial night theme that naturally accommodates an astronomical, sun-path timeline.

The goal of this design is to replace the legacy prayer chip with a dedicated, aesthetic **Celestial Prayer Timeline** (`HomePrayerTimeline`) that displays the 6 stations of the day (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) connected across an ambient astronomical axis.

---

## 2. Visual & Interaction Design

### 2.1 Timeline Anatomy
The `HomePrayerTimeline` consists of:
1. **Header Row (Next Prayer & Countdown):**
   - Left / Leading (RTL Start): Next prayer title with countdown highlight (e.g., `أذان العصر خلال 25 دقيقة`).
   - Right / Trailing (RTL End): Current city location and an interactive indicator to open the detailed sheet.
2. **The Celestial Axis (Orbital Path):**
   - A delicate horizontal connection line between the 6 prayer nodes:
     - **Passed Segment:** Muted/translucent styling indicating elapsed time.
     - **Active Highlight:** Subtle glowing accent at the next prayer station.
     - **Upcoming Segment:** Crisp, softly illuminated path.
3. **Six Prayer Stations (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha):**
   - Each station displays:
     - Prayer station icon (`Icons.wb_twilight_rounded`, `Icons.wb_sunny_outlined`, etc.).
     - Station name (localized).
     - Formatted 12-hour time (e.g., `3:45`).
   - **Station States:**
     - `past`: Muted icon and text, dimmed opacity (0.45), indicating prayer has passed.
     - `next`: Enlarged node with soft glowing halo border (golden/emerald accent), full opacity (1.0), bold text.
     - `future`: Standard active styling, normal opacity (0.85).

### 2.2 Micro-Interactions & Ambient Motion
- **Breathing Glow:** The active/next prayer node features a gentle, periodic breathing pulse.
- **Accessibility Respect:** When `MediaQuery.disableAnimationsOf(context)` is true, animations and pulses are disabled, rendering clean static styling.
- **Full Sheet Navigation:** Tapping anywhere on the timeline or on any individual station invokes `showHomePrayerTimesSheet`, maintaining compatibility with notifications, settings, and Azkar shortcuts.

### 2.3 Responsiveness & Accessibility
- Uses responsive horizontal distribution across the 6 items.
- On narrow devices or when text scaling exceeds 1.3x (`MediaQuery.textScalerOf(context)`), the timeline gracefully scrolls horizontally or clamps scaling, ensuring zero `RenderFlex` overflow errors.
- Full `Semantics` coverage providing accessible voiceover descriptions of the active prayer, remaining time, and prayer station details.

---

## 3. Architecture & Data Flow

### 3.1 Component Boundaries
- **New Widget:** `lib/features/home/presentation/widgets/home_prayer_timeline.dart`
  - Encapsulates layout, animations, node state determination, and styling.
  - Takes `PrayerTimesSnapshot snapshot`, `HomeSkin skin`, `String hijriLabel`, and optional `VoidCallback? onTap`.
- **Modified Widget:** `lib/features/home/presentation/widgets/home_night_header.dart`
  - Removes `HomePrayerChip` from the small badges `Wrap`.
  - Embeds `HomePrayerTimeline` beneath the brand lockup/badges.
- **Data Source:**
  - Uses the existing `state.prayerSnapshot` from `HomeLoaded`, calculated by `PrayerTimesService`.
  - Zero changes required to `HomeCubit`, `PrayerTimesService`, or Isar database.

### 3.2 Error & Null Handling
- If `state.prayerSnapshot == null`, `HomePrayerTimeline` returns `SizedBox.shrink()` without taking space.
- Localized strings are sourced from `context.l10n`.
- Handles both RTL (Arabic) and LTR (English) layouts naturally.

---

## 4. Verification & Testing

1. **Unit & Widget Tests:**
   - Create `test/features/home/presentation/widgets/home_prayer_timeline_test.dart` to verify:
     - Correct rendering of all 6 stations.
     - Accurate highlighting of the next prayer node.
     - Interaction triggering the detailed prayer sheet callback.
     - Graceful rendering under constrained widths and disabled animations.
2. **Static Analysis:**
   - Run `dart analyze` to ensure zero warnings or lint errors.
