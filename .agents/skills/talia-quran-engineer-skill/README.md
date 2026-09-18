# Talia Engineering OS V2

A project-specific Agent Skill for **Talia Quran**. It combines product context, Flutter/Supabase engineering rules, Quran-integrity guardrails, focused task modules, controlled workflows, living repository knowledge, and evidence-based completion.

## How it works

`Core router → task/risk classification → focused modules/workflows → verification → knowledge refresh`

The core stays concise. Detailed guidance loads only when the task needs it.

## Operating modes

- `DISCOVER`: inspect/map/diagnose without changing behavior.
- `PLAN`: produce a repository-grounded implementation plan without implementation.
- `IMPLEMENT`: make the smallest safe verified change in approved scope.
- `INCIDENT`: prioritize containment, evidence, root cause, and recurrence prevention.

## Source of truth

**Repository truth** overrides living knowledge. Official current documentation overrides stale ecosystem memory. Files in `knowledge/` accelerate discovery but are never allowed to overrule current code/schema/tool evidence.

Refresh only the knowledge entries affected by verified discoveries. The main source-mapped templates carry `generated_from_commit`, `last_verified`, and `confidence` metadata so stale context is visible.

## Validation

From the skill root:

```bash
python -m unittest discover -s tests -p "test_*.py" -v
```

PowerShell helpers in `scripts/` are intentionally non-destructive diagnostics. If `pwsh` is available, syntax-parse them before distribution.

## Pressure testing

Run the scenarios in `tests/skill-pressure-tests.md` first without the skill when feasible, then with the skill, and tighten rules when agents still rationalize unsafe behavior. `routing-scenarios.md` and `regression-scenarios.md` provide additional behavioral targets.

## Installing

Place the folder in the skills directory recognized by the chosen agent runtime or keep it alongside the Talia repository according to that runtime's skill-loading rules. Do not copy guessed project facts into `knowledge/`; populate them from the actual repository/tooling.

## Maintenance

- Keep `SKILL.md` concise and route detailed policy into supporting files.
- Never hard-code permanently “latest” framework/package versions.
- Refresh official sources only when freshness matters to the task.
- Update knowledge after verified repository changes, not from speculation.
- Add a pressure/regression scenario whenever an agent finds a new unsafe loophole worth preventing.
