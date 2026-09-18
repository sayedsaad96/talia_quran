# Ecosystem Intelligence

Use [Source Authority](../references/source-authority.md) whenever a decision depends on current external state.

## External Change Classification

- **Mandatory** — security, store/platform requirement, removed API, unsupported SDK, or unavoidable compatibility change.
- **Strongly Recommended** — important stability, supported deprecation replacement, or relevant major reliability improvement.
- **Useful Opportunity** — potentially valuable for Talia but not required.
- **Experimental** — promising but immature; isolate in a spike/benchmark.
- **Irrelevant** — no meaningful Talia problem/value.

**Discovering an update != applying an update.**

Record strategic choices in `knowledge/tech-radar.md` using `ADOPT|TRIAL|ASSESS|HOLD`; record actionable maintenance in `knowledge/update-backlog.md`.
