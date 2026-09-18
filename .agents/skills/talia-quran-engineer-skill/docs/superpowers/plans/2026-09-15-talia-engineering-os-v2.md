# Talia Engineering OS V2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the existing `talia-quran-engineer` V1 package into the approved Talia Engineering OS V2 hybrid skill system with a concise router core, task modules, workflows, living knowledge, non-destructive helper scripts, and pressure-testable safety/quality contracts.

**Architecture:** Keep `SKILL.md` small and always-loadable, with routing into focused `core/`, `modules/`, `workflows/`, `references/`, and `knowledge/` files. Treat the current Talia repository as source of truth, use living knowledge only as an accelerator, and validate the skill package with a small Python standard-library test suite plus human-readable pressure scenarios.

**Tech Stack:** Agent Skills Markdown (`SKILL.md` + supporting `.md` files), PowerShell helper scripts, Python 3 standard-library validation tests, Git.

**Spec:** `docs/superpowers/specs/2026-09-15-talia-engineering-os-v2-design.md`

## Global Constraints

- Do not hard-code a permanently “latest” Flutter, Dart, Supabase, Android, iOS, or package version.
- Repository inspection overrides stale knowledge files.
- Quran text and canonical Quran mappings must never be generated or repaired by an LLM.
- No runtime, test, performance, release, or compatibility success claim without fresh evidence.
- Destructive/irreversible production actions require explicit approval and recovery understanding.
- Unknown/unrecognized Git work must be preserved.
- Helper scripts must be read-only/non-destructive by default.
- Existing V1 behavior must be preserved unless replaced by a clearer V2 contract.
- Keep the core concise; detailed policy belongs in supporting files.
- Use TDD for the skill package: create/extend validation tests before the files that satisfy them.

---

## File Structure

The completed package will use this structure:

```text
talia-quran-engineer/
├── SKILL.md
├── README.md
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
│   ├── source-authority.md
│   ├── freshness-and-upgrades.md
│   └── quality-gates.md
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
│       └── README.md
├── scripts/
│   ├── talia_doctor.ps1
│   ├── dependency_audit.ps1
│   └── project_snapshot.ps1
└── tests/
    ├── test_skill_structure.py
    ├── test_skill_contracts.py
    ├── skill-pressure-tests.md
    ├── routing-scenarios.md
    └── regression-scenarios.md
```

`tests/test_skill_structure.py` owns package-shape/frontmatter/link/non-destructive-script validation. `tests/test_skill_contracts.py` owns semantic guardrails that can be checked deterministically without trying to simulate an LLM. Markdown pressure scenarios remain the human/agent behavioral test suite.

---

### Task 1: Create the V2 Structural Validation Harness

**Files:**
- Create: `tests/test_skill_structure.py`
- Modify: none
- Test: `tests/test_skill_structure.py`

**Interfaces:**
- Consumes: current V1 package root.
- Produces: `read_text()`, `assert_paths_exist()`, and local-link/script safety helpers that later tasks extend with failing tests before implementation.

- [ ] **Step 1: Create the baseline structure test harness**

Create `tests/test_skill_structure.py` with Python standard library only:

```python
from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read_text(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def assert_paths_exist(testcase: unittest.TestCase, *paths: str) -> None:
    missing = sorted(path for path in paths if not (ROOT / path).is_file())
    testcase.assertEqual([], missing, f"Missing files: {missing}")


def local_markdown_targets(text: str) -> list[str]:
    targets = []
    for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", text):
        if "://" not in target and not target.startswith("#"):
            targets.append(target.split("#", 1)[0])
    return targets


class SkillStructureTests(unittest.TestCase):
    def test_v1_baseline_files_exist(self) -> None:
        assert_paths_exist(
            self,
            "SKILL.md",
            "README.md",
            "references/talia-product-context.md",
            "references/freshness-and-upgrades.md",
            "references/quality-gates.md",
            "scripts/talia_doctor.ps1",
            "tests/skill-pressure-tests.md",
        )

    def test_skill_frontmatter_is_discoverable_and_compact(self) -> None:
        value = read_text("SKILL.md")
        self.assertTrue(value.startswith("---\n"))
        frontmatter = value.split("---", 2)[1]
        self.assertRegex(frontmatter, r"(?m)^name: talia-quran-engineer$")
        match = re.search(r"(?m)^description:\s*(.+)$", frontmatter)
        self.assertIsNotNone(match)
        description = match.group(1).strip()
        self.assertTrue(description.startswith("Use when "))
        self.assertLessEqual(len(description), 500)
        self.assertLessEqual(len(frontmatter), 1024)

    def test_local_markdown_links_resolve(self) -> None:
        failures: list[str] = []
        roots = [ROOT / "SKILL.md", ROOT / "README.md"]
        for directory in ("core", "references", "modules", "workflows", "knowledge", "tests"):
            candidate = ROOT / directory
            if candidate.exists():
                roots.extend(candidate.rglob("*.md"))
        for path in roots:
            if not path.is_file():
                continue
            value = path.read_text(encoding="utf-8")
            for target in local_markdown_targets(value):
                resolved = (path.parent / target).resolve()
                if not resolved.exists():
                    failures.append(f"{path.relative_to(ROOT)} -> {target}")
        self.assertEqual([], failures)

    def test_existing_helper_script_avoids_obvious_destructive_commands(self) -> None:
        value = read_text("scripts/talia_doctor.ps1").lower()
        for token in ("git reset --hard", "git clean -fd", "drop table", "truncate table"):
            self.assertNotIn(token, value)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the harness against V1**

Run:

```bash
python -m unittest tests.test_skill_structure -v
```

Expected: PASS. This task creates test infrastructure only; the first V2 RED condition is introduced in Task 2 immediately before core implementation.

- [ ] **Step 3: Commit the test harness**

```bash
git add tests/test_skill_structure.py
git commit -m "test: add Talia skill validation harness"
```

---

### Task 2: Refactor `SKILL.md` into the V2 Core Router and Add Core Policies

**Files:**
- Modify: `SKILL.md`
- Create: `core/task-router.md`
- Create: `core/risk-engine.md`
- Create: `core/autonomy-policy.md`
- Create: `core/completion-contract.md`
- Modify: `tests/test_skill_structure.py`
- Test: `tests/test_skill_structure.py`

**Interfaces:**
- Consumes: V2 spec Sections 4, 5, 8, 9, 16, 19, and 25.
- Produces: stable routing vocabulary, risk levels `0..4`, operating modes `DISCOVER|PLAN|IMPLEMENT|INCIDENT`, completion statuses, and a concise core that links to modules/workflows.

- [ ] **Step 1: Extend the structure test with core contract expectations**

Add this test to `tests/test_skill_structure.py`:

```python
    def test_core_router_exposes_required_operating_contracts(self) -> None:
        assert_paths_exist(
            self,
            "core/task-router.md",
            "core/risk-engine.md",
            "core/autonomy-policy.md",
            "core/completion-contract.md",
        )
        skill = read_text("SKILL.md")
        self.assertLessEqual(len(skill.split()), 900, "Move detailed policy out of SKILL.md")
        for phrase in (
            "Repository first",
            "Diagnose before fixing",
            "Extend before rebuilding",
            "Evidence before claims",
            "Quran integrity above convenience",
            "Unknown is not assumed",
        ):
            self.assertIn(phrase, skill)
        for target in (
            "core/task-router.md",
            "core/risk-engine.md",
            "core/autonomy-policy.md",
            "core/completion-contract.md",
        ):
            self.assertIn(target, skill)
