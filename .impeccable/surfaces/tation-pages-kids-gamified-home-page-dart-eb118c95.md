---
version: 1
slug: "tation-pages-kids-gamified-home-page-dart-eb118c95"
primary_target: "lib/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart"
related_targets: ["lib/features/memorization_plus/presentation/widgets/kids_home_navigation_cards.dart"]
---

# Kids home navigation cards

Scope: Replace the children home bottom navigation with in-page destinations. Operate mode, Arabic-first mobile, existing day/night adventure world.

User decision: Three square cards beside each other inside the page: Mushaf, My journey, Missions, reducing navigation height. Retain the current mission as the main action and existing destination behavior.

## Direction contract

THESIS: Navigation becomes a set of discoverable destinations beneath the main mission, inside the child's world. The home screen itself replaces the redundant Home tab.

OWN-WORLD: Reuse KidsTheme parchment, green accents, card corners, Arabic typography and the existing day/night landscape. No new illustration assets or visual identity.

STORY: The child sees today's learning first, then chooses reading, exploring their journey, or continuing missions through large labeled cards.

FIRST VIEWPORT: Progress and Talia retain their positions. The mission retains its primary button. Immediately below it, three equal square navigation cards sit in one row before the daily mission tiles. Each has an icon above its full label. Very narrow screens and enlarged text reflow to fewer columns without clipping labels.

FORM: Local extension of an established surface, pinned by the user; concept seed is not applicable. Square cards use native tap/focus feedback and accessible button semantics. Three columns at normal mobile widths; fewer columns when required for readable text.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

Verification: focused widget tests, static analysis, refreshed home day/night previews and scoped Android runtime checks where available. Keep Quran content, progress storage, routes and navigation guards unchanged.

## Verification record — 2026-10-02

- Three equal square cards occupy one row at default mobile text size; enlarged text reflows to fewer columns.
- 46 focused home/navigation, Arabic narrow-layout and companion tests passed. Four home day/night preview captures passed and were refreshed.
- Static analysis of all six modified Dart files passed; formatting and diff whitespace checks passed.
- Android runtime remains unverified: debug APK generation stopped before app compilation with a Java NIO local socket error (`Unable to establish loopback connection`). Existing emulator APK is stale and was not used as evidence for this change.
- This local extension reuses existing KidsTheme and localized destination labels; DESIGN.md retains the existing visual system.
- Finish review verdict: ship at the source/widget-fixture scope. Documentation consistency checked; no system-level changes required. Android runtime remains outside the verified scope.
