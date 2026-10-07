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

Check existing user authorization before destructive production DB changes, production data deletion, irreversible local migration, canonical Quran source/mapping strategy changes, auth/security-model replacement, or destructive Git history/worktree actions. If the exact action/environment and its recovery boundary are not already authorized, prepare a concrete reviewable change first and stop before execution. Do not ask again when the same action is already clearly authorized. Never broaden authorization to a different target, publish unapproved religious content, expose secrets, or replace architecture outside scope.

High risk does not itself require another permission question: continue authorized local inspection, tests and reversible fixes while preserving data and the required verification. If a content source/review gate is missing, block only that publication or canonical replacement; complete unaffected engineering work.

Never destroy unknown/unrecognized work. Preserve user changes and do not reset or clean them away.
