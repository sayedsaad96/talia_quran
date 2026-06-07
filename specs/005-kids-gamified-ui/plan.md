# Implementation Plan: Kids Gamified Memorization UI (واجهة الحفظ المُلعبة للأطفال)

**Branch**: `005-kids-gamified-ui` | **Date**: 2026-06-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/005-kids-gamified-ui/spec.md`

## Summary

Redesign the Kids Memorization Path presentation layer with a gamified, child-friendly UI inspired by a provided reference design. The new UI replaces the current flat list/card-based kids journey (`KidsJourneyPage`) and listen screen (`KidsModePage`) with an illustrated journey map featuring "memorization houses" (بيوت الحفظ) connected by a curved path, a detailed stage screen with mission steps, and a celebratory completion flow.

**Scope**: Presentation layer only (P1+P2 user stories). No domain/data model changes. Existing cubits and use cases are reused as-is. A runtime-readable feature flag enables rollback to the old UI on subsequent kids-path navigation without app restart.

## Technical Context

**Language/Version**: Dart ≥ 3.4 / Flutter ≥ 3.22

**Primary Dependencies**: flutter_bloc, go_router, just_audio, flutter_animate, equatable, get_it

**Storage**: Isar (existing, unchanged), SharedPreferences (feature flag)

**Testing**: flutter_test, bloc_test, mocktail

**Target Platform**: Android / iOS (mobile-first, RTL Arabic)

**Project Type**: Mobile app (Flutter)

**Performance Goals**: Journey map loads in <2 seconds on mid-range devices; 60fps scrolling

**Constraints**: Offline-capable; Arabic RTL-first; no adult path side effects; Quran text rendering must use Uthmani fonts

**Scale/Scope**: 5 new pages, 7 new widgets, 1 theme file, 1 config file, localization updates

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Architecture (Feature-First) | ✅ PASS | All new code under `features/memorization_plus/presentation/`. No domain/data changes. No cross-feature imports. |
| II. BLoC / Cubit State Management | ✅ PASS | Reuses existing `KidsJourneyCubit` and `KidsModeCubit`. No new cubits needed. No `setState` for business logic. |
| III. Test-Driven Quality | ✅ PASS | Widget tests will be written for all new pages. Existing cubit tests remain valid. |
| IV. Offline-First & Performance | ✅ PASS | No network calls added. All data comes from existing local Isar sources. Images are bundled assets. |
| V. Localisation & Accessibility | ✅ PASS | All new strings externalized in .arb files. Arabic RTL-first. Touch targets ≥ 48dp. Amiri font for Quranic text. |
| Technology Stack | ✅ PASS | No new packages. All approved technologies: flutter_bloc, go_router, flutter_animate, just_audio. |
| Development Workflow | ✅ PASS | Spec → Plan → Tasks → Implementation. Feature branch `005-kids-gamified-ui`. |

**Post-Phase 1 Re-check**: All gates still pass. No violations detected.

## Project Structure

### Documentation (this feature)

```text
specs/005-kids-gamified-ui/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 — codebase audit & decisions
├── data-model.md        # Phase 1 — entity mapping
├── quickstart.md        # Phase 1 — implementation quickstart
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
lib/features/memorization_plus/
├── domain/                          # UNCHANGED — no modifications
│   ├── entities/
│   │   └── memorization_entities.dart   # KidsProgress, KidsJourneyStage, etc.
│   ├── repositories/
│   └── usecases/
├── data/                            # UNCHANGED — no modifications
│   ├── datasources/
│   ├── models/
│   └── repositories/
└── presentation/
    ├── cubits/                      # UNCHANGED — reuse existing cubits
    │   ├── kids_journey_cubit.dart
    │   ├── kids_journey_state.dart
    │   ├── kids_mode_cubit.dart
    │   └── kids_mode_state.dart
    ├── theme/                       # NEW — kids gamified theme
    │   └── kids_theme.dart
    ├── widgets/                     # NEW — reusable gamified widgets
    │   ├── kids_journey_map.dart
    │   ├── kids_house_card.dart
    │   ├── kids_progress_header.dart
    │   ├── kids_mission_card.dart
    │   ├── kids_stage_details.dart
    │   ├── kids_reward_dialog.dart
    │   └── kids_ayah_card.dart
    └── pages/
        ├── kids_journey_page.dart          # EXISTING — kept as fallback
        ├── kids_mode_page.dart             # EXISTING — kept as fallback
        ├── kids_gamified_config.dart        # NEW — feature flag
        ├── kids_gamified_home_page.dart     # NEW — home screen (US-2)
        ├── kids_gamified_journey_page.dart  # NEW — journey map (US-1)
        ├── kids_gamified_stage_page.dart    # NEW — stage details (US-3)
        ├── kids_gamified_listen_page.dart   # NEW — listen & repeat (US-4)
        └── kids_gamified_completion_page.dart # NEW — celebration (US-5)