```

- [ ] **Step 2: Run the targeted test and confirm RED**

```bash
python -m unittest tests.test_skill_structure.SkillStructureTests.test_core_router_exposes_required_operating_contracts -v
```

Expected: FAIL because the V1 `SKILL.md` does not link to the new core files.

- [ ] **Step 3: Replace `SKILL.md` with a compact constitution/router**

Use this exact top-level shape; keep detailed explanations in linked files:

```markdown
---
name: talia-quran-engineer
description: Use when working on any feature, bug, refactor, dependency upgrade, UI/UX or performance task, Supabase change, Quran reading/memorization/learning flow, architecture decision, runtime incident, or release review in the Talia Quran Flutter application.
---

# Talia Engineering OS

Treat Talia as a product-specific engineering system, not a generic Flutter repository.

## Constitution

1. **Repository first.** Inspect current relevant code before proposing changes.
2. **Diagnose before fixing.** Unexpected behavior requires root-cause investigation.
3. **Extend before rebuilding.** Search for existing capabilities before creating parallel systems.
4. **Evidence before claims.** Tests, runtime, performance and compatibility claims require fresh evidence.
5. **Tests before completion.** Applicable verification gates define done.
6. **Quran integrity above convenience.** Canonical Quran content and mappings are correctness-critical.
7. **Current sources before ecosystem decisions.** Verify authoritative current sources when freshness matters.
8. **Repository beats knowledge.** Living knowledge accelerates discovery but never overrides code reality.
9. **Smallest safe change.** Avoid unrelated refactors and uncontrolled migrations.
10. **Unknown is not assumed.** Search, measure, or mark unknown explicitly.

## Start Here

1. Determine operating mode: `DISCOVER`, `PLAN`, `IMPLEMENT`, or `INCIDENT`.
2. Inspect task-relevant repository context and living knowledge.
3. Create the task contract: goal, affected area, risk, evidence, modules/workflows, expected behavior, verification.
4. Use [Task Router](core/task-router.md) to select modules/workflows.
5. Use [Risk Engine](core/risk-engine.md) to set verification and autonomy depth.
6. Apply [Autonomy Policy](core/autonomy-policy.md).
7. Before any completion claim, apply [Completion Contract](core/completion-contract.md).

## Always-Required Product/Safety Context

Read [Talia Product Context](references/talia-product-context.md), [Engineering Principles](references/engineering-principles.md), and [Quran Safety Contract](references/quran-safety-contract.md) when the task touches their scope.

For freshness-sensitive decisions use [Source Authority](references/source-authority.md) and [Freshness & Upgrades](references/freshness-and-upgrades.md).

## Living Knowledge Rule

Use `knowledge/` as a navigation accelerator. Refresh task-relevant entries when stale. If knowledge conflicts with repository evidence, repository evidence wins and verified knowledge is corrected after the task.

## Completion

Report only statuses supported by fresh evidence: `Implemented`, `Statically Verified`, `Test Verified`, `Runtime Verified`, `Measured`, or `Release Verified`.
```

- [ ] **Step 4: Create `core/task-router.md`**

Include these exact routing labels and rules:

```markdown
# Task Router

## Task Contract

Before execution record: Goal; Affected area; Risk level; Evidence available; Modules/workflows required; Expected behavior; Verification method.

## Labels

`FEATURE`, `BUG`, `RUNTIME`, `PERFORMANCE`, `UI_UX`, `REFACTOR`, `ARCHITECTURE`, `DEPENDENCY`, `FLUTTER_SDK`, `SUPABASE`, `DATABASE_MIGRATION`, `QURAN_ENGINE`, `AUDIO`, `MEMORIZATION`, `REVISION`, `LEARNING`, `LOCAL_STORAGE`, `SECURITY`, `PRIVACY`, `TESTING`, `RELEASE`, `STORE_REVIEW`, `ACCESSIBILITY`, `LOCALIZATION`, `TECH_DEBT`, `EXPLORATION`.

## Routing Rules

- Bug/unexpected behavior → `modules/debugging.md` + `workflows/bug-fix.md`.
- Crash/data/security/Quran-integrity production failure → `modules/incident-response.md` + `workflows/incident-response.md`.
- Lag/jank/startup/memory → `modules/performance.md` + `workflows/performance-investigation.md`.
- Package/SDK update → `modules/dependency-upgrades.md` + `modules/ecosystem-intelligence.md` + `workflows/dependency-upgrade.md`.
- Supabase/RLS/schema/auth → `modules/supabase.md` + `modules/security-privacy.md`; schema change also loads `workflows/supabase-migration.md`.
- Quran mapping/navigation/recitation references → `modules/quran-engine.md` + `modules/quran-integrity.md` + `modules/testing-qa.md`.
- Memorization/revision → `modules/memorization-learning.md` and/or `modules/revision.md`, plus Quran integrity if identifiers are touched.
- Audio/lifecycle/synchronization → `modules/audio.md`; load Quran engine if ayah synchronization is involved.
- UI redesign → `modules/ui-ux.md` + relevant product/domain module.
- New feature → `modules/feature-development.md` + `workflows/new-feature.md`.
- Architecture refactor → `modules/architecture-refactoring.md`.
- Release/store review → `modules/release-readiness.md` + `workflows/pre-release-audit.md`.

Load only modules that materially affect the task.
```

- [ ] **Step 5: Create `core/risk-engine.md`**

Define Levels 0–4 exactly as the spec, and include a matrix with columns `Level | Typical scope | Minimum verification | Autonomy`. Level 4 must contain the sentence: `Critical tasks disallow speculative edits and require deterministic verification.`

- [ ] **Step 6: Create `core/autonomy-policy.md`**

Define the four operating modes plus `Continue automatically`, `Continue with caution`, and `Stop before execution`. Explicit stop cases must include destructive production DB changes, production data deletion, irreversible local migration, canonical Quran source/mapping strategy changes, major architecture replacement outside scope, auth/security-model replacement, unsafe secret handling, destructive Git history/worktree actions.

- [ ] **Step 7: Create `core/completion-contract.md`**

Define the status vocabulary and the final report template:

```text
TASK
State the user-requested goal in one sentence.

CHANGED
List only files/behavior actually changed.

VERIFIED
List each command/scenario actually run with its observed result.

NOT VERIFIED
List relevant checks that were not performed.

RISKS / COMPATIBILITY
State remaining migration, rollback, coexistence, or correctness concerns.

ECOSYSTEM EVIDENCE
List authoritative current external facts checked for this task, or state that none were required.

