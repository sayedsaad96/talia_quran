# Implementation Plan: QCF Rendering Proof of Concept

**Branch**: `003-qcf-rendering-poc` | **Date**: 2026-05-18 | **Spec**: [specs/003-qcf-rendering-poc/spec.md](./spec.md)

**Input**: Feature specification from `specs/003-qcf-rendering-poc/spec.md`

## Summary

Create a temporary, isolated proof-of-concept screen that evaluates whether `qcf_quran_plus` can render memorization-oriented Quran samples without changing Hifz logic or replacing the existing JSON-backed Quran and memorization data sources. The implementation will use the already-installed `qcf_quran_plus` package only for visual rendering, keep all memorization state/progress/lock/checkpoint behavior untouched, and document unsupported display modes before any production Hifz or Memorization Plus adoption.

## Technical Context

**Language/Version**: Flutter >= 3.22, Dart >= 3.4; current package constraint `sdk: ^3.11.4`

**Primary Dependencies**: `flutter`, `go_router`, `flutter_localizations`, existing `qcf_quran_plus: ^0.0.8`; no new package adoption planned

**Storage**: No new storage. Existing JSON assets remain the source for app Quran data and memorization state/progress/locks/checkpoints remain in existing local stores.

**Testing**: `flutter_test`; targeted widget test for the temporary screen plus route/build verification where feasible

**Target Platform**: iOS and Android mobile app

**Project Type**: Mobile app, presentation-only proof of concept

**Performance Goals**: POC screen opens in under 2 seconds on a normal debug build; full-page rendering remains smooth enough for visual inspection; no extra work is added to existing Hifz session startup

**Constraints**: Must not modify Hifz business logic; must not replace current JSON datasource; `qcf_quran_plus` may render visuals only; temporary route must be easy to find and revert; production screens must not consume POC findings until limitations are reported

**Scale/Scope**: One temporary screen, one debug/test route, required samples for Al-Fatiha, Al-Baqarah 255, Al-Ikhlas, one last-verse sample, and one full-page rendering attempt

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Clean Architecture**: POC remains presentation-only under `lib/features/memorization_plus/presentation/pages/`; no domain/data layer changes because no business state is introduced.
- [x] **II. BLoC / Cubit State Management**: No business state is required. Local widget state may be used only for ephemeral UI selection/scrolling; no Cubit is needed for static rendering samples.
- [x] **III. Test-Driven Quality**: Add a focused widget test for the POC screen and verify the debug route wiring does not alter existing Hifz entry points.
- [x] **IV. Offline-First & Performance**: Uses already-bundled package assets and existing startup font loading; no network or new persistence introduced.
- [x] **V. Localisation & Accessibility**: Add POC labels/limitation messages to `.arb` files, preserve RTL rendering, and keep touch targets/readability accessible.

## Project Structure

### Documentation (this feature)

```text
specs/003-qcf-rendering-poc/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── qcf-rendering-poc-ui.md
└── tasks.md              # Created later by /speckit-tasks
```

### Source Code

```text
lib/
├── core/
│   ├── l10n/
│   │   ├── app_ar.arb
│   │   ├── app_en.arb
│   │   └── generated localisation files
│   └── router/
│       └── app_router.dart
└── features/
    └── memorization_plus/
        └── presentation/
            └── pages/
                └── qcf_rendering_poc_page.dart

test/
└── features/
    └── memorization_plus/
        └── presentation/
            └── pages/
                └── qcf_rendering_poc_page_test.dart
```

**Structure Decision**: Keep the POC under `memorization_plus/presentation/pages` because it evaluates memorization display needs, but do not touch Hifz domain/data/cubits or Memorization Plus repositories/use-cases. The only shared production file expected to change is `app_router.dart` for a temporary debug/test route, plus localisation files for visible labels.

## Phase 0: Research

See [research.md](./research.md).

## Phase 1: Design & Contracts

See [data-model.md](./data-model.md), [quickstart.md](./quickstart.md), and [contracts/qcf-rendering-poc-ui.md](./contracts/qcf-rendering-poc-ui.md).

## Post-Design Constitution Check

- [x] **I. Clean Architecture**: Design keeps rendering samples as presentation-only value objects in the POC page; no repository or use-case contracts are added.
- [x] **II. BLoC / Cubit State Management**: Static sample rendering does not justify a Cubit; any local UI affordance remains ephemeral.
- [x] **III. Test-Driven Quality**: Contract and quickstart require widget coverage for required sample labels and limitation reporting.
- [x] **IV. Offline-First & Performance**: Rendering uses bundled assets/helpers; no network or persistent writes.
- [x] **V. Localisation & Accessibility**: Contract requires localized labels and limitation text, RTL-safe layout, and accessible controls.

## Complexity Tracking

No constitutional violations. `qcf_quran_plus` already exists in `pubspec.yaml` and is initialized in `lib/main.dart`; this plan does not introduce a new dependency.
