# Talia Quran agent orchestration

Read `.codex/AGENTS.md` and applicable project skills before work. Preserve the existing project instructions and Islamic content source policy.

## Pre-release audit workflow

Only start an application audit when the user asks for it. The audit is evidence based and does not change application source unless the user separately requests fixes. The root agent owns scope, assignments, coverage tracking, and the final answer.

1. Ask `scout` to map the complete repository and create a feature and user-flow inventory. Use its map to assign coverage; verify that every feature and flow is accounted for. Reuse an existing, current inventory when its repository revision and scope match; refresh only changed areas.
2. Delegate independent review work to `qa-reviewer`, `flutter-reviewer`, `religious-reviewer`, `ux-accessibility-reviewer`, and `release-auditor`. Run in waves within the configured concurrency limit. Give each reviewer the scout inventory, relevant file paths, and a specific scope. Reviewers should reuse shared evidence and search only gaps or disputed paths, rather than repeat a full repository scan. Keep responsibilities distinct as defined in each role.
3. Ask `final-reviewer` to merge the reviewers' findings, remove duplicates, check contradictions against primary evidence, and produce a consolidated release-readiness report. The root agent checks the report for missing coverage and gives the release verdict.

Read-only reviewers must not edit files. `release-auditor` may run safe validation commands, including `flutter analyze`, `flutter test`, and `flutter build appbundle --release`; it must not edit application source. Capture command, exit code, and relevant output. A build is not proof that a user flow works. Mark untested paths as unverified.

Use these severity levels consistently: **P0 Release Blocker**, **P1 Critical**, **P2 Major**, **P3 Minor**, **P4 Improvement**. Any credible possibility of incorrect Quran text, ayah numbering, surah order, or unreliable religious content is P0 until checked against an authoritative source. Do not downgrade it because it is difficult to reproduce.

Every finding needs a location, affected flow, observed or reasoned failure, evidence and reproduction steps where possible, user impact, severity, and a suggested remedy. Distinguish verified defects from risks and unknowns. The final report includes coverage, validation results, unresolved questions, prioritized findings, and a release verdict. Do not claim full coverage without evidence.

Use the least costly capable model. The seven custom agent TOML files pin their own models and reasoning efforts; those values take precedence over spawn requests, `[agents]` defaults, and root inheritance. Spawn by role without redundant model overrides. Keep `scout` on Luna at low effort, routine QA/UX/release checks on Terra at medium effort, Flutter review on Sol at medium effort, and religious and final review on Sol at high effort.

When a lower-cost reviewer finds a credible issue beyond its ability to verify, pass only that finding, its evidence, and the narrow question to a stronger reviewer or a focused Sol investigation. Escalate to Astra only when the model delegation policy's critical criteria apply, and ask it to investigate or plan first. Do not rerun an entire specialist review merely to escalate one finding. Normally use no more than three subagents concurrently.
