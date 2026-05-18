# Feature Specification: Full Application Feature Audit & Integration Validation

**Feature Branch**: `001-feature-audit`

**Created**: 2026-05-17

**Status**: Draft

---

## Clarifications

### Session 2026-05-17

- Q: How should routes that are only reachable via runtime `extra` parameters (e.g. `/certificate`, `/quiz`, `/memorization-plus/kids`) and have no static UI entry point be classified? → A: Classify as **Conditionally Reachable** — a distinct 5th status category. The audit MUST verify that the upstream trigger (the action that passes the required params) actually exists and is reachable by the user.
- Q: Should the 6 cross-cutting core services under `lib/core/services/` (`XpService`, `StreakService`, `AchievementService`, `SubscriptionService`, `AudioCacheService`, `AppSessionService`) be audited as first-class entities or only within feature findings? → A: Audit as **first-class entities** — each core service receives its own status entry and findings in the report, independent of any feature that may or may not use it.
- Q: How thoroughly should the `auth` feature be audited — surface render check, or full auth-gate verification? → A: **Full auth-gate audit** — the audit MUST verify the login flow, session persistence, and whether any route protection guard exists in the router. The absence of a route guard is itself a Critical finding.
- Q: Should UX findings cover structural gaps only (missing widgets) or also visual/behavioural quality issues? → A: **Structural gaps + flagrant quality issues** — flag missing empty/loading/error state widgets AND obvious broken patterns (zero error feedback, unreadable text, broken layout on small screens). Subjective design opinions (spacing preferences, animation timing) are out of scope.
- Q: What threshold determines when a feature is reclassified from "Partially Working" to "Broken"? → A: **Primary flow failure = Broken** — if a user cannot complete the feature's primary purpose (its P1 equivalent user flow) even without a crash, the feature MUST be classified as Broken. Secondary or optional flows failing while the primary flow works = Partially Working.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Feature Discovery & Inventory (Priority: P1)

As a developer/product owner, I want a complete, structured inventory of every feature
and module in the application so that I know exactly what has been built, where it lives,
and how it connects to the rest of the system.

**Why this priority**: Without a full inventory there is no baseline from which to audit
anything else. Every subsequent story depends on this map existing.

**Independent Test**: The inventory alone is useful — it can be reviewed and agreed upon
before any validation work begins. Success can be verified by checking that every directory
under `lib/features/` and every registered route appears in the inventory document.

**Acceptance Scenarios**:

1. **Given** the project source tree, **When** the audit runs, **Then** every feature module
   (`auth`, `azkar`, `certificate`, `hifz`, `home`, `memorization_plus`, `onboarding`,
   `progress`, `quran`, `settings`, `splash`, `streak`, `tutorial_guide`, `xp`) is listed
   with its purpose, entry point, navigation path, and dependency list.
2. **Given** a feature in the inventory, **When** its architecture layers are examined,
   **Then** the report states which of Data / Domain / Presentation layers are present
   and whether they are populated.
3. **Given** the routing configuration, **When** cross-referenced with the inventory,
   **Then** every registered route maps to a feature in the inventory and vice-versa.

---

### User Story 2 — Runtime Integration Validation (Priority: P2)

As a developer/QA engineer, I want each feature validated for actual runtime connectivity —
not just code existence — so that I can confirm users can access and use every feature.

**Why this priority**: Code may exist but be unreachable, disconnected, or silently broken.
This story transforms the inventory into evidence-backed status assessments.

**Independent Test**: A feature's runtime status can be assessed independently by examining
its Cubit registration in DI, its route registration in the router, and whether its entry
widget is reachable from a user flow.

**Acceptance Scenarios**:

1. **Given** a feature listed in the inventory, **When** its runtime integration is assessed,
   **Then** the report states whether the feature is reachable from the home screen within
   a documented number of taps.
2. **Given** a Cubit or Bloc for a feature, **When** its DI registration is checked,
   **Then** the report confirms whether it is registered and whether it receives the correct
   repository/use-case dependencies.
3. **Given** a user-facing action in a feature (button, tap, form submit), **When** traced
   through code, **Then** the report confirms whether the action triggers a state change
   that results in a UI update.

---

### User Story 3 — Issue Detection & Categorisation (Priority: P2)

As a developer, I want all detected problems categorised by type and severity so that
I can triage and fix them in priority order without guessing.

**Why this priority**: Equal priority to runtime validation since the categorisation is
built in the same pass. Together US2 + US3 form the core audit deliverable.

**Independent Test**: The categorisation can be reviewed independently of any fixes.
A reviewer can confirm that every item has a category (broken, partial, hidden/unused,
UX problem, logic problem, dead code, performance concern) and a severity (Critical, High,
Medium, Low).

**Acceptance Scenarios**:

