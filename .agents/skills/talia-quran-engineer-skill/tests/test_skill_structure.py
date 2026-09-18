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

    def test_scripts_describe_themselves_as_read_only(self) -> None:
        for relative in ("scripts/talia_doctor.ps1", "scripts/dependency_audit.ps1", "scripts/project_snapshot.ps1"):
            value = read_text(relative).lower()
            self.assertIn("non-destructive", value)

    def test_dependency_audit_uses_outdated_not_upgrade(self) -> None:
        value = read_text("scripts/dependency_audit.ps1").lower()
        self.assertIn("flutter pub outdated", value)
        self.assertNotIn("flutter pub upgrade", value)

    def test_readme_documents_v2_usage_and_validation(self) -> None:
        value = read_text("README.md")
        self.assertIn("Talia Engineering OS V2", value)
        self.assertIn("python -m unittest", value)
        self.assertIn("Repository truth", value)
        self.assertIn("pressure", value.lower())

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


if __name__ == "__main__":
    unittest.main()
