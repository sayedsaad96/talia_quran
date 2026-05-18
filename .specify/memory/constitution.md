<!--
SYNC IMPACT REPORT
==================
Version change: [TEMPLATE] → 1.0.0 (initial ratification — all placeholders filled)

Modified principles:
  - [PRINCIPLE_1_NAME] → I. Clean Architecture (Feature-First)
  - [PRINCIPLE_2_NAME] → II. BLoC / Cubit State Management
  - [PRINCIPLE_3_NAME] → III. Test-Driven Quality
  - [PRINCIPLE_4_NAME] → IV. Offline-First & Performance
  - [PRINCIPLE_5_NAME] → V. Localisation & Accessibility

Added sections:
  - Technology Stack Constraints
  - Development Workflow

Removed sections:
  - N/A (template sections retained and populated)

Templates requiring updates:
  ✅ .specify/templates/plan-template.md — Constitution Check gates align with principles
  ✅ .specify/templates/spec-template.md — Requirements format aligned (MUST/SHOULD language)
  ✅ .specify/templates/tasks-template.md — Task categories reflect observability, testing, localisation
  ⚠ .specify/templates/commands/*.md — no generic-name violations found (no CLAUDE-only references)

Deferred TODOs:
  - TODO(RATIFICATION_DATE): Exact first-commit date unknown; set to 2026-05-17 (constitution creation date).
-->

# Talia Quran Constitution

## Core Principles

### I. Clean Architecture (Feature-First)

Every feature MUST be structured in three distinct layers: **Data**, **Domain**, and
**Presentation**. No layer may depend on a layer above it (Presentation → Domain → Data).

- Feature modules live under `lib/features/<feature_name>/`.
- Shared infrastructure (DI, routing, error handling, theming, l10n) lives under `lib/core/`.
- Cross-feature communication MUST go through domain-layer abstractions (use-cases, repositories),
  never via direct Cubit-to-Cubit calls or widget imports across features.
- New features MUST NOT introduce global singletons outside of `core/di/`.

**Rationale**: Prevents tight coupling, enables independent testing of features, and keeps the
codebase navigable as the feature count grows.

### II. BLoC / Cubit State Management

All UI state MUST be managed via `flutter_bloc` Cubits (or Blocs where event-driven logic is
required). Ad-hoc `setState` is permitted only for purely local, ephemeral widget animation
state that has no business meaning.

- Cubits/Blocs MUST be registered via `get_it` and injected through `BlocProvider`.
- State classes MUST be immutable; use `copyWith` patterns or sealed classes.
- Business logic MUST NOT reside in widgets — it belongs in the Cubit/use-case layer.
- Repositories MUST return `Either<Failure, T>` (via `dartz`) so Cubits handle errors cleanly.

**Rationale**: Enforces predictable, testable state transitions and separates UI from logic.

### III. Test-Driven Quality

Unit tests MUST be written for all use-cases, repositories, and Cubits. Tests MUST cover the
happy path and at minimum one failure path per public method.

- Tests live under `test/` mirroring the `lib/` directory structure.
- Widget tests SHOULD be written for every non-trivial widget with business logic.
- Integration/golden tests are optional but encouraged for critical user flows.
- A task MUST NOT be marked complete if its associated tests do not pass.
- Mocking MUST use `mocktail` or hand-written fakes — never real network or DB calls in unit tests.

**Rationale**: Prevents regressions in a feature-rich app where many systems interact
(SRS scheduling, audio, speech recognition, Supabase sync).

### IV. Offline-First & Performance

The app MUST function fully offline for all core Quranic reading and Hifz review features.
Network access (Supabase, audio streaming) is an enhancement, not a requirement.

- Local persistence MUST use `isar` for structured data and `shared_preferences` for simple flags.
- Audio files MUST be cached via `flutter_cache_manager` before playback.
- UI MUST render at 60 fps on mid-range devices; avoid synchronous heavy computation on the
  main isolate — offload to `compute()` or background isolates where necessary.
- Lazy loading and pagination MUST be applied to any list exceeding 50 items.

**Rationale**: The Quran audience includes users in areas with limited connectivity; offline
reliability is a core product promise.

### V. Localisation & Accessibility

Every user-facing string MUST be externalised in the `.arb` localisation files under
`lib/core/l10n/`. Hard-coded Arabic or English strings in widgets are prohibited.

- The app MUST support full RTL layout mirroring for Arabic and LTR for English without
  requiring a restart.
- Font choices MUST respect cultural authenticity: `Amiri` for Quranic text,
  `Cormorant Garamond` for display headings, `DM Sans` for body copy.
- Touch targets MUST be a minimum of 48×48 dp per Material accessibility guidelines.
- Colour contrast MUST meet WCAG AA (4.5:1 for normal text, 3:1 for large text).

**Rationale**: Talia serves a global Muslim audience; accessibility and bilingual support are
non-negotiable product requirements.

## Technology Stack Constraints

The following technology choices are locked for this project and MUST NOT be changed without
a constitution amendment:

| Concern | Approved Technology |
|---|---|
| Framework | Flutter ≥ 3.22, Dart ≥ 3.4 |
| State Management | `flutter_bloc` (Cubits preferred, Blocs when events needed) |
| Dependency Injection | `get_it` |
| Routing | `go_router` (declarative, ShellRoute for bottom-nav) |
| Local Database | `isar` (structured), `shared_preferences` (flags/prefs) |
| Error Handling | `dartz` `Either<Failure, T>` across domain/data boundary |
| Audio | `just_audio` + `flutter_cache_manager` |
| Speech Recognition | `speech_to_text` + `string_similarity` |
| Backend (optional) | Supabase (auth + realtime sync) |
| Animations | `flutter_animate`, `percent_indicator`, `shimmer` |
| Testing | `flutter_test`, `bloc_test`, `mocktail` |

Introducing a dependency outside this list requires documenting the rationale in the feature's
`plan.md` Complexity Tracking table and getting acknowledgment before implementation.

## Development Workflow

1. **Specify first**: Every non-trivial feature MUST have a `spec.md` before coding begins.
2. **Plan before implementing**: A `plan.md` with architecture decisions and a Constitution
   Check section MUST exist before tasks are generated.
3. **Tasks drive execution**: Implementation follows `tasks.md` task-by-task; no unplanned
   code changes should land outside a tracked task.
4. **Feature branches**: All work MUST occur on a feature branch named
   `<NNN>-<short-description>` (e.g., `042-parent-dashboard`).
5. **Commit frequently**: Commit after each completed task or logical chunk. Commit messages
   MUST follow Conventional Commits (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`).
6. **No dead code**: Remove unused imports, widgets, and commented-out blocks before marking
   a task complete.
7. **Code review**: All PRs MUST pass automated tests and linting (`flutter analyze`) before
   merge.

## Governance

This constitution supersedes all other development practices. Any practice not addressed here
defaults to Flutter/Dart community best practices and the official Flutter style guide.

**Amendment procedure**:

1. Propose the amendment in writing, describing which principle is affected and why.
2. Update this file using `/speckit-constitution`, incrementing the version per semver rules.
3. Propagate the change to all dependent templates (plan, spec, tasks) in the same commit.
4. Document the amendment in the Sync Impact Report (HTML comment at top of this file).

**Versioning policy**:

- MAJOR: Backward-incompatible principle removal or fundamental governance change.
- MINOR: New principle, section, or materially expanded guidance added.
- PATCH: Clarifications, wording improvements, or typo fixes.

**Compliance review**: During every `/speckit-plan` execution, the Constitution Check section
MUST be completed. Any violation MUST be justified in the Complexity Tracking table.

**Version**: 1.0.0 | **Ratified**: 2026-05-17 | **Last Amended**: 2026-05-17
