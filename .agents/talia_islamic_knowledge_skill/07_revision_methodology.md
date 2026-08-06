# 07 — Revision (Muraja'ah) Methodology

## Purpose
Define how review/revision cycles should be prioritized and scheduled, extending `06_memorization_science.md` from "why spaced review works" into "how to sequence it across a user's whole memorized portfolio."

## Overview
Muraja'ah (مراجعة — revision) is the ongoing, life-long counterpart to initial memorization. In hifz tradition, revision is often considered harder to sustain than initial memorization, because it competes for time against acquiring new material. Talia's ReviewDueEvaluator/ReviewClassifier already encode part of this; this module is the reasoning framework behind those decisions.

## Core Concepts
- **Weak pages/blocks:** portions with a recent pattern of low recall grades — highest revision priority, since they're actively decaying.
- **Strong pages/blocks:** portions with a consistent high-grade history — lowest near-term priority, but never zero priority (mature memories still decay, just slowly).
- **Due vs. overdue:** SM-2's scheduled `nextReview` date defines "due"; the further past due, the higher the forgetting risk, so overdue items should outrank merely-due items in queue ordering.
- **Competing priorities:** new memorization vs. review of due material vs. recovery of weak material — these compete for a user's limited daily time/attention, and the scheduling logic has to arbitrate, not just list everything.

## Detailed Explanation
A sound revision priority order (reflected in Talia's Smart Coach adult ordering) generally looks like:
1. Weak **and** due — actively decaying and at risk of falling further behind; highest leverage intervention.
2. Due material within the user's active/near-term plan — protects recently-built memory before it weakens.
3. Due material further along in the plan — still important, slightly lower urgency.
4. Incomplete daily plan items — keeps the day's structured session on track.
5. New ayahs — growth, but only after protecting what's already built.
6. General hifz-due fallback — catch-all for anything not covered above.

This ordering reflects a core revision principle: **protecting existing memorization takes priority over adding new memorization**, because losing memorized material is a worse outcome than delaying new acquisition by a day.

## Important Classifications
| Signal | Meaning | Priority impact |
|---|---|---|
| Weak (avg of last 3 grades < 3, min 3 reviews) | Actively at risk | Highest |
| Overdue (past `nextReview`) | Forgetting risk rising | High, scales with days overdue |
| Due today | On schedule | Normal |
| Strong + not yet due | Stable | Low, but not ignorable long-term |

## Practical Rules
- Never let "new ayahs" outrank "due/weak review" in default queue ordering — this is the single most important revision-methodology rule, and it's already correctly reflected in Smart Coach's priority order; preserve it in any redesign.
- Overdue items should get increasing (not flat) priority the longer they've been overdue, since forgetting risk compounds.
- A user who is behind on review should see this clearly (not be quietly protected from it by hiding overdue counts) — motivation research and Islamic revision tradition both favor honest awareness over false comfort, paired with a manageable path back on track.

## Common Mistakes
- Scheduling review purely by "days since last review" without weak/overdue weighting — this under-serves exactly the material most at risk.
- Letting streak/gamification pressure push users toward new memorization (which "feels like progress") at the expense of due review (which feels repetitive) — the opposite of sound revision priority.
- Treating a full "sweep" of a memorized surah/juz as unnecessary once ayah-level SM-2 says items are "due later" — ayah-level intervals can miss whole-passage fluency decay (see `06_memorization_science.md` future extensions).

## UX Implications
- Daily plan UI should make clear *why* something is prioritized (weak, overdue, due-today) — transparency supports the honest-awareness principle above and helps users trust the system.
- A visible, non-punitive way to see "how far behind" review is, with a realistic recovery plan, rather than either hiding the backlog or presenting it as guilt-inducing.

## Engineering Implications
- `ReviewDueEvaluator`/`ReviewClassifier` logic should keep weak/overdue weighting as first-class inputs to ordering, not just filtering.
- Any new "priority" signal proposed for Smart Coach should be evaluated against the ordering principle above before being added — additions should slot into the existing hierarchy, not compete with it ad hoc.

## Product Implications
Revision is the feature area most tied to long-term retention outcomes (and therefore to whether users actually achieve durable hifz) — it deserves proportionally more product attention than its "less exciting than new memorization" feel might suggest.

## AI Design Guidelines
- When asked to redesign or extend review scheduling, check proposals against the "protect existing memorization first" principle before optimizing for engagement metrics.
- Review-quality metrics (if built) should measure recall accuracy and retention over time, not just session completion counts — completing a review session with poor self-grading isn't the same as successful revision.

## Examples
- ✅ A block that's both weak and 5 days overdue is surfaced above a block that's merely due today.
- ❌ A "streak-friendly" mode that lets users mark review complete without recalling, to avoid breaking a streak — this optimizes the metric while undermining the actual goal.

## References
Builds directly on the spaced-repetition/retrieval-practice foundation in `06_memorization_science.md`, applied to Talia's existing Smart Coach ordering (see `/areas/talia.md` product memory for the current implemented priority list).

## Future Extensions
- A "recovery plan" feature for users significantly behind on review, sequencing catch-up without overwhelming a single day.
- Whole-passage (not just per-ayah) fluency checks as a complement to SM-2 scheduling.
