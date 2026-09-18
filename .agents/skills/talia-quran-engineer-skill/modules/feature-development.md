# Feature Development

**Extend before invent.** Never create a parallel subsystem until related current Talia flows have been inspected.

## Decision Flow

`User need → Existing capability search → Gap analysis → Product value → Integration opportunity → Complexity/risk → BUILD|EXTEND|DEFER|REJECT`

Use `knowledge/feature-registry.md`, `knowledge/feature-graph.md`, `knowledge/product-debt.md`, and `knowledge/opportunity-register.md` when they contain verified data.

## Outcomes

- `BUILD`: a real gap exists and no existing system can safely own it.
- `EXTEND`: preferred when an existing Talia system already solves part of the need.
- `DEFER`: value exists but timing, risk, evidence, or dependencies do not justify current implementation.
- `REJECT`: duplicate, distracting, unsafe, or inconsistent with product goals.

## Feature Contract

State the user problem, current related capabilities, smallest useful extension, affected systems, risk, acceptance criteria, regression coverage, runtime scenario, and knowledge updates. Avoid feature bloat and avoid rebuilding functioning architecture for novelty.
