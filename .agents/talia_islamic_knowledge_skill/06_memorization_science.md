# 06 — Memorization Science (Hifz)

## Purpose
Ground Talia's memorization and Smart Coach features in established learning science, connected explicitly to what's already implemented (SM-2, weak-block detection, review classification).

## Overview
Quran memorization (hifz) is a long-term retrieval-practice problem, not a short-term cramming problem. The relevant science — forgetting curves, spaced repetition, retrieval practice, desirable difficulty — maps cleanly onto Talia's existing SM-2-based Memorization V2 Session Engine and ReviewClassifier/ReviewDueEvaluator.

## Core Concepts
- **Forgetting curve:** memory strength decays over time unless reinforced; the decay rate slows each time a memory is successfully retrieved after a delay (Ebbinghaus's foundational finding).
- **Spaced repetition:** scheduling review at increasing intervals as a memory strengthens — Talia implements this via SM-2 (default ease factor 2.5, interval growth per successful recall, reset on failure).
- **Retrieval practice (active recall):** the act of recalling from memory (not re-reading/re-listening) is itself what strengthens memory — this is why Talia's Unified Assessment Model requires Hide Text → Record → Self Grade rather than passive re-listening.
- **Desirable difficulty:** review that feels slightly effortful (but still succeeds) produces stronger retention than review that's too easy — informs how "due" thresholds and block sizing should be tuned, not just how they're scheduled.
- **Interleaving:** mixing review of different surahs/sections (vs. blocked, one-at-a-time review) generally improves long-term retention and discrimination between similar passages — relevant to how Talia's daily review queue is composed, not just which items are due.

## Detailed Explanation
Memorization stages typically observed in hifz pedagogy, mapped to what Talia already models:
1. **New acquisition** — first encoding of an ayah/block (repetition-heavy, short-interval).
2. **Consolidation** — early spaced review while the memory is still fragile (Talia: `repetitions` 1–2, short intervals of 1 and 6 days per SM-2).
3. **Long-term retention** — mature review at increasing intervals (Talia: `intervalDays` growing via ease factor).
4. **Maintenance/mastery** — sustained recall over months/years, often needing periodic full-surah or full-juz "sweep" review beyond individual ayah scheduling — this is the layer where "weak block" detection matters most.

## Important Classifications
| Review cadence | Purpose | Talia mechanism |
|---|---|---|
| Daily | New material + due items | SM-2 due queue |
| Weekly | Reinforce recent surahs before they fully mature in the schedule | Smart Coach recommendation signals |
| Monthly | Full-juz/full-surah sweep to catch drift not visible at ayah granularity | Not yet automated — candidate for Smart Coach expansion |
| Annual | Full khatm-style review (common in hifz tradition, e.g., during Ramadan) | Product-level feature, not yet built |

## Practical Rules
- A grade below 3 (SM-2 scale) should reset repetitions and shrink the interval — Talia already implements this correctly; any new feature touching grading must preserve this, not introduce a "partial credit" path that silently weakens the algorithm's guarantees.
- "Weak" classification should be based on a rolling window of recent grades (Talia's existing rule: average of last 3 grades < 3, minimum 3 reviews) rather than a single bad recall — a single slip is normal and shouldn't be over-penalized.
- Kids Mode needs materially different pacing/thresholds than adult mode (shorter blocks, more forgiving grading friction) — already reflected in Talia's Kids Mode STT bypass and separate mode architecture; don't let generic "improve the algorithm" work quietly erode that separation.

## Common Mistakes
- Treating "more repetition" as always better — beyond a point, repetition without spacing produces short-term fluency that doesn't transfer to long-term retention (this is the core insight spaced repetition is designed around).
- Scheduling purely by elapsed time without accounting for block difficulty (some ayahs/passages are objectively harder to retain — similar-sounding parallel verses, long enumerations) — difficulty-aware scheduling is a meaningful improvement path over pure SM-2.
- Over-gamifying in a way that rewards speed over accuracy of recall (streak pressure that encourages rushing self-grading).

## UX Implications
- Review sessions should make the effort of active recall unavoidable before revealing the answer — Talia's Hide Text → Record → Self Grade flow is the right shape; any redesign should preserve "recall before reveal" as non-negotiable.
- Progress visualization should distinguish "newly acquired" from "long-term retained" so users don't mistake early fluency for mastery.

## Engineering Implications
- Keep SM-2 state (`repetitions`, `easeFactor`, `intervalDays`) per-ayah or per-block as currently modeled — don't collapse it to a single per-surah value, since retention genuinely varies within a surah.
- Difficulty-estimation (harder passages needing tighter scheduling) is a legitimate SM-2 extension — feed a difficulty signal into interval calculation rather than replacing SM-2 wholesale.

## Product Implications
Smart Coach's existing priority order (weak+due → quiz, due-near → daily plan, due-far → daily plan, incomplete plan, new ayahs, hifz-due fallback, kids mission) already reflects sound memorization-science prioritization — weak+due items are exactly where desirable-difficulty-informed intervention has the highest leverage.

## AI Design Guidelines
- When proposing new Smart Coach signals, ground them in one of: forgetting-curve timing, retrieval-practice quality, or difficulty estimation — not generic "engagement" metrics that could undermine retention (e.g., rewarding session frequency over recall quality).
- Any AI-generated encouragement/coaching copy should reinforce effortful recall ("try to recall it fully before checking"), not shortcut it ("here's a hint" offered too early).

## Examples
- ✅ A block with 3 recent grades of [2, 2, 3] is flagged weak and prioritized, even though the most recent grade passed.
- ❌ A feature that lets users skip self-grading and auto-marks a review "complete" after audio playback — this removes retrieval practice entirely.

## References
Core science: Ebbinghaus's forgetting curve; spaced repetition research (as implemented via SM-2); retrieval practice research (Roediger & Karpicke and the broader testing-effect literature). See `18_references.md` for pointers; no fabricated citations are used here.

## Future Extensions
- A monthly/annual "sweep review" feature to complement ayah-level SM-2, addressing the gap noted above.
- Difficulty-estimation signals (e.g., flagging mutashabihat — similar-sounding verses — as inherently higher-difficulty) feeding into interval calculation.
