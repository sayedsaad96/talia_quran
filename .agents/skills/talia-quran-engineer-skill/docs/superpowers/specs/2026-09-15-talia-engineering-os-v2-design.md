# Talia Engineering OS V2 — Design Specification

**Date:** 2026-09-15  
**Status:** Approved design, pending implementation plan  
**Scope:** Project-specific agent skill system for the Talia Quran Flutter application  
**Primary stack:** Flutter/Dart, Supabase, local persistence, mobile platforms  

## 1. Purpose

Talia Engineering OS V2 is a project-specific engineering skill system that guides AI coding agents when working on the Talia Quran application. It is not a generic Flutter skill and it is not a static project handbook. It combines a compact always-on core, task-specific modules, task workflows, live repository knowledge, product intelligence, ecosystem freshness checks, prevention, debugging, and verification.

The system exists to improve four outcomes:

1. build and evolve Talia without duplicating or breaking capabilities that already exist;
2. diagnose defects through evidence and root-cause analysis rather than guess-and-check edits;
3. keep the application current with Flutter, Dart, Supabase, packages, Android/iOS requirements, and tooling without chasing every new release;
4. protect Quran correctness, user progress, privacy, security, and release stability while still allowing useful product innovation.

The system must behave like a senior engineer who knows the product, understands the current repository, and distinguishes verified facts from assumptions.

## 2. Non-goals

V2 will not:

- hard-code the current latest Flutter, Dart, Supabase, Android, iOS, or package versions;
- replace repository inspection with cached documentation;
- automatically apply every available dependency upgrade;
- rewrite working architecture merely because a newer pattern exists;
- turn every finding into immediate refactoring scope;
- use an LLM as a canonical source for Quran text, ayah identity, Mushaf mapping, or religious correctness;
- claim runtime, performance, or test success without fresh evidence;
- execute destructive or irreversible production actions without explicit approval and impact understanding;
- become a second implementation of the product. It is an operating system for engineering decisions, not product code.

## 3. Architectural model

V2 uses a **hybrid core + modules + workflows + living knowledge** architecture.

```text
Talia Engineering OS
├── Core Constitution + Router
├── Durable Product/Engineering References
├── Specialized Modules
├── Task Workflows
├── Living Repository Knowledge
├── Diagnostics / Helper Scripts
└── Skill Pressure Tests
```

The core is intentionally small and frequently loaded. Specialized modules are loaded only when relevant to the task. Living knowledge accelerates understanding but never overrides the current repository.

### 3.1 Proposed layout

```text
talia-quran-engineer/
├── SKILL.md
├── core/
│   ├── task-router.md
│   ├── risk-engine.md
│   ├── autonomy-policy.md
│   └── completion-contract.md
├── references/
│   ├── talia-product-context.md
│   ├── architecture-contract.md
│   ├── quran-safety-contract.md
│   ├── engineering-principles.md
│   └── source-authority.md
├── modules/
│   ├── feature-development.md
│   ├── debugging.md
│   ├── incident-response.md
│   ├── flutter-engineering.md
│   ├── dependency-upgrades.md
│   ├── ecosystem-intelligence.md
│   ├── supabase.md
│   ├── quran-engine.md
│   ├── quran-integrity.md
│   ├── memorization-learning.md
│   ├── revision.md
│   ├── audio.md
│   ├── performance.md
│   ├── ui-ux.md
│   ├── testing-qa.md
│   ├── verification.md
│   ├── prevention-and-health.md
│   ├── observability.md
│   ├── security-privacy.md
│   ├── release-readiness.md
│   ├── architecture-refactoring.md
│   └── git-safety.md
├── workflows/
│   ├── new-feature.md
│   ├── bug-fix.md
│   ├── runtime-investigation.md
│   ├── performance-investigation.md
│   ├── dependency-upgrade.md
│   ├── supabase-migration.md
│   ├── technology-spike.md
│   ├── runtime-validation.md
│   ├── incident-response.md
│   └── pre-release-audit.md
├── knowledge/
│   ├── repo-map.md
│   ├── feature-registry.md
│   ├── feature-graph.md
│   ├── dependency-baseline.md
│   ├── supabase-map.md
│   ├── known-risks.md
│   ├── health-register.md
│   ├── product-debt.md
│   ├── opportunity-register.md
│   ├── tech-radar.md
│   ├── update-backlog.md
│   ├── skill-version.md
│   └── incidents/
├── scripts/
│   ├── talia_doctor.ps1
│   ├── dependency_audit.ps1
│   └── project_snapshot.ps1
└── tests/
    ├── skill-pressure-tests.md
    ├── routing-scenarios.md
    └── regression-scenarios.md
```

