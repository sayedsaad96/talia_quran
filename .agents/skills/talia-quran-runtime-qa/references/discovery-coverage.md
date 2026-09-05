# Discovery-First Coverage Model

This skill does not define the application's feature list. The current build defines it.

## 1. Black-Box First

After the launch gate, begin from the first usable runtime state. Do not read a checklist of expected product features. Observe the UI and discover interaction targets from what the user can actually see or reasonably access.

The only source inspection allowed before meaningful exploration is what is necessary to launch/bootstrap the app or make the runtime test harness work.

## 2. Build an Application Graph

Represent exploration as a graph:

```text
State A
  -> interaction 1 -> State B
  -> interaction 2 -> State C
State B
  -> interaction 3 -> State D
```

A state can be a screen, dialog, sheet, expanded/collapsed UI, changed selection, permission state, loading/error/empty condition, signed/unsigned state, or any other materially different user-visible state discovered at runtime.

For each state:
- enumerate visible or reasonably discoverable interactive elements;
- interact with each one when safe;
- record the resulting state/behavior;
- continue until the branch terminates, loops to a known state, or is blocked;
- avoid marking an element covered merely because it rendered.

## 3. Discover Journeys, Do Not Prescribe Them

When multiple interactions form a coherent user goal, treat them as a journey and follow it end-to-end. Test the normal completion path first, then reasonable variations discovered from that flow: cancel, back, retry, repeat, re-entry, restart, changed state, or alternative branches where the UI exposes them.

Do not invent flows that are not present in the app.

## 4. Explore State Changes

When an action changes persistent or session state, revisit relevant areas and confirm the application reflects that change correctly. When appropriate, background/reopen or terminate/relaunch and check whether the resulting state is coherent.

If the app exposes multiple user states, modes, roles, account states, permissions, configuration states, or conditional experiences, discover and traverse them rather than assuming their names or existence.

## 5. Observe Release Quality Continuously

During every interaction, watch for more than pass/fail functionality:
- runtime exceptions, crashes, freezes, ANRs, hangs;
- unexpected or dead navigation;
- broken or stale state;
- blank, stuck, loading, empty, or error states behaving incorrectly;
- slow startup or interaction latency;
- visible jank, dropped frames, flicker, unnecessary waits;
- clipping, overflow, broken layout, unreadable content, bad scrolling;
- unresponsive or duplicate interactions;
- missing/broken assets or media when encountered;
- permission, keyboard, focus, back-navigation, lifecycle, persistence, accessibility, localization, or responsiveness problems when encountered;
- any other behavior that would lower confidence in a public release.

Do not ignore a defect merely because the app does not crash.

## 6. Exploratory Stress Pass

After understanding a normal branch, use reasonable adversarial behavior where safe: rapid taps, repeated actions, quick navigation, back during loading, aggressive scrolling, leaving/returning, background/restore, relaunch, interrupting operations, and boundary inputs exposed by the UI.

Do not perform destructive or unsafe actions unless explicitly required and safely isolated.

## 7. Source Reconciliation Comes After Runtime Discovery

After substantial black-box exploration, inspect implementation to find what the runtime pass missed. Inventory user-facing routes, screens, dialogs/sheets, navigation entry points, conditional visibility, state-driven branches, feature flags, deep links/alternate entry points when present, and recent user-facing changes.

For every implementation item not observed at runtime, determine why:
- legitimate internal implementation;
- conditional and condition documented;
- unreachable/orphaned;
- hidden by an incorrect condition;
- missing runtime entry point;
- blocked by environment/data/state;
- broken at runtime;
- not actually user-facing.

Return to the running app for every newly discovered testable branch.

## 8. Coverage Reconciliation

Every user-facing capability discovered from runtime or source must end in exactly one status:

- `TESTED — PASS`
- `TESTED — ISSUE FOUND`
- `BLOCKED`
- `UNREACHABLE`
- `CONDITIONAL`

`NOT TESTED` is not an acceptable final status without being converted to one of the above with a documented reason.

Coverage is closed only when no meaningful unexplored branch remains.