1. **Given** a feature with incomplete integration, **When** categorised, **Then** it
   appears in the "Partially Working Features" section with specific missing pieces listed.
2. **Given** a feature that exists in code but has no reachable navigation entry point,
   **When** categorised, **Then** it appears in "Hidden / Unused Features".
3. **Given** a feature causing a runtime crash or data-loss risk, **When** categorised,
   **Then** it appears in "Broken Features" with a Critical or High severity label.
4. **Given** a UX problem (e.g., missing empty state, broken loading indicator), **When**
   categorised, **Then** it appears in "UX Problems" with an affected screen identified.

---

### User Story 4 — Architecture & Stability Assessment (Priority: P3)

As a senior developer, I want the audit to flag architectural violations and stability
risks so that the codebase remains maintainable and safe to extend.

**Why this priority**: Important for long-term health but not blocking a release; it is
additive to the core audit already delivered by US1–US3.

**Independent Test**: Architecture findings are self-contained — they can be produced by
static analysis of the source tree without running the app.

**Acceptance Scenarios**:

1. **Given** any feature, **When** its layer dependencies are inspected, **Then** the
   report flags any case where the Presentation layer imports directly from the Data layer
   (violating Clean Architecture).
2. **Given** async operations in use-cases or Cubits, **When** examined, **Then** the
   report lists any cases lacking proper cancellation, error-propagation, or `Either`
   wrapping.
3. **Given** all features, **When** scanned for duplicate business logic, **Then** the
   report lists instances where the same logic is reimplemented in more than one feature
   without being extracted to `core/`.

---

### User Story 5 — Prioritised Fix Recommendations (Priority: P3)

As a product owner/developer, I want actionable, prioritised fix recommendations for every
issue found so that the team knows exactly what to address and in what order.

**Why this priority**: Recommendations are the outcome of US2–US4; they cannot exist
before the audit findings are complete.

**Independent Test**: Each recommendation can be reviewed independently: it either refers
to a real finding in the report and provides a concrete next step, or it does not.

**Acceptance Scenarios**:

1. **Given** a finding in any category, **When** recommendations are generated, **Then**
   every finding has at least one corresponding recommendation with a severity label
   (Critical / High / Medium / Low), affected file(s), and a safe implementation approach.
2. **Given** a Critical finding, **When** its recommendation is read, **Then** it describes
   a targeted fix that does not require a large-scale refactor.
3. **Given** the full recommendation list, **When** sorted by severity, **Then** Critical
   items appear first with no dependencies on lower-priority items for their own resolution.

---

### Edge Cases

- What if a feature directory exists but contains only empty files or stubs?
  → It MUST be categorised as "Partially Working" (skeleton exists, not implemented).
- What if a Cubit is registered in DI but never provided to any widget tree?
  → It MUST be flagged as "Hidden / Unused" with a note about the missing `BlocProvider`.
- What if a route is registered but leads to a `TODO` placeholder screen?
  → It MUST be categorised as "Partially Working" with the placeholder widget identified.
- What if the same business logic appears in both `core/` and a feature layer?
  → Both occurrences MUST be listed under "Dead / Duplicate Code".
- What if a feature works on one platform (Android) but not another (iOS)?
  → The platform-specific behaviour MUST be noted in the finding.
- What if a route requires runtime `extra` parameters and has no static UI navigation entry?
  → It MUST be classified as **Conditionally Reachable** (not Hidden/Unused). The audit
  MUST then trace the upstream action that provides those parameters and confirm it is
  itself reachable. If the upstream trigger is missing or broken, the finding severity
  escalates to High.
- What if the router has no authentication guard and all routes are publicly accessible?
  → This MUST be reported as a **Critical** finding under the `auth` feature, stating that
  login enforcement is absent and any user can deeplink to any screen without authenticating.
- What if a feature's primary flow silently fails (no crash, but the action has no effect)?
  → It MUST be classified as **Broken** (not Partially Working). Silent primary-flow
  failure is as severe as a crash from the user's perspective.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The audit MUST produce a structured report covering all 14 feature modules
  identified in `lib/features/` **and** the 6 core services registered in DI
  (`XpService`, `StreakService`, `AchievementService`, `SubscriptionService`,
  `AudioCacheService`, `AppSessionService`). Each service is a first-class audited
  entity with its own status classification and findings.