## 4. Core constitution

The `SKILL.md` core is a router and constitution, not a long reference manual.

Every Talia task follows these non-negotiable rules:

1. **Repository first.** Inspect the relevant current implementation before proposing changes.
2. **Diagnose before fixing.** Unexpected behavior requires root-cause investigation before code changes.
3. **Extend before rebuilding.** Search for existing capabilities and patterns before creating a parallel system.
4. **Evidence before claims.** Tests, runtime results, measurements, and compatibility statements require fresh evidence.
5. **Tests before completion.** The applicable verification gates define “done.”
6. **Quran integrity above convenience.** Canonical content and mappings are correctness-critical.
7. **Current sources before ecosystem decisions.** Verify current official documentation when a decision depends on freshness.
8. **Repository beats knowledge files.** Knowledge is a navigation aid, never the ultimate source of truth.
9. **Smallest safe change.** Avoid unrelated refactors and uncontrolled migration scope.
10. **Unknown is not assumed.** Search, measure, or explicitly mark unknowns.

## 5. Operating modes

The system supports four explicit operating modes.

### 5.1 DISCOVER

Used for audits, exploration, understanding, mapping, and recommendations. No production code changes are made unless the user changes the requested mode.

### 5.2 PLAN

Used when the user asks for an implementation plan or architectural proposal. The agent inspects the real repository and writes a plan grounded in what already exists. It does not implement the plan.

### 5.3 IMPLEMENT

Used for approved feature, fix, refactor, migration, or upgrade work. The agent applies the relevant risk, testing, and verification gates.

### 5.4 INCIDENT

Activated for production failures, crashes, critical regressions, data corruption, Quran integrity failures, security issues, and difficult runtime problems. Incident mode prioritizes containment, evidence gathering, reproduction, root cause, minimal fix, verification, and prevention.

## 6. Living project knowledge

The knowledge layer is a compact, updateable map of the real repository.

### 6.1 Knowledge files

**`repo-map.md`** records major directories, architectural entry points, routing, state management, persistence, dependency injection, and platform configuration.

**`feature-registry.md`** records every confirmed product capability with entry points, state management, repositories/services, persistence, backend dependencies, tests, status, and known limitations.

**`feature-graph.md`** records relationships between major product capabilities so agents understand cross-feature integration opportunities and regression risk.

**`dependency-baseline.md`** records direct packages, purpose, criticality, affected features, upgrade risk, and last verification metadata. It does not attempt to store “latest available” forever.

**`supabase-map.md`** records confirmed schema objects, migrations, RLS relationships, storage, functions, Edge Functions, auth usage, and client dependencies.

**`known-risks.md`** records verified engineering risks with severity, confidence, evidence, affected area, and status.

**`health-register.md`** records preventive findings such as deprecated APIs, missing coverage, architecture drift, or package health concerns that do not require immediate repair.

**`product-debt.md`** records product journey gaps, redundant flows, confusing transitions, and experience debt that is not necessarily a technical defect.

**`opportunity-register.md`** records validated future opportunities with user problem, value, dependencies, complexity, risk, and recommended timing.

**`tech-radar.md`** classifies relevant technologies as ADOPT, TRIAL, ASSESS, or HOLD.

**`update-backlog.md`** stores non-urgent ecosystem migrations and maintenance items.

### 6.2 Staleness metadata

Generated or maintained knowledge files include metadata when practical:

```yaml
generated_from_commit: <git-sha-or-unknown>
last_verified: <date>
confidence: high|medium|low
```

If repository state differs materially from the recorded source commit, the agent performs targeted refresh on the task area before relying on the file.

### 6.3 Knowledge update policy

Agents may update technical knowledge files after verified work, but only with facts confirmed by repository inspection, commands, tests, runtime evidence, or authoritative external sources.

Product principles and Quran safety contracts are not silently rewritten as part of routine implementation tasks.

## 7. Discovery protocol

On first use in a repository, or when knowledge is absent/stale enough to be unreliable, the agent performs a targeted discovery pass:

1. inspect repository structure;
2. inspect `pubspec.yaml` and lockfile;
3. identify routing/navigation;
4. identify dependency injection/service location;
5. identify state management patterns;
6. identify domain/data boundaries;
7. identify local persistence and migration mechanisms;
8. identify Supabase integration and migrations;
9. discover major feature entry points;
10. inspect tests and QA tooling;
11. inspect Android/iOS configuration relevant to the task;
12. build or refresh only the knowledge files justified by the task.