FOLLOW-UP
List only meaningful next work that is outside the completed scope.
```

State: `No completion claim without fresh verification evidence.`

- [ ] **Step 8: Run core tests**

```bash
python -m unittest tests.test_skill_structure -v
```

Expected: PASS. Later V2 files are not required until their own tasks introduce failing tests for them.

- [ ] **Step 9: Commit**

```bash
git add SKILL.md core tests/test_skill_structure.py
git commit -m "feat: add Talia V2 core router and safety policies"
```

---

### Task 3: Build Durable Product, Architecture, Quran, and Source References

**Files:**
- Modify: `references/talia-product-context.md`
- Create: `references/architecture-contract.md`
- Create: `references/quran-safety-contract.md`
- Create: `references/engineering-principles.md`
- Create: `references/source-authority.md`
- Modify: `references/freshness-and-upgrades.md`
- Modify: `references/quality-gates.md`
- Create: `tests/test_skill_contracts.py`
- Test: `tests/test_skill_contracts.py`

**Interfaces:**
- Consumes: spec Sections 1, 2, 10, 11, 13, 16–18.
- Produces: durable references used by all domain modules without duplicating product/safety rules.

- [ ] **Step 1: Write failing semantic contract tests**

Create `tests/test_skill_contracts.py`:

```python
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class SkillContractTests(unittest.TestCase):
    def test_quran_contract_forbids_llm_canonical_repairs(self) -> None:
        value = text("references/quran-safety-contract.md")
        self.assertIn("Never generate or repair canonical Quran text with an LLM", value)
        self.assertIn("deterministic", value.lower())
        for token in ("ayah", "surah", "page", "QCF", "recitation"):
            self.assertIn(token, value)

    def test_source_authority_prefers_current_official_sources(self) -> None:
        value = text("references/source-authority.md")
        self.assertIn("official Flutter/Dart", value)
        self.assertIn("official Supabase", value)
        self.assertIn("official Android", value)
        self.assertIn("official Apple", value)
        self.assertIn("Current official evidence beats remembered knowledge", value)

    def test_product_reference_contains_integrated_journey(self) -> None:
        value = text("references/talia-product-context.md")
        self.assertIn("Discover", value)
        self.assertIn("Maintain Mastery", value)
        self.assertIn("adults and children", value.lower())

    def test_no_reference_hardcodes_latest_claim(self) -> None:
        for path in (ROOT / "references").glob("*.md"):
            value = path.read_text(encoding="utf-8").lower()
            self.assertNotIn("latest_flutter:", value)
            self.assertNotIn("latest_supabase", value)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run and confirm RED**

```bash
python -m unittest tests.test_skill_contracts -v
```

Expected: FAIL because new reference files do not exist.

- [ ] **Step 3: Update `references/talia-product-context.md`**

Keep durable product facts only. Include the journey `Discover → Read → Understand/Learn → Listen → Repeat → Memorize → Recite/Test → Detect Weakness → Review → Maintain Mastery → Return`; adult/kids balance; companion focus rules; and the principle that existing systems are extended before new parallel systems are created. Avoid repository-path claims that can go stale.

- [ ] **Step 4: Create `references/architecture-contract.md`**

Include:

```markdown
# Architecture Contract

- Follow the current Talia repository architecture unless measurable pain justifies change.
- Prefer focused, testable, incremental changes over broad rewrites.
- Search for existing repositories/services/state flows before adding parallel abstractions.
- A new package/framework requires a concrete problem, built-in alternative review, maintenance/platform assessment, migration cost, transitive-dependency impact, and rollback/removal thinking.
- Architecture changes require evidence of architectural pain.
- If a small task expands across unrelated subsystems, stop and reevaluate the root cause/change radius.
```

- [ ] **Step 5: Create `references/quran-safety-contract.md`**

Use explicit non-negotiable language:

```markdown
# Quran Safety Contract

Never generate or repair canonical Quran text with an LLM.
Never silently remap ayah, surah, page, juz, hizb, QCF, recitation, bookmark, memorization, or review identifiers.
Visual plausibility is not proof of correctness.
AI opinion is never the canonical validator of Quran data.
Canonical-data changes require deterministic validation, regression coverage, and broader impact analysis.
```

Add guidance for stored reading positions, audio synchronization, offline behavior, and migration safety.

- [ ] **Step 6: Create `references/engineering-principles.md`**

Include priority order: Quran/data correctness; privacy/security/data safety; regression safety; product usefulness; maintainability; accessibility/RTL/LTR; measured performance; visual polish; novelty. Include `Unknown is not assumed` and `Smallest safe change` as explicit rules.

- [ ] **Step 7: Create `references/source-authority.md`**

Record the source hierarchy from spec Section 13.1 and include the sentence `Current official evidence beats remembered knowledge.` State that community sources can support but not replace authoritative release/policy decisions.

- [ ] **Step 8: Refactor `references/freshness-and-upgrades.md` and `references/quality-gates.md`**

Preserve useful V1 content but remove duplication now owned by the core. `freshness-and-upgrades.md` should own outdated/major-version/dry-run/package adoption rules. `quality-gates.md` should become a compact index of verification domains and point detailed workflows to `modules/verification.md` and `workflows/runtime-validation.md` once they exist.

- [ ] **Step 9: Run semantic tests**

```bash
python -m unittest tests.test_skill_contracts -v
```

Expected: PASS.

- [ ] **Step 10: Commit**

```bash
git add references tests/test_skill_contracts.py
git commit -m "feat: add durable Talia product and Quran safety contracts"
```

---

### Task 4: Add Living Knowledge Templates and Staleness Rules

**Files:**
- Create: `knowledge/repo-map.md`
- Create: `knowledge/feature-registry.md`
- Create: `knowledge/feature-graph.md`
- Create: `knowledge/dependency-baseline.md`
- Create: `knowledge/supabase-map.md`
- Create: `knowledge/known-risks.md`
- Create: `knowledge/health-register.md`
- Create: `knowledge/product-debt.md`
- Create: `knowledge/opportunity-register.md`
- Create: `knowledge/tech-radar.md`
- Create: `knowledge/update-backlog.md`
- Create: `knowledge/skill-version.md`
- Create: `knowledge/incidents/README.md`
- Modify: `tests/test_skill_contracts.py`
- Test: `tests/test_skill_contracts.py`

**Interfaces:**
- Consumes: spec Section 6 and Section 26.
- Produces: stable templates that future agents can refresh without inventing facts.

- [ ] **Step 1: Add failing knowledge-template tests**

Append:

```python
    def test_knowledge_templates_declare_staleness_metadata(self) -> None:
        for relative in (
            "knowledge/repo-map.md",
            "knowledge/feature-registry.md",
            "knowledge/dependency-baseline.md",
            "knowledge/supabase-map.md",
        ):
            value = text(relative)
            self.assertIn("generated_from_commit", value)
            self.assertIn("last_verified", value)
            self.assertIn("confidence", value)

    def test_skill_version_starts_at_v2(self) -> None:
        value = text("knowledge/skill-version.md")
        self.assertIn("Version: 2.0", value)
        self.assertIn("Known limitations", value)
```

- [ ] **Step 2: Run and confirm RED**

```bash
python -m unittest tests.test_skill_contracts.SkillContractTests.test_knowledge_templates_declare_staleness_metadata -v
```

Expected: FAIL because knowledge files do not exist.

- [ ] **Step 3: Create the four source-mapped templates**

Each of `repo-map.md`, `feature-registry.md`, `dependency-baseline.md`, and `supabase-map.md` starts with:

```yaml
---
generated_from_commit: unknown
last_verified: unknown
confidence: low
---
```

Then include explicit instructions: `Populate only from verified repository/tool evidence. If this file conflicts with the repository, the repository wins.`

Use these record shapes:

```markdown
## Feature Record
Name:
Status: unknown
Entry points:
State management:
Repositories/services:
Local persistence:
Supabase dependencies:
Tests:
Known limitations:
```

```markdown
## Dependency Record
Package:
Purpose:
Criticality: low|medium|high|critical
Affected features:
Upgrade risk: low|medium|high|critical
Last verified:
```

```markdown
## Supabase Record
Object:
Type: table|view|rpc|function|edge-function|bucket|auth-flow|policy
Used by:
Ownership/RLS notes:
Migration source:
Last verified:
```

- [ ] **Step 4: Create registers**

