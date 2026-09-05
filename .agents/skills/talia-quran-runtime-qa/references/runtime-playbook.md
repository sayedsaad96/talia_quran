# Runtime Playbook — Autonomous Pre-Release Audit

## 1. Project and Device Gates

From the repository root, verify project identity and run:

```powershell
adb devices
flutter devices
```

Prefer a connected physical Android target. Otherwise use an already-running emulator or discover/launch one with:

```powershell
flutter emulators
flutter emulators --launch <emulator_id>
```

Wait until adb reports the selected target as `device`. Record its exact ID. Do not continue on `offline`, `unauthorized`, or absent targets.

## 2. Real Launch Gate

Inspect only the bootstrap/configuration needed to launch safely. Use Patrol CLI directly where supported by the project.

Typical form:

```powershell
patrol test -d <device-id> <runtime-test-path>
```

Use the command compatible with the installed Patrol/project setup. Runtime QA has not started until the real app reaches a usable Android state.

Record:
- device ID/type;
- exact launch/runtime command;
- build/install/launch result;
- first usable state or blocking symptom.

## 3. Black-Box Discovery Pass

Do not begin with source-derived feature names. Starting from the first usable state:

1. capture the state in `qa/application_graph.md`;
2. enumerate interactive elements visible/reasonably discoverable there;
3. exercise each safe interaction;
4. record destination/result;
5. continue recursively through new states;
6. revisit branches when state changes expose new behavior.

A successful render is not coverage. The interaction must be exercised and its result observed.

## 4. Journey and State Pass

Group discovered edges into coherent journeys. Complete each normal journey, then try reasonable branches exposed by the app: cancellation, back, retry, repeat, re-entry, changed state, lifecycle/relaunch, and boundary interactions.

Continuously collect runtime quality evidence, not only assertions.

## 5. Exploratory Stress Pass

Once a flow is understood, use realistic stress behavior where safe. Look for race conditions, repeated-action defects, navigation/state corruption, slow/janky transitions, stuck loading, and lifecycle/persistence failures.

## 6. Source Reconciliation Pass

Only after substantial runtime exploration, inspect implementation and recent user-facing changes. Build `qa/capability_inventory.md` from both runtime and source discoveries.

For anything implemented but unseen at runtime:
1. identify its entry condition/path;
2. determine whether it should be user-reachable;
3. return to runtime and attempt the branch;
4. classify it with evidence.

Record truly inaccessible user-facing implementation in `qa/unreachable_implementation.md`.

## 7. Defect Loop

For every meaningful issue:

```text
REPRODUCE
  -> CAPTURE RUNTIME EVIDENCE
  -> IDENTIFY ROOT CAUSE
  -> ADD/UPDATE REGRESSION COVERAGE
  -> FIX
  -> REBUILD/RELAUNCH
  -> RERUN EXACT JOURNEY
  -> RUN RELATED REGRESSION
```

Do not weaken a meaningful test to make broken behavior appear green.

## 8. Coverage Closure

Reconcile the application graph, capability inventory, source audit, runtime tests, and recent changes. No user-facing item may remain unexplored without a documented `BLOCKED`, `UNREACHABLE`, or `CONDITIONAL` reason.

If a newly fixed or newly discovered state exposes more branches, return to discovery. Repeat until coverage stabilizes.

## 9. Release Readiness Gate

The final report begins with exactly one verdict:

- `READY FOR RELEASE`
- `READY WITH MINOR ISSUES`
- `NOT READY FOR RELEASE`
- `INCOMPLETE RUNTIME AUDIT`

Never issue `READY FOR RELEASE` without real Android runtime evidence and closed discovery coverage.
