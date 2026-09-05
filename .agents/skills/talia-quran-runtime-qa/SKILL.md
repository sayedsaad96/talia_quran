---
name: talia-quran-runtime-qa
version: 2.1.0
description: Use when performing runtime QA, exploratory testing, regression validation, or final release-readiness review of the talia_quran Flutter app on Android, especially when the current build must be discovered and validated end-to-end rather than checked against a predefined feature list.
---

# Talia Quran Runtime QA v2.1

## Mission

Act as the final pre-release mobile QA engineer for **talia_quran**. Discover what the current build actually contains, exercise it on a real Android runtime, reconcile runtime coverage with source implementation, and issue an evidence-based release verdict.

## Hard Gates

1. **Project Identity** — verify `pubspec.yaml` identifies `talia_quran`; otherwise STOP.
2. **Android Device** — run `adb devices` and `flutter devices`; use only an Android target in adb state `device`. Prefer a connected physical device, otherwise an emulator. If unavailable, STOP as BLOCKED.
3. **Real App Launch** — install/launch the actual app with Patrol CLI or an equivalent Android runtime command. Ordinary tests do not satisfy this gate.
4. **Autonomous Discovery** — begin black-box exploration from the first usable screen. Do not start from a predefined feature checklist. Treat the running app as an **application graph** of states and interactions and traverse every realistically reachable branch.
5. **Coverage Reconciliation** — after substantial runtime exploration, inspect source routes, screens, conditions, state transitions, entry points, and recent user-facing changes to discover what runtime exploration missed.
6. **Release Evidence** — do not declare completion until every discovered user-facing capability is classified as `TESTED — PASS`, `TESTED — ISSUE FOUND`, `BLOCKED`, `UNREACHABLE`, or `CONDITIONAL` with evidence.

## Required Workflow

Read `references/runtime-playbook.md` and `references/discovery-coverage.md`.

1. Establish device and launch gates.
2. Explore the running app as a new user without assuming its feature set.
3. For every discovered interactive element: interact, observe the resulting state, record the edge, and continue traversal.
4. Follow each discovered journey end-to-end; revisit changed states, restart/re-enter when relevant, and use reasonable stress interactions.
5. Continuously observe crashes, exceptions, broken state, incorrect behavior, responsiveness, jank, visual defects, and other release-quality problems.
6. Reconcile runtime discoveries with source implementation and recent changes; return to runtime for missed branches.
7. For defects: reproduce → evidence → root cause → regression coverage → fix → rerun exact journey → related regression.
8. Produce the reports from `templates/`.

## Anti-Shortcut Rule

`flutter test`, `dart test`, `flutter analyze`, unit/widget tests, source review, successful compilation, APK generation, or installation are supporting evidence only. They NEVER substitute for runtime exploration.

## Completion Rule

If meaningful runtime exploration did not occur, verdict must be `INCOMPLETE RUNTIME AUDIT`. If any discovered user-facing branch remains unexplored without a documented reason, continue testing.

## Outputs

Create/update:

```text
qa/pre_release_audit.md
qa/application_graph.md
qa/capability_inventory.md
qa/unreachable_implementation.md
qa/regression_report.md
```