assets/images/kids/                  # NEW — gamified illustrations
├── house_completed.png
├── house_current.png
├── house_locked.png
├── house_review.png
├── kid_avatar.png
├── path_decoration.png
├── ribbon_banner.png
└── star_reward.png

lib/core/
├── router/app_router.dart           # MODIFY — add feature flag routing
└── l10n/
    ├── app_ar.arb                   # MODIFY — add Arabic strings
    └── app_en.arb                   # MODIFY — add English strings

test/features/memorization_plus/
├── presentation/pages/
│   ├── kids_gamified_home_page_test.dart    # NEW
│   ├── kids_gamified_journey_page_test.dart # NEW
│   ├── kids_gamified_stage_page_test.dart   # NEW
│   └── kids_gamified_listen_page_test.dart  # NEW
└── presentation/widgets/
    └── kids_house_card_test.dart            # NEW
```

**Structure Decision**: All new code lives within the existing `memorization_plus` feature module under `presentation/`. This follows the constitution's Feature-First architecture. New subdirectories (`theme/`, `widgets/`) organize gamified UI components without affecting the existing file structure.

## Implementation Phases

### Phase 1: Foundation (Theme + Config + Assets)

1. Create `kids_theme.dart` with the gamified color palette constants (night sky, forest green, gold, cream, etc.)
2. Create `kids_gamified_config.dart` with the runtime-readable `useNewKidsGamifiedUi` feature flag backed by `SharedPreferences` (no app restart needed to toggle)
3. Generate and save illustration assets under `assets/images/kids/`
4. Update `pubspec.yaml` to register the new assets directory
5. Add all new localization keys to `app_ar.arb` and `app_en.arb`

### Phase 2: Reusable Widgets

Build the 7 reusable widgets in isolation (no page integration yet):

1. `KidsHouseCard` — Three visual states (locked/current/completed/review) with house illustration, label, ayah range, progress indicator
2. `KidsJourneyMap` — CustomPainter for curved path + positioned house cards
3. `KidsProgressHeader` — Welcome greeting, avatar, level bar, star count
4. `KidsMissionCard` — Last mission card with continue button
5. `KidsStageDetails` — Ribbon banner header, 3 mission steps, start button
6. `KidsRewardDialog` — Animated stars celebration with earned rewards
7. `KidsAyahCard` — Parchment-style Quran text card using QcfHifzVerseView

### Phase 3: New Pages

Build 5 new pages using the widgets from Phase 2:

1. `KidsGamifiedHomePage` — Composes: KidsProgressHeader, KidsMissionCard, quick-access buttons, bottom nav
2. `KidsGamifiedJourneyPage` — Composes: KidsJourneyMap with KidsHouseCards, scrollable
3. `KidsGamifiedStagePage` — Composes: KidsStageDetails with ribbon banner and mission steps
4. `KidsGamifiedListenPage` — Composes: KidsAyahCard, audio controls (reusing KidsModeCubit)
5. `KidsGamifiedCompletionPage` — Composes: KidsRewardDialog with navigation buttons

### Phase 4: Router Integration & Feature Flag

1. Modify `app_router.dart` to conditionally route to new gamified pages when runtime `useNewKidsGamifiedUi` is true
2. Add error boundary wrapping so new UI load failures fall back to old pages without data loss
3. Register new routes for stage details and completion screens
4. Verify all existing kids navigation paths work correctly

### Phase 5: Polish & Testing

1. Write widget tests for all 5 new pages
2. Write widget tests for `KidsHouseCard` (4 states)
3. Run `flutter analyze` and fix all warnings
4. Run `flutter test` and verify zero regressions
5. Manual testing: Arabic RTL, locked/current/completed states, navigation flow
6. Verify adult memorization paths are completely unaffected

## Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| New UI breaks existing kids flow | Medium | Feature flag for instant rollback; old pages preserved |
| Asset images too large | Low | Optimize PNGs; use WebP if needed |
| CustomPainter performance on journey map | Low | Limit repaint regions; use RepaintBoundary |
| Adult path side effects | Low | All changes scoped to kids pages; router change isolated by feature flag |
| Localization string conflicts | Low | Use unique key prefixes (`kidsGamified*`) |
| Missing Quran text edge case | Low | Existing `QcfHifzVerseView` fallback handles missing text |

## Dependencies (Implementation Order)

```
Phase 1 (Foundation) → no dependencies
Phase 2 (Widgets) → depends on Phase 1 (theme + assets)
Phase 3 (Pages) → depends on Phase 2 (widgets)
Phase 4 (Router) → depends on Phase 3 (pages exist)
Phase 5 (Testing) → depends on Phase 4 (complete feature)
```
