# Implementation Plan: QCF Hifz Rendering Rollout

**Branch**: `004-qcf-hifz-rendering` | **Date**: 2026-05-18 | **Spec**: [specs/004-qcf-hifz-rendering/spec.md](./spec.md)

**Input**: Feature specification from `specs/004-qcf-hifz-rendering/spec.md`

## Summary

Apply `qcf_quran_plus` as the shared visual Quran rendering layer across Hifz and Memorization Plus presentation screens while preserving the existing JSON-backed Quran text and memorization stores as the logic source of truth. The rollout will introduce one reusable Hifz rendering widget that accepts verse identity, fallback text, lock/memorized state, and an optional display mode, then replace direct verse `Text` rendering in memorization screens with that widget. Existing Cubits, repositories, routes, progress, locks, checkpoints, tests, and user settings remain unchanged unless a narrowly-scoped presentation adapter is required.

## Technical Context

**Language/Version**: Flutter >= 3.22, Dart >= 3.4; current package SDK constraint `^3.11.4`

**Primary Dependencies**: `flutter`, `flutter_bloc`, `go_router`, `qcf_quran_plus: ^0.0.8`, existing app theme/l10n utilities; no new dependency planned

**Storage**: No new storage. Existing JSON Quran data remains the fallback text source; existing Isar/shared_preferences/JSON-backed memorization progress, locks, checkpoints, reviews, and settings remain unchanged

**Testing**: `flutter_test`; targeted widget tests for the shared renderer and updated Hifz/Memorization Plus screens, plus existing Hifz and Memorization Plus unit tests and `flutter analyze`

**Target Platform**: iOS and Android Flutter mobile app

**Project Type**: Mobile app, presentation-layer rollout within existing feature modules

**Performance Goals**: Rendering updates preserve smooth 60 fps scrolling/session interaction on normal memorization screens; no synchronous heavy computation is added to Cubits or build methods beyond `qcf_quran_plus` verse/style helper calls

**Constraints**: QCF package is visual-only; JSON and existing repositories/Cubits remain the source of truth; locked verses must not reveal hidden content; fallback text must appear when QCF cannot render safely; production Quran reader screens stay out of scope

**Scale/Scope**: Shared widget plus updates for identified Hifz/memorization verse display sites: `HifzSessionPage`, `DailyPlanPage`, `KidsModePage`, and quiz answer comparison; review/checkpoint coverage through session checkpoint and daily/quiz flows; metadata-only journey/list pages are inspected but changed only if they display actual Quran verse text

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Clean Architecture**: Work stays in presentation widgets/pages under `lib/features/hifz/` and `lib/features/memorization_plus/`; no data/domain dependency inversion changes are required.
- [x] **II. BLoC / Cubit State Management**: Existing Cubits continue to load verse identity, progress, locks, tests, and checkpoints. The new widget is stateless/presentation-only and receives existing state as inputs.
- [x] **III. Test-Driven Quality**: Plan requires widget coverage for the shared renderer, fallback, locked, unlocked, memorized, single-verse, multi-verse, and updated screen usage, plus existing focused Hifz/Memorization Plus tests.
- [x] **IV. Offline-First & Performance**: Rendering uses the existing bundled `qcf_quran_plus` package and fallback JSON text; no network or new persistence is introduced.
- [x] **V. Localisation & Accessibility**: No new explanatory production strings are expected. Any visible fallback/status semantics must use existing localized app patterns or `.arb` strings, preserve RTL Quran layout, and keep existing touch targets.

## Project Structure

### Documentation (this feature)

```text
specs/004-qcf-hifz-rendering/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── hifz-verse-rendering-ui.md
└── tasks.md              # Created later by /speckit-tasks
```

### Source Code

```text
lib/
├── core/
│   ├── router/
│   │   └── app_router.dart                        # no planned production route changes
│   └── widgets/
│       └── qcf_hifz_verse_view.dart               # shared renderer
└── features/
    ├── hifz/
    │   └── presentation/
    │       └── pages/
    │           ├── hifz_page.dart                 # inspect, likely metadata only
    │           └── hifz_session_page.dart         # verse/checkpoint session rendering
    └── memorization_plus/
        └── presentation/
            └── pages/
                ├── daily_plan_page.dart           # adult/smart daily plan verse tiles
                ├── kids_mode_page.dart            # child single verse display
                ├── kids_journey_page.dart         # inspect, metadata/stage labels only
                ├── quiz_page.dart                 # test/checkpoint answer comparison
                └── qcf_rendering_poc_page.dart    # existing isolated POC, retained

test/
├── core/
│   └── widgets/
│       └── qcf_hifz_verse_view_test.dart
├── features/
│   └── memorization_plus/
│       └── presentation/
│           └── pages/
│               ├── daily_plan_page_test.dart
│               ├── kids_mode_page_test.dart
│               └── quiz_page_test.dart
└── existing focused Hifz/Memorization Plus tests remain in place
```

**Structure Decision**: Put the shared renderer under `lib/core/widgets/` because it is consumed by both Hifz and Memorization Plus presentation surfaces. This avoids cross-feature widget imports while keeping the renderer presentation-only with no storage, Cubit, repository, or route ownership.

## Phase 0: Research

See [research.md](./research.md).

## Phase 1: Design & Contracts

See [data-model.md](./data-model.md), [quickstart.md](./quickstart.md), and [contracts/hifz-verse-rendering-ui.md](./contracts/hifz-verse-rendering-ui.md).

## Post-Design Constitution Check

- [x] **I. Clean Architecture**: Data model is a presentation request object; contracts explicitly forbid repository/Cubit mutations and JSON replacement.
- [x] **II. BLoC / Cubit State Management**: Screen updates consume existing state fields (`surahId`, `ayahNumber`, `ayahText`, completed/locked/memorized markers) and do not move business decisions into widgets.
- [x] **III. Test-Driven Quality**: Quickstart and contract require renderer fallback tests and screen-level verification for children, adults/smart daily plan, Hifz session/checkpoint, and quiz result surfaces.
- [x] **IV. Offline-First & Performance**: Fallback remains local JSON text; QCF calls use local package helpers; no network or persistent writes are added.
- [x] **V. Localisation & Accessibility**: Rendering remains RTL, semantic labels expose verse identity/state where helpful, and new user-facing labels must be localized if introduced.

## Complexity Tracking

No constitutional violations. The dependency already exists in `pubspec.yaml`, and this rollout is a presentation refactor rather than a new subsystem.