- **FR-002**: The report MUST classify each feature into exactly one primary status:
  Fully Working, Partially Working, Hidden/Unused, Broken, or **Conditionally Reachable**.
  *Conditionally Reachable* applies to screens that are only accessible when a specific
  upstream action passes required runtime parameters (e.g. route `extra` data). The audit
  MUST verify the upstream trigger exists, is itself reachable, and correctly supplies the
  required parameters.
  Status definitions:
  - **Fully Working**: Primary and all secondary user flows complete without error.
  - **Partially Working**: Primary flow succeeds; one or more secondary/optional flows
    fail, are disconnected, or produce incorrect output.
  - **Broken**: The feature's primary user flow cannot be completed by the user, whether
    due to a runtime crash, silent failure, missing state update, or disconnected logic.
  - **Hidden/Unused**: Feature code exists but is not reachable via any navigation path
    or is registered in DI but never consumed.
  - **Conditionally Reachable**: Reachable only via a runtime-parameter-driven upstream
    action; audit MUST verify the upstream trigger is present and functional.
- **FR-003**: Each finding MUST include the affected files or directories, a description
  of the problem, and a severity level (Critical / High / Medium / Low).
- **FR-004**: The audit MUST trace each feature's navigation path from the app's root
  entry point and confirm reachability.
- **FR-005**: The audit MUST verify DI registration for every Cubit/Bloc and confirm
  correct dependency injection of repositories and use-cases.
- **FR-006**: The audit MUST identify all routes registered in the router configuration
  and confirm each maps to an accessible, functional screen.
- **FR-007**: The audit MUST identify UX deficiencies per screen in two tiers:
  - **Structural** (always flag): missing empty states, loading states, or error state
    widgets where the feature can produce an empty, loading, or error condition.
  - **Flagrant quality** (flag when clearly broken): zero user-facing error feedback on
    actions that can fail, text that is unreadable due to colour or size, layouts that
    overflow or break on common small-screen sizes (≤360 dp width).
  - Out of scope: subjective design opinions, animation timing, spacing preferences.
- **FR-008**: The audit MUST flag any Clean Architecture layer violations (e.g.,
  Presentation importing Data directly).
- **FR-009**: The audit MUST flag duplicate or dead business logic across features.
- **FR-010**: Each recommendation MUST be production-safe: no large-scale automatic
  refactors; fixes MUST be incremental and targeted.
- **FR-011**: The audit MUST NOT implement any fixes automatically — it produces findings
  and recommendations only.
- **FR-012**: The `auth` feature audit MUST verify three things independently: (a) the
  login flow renders and `AuthCubit` state transitions work, (b) session state is persisted
  across app restarts, and (c) the router has a redirect guard that enforces authentication
  on protected routes. If (c) is absent, it MUST be reported as a Critical finding.

### Key Entities

- **Feature**: A module under `lib/features/<name>/` with Data, Domain, and Presentation
  sub-layers. Attributes: name, status, entry point, navigation path, DI registration
  status, layer completeness, dependencies.
- **CoreService**: A shared service registered in DI under `lib/core/services/`
  (`XpService`, `StreakService`, `AchievementService`, `SubscriptionService`,
  `AudioCacheService`, `AppSessionService`). Attributes: name, registration type
  (singleton/factory), consuming cubits/features, usage status (active/unused/partial).
- **Finding**: A specific problem detected for a feature, core service, or cross-cutting
  concern. Attributes: category, severity, description, affected files, root cause.
- **Recommendation**: An actionable suggestion tied to one or more findings.
  Attributes: severity, problem summary, root cause, safe fix approach, risk level,
  affected files.
- **Route**: An entry in the go_router configuration. Attributes: path, target widget,
  reachability, feature association.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 14 feature modules **and** all 6 core services appear in the report,
  each with a definitive status classification — no feature or service is left unassessed.
- **SC-002**: Every finding has an associated recommendation; no finding is left without
  a suggested resolution path.
- **SC-003**: The report is reviewable by a developer unfamiliar with the codebase and
  allows them to understand the state of any feature within 2 minutes of reading its entry.
- **SC-004**: Critical and High severity issues are surfaced first, enabling the team to
  address the most impactful problems without reading the entire report.
- **SC-005**: Zero automatic code changes are made during the audit — the codebase is
  identical before and after the audit report is produced.
- **SC-006**: The report's "Suggested Fixes" section covers 100% of findings from all
  categories (broken, partial, hidden, UX, logic, dead code, performance).

---

## Assumptions

- The audit is a read-only, analysis-only operation — it does NOT modify any source files.
- The scope is the Flutter application under `lib/`, its test files under `test/`, and its
  configuration files (`pubspec.yaml`, router config, DI setup).
- Backend infrastructure (Supabase schema, cloud functions) is out of scope for this audit
  unless a client-side integration gap is detected.
- Platform-specific code (native Android/iOS plugins) is out of scope unless it directly
  blocks a Dart-layer feature from functioning.
- The audit targets the current state of the `main` branch (or active branch at time of
  execution); no historical comparison is required.
- "Working" means the feature is navigable, its state machine functions, and its primary
  user flow completes without a crash or hard error — not that every edge case is handled.