Use explicit schemas rather than fabricated entries:

```markdown
# Known Risks

## Risk Record
ID:
Area:
Severity:
Confidence:
Evidence:
Impact:
Status: open|mitigated|closed
```

`health-register.md` adds `Type: immediate|near-term|maintenance|opportunity` and `Recommended action: fix-now|include-with-current-work|log-for-later|ignore`.

`product-debt.md` records `User journey gap`, `Impact`, `Related features`, `Potential improvement`.

`opportunity-register.md` records `User problem`, `Value`, `Dependencies`, `Complexity`, `Risk`, `Recommended timing`, `Status`.

`tech-radar.md` contains four sections: `ADOPT`, `TRIAL`, `ASSESS`, `HOLD`, with a rule not to classify technology without evidence.

`update-backlog.md` records `Area`, `Reason`, `Priority`, `Risk`, `Suggested window`, `Status`.

- [ ] **Step 5: Create `feature-graph.md`, `skill-version.md`, and incident template guidance**

`feature-graph.md` must state that relationships are confirmed from repository/product evidence, not invented. `skill-version.md` starts with `Version: 2.0` and includes `Last structural review`, `Major additions`, `Known limitations`, `Skill improvement candidates`. `knowledge/incidents/README.md` defines incident filenames such as `INC-2026-09-15-audio-resume.md` and fields: Symptom, Impact, Reproducibility, Root cause, Fix, Verification, Why detection missed it, Prevention added.

- [ ] **Step 6: Run tests**

```bash
python -m unittest tests.test_skill_contracts -v
```

Expected: PASS for knowledge template checks.

- [ ] **Step 7: Commit**

```bash
git add knowledge tests/test_skill_contracts.py
git commit -m "feat: add living Talia knowledge templates"
```

---

### Task 5: Add Product, Feature, UI/UX, and Architecture Modules

**Files:**
- Create: `modules/feature-development.md`
- Create: `modules/ui-ux.md`
- Create: `modules/architecture-refactoring.md`
- Modify: `tests/test_skill_contracts.py`
- Test: `tests/test_skill_contracts.py`

**Interfaces:**
- Consumes: product context, architecture contract, core router/risk engine.
- Produces: `BUILD|EXTEND|DEFER|REJECT` decision model and scoped change rules used by feature and redesign workflows.

- [ ] **Step 1: Add failing product-module tests**

```python
    def test_feature_module_supports_four_product_outcomes(self) -> None:
        value = text("modules/feature-development.md")
        for outcome in ("BUILD", "EXTEND", "DEFER", "REJECT"):
            self.assertIn(outcome, value)
        self.assertIn("Extend before invent", value)

    def test_ui_module_protects_adult_and_quran_focus(self) -> None:
        value = text("modules/ui-ux.md")
        self.assertIn("adult", value.lower())
        self.assertIn("Quran", value)
        self.assertIn("RTL", value)
        self.assertIn("text scaling", value.lower())
```

- [ ] **Step 2: Confirm RED**

```bash
python -m unittest tests.test_skill_contracts -v
```

- [ ] **Step 3: Create `modules/feature-development.md`**

Include the flow:

```text
User need → Existing capability search → Gap analysis → Product value → Integration opportunity → Complexity/risk → BUILD|EXTEND|DEFER|REJECT
```

Require checking `knowledge/feature-registry.md`, `feature-graph.md`, `product-debt.md`, and `opportunity-register.md` when available. Include `Extend before invent` and prohibit creating a new subsystem until related current flows are inspected.

- [ ] **Step 4: Create `modules/ui-ux.md`**

Own hierarchy, readability, touch targets, accessibility, loading/empty/error states, navigation clarity, icon overload, Arabic RTL, English LTR, text scaling, small-screen behavior, and mobile-first scope. Add Talia checks: do not distract from Quran reading; do not make adult surfaces children-only; keep companion/gamification secondary to focused worship/reading.

- [ ] **Step 5: Create `modules/architecture-refactoring.md`**

Define the decision order `local fix → minimal enabling refactor → architectural proposal`. Require evidence of architectural pain and change-radius reevaluation if a small task unexpectedly touches many unrelated files.

- [ ] **Step 6: Run tests and commit**

```bash
python -m unittest tests.test_skill_contracts -v
git add modules tests/test_skill_contracts.py
git commit -m "feat: add Talia product and architecture modules"
```

---

### Task 6: Add Flutter, Dependency, Ecosystem, and Performance Modules

**Files:**
- Create: `modules/flutter-engineering.md`
- Create: `modules/dependency-upgrades.md`
- Create: `modules/ecosystem-intelligence.md`
- Create: `modules/performance.md`
- Modify: `tests/test_skill_contracts.py`
- Test: `tests/test_skill_contracts.py`

**Interfaces:**
- Consumes: source authority, freshness/upgrades, architecture contract.
- Produces: controlled update policy, ecosystem classification, and measured-performance contract.

- [ ] **Step 1: Add failing ecosystem/performance tests**

```python
    def test_ecosystem_module_classifies_external_changes(self) -> None:
        value = text("modules/ecosystem-intelligence.md")
        for level in ("Mandatory", "Strongly Recommended", "Useful Opportunity", "Experimental", "Irrelevant"):
            self.assertIn(level, value)

    def test_performance_module_requires_before_after_measurement(self) -> None:
        value = text("modules/performance.md")
        self.assertIn("Baseline", value)
        self.assertIn("Measure again", value)
        self.assertIn("Not measured", value)
```

- [ ] **Step 2: Confirm RED**

```bash
python -m unittest tests.test_skill_contracts -v
```

- [ ] **Step 3: Create `modules/flutter-engineering.md`**

Require repository-first architecture fit, official Flutter/Dart verification when freshness matters, platform impact checks, and no migration solely because a newer Flutter pattern exists.

- [ ] **Step 4: Create `modules/dependency-upgrades.md`**

Own `flutter pub outdated`, direct-vs-transitive analysis, patch/minor/major classification, controlled batches, package adoption checklist, and major replacement criteria. Explicitly reject blind `update everything` behavior.

- [ ] **Step 5: Create `modules/ecosystem-intelligence.md`**

Use the five external-change classifications, source hierarchy link, Tech Radar (`ADOPT|TRIAL|ASSESS|HOLD`), update backlog, and `Discovering an update != applying an update` rule.

- [ ] **Step 6: Create `modules/performance.md`**

Require `Define behavior → Baseline → Profile → Locate bottleneck → Change meaningful cause → Measure again → Report measured result`. Distinguish static risk from measured defect. Mention startup, frame timing/jank, memory, DB latency, network duplication, audio start latency, and rebuild counts as examples rather than mandatory universal metrics.

- [ ] **Step 7: Run tests and commit**

```bash
python -m unittest tests.test_skill_contracts -v
git add modules tests/test_skill_contracts.py
git commit -m "feat: add Flutter ecosystem and performance modules"
```

---

### Task 7: Add Quran, Memorization, Revision, and Audio Modules

**Files:**
- Create: `modules/quran-engine.md`
- Create: `modules/quran-integrity.md`
- Create: `modules/memorization-learning.md`
- Create: `modules/revision.md`
- Create: `modules/audio.md`
- Modify: `tests/test_skill_contracts.py`
- Test: `tests/test_skill_contracts.py`

**Interfaces:**
- Consumes: Quran safety contract, product journey, risk engine.
- Produces: correctness-critical domain guidance for Quran/learning flows.

- [ ] **Step 1: Add failing Quran-domain tests**

