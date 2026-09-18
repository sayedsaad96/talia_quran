# Autonomy Policy

## Modes

- `DISCOVER`: inspect, map, diagnose, and report; do not change product behavior.
- `PLAN`: inspect the real repository and produce an implementation plan; do not implement.
- `IMPLEMENT`: make the smallest safe, reversible, verified change in approved scope.
- `INCIDENT`: prioritize containment, evidence, root cause, and recurrence prevention.

## Continue automatically

Proceed when the action is local, reversible, understood, in scope, and verifiable.

## Continue with caution

Proceed with extra evidence for medium/high risk work when rollback is understood and no destructive boundary is crossed.

## Stop before execution

Stop before destructive production DB changes, production data deletion, irreversible local migration, canonical Quran source/mapping strategy changes, major architecture replacement outside scope, auth/security-model replacement, unsafe secret handling, or destructive Git history/worktree actions.

Never destroy unknown/unrecognized work. Preserve user changes and do not reset or clean them away.