A full repository scan is not required for every task.

## 8. Task intelligence and routing

The core classifies every request into one or more task labels:

```text
FEATURE, BUG, RUNTIME, PERFORMANCE, UI_UX, REFACTOR, ARCHITECTURE,
DEPENDENCY, FLUTTER_SDK, SUPABASE, DATABASE_MIGRATION, QURAN_ENGINE,
AUDIO, MEMORIZATION, REVISION, LEARNING, LOCAL_STORAGE, SECURITY,
PRIVACY, TESTING, RELEASE, STORE_REVIEW, ACCESSIBILITY, LOCALIZATION,
TECH_DEBT, EXPLORATION
```

The router loads only the modules needed for the classified task.

Examples:

- Quran page restoration lag → BUG + PERFORMANCE + QURAN_ENGINE + LOCAL_STORAGE.
- Update `supabase_flutter` → DEPENDENCY + SUPABASE + TESTING.
- Redesign kids path → UI_UX + FEATURE + PRODUCT CONTEXT.
- Wrong highlighted ayah during playback → BUG + AUDIO + QURAN_ENGINE + RUNTIME.

Before work begins, the agent creates a compact task contract:

```text
Goal
Affected area
Risk level
Evidence currently available
Modules/workflows required
Expected behavior
Verification method
```

## 9. Risk engine

Risk determines autonomy, verification depth, rollback thinking, and whether an explicit stop is required.

### Level 0 — Trivial

Copy, isolated spacing, non-functional visual polish.

### Level 1 — Low

Isolated widgets, minor UX improvements, local refactors with narrow impact.

### Level 2 — Medium

State management, navigation, local persistence behavior, audio controls, normal new features.

### Level 3 — High

Quran reader behavior, memorization progress, revision scheduling, auth, RLS, offline persistence, database migrations, audio/ayah synchronization.

### Level 4 — Critical

Canonical Quran text/mappings, destructive user-progress migration, data deletion, security model changes, irreversible production migration.

Critical tasks disallow speculative edits and require deterministic verification.

## 10. Product intelligence

Talia is treated as a coherent Quran companion rather than a collection of features.

### 10.1 Product journey

The system evaluates features against the broader journey:

```text
Discover → Read → Understand/Learn → Listen → Repeat → Memorize →
Recite/Test → Detect Weakness → Review → Maintain Mastery → Return
```

Not every user must follow the full path. The journey is a product integration model, not a mandatory funnel.

### 10.2 Product decision outcomes

A proposal is classified as:

- **BUILD** — justified new capability;
- **EXTEND** — existing system should be evolved;
- **DEFER** — useful but not worth current cost/risk;
- **REJECT** — duplicative, distracting, unsafe, or misaligned.

### 10.3 Product value dimensions

Agents consider:

- real user need;
- relationship to Quran use;
- integration with existing Talia capabilities;
- learning/memorization value;
- habit/return value;
- differentiation;
- implementation complexity;
- maintenance burden;
- correctness/privacy/security risk.

The scoring model is a decision aid, not a fake precision metric.

### 10.4 Adult and kids balance

Core data and learning systems should be shared where appropriate. Presentation may vary by audience. Playful UI, characters, celebrations, and gamification must not make the adult experience feel children-only or interfere with focused Quran reading.

### 10.5 Gamification rule

Rewards should reinforce meaningful Quran, learning, revision, or habit behaviors rather than arbitrary app engagement.

## 11. Quran integrity contract

Quran-related content and identifiers are correctness-critical.

The agent must not:

- generate or “repair” Quran text with an LLM;
- silently remap ayah, surah, page, juz, hizb, QCF, recitation, bookmark, memorization, or review identifiers;
- treat visual plausibility as proof of correctness;
- use an AI opinion as the canonical validator of Quran data.

When a change touches canonical mappings, navigation, recitation synchronization, or stored Quran locations, it requires deterministic regression coverage and broader impact analysis.

## 12. Prevention and self-defense

The system performs targeted preventive checks relevant to the current task.

Signals include:

- deprecated APIs;
- upcoming platform incompatibility;
- unmaintained or unstable dependencies;
- security/RLS concerns;
- missing regression coverage;
- architecture drift;
- repeated runtime failures;
- expensive rebuilds or synchronous work on critical paths;
- slow/repeated queries;
- unsafe migrations;
- release-policy risks.

Findings are classified as:

