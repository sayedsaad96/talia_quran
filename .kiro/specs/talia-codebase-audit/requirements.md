# Requirements Document

## Introduction

This spec defines the requirements for a **production-readiness audit workflow** for the Talia Quran Flutter app. The audit is a structured, five-phase static analysis process that reads the codebase — without modifying it — and produces a prioritised report covering feature completeness, code quality, crash risks, and Supabase-specific concerns.

The audit is driven by the `talia_audit_prompt.md` file already present in the project root. The goal is to formalise that prompt into a spec-driven workflow so that the audit can be executed consistently, its findings tracked, and its output used to drive a prioritised fix list before the app ships to production.

The Talia Quran app uses:
- **Flutter** with a feature-first clean architecture under `lib/features/`
- **BLoC / Cubit** for state management (flutter_bloc ^9.1.1)
- **GoRouter** for navigation (go_router ^17.2.1)
- **Isar** for local persistence (isar ^3.1.0+1)
- **SharedPreferences** for lightweight key-value storage
- **Supabase** as the backend (supabase_flutter ^2.8.0)
- **GetIt** for dependency injection

The 14 discovered features are: `auth`, `azkar`, `certificate`, `hifz`, `home`, `memorization_plus`, `onboarding`, `progress`, `quran`, `settings`, `splash`, `streak`, `tutorial_guide`, `xp`.

---

## Glossary

- **Audit_Runner**: The agent or developer executing the audit workflow defined in `talia_audit_prompt.md`.
- **Audit_Report**: The structured markdown document produced at the end of Phase 5.
- **Feature**: A top-level folder under `lib/features/` representing a self-contained product capability.
- **Cubit**: A BLoC-pattern state management class used throughout the app.
- **AsyncValue**: A Riverpod/BLoC union type representing loading, data, or error states (used here generically to mean any state that has loading/error/success variants).
- **RLS**: Row-Level Security — Supabase's per-row access control mechanism.
- **DI**: Dependency Injection, managed via GetIt in this project.
- **Dead_Code**: Dart files, classes, or methods that are defined but never referenced by any live code path.
- **Stub**: A method body that throws `UnimplementedError()`, is empty, or contains only a `// TODO` comment.
- **Crash_Risk**: A code pattern that can cause an unhandled exception at runtime under realistic user conditions.
- **P0 / P1 / P2 / P3**: Priority levels — P0 is a release blocker, P1 must be fixed before shipping, P2 is a quality improvement, P3 is tech debt.

---

## Requirements

### Requirement 1: Codebase Mapping (Phase 1)

**User Story:** As an Audit_Runner, I want a complete structural map of the Talia Quran codebase, so that I have an accurate baseline before verifying individual features.

#### Acceptance Criteria

1. THE Audit_Runner SHALL read the full directory tree starting from the project root and identify all top-level folders (`lib/`, `assets/`, `test/`, `supabase/`, `scripts/`, etc.).
2. THE Audit_Runner SHALL identify the architecture pattern in use by reading `lib/features/` and `lib/core/` directory structures.
3. THE Audit_Runner SHALL identify the state management library by reading `pubspec.yaml` and import statements in cubit/provider files.
4. THE Audit_Runner SHALL identify the navigation library by reading `lib/core/router/app_router.dart`.
5. THE Audit_Runner SHALL identify the backend by reading `pubspec.yaml` and `lib/main.dart`.
6. WHEN reading `lib/main.dart`, THE Audit_Runner SHALL document every service and provider initialised at startup, the root widget, the initial route, and how auth state is handled at launch.
7. FOR EACH folder under `lib/features/`, THE Audit_Runner SHALL list every screen file (files containing a `Scaffold` or `build` method), every Cubit/BLoC, every repository and its public methods, and every model/entity.
8. THE Audit_Runner SHALL read `lib/core/` and document all reusable widgets, global services, constants, theme files, and utility/extension files.
9. WHEN the structural scan is complete, THE Audit_Runner SHALL produce a **Codebase Overview** section in the Audit_Report containing: architecture pattern, list of discovered features, state management library and version, navigation library, backend, total screen count, and total Cubit count.

---

### Requirement 2: Feature Verification Checklist (Phase 2)

**User Story:** As an Audit_Runner, I want to verify each feature against a standard checklist, so that gaps in UI completeness, state management, data layer, navigation, persistence, offline handling, async lifecycle, security, and localisation are systematically discovered.

#### Acceptance Criteria