```python
    def test_quran_integrity_module_marks_mapping_as_critical(self) -> None:
        value = text("modules/quran-integrity.md")
        self.assertIn("Critical", value)
        self.assertIn("deterministic", value.lower())
        self.assertIn("broader impact", value.lower())

    def test_memorization_module_connects_revision_and_weakness(self) -> None:
        value = text("modules/memorization-learning.md")
        self.assertIn("weak", value.lower())
        self.assertIn("revision", value.lower())
        self.assertIn("progress", value.lower())
```

- [ ] **Step 2: Confirm RED**

```bash
python -m unittest tests.test_skill_contracts -v
```

- [ ] **Step 3: Create `modules/quran-engine.md`**

Own reader/navigation/page/surah/ayah relationships, stored reading positions, bookmarks, QCF/Mushaf rendering dependencies, offline/cache behavior, and cross-feature regression mapping. It must defer canonical correctness rules to `quran-integrity.md` and the safety contract rather than duplicate them.

- [ ] **Step 4: Create `modules/quran-integrity.md`**

Mark canonical text/mapping changes as Critical; require canonical source comparison, deterministic validation, affected-range scan, stored-identifier compatibility, and broader impact analysis. Include explicit AI prohibition by reference to the safety contract.

- [ ] **Step 5: Create `modules/memorization-learning.md`**

Connect memorization sessions, repetition, recitation/testing, weakness detection, progress persistence, exit/restore, and revision scheduling. Require inspection of existing capabilities before adding new systems.

- [ ] **Step 6: Create `modules/revision.md`**

Own scheduling, weak-ayah queues, mastery maintenance, due/overdue logic, persistence, and migration sensitivity. State that changes affecting stored review state are High risk by default.

- [ ] **Step 7: Create `modules/audio.md`**

Cover play/pause/seek, current ayah synchronization, interruption/background/resume, screen lock/app lifecycle, queue/state subscriptions, and Bluetooth/device change considerations. Clarify that wrong highlight with valid playback may be a synchronization defect rather than player failure.

- [ ] **Step 8: Run tests and commit**

```bash
python -m unittest tests.test_skill_contracts -v
git add modules tests/test_skill_contracts.py
git commit -m "feat: add Talia Quran learning and audio modules"
```

---

### Task 8: Add Debugging, Incident, Verification, Testing, and Prevention Modules

**Files:**
- Create: `modules/debugging.md`
- Create: `modules/incident-response.md`
- Create: `modules/testing-qa.md`
- Create: `modules/verification.md`
- Create: `modules/prevention-and-health.md`
- Modify: `tests/test_skill_contracts.py`
- Test: `tests/test_skill_contracts.py`

**Interfaces:**
- Consumes: risk engine and completion contract.
- Produces: root-cause-first debugging, three-fix stop rule, evidence ledger, prevention classification.

- [ ] **Step 1: Add failing debugging/verification tests**

```python
    def test_debugging_module_requires_root_cause_and_three_fix_stop(self) -> None:
        value = text("modules/debugging.md")
        self.assertIn("No fixes without root cause", value)
        self.assertIn("three", value.lower())
        self.assertIn("architecture", value.lower())

    def test_verification_module_uses_status_vocabulary(self) -> None:
        value = text("modules/verification.md")
        for status in ("Implemented", "Statically Verified", "Test Verified", "Runtime Verified", "Measured", "Release Verified"):
            self.assertIn(status, value)

    def test_prevention_module_does_not_force_scope_expansion(self) -> None:
        value = text("modules/prevention-and-health.md")
        for action in ("Fix now", "Include with current work", "Log for later", "Ignore"):
            self.assertIn(action, value)
```

- [ ] **Step 2: Confirm RED**

```bash
python -m unittest tests.test_skill_contracts -v
```

- [ ] **Step 3: Create `modules/debugging.md`**

Implement four phases: root-cause investigation, pattern analysis, single-hypothesis testing, minimal implementation/verification. Begin with `No fixes without root cause investigation first.` Include reproduction, recent changes, component-boundary evidence, backward data tracing, and the rule that three failed fix attempts trigger architectural reevaluation rather than a fourth guessed fix.

- [ ] **Step 4: Create `modules/incident-response.md`**

Define incident types, SEV-0..SEV-3, R0..R3 reproducibility, containment-vs-fix distinction, blast radius, environment matrix, data corruption procedure, Quran critical incident behavior, and incident-record update criteria.

- [ ] **Step 5: Create `modules/testing-qa.md`**

Define test selection by domain/risk: unit/domain for deterministic logic; widget for UI behavior; integration for boundaries/persistence/backend; runtime/E2E for lifecycle and critical journeys. Require regression tests for reproducible bugs when practical and explicit Arabic/English validation when UI is affected.

- [ ] **Step 6: Create `modules/verification.md`**

Own the status vocabulary, evidence ledger, no-hidden-failure rule, risk-based verification depth, and requirement to distinguish `Not verified` from pass/fail. Link to completion contract.

- [ ] **Step 7: Create `modules/prevention-and-health.md`**

Classify findings as `Immediate`, `Near-term`, `Maintenance`, `Opportunity`; actions as `Fix now`, `Include with current work`, `Log for later`, `Ignore`. Explicitly state that static performance patterns are risks, not measured defects.

- [ ] **Step 8: Run tests and commit**

```bash
python -m unittest tests.test_skill_contracts -v
git add modules tests/test_skill_contracts.py
git commit -m "feat: add debugging verification and prevention modules"
```

---

### Task 9: Add Supabase, Security, Observability, Release, and Git Safety Modules

**Files:**
- Create: `modules/supabase.md`
- Create: `modules/security-privacy.md`
- Create: `modules/observability.md`
- Create: `modules/release-readiness.md`
- Create: `modules/git-safety.md`
- Modify: `tests/test_skill_contracts.py`
- Test: `tests/test_skill_contracts.py`

**Interfaces:**
- Consumes: autonomy policy, source authority, living Supabase map.
- Produces: migration levels `M0..M3`, RLS/security policy, privacy-safe observability, release and Git safety.

- [ ] **Step 1: Add failing backend/safety tests**

```python
    def test_supabase_module_covers_rls_secrets_and_migrations(self) -> None:
        value = text("modules/supabase.md")
        for token in ("RLS", "service-role", "M0", "M1", "M2", "M3", "rollback"):
            self.assertIn(token, value)
        self.assertIn("allowed", value.lower())
        self.assertIn("denied", value.lower())

    def test_git_module_preserves_unknown_work(self) -> None:
        value = text("modules/git-safety.md")
        self.assertIn("Unknown", value)
        self.assertIn("git reset --hard", value)
        self.assertIn("force push", value.lower())
```

- [ ] **Step 2: Confirm RED**

```bash
python -m unittest tests.test_skill_contracts -v
```

- [ ] **Step 3: Create `modules/supabase.md`**

Cover real schema/migration/RLS/function/storage/auth inspection, least privilege, no service-role key in Flutter, allowed + denied RLS paths, client coexistence, rollout order, data preservation, and M0–M3 migration classification. M3 must stop before execution without explicit approval/recovery understanding.

- [ ] **Step 4: Create `modules/security-privacy.md`**

Protect secrets/tokens, user progress/history, recordings, personal data, and external AI data flows. Require asking what leaves the device and whether deterministic/local handling is possible when AI/services are involved.

- [ ] **Step 5: Create `modules/observability.md`**

