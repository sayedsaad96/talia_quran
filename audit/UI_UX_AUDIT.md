# UI/UX Audit Report — Talia Quran

> This report was produced from a fresh independent audit of the current application state. Previous audits, issue lists, scores, and recommendations were excluded from the discovery and evidence process.

---

## 1. Executive Summary

This fresh audit evaluated the live Talia Quran application across onboarding, navigation, the home dashboard, reading, memorization, and settings. 

The application demonstrates exceptional typography (Amiri & Naskh), reverent Islamic aesthetics, clean Tajweed rendering via QCF fonts, and thoughtful RTL care. However, runtime inspection and live device profiling revealed **two objective P1 defects** (inverted string parameters and double-flipped chevrons), alongside several layout and density improvements.

---

## 2. Findings Matrix

| Finding ID | Feature / Screen | Problem Summary | Severity | Effort | Classification |
|---|---|---|---|---|---|
| `AUD-UX-001` | Home — Daily Wird Card | Inverted Surah name and Page number in string localization | **P1** | Low | Objective Defect |
| `AUD-UX-002` | Global (11+ screens) | Double-flipped navigation chevrons pointing backwards in RTL | **P1** | Low | Objective Defect |
| `AUD-UX-003` | Onboarding (Steps 1 & 2) | Hard rectangular shader artifact at screen bottom | **P2** | Low | Objective Visual Defect |
| `AUD-UX-004` | Home Dashboard | Duplicate "الورد اليومي" cards rendered simultaneously | **P2** | Med | Product / Design Decision |
| `AUD-UX-005` | Home — Quick Actions | Asymmetrical 3-column grid leaving orphan card in row 2 | **P2** | Low | Product / Design Decision |
| `AUD-UX-006` | Quran Reader Top Bar | Dense button clustering on narrow viewports | **P2** | Med | Responsive / Usability Polish |
| `AUD-A11Y-001`| Home — Level Badge | Low contrast gray text on light theme for beginner level | **P2** | Low | A11y / Contrast |

---

## 3. Detailed Findings

### AUD-UX-001: Inverted Surah Name and Page Number in Daily Wird Card
- **Screen / Feature**: Home Page (`lib/features/home/presentation/pages/home_page_widgets.dart:340`)
- **Problem**: The Daily Wird card displays:
  - `سورة 313 — صفحة طه` (instead of `سورة طه — صفحة 313`)
  - `سورة 93 — صفحة النساء` (instead of `سورة النساء — صفحة 93`)
- **Evidence**:
  - Live runtime screenshot `screen_after_onboarding.png` and `screen_home_restored.png`.
  - In `lib/core/l10n/app_localizations_ar.dart:2935`, Flutter gen-l10n generated:
    ```dart
    String homeDailyWirdSurahPage(Object page, Object surah);
    ```
    (Ordered alphabetically: `{page}` first, `{surah}` second).
  - In `home_page_widgets.dart:340`, the caller passed:
    ```dart
    wird = context.l10n.homeDailyWirdSurahPage(surahName, pageNumber.toString());
    ```
- **User Impact**: Direct misinformation on the primary Quran reader card on the home screen.
- **Severity**: **P1 — Should fix before release**
- **Recommended Action**: Invert the argument order to:
  ```dart
  wird = context.l10n.homeDailyWirdSurahPage(pageNumber.toString(), surahName);
  ```
- **Implementation Effort**: Low (< 5 minutes).
- **Product / Design Decision**: No (Objective Bug).

---

### AUD-UX-002: Double-Flipped Navigation Chevrons in RTL Across the App
- **Screen / Feature**: 11+ presentation files:
  - `lib/features/quran/presentation/pages/quran_page.dart:469`
  - `lib/features/home/presentation/pages/home_page_widgets.dart:408`
  - `lib/features/home/presentation/widgets/unified_hero_action_card.dart:113`
  - `lib/features/settings/presentation/widgets/settings_section.dart:222`
  - `lib/features/azkar/presentation/pages/azkar_page.dart:409`
  - `lib/features/memorization_plus/presentation/widgets/practice_surah_tile.dart:100`
  - `lib/features/memorization_plus/presentation/pages/memorization_hub_page.dart:659, 780`
- **Problem**: Forward navigation disclosure chevrons point to the **RIGHT** (`>`) instead of pointing **LEFT** (`<`) in Arabic RTL layout.
- **Evidence**:
  - Runtime verification on live emulator (`screen_quran_tab.png`).
  - In Flutter's `MaterialIcons`, `Icons.arrow_back_ios_new_rounded` is defined with:
    `matchTextDirection: true`
  - When Flutter renders an icon with `matchTextDirection: true` in an RTL context, it automatically mirrors the icon horizontally.
  - The codebase repeatedly uses:
    ```dart
    Icon(context.isArabic ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded)
    ```
    Because the author swapped the icon manually AND Flutter mirrors it automatically, the icon is flipped twice, resulting in a chevron that points backwards.
