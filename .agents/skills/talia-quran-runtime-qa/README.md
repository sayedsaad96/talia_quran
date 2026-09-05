# Talia Quran Runtime QA Skill v2.1

A project-local Agent Skill for **talia_quran** that performs discovery-first Android runtime QA as a final pre-release review. It does not assume or prescribe the app's feature set; the agent must discover the current build from runtime, then reconcile that discovery with source implementation.

## What changed from v2

- Removed hard-coded product feature/domain checklists.
- Added autonomous black-box application discovery.
- Added application-graph traversal for every discovered interaction/state.
- Added source reconciliation only after substantial runtime exploration.
- Added coverage closure: every user-facing capability requires a final status/evidence.
- Added release-readiness verdict and pre-store report.
- Kept hard Android Device, Real Launch, Runtime Evidence, and anti-fallback gates.

## Install

Delete/replace the previous skill folder, then copy this directory to:

```text
<repo>/.agents/skills/talia-quran-runtime-qa/
```

Windows example:

```text
D:\Flutter\talia_quran\.agents\skills\talia-quran-runtime-qa\
```

## Windows preflight

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.agents\skills\talia-quran-runtime-qa\scripts\check-qa-env.ps1
```

## Invoke

A short instruction is intentionally enough:

```text
Use talia-quran-runtime-qa. Perform the final autonomous pre-release Android runtime audit of the current build. Discover the application yourself from A to Z, close runtime/source coverage, fix reproducible release issues, and produce the release-readiness report.
```

## Patrol MCP

Not required. v2.1 works with Patrol CLI directly from Codex, Cursor, or Antigravity. Do not force `patrol_mcp` into the app when it conflicts with the project's dependencies.