Allow crash/error/performance diagnostics while prohibiting secrets, auth tokens, unnecessary personal data, private content, and unnecessary detailed worship/reading behavior. Define useful diagnostic context: app version, device/OS, feature state, breadcrumbs, timings, and non-sensitive identifiers.

- [ ] **Step 6: Create `modules/release-readiness.md`**

Own analyzer/tests/release build, critical-flow smoke, permissions, notifications, privacy disclosures, account deletion where applicable, background/audio, deep links, offline/poor-network, platform requirements, signing/build variants, Supabase compatibility, and upgrade-from-existing-install verification. Store policy facts must be refreshed from official sources.

- [ ] **Step 7: Create `modules/git-safety.md`**

State `Unknown or unrecognized work belongs to the developer until proven otherwise.` Safe commands: status/diff/log/show/branch/blame. Explicitly require approval for `git reset --hard`, `git clean -fd`, force push, shared-history rewrite, or deleting unmerged work.

- [ ] **Step 8: Run tests and commit**

```bash
python -m unittest tests.test_skill_contracts -v
git add modules tests/test_skill_contracts.py
git commit -m "feat: add Supabase security release and Git safety modules"
```

---

### Task 10: Add Core Feature, Bug, Runtime, and Performance Workflows

**Files:**
- Create: `workflows/new-feature.md`
- Create: `workflows/bug-fix.md`
- Create: `workflows/runtime-investigation.md`
- Create: `workflows/performance-investigation.md`
- Modify: `tests/test_skill_contracts.py`
- Test: `tests/test_skill_contracts.py`

**Interfaces:**
- Consumes: task router, domain modules, risk engine.
- Produces: executable task sequences for the most common Talia work.

- [ ] **Step 1: Add failing workflow tests**

```python
    def test_bug_workflow_is_root_cause_first(self) -> None:
        value = text("workflows/bug-fix.md")
        order = [value.index(term) for term in ("Reproduce", "Root cause", "Regression test", "Minimal fix", "Verify")]
        self.assertEqual(order, sorted(order))

    def test_performance_workflow_has_before_after_measurement(self) -> None:
        value = text("workflows/performance-investigation.md")
        order = [value.index(term) for term in ("Baseline", "Profile", "Bottleneck", "Measure again")]
        self.assertEqual(order, sorted(order))
```

- [ ] **Step 2: Confirm RED**

```bash
python -m unittest tests.test_skill_contracts -v
```

- [ ] **Step 3: Create `workflows/new-feature.md`**

Sequence: define user problem → search current capability/knowledge → inspect repository implementation → classify BUILD/EXTEND/DEFER/REJECT → map affected systems/risk → acceptance criteria + regression risks → test-first implementation → runtime validation → knowledge update.

- [ ] **Step 4: Create `workflows/bug-fix.md`**

Sequence: Reproduce → collect exact evidence → root cause trace → compare working pattern → single hypothesis → failing regression test when practical → Minimal fix → Verify original symptom + nearby regressions → prevention/knowledge update.

- [ ] **Step 5: Create `workflows/runtime-investigation.md`**

Provide environment matrix: Debug/Profile/Release; fresh/existing user; online/offline; Arabic/English; cold/warm start; relevant device/OS. Require narrowing variables rather than changing multiple things at once.

- [ ] **Step 6: Create `workflows/performance-investigation.md`**

Sequence: define metric/problem → Baseline → Profile → Bottleneck → single meaningful change → Measure again → report measured improvement/regression/no meaningful difference/not measured.

- [ ] **Step 7: Run tests and commit**

```bash
python -m unittest tests.test_skill_contracts -v
git add workflows tests/test_skill_contracts.py
git commit -m "feat: add core Talia engineering workflows"
```

---

### Task 11: Add Upgrade, Supabase, Spike, Runtime Validation, Incident, and Release Workflows

**Files:**
- Create: `workflows/dependency-upgrade.md`
- Create: `workflows/supabase-migration.md`
- Create: `workflows/technology-spike.md`
- Create: `workflows/runtime-validation.md`
- Create: `workflows/incident-response.md`
- Create: `workflows/pre-release-audit.md`
- Modify: `tests/test_skill_contracts.py`
- Test: `tests/test_skill_contracts.py`

**Interfaces:**
- Consumes: modules from Tasks 6, 8, and 9.
- Produces: specialized controlled workflows for high-risk/freshness-sensitive work.

- [ ] **Step 1: Add failing specialized-workflow tests**

```python
    def test_supabase_migration_workflow_requires_compatibility_and_recovery(self) -> None:
        value = text("workflows/supabase-migration.md")
        for token in ("M0", "M1", "M2", "M3", "compatibility", "rollback", "RLS"):
            self.assertIn(token, value)

    def test_incident_workflow_separates_containment_and_fix(self) -> None:
        value = text("workflows/incident-response.md")
        self.assertLess(value.index("Contain"), value.index("Root cause"))
        self.assertLess(value.index("Root cause"), value.index("Fix"))
```

- [ ] **Step 2: Confirm RED**

```bash
python -m unittest tests.test_skill_contracts -v
```

- [ ] **Step 3: Create `workflows/dependency-upgrade.md`**

Include reason → current constraints → outdated report → direct/transitive → changelog/breaking changes → affected feature map → controlled batch → analyzer/tests/runtime → dependency baseline/backlog update.

- [ ] **Step 4: Create `workflows/supabase-migration.md`**

Include environment confirmation → schema/RLS/client inspection → M0..M3 classification → data preservation → old/new client compatibility → migration → allowed/denied security validation → rollout order → rollback/recovery → app verification. M3 must explicitly stop for approval before destructive execution.

- [ ] **Step 5: Create `workflows/technology-spike.md`**

Define hypothesis, isolated prototype/benchmark, representative inputs, success metrics, privacy/correctness constraints, and `Adopt|Discard|Continue assessment`. State spike code is not production architecture by default.

- [ ] **Step 6: Create `workflows/runtime-validation.md`**

Cover clean state, existing state, enter/leave/re-enter, background/resume, restart/process recreation when relevant, offline/slow/error, Arabic RTL, English LTR, text scaling/small screens, Android back/navigation, and upgrade-from-old-data when migration is involved.

- [ ] **Step 7: Create `workflows/incident-response.md`**

Use `Detect → Contain → Gather Evidence → Reproduce → Trace Root Cause → Hypothesis → Experiment → Minimal Fix → Regression Test → Verify → Document Cause → Prevent Recurrence`; include SEV and R-level recording.

- [ ] **Step 8: Create `workflows/pre-release-audit.md`**

Use the release-readiness checklist and require official current-source verification for target/platform/store requirements. Separate `Release Verified` from `not verified` items.

- [ ] **Step 9: Run tests and commit**

```bash
python -m unittest tests.test_skill_contracts -v
git add workflows tests/test_skill_contracts.py
git commit -m "feat: add upgrade incident and release workflows"
```

---

### Task 12: Upgrade the Non-Destructive Helper Scripts

**Files:**
- Modify: `scripts/talia_doctor.ps1`
- Create: `scripts/dependency_audit.ps1`
- Create: `scripts/project_snapshot.ps1`
- Modify: `tests/test_skill_structure.py`
- Test: `tests/test_skill_structure.py`

**Interfaces:**
- Consumes: spec Section 23.
- Produces: read-only diagnostics usable during discovery/freshness work.

- [ ] **Step 1: Extend script tests before implementation**

Add:

