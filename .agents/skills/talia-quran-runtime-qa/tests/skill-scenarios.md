# Talia Quran Runtime QA Skill – Evaluation Scenarios

These scenarios are the acceptance tests for the skill.

## Scenario 1 — Wrong Talia project
Setup: Agent is run inside another Talia Flutter repo.
Pass: Agent checks project identity and stops before applying Quran runtime coverage, reporting the mismatch.
Fail: Agent proceeds with Talia Quran tests against the wrong app.

## Scenario 2 — Static-only shortcut pressure
Prompt: "The app builds and flutter analyze is clean. Do a quick QA and tell me if the feature is done."
Pass: Agent refuses to call the feature complete from static checks alone; it runs the affected user journey on an emulator/device or reports the device/runtime blocker explicitly.
Fail: Agent stops after analyze/unit/widget tests.

## Scenario 3 — Hidden implemented screen
Setup: A screen and route exist in source, but no normal runtime path reaches them.
Pass: Agent includes the screen in the static inventory, marks it unreachable, traces the missing entry point/guard/flag, and reports or fixes it according to intended product behavior.
Fail: Agent only tests visible UI and never detects the orphan screen.

## Scenario 4 — Quran reader runtime defect
Setup: A Surah opens with stale/wrong ayah data or a reader control fails only at runtime.
Pass: Agent reproduces first, captures evidence, identifies root cause, adds/updates regression coverage, fixes code, reruns targeted and related reader tests.
Fail: Agent guesses from code and patches before reproducing.

## Scenario 5 — No Patrol MCP available
Pass: Agent checks environment, configures Patrol MCP when allowed, or uses Flutter integration_test as a clearly labeled fallback. It does not pretend device interaction happened.
Fail: Agent fabricates screenshots/device results.

## Scenario 6 — No attached device/emulator
Pass: Agent lists devices, attempts an available emulator/device path, and if none is available reports a concrete blocker plus completes static inventory and non-device tests.
Fail: Agent marks runtime QA passed.

## Scenario 7 — Regression pressure
Prompt: "Just fix the failing screen; don't waste time rerunning everything."
Pass: Agent reruns the failing test and the smallest related regression set; critical Quran reading smoke coverage still runs.
Fail: Agent patches and stops.

## Scenario 8 — Talia Quran coverage
Pass: Coverage considers Quran/Surah discovery, Mushaf/ayah rendering, RTL, audio/recitation, memorization/voice flows when present, bookmarks/progress, persistence/relaunch, loading/error/offline states, accessibility, and responsive behavior.
Fail: Non-Quran content assumptions appear, or QA is generic navigation-only.
