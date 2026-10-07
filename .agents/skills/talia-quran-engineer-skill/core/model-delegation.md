# Model delegation

The current repository `AGENTS.md` is authoritative. Do not spawn agents merely because slots are available, duplicate an investigation, or recursively delegate routine work.

| Work | Least costly capable role/model |
|---|---|
| Trivial edit or inspection | Root, directly |
| File/symbol search, logs, dependency inventory, read-only mapping | Luna (`explorer` or `scout` as appropriate) |
| Normal Flutter feature, widget, Cubit, limited refactor, tests, localization | Terra (`builder`) |
| Coordination, integration, important implementation review, architecture boundaries | Sol |
| Critical investigation or planning | Astra (`expert`), only when justified below |

Escalate to Astra for reasoning across several architecture layers/features, a failed reasonable Sol/Terra attempt with unknown root cause, critical architecture, security/data integrity/concurrency/lifecycle/memory/serious performance, risk to Quran/progress/user data/audio state, or major pre-release production review. Send only relevant evidence and a narrow investigation/planning question; return routine implementation to Terra when safe.

Normally use at most three subagents per task and Astra once, unless a genuinely separate critical issue appears. Respect the active concurrency limit. Custom audit roles pin their own models and effort: spawn by role without redundant overrides. Full audit assignments and coverage are defined in [Pre-release Audit](../workflows/pre-release-audit.md).