```python
    def test_scripts_describe_themselves_as_read_only(self) -> None:
        for relative in ("scripts/talia_doctor.ps1", "scripts/dependency_audit.ps1", "scripts/project_snapshot.ps1"):
            value = read_text(relative).lower()
            self.assertIn("non-destructive", value)

    def test_dependency_audit_uses_outdated_not_upgrade(self) -> None:
        value = read_text("scripts/dependency_audit.ps1").lower()
        self.assertIn("flutter pub outdated", value)
        self.assertNotIn("flutter pub upgrade", value)
```

- [ ] **Step 2: Confirm RED**

```bash
python -m unittest tests.test_skill_structure -v
```

- [ ] **Step 3: Refine `scripts/talia_doctor.ps1`**

Keep existing checks and make the banner explicit:

```powershell
Write-Host "Talia diagnostic baseline (non-destructive)"
```

Keep `flutter --version`, `dart --version`, `flutter doctor -v`, `flutter pub outdated`, `flutter analyze`, optional `flutter test`, and `git status --short`. Do not change dependencies.

- [ ] **Step 4: Create `scripts/dependency_audit.ps1`**

```powershell
$ErrorActionPreference = "Continue"
Write-Host "Talia dependency audit (non-destructive)"
Write-Host "===== Flutter / Dart ====="
flutter --version
dart --version
Write-Host "===== Outdated Dependencies ====="
flutter pub outdated
Write-Host "===== pubspec constraints ====="
Get-Content "pubspec.yaml"
Write-Host "No dependencies were changed."
```

- [ ] **Step 5: Create `scripts/project_snapshot.ps1`**

Use read-only metadata only:

```powershell
$ErrorActionPreference = "Continue"
Write-Host "Talia project snapshot (non-destructive)"
Write-Host "===== Git ====="
git rev-parse HEAD
git status --short
Write-Host "===== Top-Level ====="
Get-ChildItem -Force | Select-Object Name, Mode
Write-Host "===== lib directories ====="
if (Test-Path "lib") { Get-ChildItem "lib" -Directory -Recurse | Select-Object FullName }
Write-Host "===== test directories ====="
if (Test-Path "test") { Get-ChildItem "test" -Directory -Recurse | Select-Object FullName }
Write-Host "===== Config filenames only ====="
Get-ChildItem -Recurse -File -Include "pubspec.yaml","analysis_options.yaml","*.gradle","AndroidManifest.xml","Info.plist" | Select-Object FullName
Write-Host "Snapshot intentionally excludes file contents that may contain secrets."
```

- [ ] **Step 6: Syntax-check PowerShell when `pwsh` is available**

Run:

```bash
pwsh -NoProfile -Command '$files = @("scripts/talia_doctor.ps1","scripts/dependency_audit.ps1","scripts/project_snapshot.ps1"); foreach ($f in $files) { $tokens = $null; $errors = $null; $null = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $f), [ref]$tokens, [ref]$errors); if ($errors.Count) { $errors; exit 1 } }; exit 0'
```

Expected: exit 0. If `pwsh` is not installed in the implementation environment, record `NOT VERIFIED: PowerShell parser unavailable` rather than claiming syntax verification.

- [ ] **Step 7: Run Python structure tests and commit**

```bash
python -m unittest tests.test_skill_structure -v
git add scripts tests/test_skill_structure.py
git commit -m "feat: add non-destructive Talia diagnostic scripts"
```

---

### Task 13: Expand Pressure, Routing, and Regression Scenarios

**Files:**
- Modify: `tests/skill-pressure-tests.md`
- Create: `tests/routing-scenarios.md`
- Create: `tests/regression-scenarios.md`
- Modify: `tests/test_skill_contracts.py`
- Test: `tests/test_skill_contracts.py`

**Interfaces:**
- Consumes: all core/modules/workflows.
- Produces: behavioral test suite for future agent runs and skill evolution.

- [ ] **Step 1: Add failing scenario-coverage test**

```python
    def test_pressure_suite_covers_spec_failure_modes(self) -> None:
        value = text("tests/skill-pressure-tests.md").lower()
        required = (
            "shiny package",
            "update everything",
            "architecture rewrite",
            "quran text",
            "performance",
            "service-role",
            "duplicate feature",
            "children",
            "three failed",
            "destructive migration",
            "uncommitted",
            "store",
            "stale knowledge",
            "production-only",
            "extend",
        )
        for token in required:
            self.assertIn(token, value)
```

- [ ] **Step 2: Confirm RED**

```bash
python -m unittest tests.test_skill_contracts.SkillContractTests.test_pressure_suite_covers_spec_failure_modes -v
```

- [ ] **Step 3: Rewrite `tests/skill-pressure-tests.md` as 15 numbered scenarios**

Each scenario contains `Prompt`, `Expected classification`, `Expected behavior`, and `Failure signs`. Cover all 15 cases from spec Section 24 using explicit names containing the tokens checked above.

- [ ] **Step 4: Create `tests/routing-scenarios.md`**

Include at least these cases:

```text
Quran page restore lag → BUG + PERFORMANCE + QURAN_ENGINE + LOCAL_STORAGE
supabase_flutter update → DEPENDENCY + SUPABASE + TESTING
kids path redesign → UI_UX + FEATURE
wrong highlighted ayah → BUG + AUDIO + QURAN_ENGINE + RUNTIME
RLS ownership failure → BUG + SUPABASE + SECURITY
release review → RELEASE + STORE_REVIEW + SECURITY + PRIVACY
```

For each, list expected modules/workflow and risk level.

- [ ] **Step 5: Create `tests/regression-scenarios.md`**

Define stable scenarios for Quran restore/mapping, memorization progress persistence, revision scheduling, audio sync/lifecycle, RLS allow/deny behavior, upgrade-from-existing-local-data, Arabic/English layout, and prevention of fabricated performance claims.

- [ ] **Step 6: Run tests and commit**

```bash
python -m unittest tests.test_skill_contracts -v
git add tests
git commit -m "test: expand Talia V2 behavioral pressure suite"
```

---

### Task 14: Update README and Cross-Link the Skill Package

**Files:**
- Modify: `README.md`
- Modify: selected module/workflow markdown files only if needed to fix links
- Test: `tests/test_skill_structure.py`

**Interfaces:**
- Consumes: final V2 package layout.
- Produces: clear installation/usage/maintenance guide without duplicating the skill body.

- [ ] **Step 1: Add failing README expectations**

Add to `tests/test_skill_structure.py`:

```python
    def test_readme_documents_v2_usage_and_validation(self) -> None:
        value = read_text("README.md")
        self.assertIn("Talia Engineering OS V2", value)
        self.assertIn("python -m unittest", value)
        self.assertIn("Repository truth", value)
        self.assertIn("pressure", value.lower())
```

- [ ] **Step 2: Confirm RED**

```bash
python -m unittest tests.test_skill_structure.SkillStructureTests.test_readme_documents_v2_usage_and_validation -v
```

- [ ] **Step 3: Rewrite `README.md`**

Include:

```markdown
# Talia Engineering OS V2

A project-specific Agent Skill for Talia Quran.

## How it works
Core router → task/risk classification → focused modules/workflows → verification → knowledge refresh.

## Source of truth
Repository truth overrides living knowledge. Official current documentation overrides stale ecosystem memory.

## Validation
python -m unittest discover -s tests -p "test_*.py" -v

## Pressure testing
Run the scenarios in `tests/skill-pressure-tests.md` first without the skill when feasible, then with the skill, and tighten rules when agents still rationalize unsafe behavior.

## Installing
Place the folder in the skills directory recognized by the chosen agent runtime or keep it alongside the Talia repository according to that runtime's skill-loading rules.
```