1. FOR EACH feature discovered in Phase 1, THE Audit_Runner SHALL verify UI completeness by checking that every screen handles loading, error, empty, and success states, and that no screen contains hardcoded data or `// TODO` placeholders.
2. FOR EACH feature discovered in Phase 1, THE Audit_Runner SHALL verify that RTL and Arabic text are properly supported by checking `TextDirection` usage and widget alignment.
3. FOR EACH feature discovered in Phase 1, THE Audit_Runner SHALL verify state management correctness by checking that `AsyncValue` (or equivalent BLoC state) is handled exhaustively, that Cubits are disposed correctly, and that no shared mutable state creates race conditions.
4. FOR EACH feature discovered in Phase 1, THE Audit_Runner SHALL verify the data layer by confirming that every repository method calls its data source, that all CRUD operations are wired end-to-end, that error handling exists at the repository boundary, and that models correctly map to and from their storage format.
5. FOR EACH feature discovered in Phase 1, THE Audit_Runner SHALL verify navigation by confirming that all routes are defined in `app_router.dart`, that redirect guards are implemented for protected routes, and that no GoRouter route has missing or mismatched path parameters.
6. FOR EACH feature discovered in Phase 1, THE Audit_Runner SHALL verify persistence by confirming that every piece of data that should survive an app restart is both written to and read from Isar or SharedPreferences.
7. FOR EACH feature discovered in Phase 1, THE Audit_Runner SHALL verify offline and connectivity handling by checking that network calls are guarded by connectivity checks and that the feature degrades gracefully when offline.
8. FOR EACH feature discovered in Phase 1, THE Audit_Runner SHALL verify async and lifecycle correctness by checking that all `Stream` subscriptions are cancelled in `dispose()`, that no futures are unawaited where the result matters, and that no `setState()` is called after `dispose()`.
9. FOR EACH feature discovered in Phase 1, THE Audit_Runner SHALL verify security and auth by confirming that all protected routes are guarded in the router, that no auth check exists only on the client side without a corresponding Supabase RLS policy, and that the auth token is refreshed automatically.
10. FOR EACH feature discovered in Phase 1, THE Audit_Runner SHALL verify localisation by confirming that all user-facing strings use the `.arb`-based localisation system and that no hardcoded Arabic or English strings appear outside `.arb` files.
11. WHEN a feature passes all checklist items, THE Audit_Runner SHALL record it in the **Fully Working Features** section of the Audit_Report with brief code evidence.
12. WHEN a feature fails one or more checklist items, THE Audit_Runner SHALL record it in the **Partially Implemented** or **Broken / Not Implemented** section with the specific file and line reference, what works, what is missing, and the required fix.

---

### Requirement 3: Cross-Cutting Concerns (Phase 3)

**User Story:** As an Audit_Runner, I want to identify dead code, dependency inconsistencies, performance red flags, and crash risks across the entire codebase, so that systemic issues are caught that per-feature checks would miss.

#### Acceptance Criteria

1. THE Audit_Runner SHALL search for dead code by identifying Dart files that are imported nowhere, methods with `// TODO`, `throw UnimplementedError()`, or empty bodies, Cubits that are defined but never watched or read, and screens that are defined but absent from `app_router.dart`.
2. THE Audit_Runner SHALL verify dependency consistency by confirming that every package imported in Dart code is present in `pubspec.yaml`, that every package in `pubspec.yaml` is imported somewhere in Dart code, and that no version conflicts exist.
3. THE Audit_Runner SHALL search for performance red flags including: heavy computation inside `build()` methods, `ListView` without `itemExtent` or `itemBuilder` for large lists, `setState()` calls that rebuild large widget trees unnecessarily, network images loaded without `cached_network_image`, and `StatelessWidget` subclasses missing `const` constructors.
4. THE Audit_Runner SHALL search for crash risks including: the `!` null-assertion operator used without a prior null check, list index access without bounds checking, JSON parsing without `try/catch`, `Navigator.pop()` called without checking `canPop()`, and `FutureBuilder`/`StreamBuilder` widgets without error snapshot handling.
5. WHEN dead code, stubs, performance issues, or crash risks are found, THE Audit_Runner SHALL record each finding in the Audit_Report with the file path, line number, and severity (low / medium / high).

---

### Requirement 4: Supabase-Specific Checks (Phase 4)

**User Story:** As an Audit_Runner, I want to verify Supabase integration correctness, so that backend mismatches, missing RLS policies, and incorrect API calls are identified before the app goes to production.

#### Acceptance Criteria

