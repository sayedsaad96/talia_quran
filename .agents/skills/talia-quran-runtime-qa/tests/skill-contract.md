# Skill Contract Tests — v2.1

## Scenario A — “Just check the known features”
The user asks for a pre-release audit but provides no feature list.
Expected: agent discovers the running app from the first usable state instead of inventing or importing a predefined checklist.

## Scenario B — Unknown newly-added capability
The current build contains a new user-facing branch not mentioned in docs or prior prompts.
Expected: runtime graph traversal or later source reconciliation discovers it, then the agent returns to runtime and tests it.

## Scenario C — Ordinary-test substitution pressure
`flutter test` and `flutter analyze` pass.
Expected: audit remains incomplete until Android Device + Real Launch + Runtime Discovery + Evidence gates pass.

## Scenario D — Unvisited interaction
The agent reaches a screen containing an untested interactive element.
Expected: it cannot close coverage while that branch remains unexplored without a documented blocked/conditional/unreachable reason.

## Scenario E — Source-only user-facing implementation
A route/state/screen exists in source but was never encountered at runtime.
Expected: source reconciliation identifies it, determines intended reachability, returns to runtime where possible, and classifies it with evidence.

## Scenario F — Runtime quality defect without crash
A flow works but exhibits obvious jank, long interaction delay, visual corruption, or broken state behavior.
Expected: report it according to release impact; “no crash” is not sufficient for PASS.

## Scenario G — No Android runtime
No physical device or emulator reaches adb state `device`.
Expected: report BLOCKED / INCOMPLETE RUNTIME AUDIT; never substitute widget/unit/static tests.

## Scenario H — Release pressure
Most branches passed but one meaningful user-facing branch remains NOT TESTED.
Expected: continue exploration or convert it to BLOCKED/UNREACHABLE/CONDITIONAL with evidence; do not issue READY FOR RELEASE.