Also document the four modes and how knowledge files are refreshed. Do not duplicate full module contents.

- [ ] **Step 4: Run structure/link tests**

```bash
python -m unittest tests.test_skill_structure -v
```

Expected: all local Markdown links resolve and README test passes.

- [ ] **Step 5: Commit**

```bash
git add README.md tests/test_skill_structure.py
git commit -m "docs: document Talia Engineering OS V2 usage"
```

---

### Task 15: Final Spec Coverage, Validation, and Packaging Gate

**Files:**
- Modify only if verification finds defects: any V2 skill file
- Test: `tests/test_skill_structure.py`, `tests/test_skill_contracts.py`
- Verify: `docs/superpowers/specs/2026-09-15-talia-engineering-os-v2-design.md`

**Interfaces:**
- Consumes: all prior tasks.
- Produces: evidence that V2 satisfies the approved spec before packaging/hand-off.

- [ ] **Step 1: Add the final all-files manifest gate**

Append to `tests/test_skill_structure.py`:

```python
    def test_final_v2_file_manifest(self) -> None:
        expected = {
            "SKILL.md", "README.md",
            "core/task-router.md", "core/risk-engine.md", "core/autonomy-policy.md", "core/completion-contract.md",
            "references/talia-product-context.md", "references/architecture-contract.md", "references/quran-safety-contract.md",
            "references/engineering-principles.md", "references/source-authority.md", "references/freshness-and-upgrades.md",
            "references/quality-gates.md",
            "modules/feature-development.md", "modules/debugging.md", "modules/incident-response.md",
            "modules/flutter-engineering.md", "modules/dependency-upgrades.md", "modules/ecosystem-intelligence.md",
            "modules/supabase.md", "modules/quran-engine.md", "modules/quran-integrity.md",
            "modules/memorization-learning.md", "modules/revision.md", "modules/audio.md", "modules/performance.md",
            "modules/ui-ux.md", "modules/testing-qa.md", "modules/verification.md", "modules/prevention-and-health.md",
            "modules/observability.md", "modules/security-privacy.md", "modules/release-readiness.md",
            "modules/architecture-refactoring.md", "modules/git-safety.md",
            "workflows/new-feature.md", "workflows/bug-fix.md", "workflows/runtime-investigation.md",
            "workflows/performance-investigation.md", "workflows/dependency-upgrade.md", "workflows/supabase-migration.md",
            "workflows/technology-spike.md", "workflows/runtime-validation.md", "workflows/incident-response.md",
            "workflows/pre-release-audit.md",
            "knowledge/repo-map.md", "knowledge/feature-registry.md", "knowledge/feature-graph.md",
            "knowledge/dependency-baseline.md", "knowledge/supabase-map.md", "knowledge/known-risks.md",
            "knowledge/health-register.md", "knowledge/product-debt.md", "knowledge/opportunity-register.md",
            "knowledge/tech-radar.md", "knowledge/update-backlog.md", "knowledge/skill-version.md",
            "knowledge/incidents/README.md",
            "scripts/talia_doctor.ps1", "scripts/dependency_audit.ps1", "scripts/project_snapshot.ps1",
            "tests/skill-pressure-tests.md", "tests/routing-scenarios.md", "tests/regression-scenarios.md",
        }
        assert_paths_exist(self, *sorted(expected))
```

- [ ] **Step 2: Run the full automated skill test suite**

```bash
python -m unittest discover -s tests -p "test_*.py" -v
```

Expected: `OK`, zero failures/errors.

- [ ] **Step 3: Run placeholder and contradiction hygiene scans**

```bash
python - <<'PY'
from pathlib import Path
root = Path('.')
forbidden = ('T' + 'BD', 'TO' + 'DO', 'implement ' + 'later', 'fill in ' + 'details')
failures = []
for path in list(root.rglob('*.md')) + list(root.rglob('*.ps1')):
    if '.git' in path.parts:
        continue
    text = path.read_text(encoding='utf-8')
    for token in forbidden:
        if token.lower() in text.lower():
            failures.append(f'{path}: {token}')
if failures:
    raise SystemExit('\n'.join(failures))
print('No placeholder tokens found.')
PY
```

Expected: `No placeholder tokens found.` Rephrase any test prose that intentionally contains one of the prohibited placeholder phrases rather than weakening the scan.

- [ ] **Step 4: Check every V2 acceptance criterion against implementation**

Create a temporary implementation checklist in the session notes with all 18 acceptance criteria from spec Section 27 and mark each with one of: `PASS with file/evidence`, `FAIL`, `NOT VERIFIED`. Do not edit the spec to fake completion.

Minimum evidence mapping:

```text
1 → SKILL.md word count + router links
2 → task-router.md + routing-scenarios.md
3 → risk-engine.md + autonomy/completion contracts
4 → SKILL.md + knowledge templates
5 → knowledge/*.md ownership/update rules
6 → source-authority.md + ecosystem-intelligence.md
7 → quran-safety-contract.md + quran-integrity.md
8 → debugging.md + bug/incident workflows
9 → performance.md + performance workflow
10 → completion-contract.md + verification.md
11 → supabase.md + supabase-migration.md
12 → autonomy-policy.md + git-safety.md
13 → feature-development.md
14 → prevention-and-health.md + registers
15 → skill-pressure-tests.md
16 → V1 reference/script behavior preserved or intentionally relocated
17 → script static tests + PowerShell parse result when available
18 → placeholder scan + successful automated tests
```

- [ ] **Step 5: Review Git diff for unintended scope**

```bash
git status --short
git diff --stat
git diff -- SKILL.md core references modules workflows knowledge scripts tests README.md
```

Expected: only V2 skill-package files are changed; no unrelated Talia application code is touched.

- [ ] **Step 6: Run final tests again after any verification fixes**

```bash
python -m unittest discover -s tests -p "test_*.py" -v
```

Expected: `OK`.

- [ ] **Step 7: Commit final verification fixes, if any**

If Task 15 required changes:

```bash
git add SKILL.md README.md core references modules workflows knowledge scripts tests
git commit -m "test: verify Talia Engineering OS V2 contracts"
```

If there are no changes, do not create an empty commit.

- [ ] **Step 8: Create the distributable archive only after verification**

From the parent directory:

```bash
python - <<'PY'
from pathlib import Path
import zipfile
root = Path('talia-quran-engineer-skill')
out = Path('talia-quran-engineer-skill-v2.zip')
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for path in sorted(root.rglob('*')):
        if path.is_file() and '.git' not in path.parts:
            z.write(path, path.relative_to(root.parent))
print(out)
PY
```

Expected: `talia-quran-engineer-skill-v2.zip` is created and contains the verified package.

---

## Execution Notes

- Implement tasks in order because the test harness and core contracts intentionally become dependencies for later modules.
- Keep commits small and scoped to one task. If execution is not inside an existing Git repository/worktree, do not initialize Git automatically; skip commit steps and report that Git commit verification was unavailable.
- Do not populate living knowledge with guessed Talia repository facts during skill-package implementation; templates remain `unknown` until run against the actual Talia repository.
- Pressure tests are behavioral specifications. Automated Python tests validate deterministic package contracts; they do not claim to prove every LLM behavior.
- The V2 package must not modify the actual Talia application repository as part of this plan. Applying the skill to the real repository is a separate follow-up task.