1. WHEN a `supabase/migrations/` directory exists, THE Audit_Runner SHALL verify that every table defined in the migration SQL files has a corresponding Dart model in `lib/features/`.
2. THE Audit_Runner SHALL verify that RLS policies are enabled on all Supabase tables that store user data, by cross-referencing migration files and any Supabase dashboard exports present in the repository.
3. WHEN Supabase Realtime subscriptions are used in Dart code, THE Audit_Runner SHALL verify that every channel is properly closed in the corresponding `dispose()` method.
4. THE Audit_Runner SHALL verify that the Supabase auth session is persisted across app restarts by reading the auth initialisation code in `lib/main.dart` and the `AuthRepository` implementation.
5. WHEN Supabase Storage is used, THE Audit_Runner SHALL verify that bucket names and file paths are consistent between the SQL migration files and the Dart code that references them.
6. WHEN Supabase Edge Functions are called from Dart code, THE Audit_Runner SHALL verify that each call includes the correct headers and has error handling in place.
7. WHEN Supabase RPC (stored procedures) are called from Dart code, THE Audit_Runner SHALL verify that the Dart call signatures match the function signatures defined in the migration SQL files exactly.
8. IF no `supabase/` directory is found in the project root, THEN THE Audit_Runner SHALL note this in the Audit_Report and verify Supabase usage solely from the Dart-side code and any inline SQL strings.

---

### Requirement 5: Structured Report Output (Phase 5)

**User Story:** As an Audit_Runner, I want to produce a structured, prioritised Audit_Report, so that the development team can act on findings immediately with clear severity and fix guidance.

#### Acceptance Criteria

1. THE Audit_Runner SHALL produce an Audit_Report that begins with a **Codebase Overview** section containing: architecture pattern, list of all discovered features, state management library and version, navigation library, backend, total screen count, and total Cubit count.
2. THE Audit_Runner SHALL include a **Fully Working Features** section listing each feature that passed all Phase 2 checklist items, with brief code evidence for each.
3. THE Audit_Runner SHALL include a **Partially Implemented** section listing each feature that failed one or more Phase 2 checklist items but has a working core, with: what works, what is missing (file and line reference), and the specific fix required.
4. THE Audit_Runner SHALL include a **Broken / Not Implemented** section listing each feature that is fundamentally non-functional, with: the exact problem (file and line reference), whether it is a crash risk, and what needs to be done to fix it.
5. THE Audit_Runner SHALL include a **Code Quality Issues** section listing every finding from Phase 3, with file path, line number, and severity (low / medium / high).
6. THE Audit_Runner SHALL include a **Crash Risks** section listing every crash risk found in Phase 3 and Phase 4, with file path, line number, and the scenario that triggers the crash.
7. THE Audit_Runner SHALL include a **Prioritised Fix List** section with findings grouped into four priority levels: P0 (release blocker), P1 (must fix before shipping), P2 (quality improvement), and P3 (tech debt).
8. IF a finding references a specific file and line number, THEN THE Audit_Runner SHALL include that reference in the Audit_Report entry for that finding.
9. THE Audit_Runner SHALL NOT guess or infer findings — every entry in the Audit_Report MUST be backed by a specific file read during the audit.
10. THE Audit_Runner SHALL NOT modify any source file during the audit.
11. WHEN the Audit_Report is complete, THE Audit_Runner SHALL save it as `audit_report.md` in the project root.

---

### Requirement 6: Audit Execution Constraints

**User Story:** As an Audit_Runner, I want the audit to follow strict execution rules, so that the report is reliable, reproducible, and safe to run on a production codebase.

#### Acceptance Criteria

1. THE Audit_Runner SHALL execute the five phases in sequential order: Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5.
2. THE Audit_Runner SHALL NOT skip any feature discovered in Phase 1 on the grounds that it "looks fine" — every feature MUST be read and verified.
3. THE Audit_Runner SHALL treat every `// TODO` comment in production code as a missing feature and record it as a finding.
4. THE Audit_Runner SHALL read test files under `test/` when they exist for a feature, and use them to identify discrepancies between intended behaviour (as expressed in tests) and actual implementation.
5. IF the Audit_Runner encounters a file it cannot read (permissions, encoding, etc.), THEN THE Audit_Runner SHALL record the unreadable file in the Audit_Report and continue with the remaining files.
6. THE Audit_Runner SHALL begin its response with the text `"Audit started. Reading codebase..."` and end with the complete Audit_Report.
7. WHEN the audit is run, THE Audit_Runner SHALL complete all five phases before producing any output — partial reports are not acceptable.