- **Immediate** — active correctness, security, data, crash, or release blocker;
- **Near-term** — clear upcoming compatibility/deprecation issue;
- **Maintenance** — technical debt worth tracking;
- **Opportunity** — optional improvement, not a defect.

Discovery never implies automatic repair. The agent chooses Fix now, Include with current work, Log for later, or Ignore.

## 13. Ecosystem intelligence

When decisions depend on current external state, the agent performs a freshness check.

### 13.1 Source hierarchy

Use the most authoritative current source available:

1. official Flutter/Dart documentation and release notes;
2. official Supabase documentation and migration guides;
3. official Android/Apple platform documentation and store policies;
4. official package repository/changelog;
5. pub.dev package metadata;
6. maintainer issue trackers and high-quality supporting discussion.

### 13.2 Change classification

External changes are classified as:

- Mandatory;
- Strongly Recommended;
- Useful Opportunity;
- Experimental;
- Irrelevant to Talia.

“New” is not equivalent to “better.”

### 13.3 Dependency upgrade workflow

For dependency work:

1. identify reason for upgrade;
2. inspect project constraints and `pubspec` state;
3. run/inspect outdated tooling;
4. distinguish direct and transitive dependencies;
5. inspect changelogs and breaking changes;
6. map affected Talia features;
7. upgrade in controlled batches;
8. run relevant analysis/tests/runtime validation;
9. update dependency baseline/backlog only with verified facts.

Major package replacement requires a concrete current pain point, feature parity analysis, migration cost, data compatibility, platform reliability, and rollback/removal thinking.

## 14. Debugging and incident response

No bug fix is proposed before root-cause investigation.

### 14.1 Standard debugging phases

1. read the exact error, logs, and stack traces;
2. reproduce consistently where possible;
3. check recent changes and environmental differences;
4. trace data/state across component boundaries;
5. compare with similar working code;
6. form one explicit hypothesis;
7. test the hypothesis with the smallest useful experiment;
8. create a failing regression case when practical;
9. implement the minimal root-cause fix;
10. verify the original symptom and nearby regressions.

After three failed fix attempts, the agent stops adding fixes and reevaluates architectural assumptions.

### 14.2 Incident classification

Incidents may include crashes, data corruption, state inconsistency, performance regression, build/release failures, dependency regressions, Supabase/auth failures, Quran integrity failures, audio lifecycle failures, and unknown production-only defects.

Severity is classified SEV-0 through SEV-3 based on blast radius, recoverability, correctness, data, security, and product impact.

### 14.3 Reproducibility

Use:

- R0 — not reproduced;
- R1 — reproduced once;
- R2 — intermittently reproducible;
- R3 — consistently reproducible.

Intermittent issues should record observed rate when practical.

### 14.4 Incident workflow

```text
Detect → Contain → Gather Evidence → Reproduce → Trace Root Cause →
Hypothesis → Experiment → Minimal Fix → Regression Test → Verify →
Document Cause → Prevent Recurrence
```

Containment and repair are distinct. A feature flag or safe fallback may be used to stop damage while investigation continues.

### 14.5 Incident records

Significant incidents may create `knowledge/incidents/INC-<date>-<slug>.md` containing symptom, impact, root cause, fix, verification, missed detection, and prevention added.

## 15. Supabase and data safety

Before backend changes, inspect the real schema, migrations, RLS, functions, storage, auth, and client assumptions.

Rules:

- least privilege;
- no service-role key in Flutter;
- RLS must test both allowed and denied paths;
- destructive data changes are high/critical risk;
- old and new application versions may coexist, so backend compatibility windows matter;
- migrations must consider rollout order and rollback/recovery;
- user progress/history must not be silently reset or remapped.

### 15.1 Migration risk levels

- **M0 Additive** — new optional fields/tables without breaking clients;
- **M1 Compatible** — behavior/schema changes that preserve current clients;
- **M2 Transformative** — transforms existing data or identifiers;
- **M3 Destructive/Breaking** — removes/renames required structures or irreversibly transforms data.

M2/M3 changes require explicit data-preservation and recovery thinking. M3 requires approval before execution.

## 16. Verification and quality system

The completion standard is evidence-based.

### 16.1 Status vocabulary

Agents distinguish:

- **Implemented** — code changed;
- **Statically Verified** — analyzer/lint/static checks passed;
- **Test Verified** — relevant automated tests passed;
- **Runtime Verified** — real scenario was exercised successfully;
- **Measured** — before/after performance or other metrics were captured;
- **Release Verified** — required release gates passed.

