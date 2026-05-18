# Implementation Plan: Full Application Feature Audit & Integration Validation

**Branch**: `001-feature-audit` | **Date**: 2026-05-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/feature-audit/spec.md`

---

## Summary

A read-only, static-analysis audit of the Talia Quran Flutter application covering all 14
feature modules and 6 registered core services. The audit will classify every feature/service
by status (Fully Working / Partially Working / Broken / Hidden+Unused / Conditionally
Reachable), produce a findings report with severities (Critical → Low), and attach
prioritised, production-safe fix recommendations. No source files are modified by the audit
itself. Implementation of fixes follows in separate tasks ordered by severity.

---

## Technical Context

**Language/Version**: Dart 3.11.4 / Flutter 3.22+

**Primary Dependencies**:
- State management: `flutter_bloc` ^9.1.1 (Cubits)
- DI: `get_it` ^9.2.1
- Routing: `go_router` ^17.2.1
- Local DB: `isar` ^3.1.0+1 + `shared_preferences` ^2.5.5
- Error handling: `dartz` ^0.10.1
- Backend: `supabase_flutter` ^2.8.0
- Audio: `just_audio` ^0.10.5 + `flutter_cache_manager`
- Speech: `speech_to_text` ^7.3.0 + `string_similarity`
- Extras: `confetti`, `screenshot`, `pdf`, `printing`, `qr_flutter`, `mobile_scanner`,
  `qcf_quran_plus`

**Storage**: Isar (structured data), SharedPreferences (flags/preferences)

**Testing**: `flutter_test`, `bloc_test` (existing test suite under `test/`)

**Target Platform**: Android + iOS (portrait-only)

**Project Type**: Mobile app (feature-first Clean Architecture)

**Performance Goals**: 60 fps on mid-range devices; offline-first for all core Quran/Hifz flows

**Constraints**:
- Read-only audit — zero source file modifications during the audit pass
- Preserve all existing architecture, routes, DI registrations, and UI structure
- Incremental, production-safe fixes only — no large refactors
- Supabase requires a `.env` file at runtime (bootstrap throws StateError if missing)

**Scale/Scope**:
- 14 feature modules under `lib/features/`
- 6 core services registered in DI + 3 additional unlisted services
- ~25 registered Cubits, ~30 route definitions

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Clean Architecture (Feature-First) | PASS | Audit preserves existing layering; no cross-layer changes |
| II. BLoC / Cubit State Management | PASS | Audit verifies existing Cubits; no new state introduced |
| III. Test-Driven Quality | PASS | Audit produces zero code changes; fix tasks require tests |
| IV. Offline-First & Performance | PASS | Audit validates offline behaviour per feature |
| V. Localisation & Accessibility | PASS | UX tier includes layout overflow and readability checks |

No violations. No Complexity Tracking entry required.

---

## Project Structure

### Documentation (this feature)

```text
specs/feature-audit/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root — READ-ONLY during audit)

```text
lib/
├── main.dart                          # Bootstrap: Supabase, DI, notifications, runApp
├── app.dart                           # Root widget: theme, locale, router
├── core/
│   ├── di/injection.dart              # GetIt container (~374 lines, 25 Cubits)
│   ├── router/app_router.dart         # GoRouter config (~331 lines, ~30 routes)
│   ├── services/                      # 9 service files (6 registered in DI)
│   ├── theme/                         # ThemeCubit + theme data
│   ├── l10n/                          # ARB localisation files
│   └── widgets/app_shell.dart         # StatefulShellRoute bottom-nav shell
└── features/
    ├── auth/                          # Login, AuthCubit, AuthRepository (Supabase)
    ├── azkar/                         # Morning/Evening/General dhikr
    ├── certificate/                   # Shareable Hifz completion certificate
    ├── hifz/                          # SRS memorisation + session + checkpoint review
    ├── home/                          # Dashboard, continue-reading, streaks shortcut
    ├── memorization_plus/             # Track selection, daily plan, kids mode, quiz, parent dashboard
    ├── onboarding/                    # First-launch onboarding flow
    ├── progress/                      # Stats, achievements, activity heatmap
    ├── quran/                         # Surah list, page reader, bookmarks, search, audio
    ├── settings/                      # Theme, locale, notifications, profile
    ├── splash/                        # Splash + routing decision (onboarding vs home)
    ├── streak/                        # StreakCubit (data + domain only, no route)
    ├── tutorial_guide/                # In-app tutorial overlay
    └── xp/                            # XP data model only (no domain/presentation)
```

**Structure Decision**: Single-project mobile app. All audit work is static analysis of the
existing tree above. No new directories or files are created during the audit pass.

---

## Complexity Tracking

> No constitution violations detected. Section intentionally empty.