- **User Impact**: Navigation cues point in the opposite direction of the navigation hierarchy in Arabic.
- **Severity**: **P1 — Should fix before release**
- **Recommended Action**: Remove the ternary check and use `Icons.arrow_forward_ios_rounded` (or unmirrored directional icon constants) so that Flutter's natural text direction mirroring points forward (left in RTL, right in LTR).
- **Implementation Effort**: Low (Uniform refactor across 11 files).
- **Product / Design Decision**: No (Objective Defect).

---

### AUD-UX-003: Rectangular Shader Artifact at Bottom of Onboarding Scene
- **Screen / Feature**: Onboarding (`lib/features/onboarding/presentation/widgets/onboarding_night_scene.dart:80-98`)
- **Problem**: A visible dark rectangle (130×190 logical pixels) appears at the bottom center of the Onboarding screen.
- **Evidence**:
  - Live screenshots `screen_launch.png` and `screen_onboarding_step2.png`.
  - `_PathOfLight` widget defines:
    ```dart
    SizedBox(
      width: 130,
      height: 190,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          gradient: RadialGradient(
            center: Alignment(0, 1.15),
            radius: 0.95,
            colors: [Color(0x2EF59E0B), Color(0x00F59E0B)],
          ),
        ),
      ),
    )
    ```
  - On standard Android GPU / OpenGL ES pipelines, this clamped box does not smoothly fade to transparent, creating sharp visible edges.
- **User Impact**: First visual impression of the application contains an unpolished graphical boundary.
- **Severity**: **P2 — Important improvement**
- **Recommended Action**: Use a full-width container with a `LinearGradient` or soften gradient boundaries with a `ShaderMask`.
- **Implementation Effort**: Low.
- **Product / Design Decision**: No (Visual Defect).

---

### AUD-UX-004: Duplicate Daily Wird Cards on Home Screen
- **Screen / Feature**: Home Page (`lib/features/home/presentation/pages/home_page.dart:184-277`)
- **Problem**: On initial launch and when no other urgent smart recommendation is pending, `heroAction` defaults to `dailyReading`. Consequently, the home screen renders:
  1. `UnifiedHeroActionCard`: "الورد اليومي — اقرأ وردك اليومي"
  2. `KhatmahHeroCard`: "ابدأ ختمة"
  3. `_DailyWirdCard`: "الورد اليومي — سورة ... صفحة ..."
- **Evidence**: Verified live on device in `screen_after_onboarding.png` and `screen_home_restored.png`.
- **User Impact**: Visual redundancy and confusing hierarchy (two different cards with the same title "الورد اليومي" separated by the Khatmah card).
- **Severity**: **P2 — Important improvement**
- **Recommended Action**: When `state.heroAction?.actionType == UnifiedJourneyActionType.dailyReading`, suppress the redundant `_DailyWirdCard`, or incorporate the specific surah/page metadata directly into `UnifiedHeroActionCard`.
- **Implementation Effort**: Medium.
- **Product / Design Decision**: **PRODUCT / DESIGN DECISION**
  - *Option A*: Suppress `_DailyWirdCard` when hero card is Daily Reading.
  - *Option B*: Let `UnifiedHeroActionCard` show specific page details and remove `_DailyWirdCard` entirely.
  - *Tradeoff*: Option B simplifies the home feed while keeping the single primary call-to-action focused.

---

### AUD-UX-005: Asymmetrical Quick Actions Grid with Orphan Item
- **Screen / Feature**: Home Page (`lib/features/home/presentation/pages/home_page_widgets.dart:740`)
- **Problem**: `GridView.extent(maxCrossAxisExtent: 190)` on standard phone viewports (~400dp width) resolves to 3 columns. Because there are exactly 4 action cards, Row 1 has 3 items and Row 2 has 1 item pinned to the right edge with empty space on the left.
- **Evidence**: Verified in runtime screenshot `screen_home_scroll1.png`.
- **User Impact**: Unbalanced, incomplete visual feel at the bottom of the Home screen.
- **Severity**: **P2 — Important improvement**
- **Recommended Action**: Replace `GridView.extent` with a 2-column grid (`crossAxisCount: 2`) on mobile devices, expanding to 4 columns on tablets/wide screens (`context.screenWidth >= 600`).
- **Implementation Effort**: Low.
- **Product / Design Decision**: **PRODUCT / DESIGN DECISION**.

---

### AUD-UX-006: Dense Action Cluster in Quran Reader Top Bar
- **Screen / Feature**: Quran Reader (`lib/features/quran/presentation/pages/quran_reader_page.dart:715-794`)
- **Problem**: The reader top bar packs 5 interactive controls into a single row on the trailing side: Surah Name, Audio Play/Pause, Reciter Selector, Focus Mode, and Close button. On screens under 360dp or with accessibility text scaling (> 1.2x), the Surah name can truncate or controls touch targets can become compressed.
- **Severity**: **P2 — Important improvement**
- **Recommended Action**: Consolidate secondary audio actions (reciter selection) into the audio player bottom sheet or mini-player, keeping the top bar minimal (Surah Name, Audio, Fullscreen, Close).
- **Implementation Effort**: Medium.
- **Product / Design Decision**: **PRODUCT / DESIGN DECISION**.