No stronger status is claimed without its evidence.

### 16.2 Verification matrix

Verification depth is selected by task and risk, not by a universal command list.

Examples:

**Low UI change:** analyzer + targeted widget/runtime visual check.

**Quran reader change:** analyzer + relevant unit/widget/integration coverage + mapping/restore checks + runtime navigation + affected audio/bookmark regressions.

**Supabase migration:** schema/migration validation + RLS allowed/denied paths + client compatibility + data preservation + rollout/rollback assessment.

**Performance task:** measured baseline + profiling + one or more controlled changes + measured after state.

### 16.3 Runtime validation

Depending on the change, runtime validation covers:

- clean/fresh state;
- existing user state;
- enter/leave/re-enter flow;
- app background/resume;
- restart/process recreation where relevant;
- offline/slow/failure states;
- Arabic RTL and English LTR;
- text scaling and small-screen layout;
- Android back/navigation behavior;
- upgrade from an older app/data version when migrations are involved.

### 16.4 Evidence ledger

Large tasks maintain a compact record of which checks passed, failed, were not run, or were not applicable. This prevents “done” claims from relying on memory or inference.

### 16.5 No hidden failure rule

Pre-existing failures may be separated from new failures only when a baseline or other evidence proves they predate the current change.

## 17. Performance contract

Static code review may identify performance risk but does not prove measured performance impact.

Performance work must:

1. define the slow/janky/expensive behavior;
2. capture a baseline;
3. profile the relevant resource/path;
4. identify the bottleneck;
5. change a meaningful cause;
6. measure again;
7. report measured improvement, regression, no meaningful difference, or not measured.

Metrics may include startup time, frame timing/jank, memory, database latency, network duplication, audio start latency, rebuild counts, or other task-specific signals.

## 18. UI/UX and accessibility contract

A redesign is not considered successful solely because it looks better.

Relevant checks include hierarchy, readability, touch targets, accessibility, loading/empty/error states, navigation clarity, consistency, icon overload, RTL/LTR, text scaling, and real user effort.

Talia-specific UX checks include:

- does it distract from Quran reading;
- does it make adult experiences feel children-only;
- does the companion interrupt focus;
- does it add unnecessary dashboard complexity;
- does it support the intended learning/reading/habit journey.

The application is mobile-first; web/desktop responsiveness is not added unless product scope changes.

## 19. Autonomy and safety

### 19.1 Default autonomy

The agent may proceed autonomously when a change is understood, local, reversible, in approved scope, and verifiable.

Normal autonomous actions include reading files, editing relevant project code, adding tests, running analysis/tests/profile commands, performing scoped refactors required by the task, and updating verified knowledge files.

### 19.2 Explicit approval boundaries

Stop before executing:

- destructive production database changes;
- production data deletion;
- irreversible local data migrations;
- changes to canonical Quran sources or canonical mapping strategy;
- major application architecture replacement outside approved scope;
- authentication/security-model replacement;
- exposure/rotation/use of secrets in unsafe ways;
- broad framework/package replacement with major project-wide impact;
- force push, history rewriting, destructive git reset/clean affecting unknown work.

The agent should still perform analysis and propose the safe path before stopping.

### 19.3 Git safety

Unknown or unrecognized work is preserved. The agent never resets or deletes it merely because it did not create it.

Safe inspection commands such as status, diff, log, show, branch, and blame are allowed. Destructive history/worktree actions require explicit authorization and impact awareness.

### 19.4 Scope and change-radius guard

Every task has an expected change radius. If an apparently small task expands across many unrelated files/subsystems, the agent stops and reevaluates whether the root cause or architecture assumptions are wrong.

Only task-required refactors are included. Other findings go to the risk, health, product-debt, opportunity, or update registers.

### 19.5 Destructive action gate

Before any destructive action, the agent must know:

- environment;
- exact scope;
- blast radius;
- backup/recovery path;
- rollback feasibility;
- why the action is necessary.

If these are unknown, the action is not executed.

## 20. Observability

Observability exists to reduce production-only guesswork while preserving privacy.

Relevant signals may include crashes, uncaught exceptions, critical flow failures, startup failures, audio failures, Supabase failures, migration failures, and performance traces.

Do not log secrets, auth tokens, unnecessary personal data, private user content, or detailed worship/reading behavior without a justified product/diagnostic need and appropriate privacy treatment.

## 21. Release readiness

A pre-release workflow evaluates, as applicable:

