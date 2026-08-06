# 16 — Product Knowledge: Talia Philosophy

## Purpose
Capture Talia's product philosophy as already established through its Constitution and prior product decisions, so any agent proposing new features or content extends this philosophy rather than reinventing or contradicting it.

## Overview
Talia (تالية) is a Quran memorization and review companion app for the Egyptian/MENA Arabic-speaking market, built by Sayed as a solo founder. Its product identity rests on a small number of consistent commitments, formalized in the Talia Product Constitution (v1.2) and its companion Implementation Roadmap and Technical Decisions documents.

## Core Concepts
- **Offline-first.** Core reading, memorization, and review must work without connectivity — reflected end-to-end in the architecture (Isar local storage alongside Supabase) and should be treated as a default requirement for any new feature, not an add-on.
- **Companion experience, not a tool.** Talia is designed around a companion character (تالية) that reflects the user's state — welcoming, following along, celebrating, quietly present during struggle — rather than a neutral utility UI. New features should ask "how does the companion relate to this," not just "what does this screen do."
- **Memorization philosophy: protect before grow.** Consistent with `07_revision_methodology.md`'s priority ordering, Talia's Smart Coach prioritizes safeguarding existing memorization (weak/due review) ahead of new acquisition.
- **Review philosophy: active recall, not passive exposure.** The Unified Assessment Model (Hide Text → Record → Self Grade) is central to both memorization and review paths, and reflects a deliberate rejection of passive-listening-only review.
- **Kids Mode as a genuinely separate experience,** not a themed skin over Adult Mode — different pacing, different STT policy, different companion behavior, Parent Dashboard visibility.
- **AI coach as a scaffolding layer,** approximating what a good hifz teacher would prioritize next (see `12_islamic_education.md`), not a generic recommendation engine optimizing engagement.
- **Progress tracking and certificates** as recognition of real, verified progress (per Talia's SM-2-based tracking), shared consistently across memorization paths (Hifz, Adult Memorization Plus, Kids Mode, legacy).
- **Daily plans** as the primary interaction unit — Talia is built around "what should I do today," informed by Smart Coach signals, rather than an undifferentiated content browser.

## Detailed Explanation
Architecturally, Talia is built on Flutter + Cubit + Clean Architecture + GoRouter + GetIt + Supabase + Isar, deliberately not migrated to Riverpod, with a locked v3 domain split into 8 Bounded Contexts: Quran, Learning, Assessment, Review, Guidance (Smart Coach), Progress, Family, and Synchronization. This architecture is itself a product statement: religious-content concerns (Quran), pedagogical concerns (Learning/Assessment/Review), coaching (Guidance), and family/parental concerns (Family) are treated as distinct bounded domains rather than flattened into one generic "content" layer — new features should generally slot into one of these contexts rather than creating ad hoc cross-cutting logic.

## Important Classifications
| Philosophy pillar | What it rules out |
|---|---|
| Offline-first | Any devotional feature that requires connectivity to function at all |
| Companion, not tool | Purely transactional UI for core flows (memorization/review) without companion presence |
| Protect before grow | Smart Coach logic that surfaces "new material" ahead of weak/due review |
| Active recall | Review flows that let users mark completion without a genuine recall attempt |
| Kids Mode ≠ skin | Shared thresholds/pacing between Kids and Adult mode "for simplicity" |
| Teacher-scaffolding AI coach | Engagement-metric-optimized recommendations disconnected from pedagogical reasoning |

## Practical Rules
- Any new feature proposal should be checked against these pillars explicitly (see `15_feature_design_guidelines.md`'s checklist) — if a proposal seems to conflict with one, that's a flag to raise, not silently resolve.
- Character companion behavior changes should be evaluated against the existing character spec's boundary: a calm educational companion, explicitly not a religious/sacred figure and not attributed qualities like praying for the user or representing angels.

## Common Mistakes
- Proposing engagement mechanics borrowed from generic habit apps without checking whether they undermine "protect before grow" or "active recall."
- Treating Kids Mode as a smaller version of Adult Mode rather than a genuinely different pedagogical experience.
- Adding online-dependency to a feature by default, without an explicit offline-first design pass.

## UX Implications
See `13_islamic_ux.md` for the reverence-specific layer; this module is the broader product-philosophy layer that `13` sits inside.

## Engineering Implications
New features should map cleanly onto one (or a clearly justified combination) of the 8 Bounded Contexts — if a feature doesn't fit any of them cleanly, that's worth surfacing as an architecture question before building, not resolving ad hoc.

## Product Implications
Talia's differentiation against competitors (e.g., Tarteel, Quran Majeed, referenced in prior competitive analysis) rests on this specific combination of companion warmth, pedagogically sound review science, and offline-first reliability — features that trade any of these away for generic "more features" growth should be scrutinized accordingly.

## AI Design Guidelines
When asked to design or evaluate a feature for Talia, explicitly check it against the pillars in this module before presenting a design — don't just solve the stated request in isolation from Talia's established philosophy.

## Examples
- ✅ A new "quick review" widget that still routes through Hide Text → Record → Self Grade, just with a shorter block.
- ❌ A "quick review" widget that shows the answer immediately alongside the prompt "for speed," bypassing active recall.

## References
Grounded in Talia's own Product Constitution v1.2, Implementation Roadmap, and Technical Decisions documents, and prior product/technical work (see project memory).

## Future Extensions
- Certificates and progress-sharing features could extend this philosophy into a social/community layer — if pursued, it should be evaluated against "companion, not tool" and offline-first constraints from the outset, not retrofitted.
