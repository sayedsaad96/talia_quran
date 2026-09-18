# Risk Engine

Use the highest applicable level.

| Level | Typical scope | Minimum verification | Autonomy |
|---|---|---|---|
| 0 | Copy, labels, spacing, non-functional polish | Focused inspection | Automatic |
| 1 | Isolated widget or low-risk refactor | Analyze + targeted test | Automatic |
| 2 | State, navigation, audio control, feature behavior | Impact analysis + tests + runtime check | Automatic with caution |
| 3 | Quran reader, progress, RLS, auth, migrations, persistence | Baseline + regression + runtime + data/state checks | Cautious; preserve rollback |
| 4 | Canonical Quran data, destructive user-data/auth/security changes | Deterministic verification + recovery/rollback + explicit boundaries | Stop before irreversible action |

**Critical tasks disallow speculative edits and require deterministic verification.**

Escalate risk when a change crosses subsystems, changes stored identifiers, changes backend contracts, or cannot be safely rolled back.
