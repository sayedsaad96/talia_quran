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

    def test_ecosystem_module_classifies_external_changes(self) -> None:
        value = text("modules/ecosystem-intelligence.md")
        for level in ("Mandatory", "Strongly Recommended", "Useful Opportunity", "Experimental", "Irrelevant"):
            self.assertIn(level, value)

    def test_performance_module_requires_before_after_measurement(self) -> None:
        value = text("modules/performance.md")
        self.assertIn("Baseline", value)
        self.assertIn("Measure again", value)
        self.assertIn("Not measured", value)

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

    def test_bug_workflow_is_root_cause_first(self) -> None:
        value = text("workflows/bug-fix.md")
        order = [value.index(term) for term in ("Reproduce", "Root cause", "Regression test", "Minimal fix", "Verify")]
        self.assertEqual(order, sorted(order))

    def test_performance_workflow_has_before_after_measurement(self) -> None:
        value = text("workflows/performance-investigation.md")
        order = [value.index(term) for term in ("Baseline", "Profile", "Bottleneck", "Measure again")]
        self.assertEqual(order, sorted(order))

    def test_supabase_migration_workflow_requires_compatibility_and_recovery(self) -> None:
        value = text("workflows/supabase-migration.md")
        for token in ("M0", "M1", "M2", "M3", "compatibility", "rollback", "RLS"):
            self.assertIn(token, value)

    def test_incident_workflow_separates_containment_and_fix(self) -> None:
        value = text("workflows/incident-response.md")
        self.assertLess(value.index("Contain"), value.index("Root cause"))
        self.assertLess(value.index("Root cause"), value.index("Fix"))

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


if __name__ == "__main__":
    unittest.main()