- analyzer/tests;
- release build;
- crash-free launch and critical flows;
- permissions and notification behavior;
- privacy/data disclosures;
- account deletion requirements when relevant;
- background/audio behavior;
- deep links;
- offline/poor-network behavior;
- platform target/manifest configuration;
- signing/build variants;
- Supabase compatibility;
- upgrade from an existing installation/data state;
- Android/iOS/store requirements verified against current official sources.

Release readiness never assumes store policies are unchanged.

## 22. Technology spikes

Promising but uncertain technology is evaluated through isolated experiments rather than direct production adoption.

A technology spike defines:

- question/hypothesis;
- minimal prototype or benchmark;
- representative input set;
- success metrics;
- privacy/correctness constraints;
- discard/adopt decision.

Spike code is not automatically promoted to production architecture.

## 23. Scripts

V2 may include non-destructive helper scripts. Scripts are convenience tools, not substitutes for agent reasoning.

**`talia_doctor.ps1`** captures Flutter/Dart/tooling/dependency/analyzer/test/git baseline.

**`dependency_audit.ps1`** captures dependency status without automatically changing versions.

**`project_snapshot.ps1`** produces a concise project snapshot suitable for refreshing living knowledge without dumping sensitive values.

All scripts must default to read-only/non-destructive behavior unless the user explicitly invokes a documented mutating mode.

## 24. Skill pressure testing

The skill itself is tested with pressure scenarios. At minimum:

1. shiny new package replacement request;
2. blind “update everything” request;
3. generic architecture rewrite request;
4. LLM Quran text normalization request;
5. fabricated performance improvement request;
6. Supabase service-role-in-client shortcut;
7. duplicate feature creation request;
8. whole-app childlike redesign request;
9. three failed fix attempts without architecture reevaluation;
10. destructive migration without recovery plan;
11. unknown uncommitted work followed by reset request;
12. store/release claim based on stale platform assumptions;
13. stale knowledge file conflicting with repository code;
14. production-only bug without reproduction evidence;
15. feature request that should extend an existing capability.

Pressure tests should be run first without the skill when feasible, then with the skill, and failures should be used to tighten wording rather than simply add verbosity.

## 25. Completion report contract

For substantial work, the agent reports:

```text
TASK
<goal>

CHANGED
<verified scope of changes>

VERIFIED
<checks actually run and results>

NOT VERIFIED
<relevant checks not performed>

RISKS / COMPATIBILITY
<remaining risk, migration, rollback, or coexistence concerns>

ECOSYSTEM EVIDENCE
<which current external facts were verified, if applicable>

FOLLOW-UP
<only meaningful next work>
```

A report must not imply stronger verification than was actually performed.

## 26. Skill evolution policy

The skill records its own structural version and limitations in `knowledge/skill-version.md`.

Routine feature tasks may propose skill-improvement candidates when they expose a missing rule or workflow. They do not silently rewrite core product principles or safety rules.

Skill changes should be pressure-tested before being treated as stable.

## 27. Acceptance criteria for V2 implementation

V2 implementation is complete when all of the following are true:

1. `SKILL.md` is concise and acts as router/constitution rather than a monolith.
2. All task families in this spec route to appropriate modules/workflows.
3. Risk levels materially change verification/autonomy behavior.
4. Repository truth explicitly overrides stale knowledge.
5. Knowledge files have clear ownership and update rules.
6. Ecosystem freshness never depends on permanently stored “latest” versions.
7. Quran safety rules prevent LLM-generated canonical content and speculative mapping changes.
8. Debugging workflow requires root cause before fixes and stops after repeated failed attempts.
9. Performance claims require measurements.
10. Verification statuses distinguish implemented, statically verified, test verified, runtime verified, measured, and release verified.
11. Supabase rules cover RLS, secrets, migration compatibility, rollout order, and data preservation.
12. Git/destructive-action safety protects unknown work and production data.
13. Product intelligence can recommend BUILD, EXTEND, DEFER, or REJECT.
14. Prevention findings can be logged without forcing scope expansion.
15. Pressure tests cover the major rationalization/failure modes in Section 24.
16. Existing V1 capabilities are preserved or deliberately replaced by clearer V2 modules.
17. Helper scripts are non-destructive by default.
18. No unresolved placeholder, contradictory requirement, or undefined critical term remains in the spec.

## 28. Implementation boundary

This document defines the V2 design only. It does not authorize direct modification of the Talia application repository. The next step after user review is to create a detailed implementation plan for transforming the existing `talia-quran-engineer` skill package into this architecture, then execute that plan with skill-level tests and verification.
