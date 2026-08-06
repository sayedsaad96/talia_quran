# 15 — Feature Design Guidelines

## Purpose
Give a repeatable checklist for evaluating any new Talia feature before/while it's built, so Islamic, UX, technical, and educational considerations aren't left implicit or discovered late.

## Overview
Most feature mistakes in an app like Talia aren't "wrong code" — they're "the feature is fine technically but is religiously careless, patronizing, or motivationally counterproductive." This checklist is meant to catch those before they ship.

## Core Concepts — The Checklist
For any new or significantly changed feature, work through:

1. **Purpose** — What user need does this serve? Is it a memorization/review need, a motivational need, an informational need, or a companion/emotional need? (Different needs call for different rigor levels — see item 2.)
2. **Islamic considerations** — Does this feature touch Quran text, hadith, dua/adhkar, fiqh, or tafsir? If yes, it inherits the sourcing rules in `14_content_validation.md` in full. If no, this section can be brief.
3. **UX considerations** — Check against `13_islamic_ux.md`'s table (reverence, RTL, motion, tone, offline).
4. **Technical considerations** — Does it fit Talia's locked stack (Flutter, Cubit, Clean Architecture, GetIt, Supabase, Isar, GoRouter — see product memory)? Offline-first? Kids/Adult mode split respected where relevant?
5. **Educational considerations** — Check against `12_islamic_education.md` (intrinsic vs. extrinsic motivation, age-appropriateness, habit formation) and, if it touches memorization/review, `06_memorization_science.md` / `07_revision_methodology.md`.
6. **Validation checklist** — Every religious-content item has a source, grading (where applicable), and source-type tag per `14_content_validation.md`.
7. **Potential risks** — What's the worst-case failure mode (wrong citation, patronizing tone, breaking Kids/Adult separation, undermining retrieval practice for the sake of engagement)? Is there a reviewer/gate for it before shipping?

## Detailed Explanation
This checklist is intentionally lightweight for features that don't touch religious content (e.g., a settings screen redesign) and gets progressively heavier the more a feature touches sacred text, worship practice, or a child audience. Don't apply full religious-content rigor to a feature that doesn't need it — but don't skip it for one that does, even if it seems minor (e.g., a single "verse of the day" widget still needs full sourcing discipline).

## Important Classifications
| Feature touches... | Rigor level |
|---|---|
| Quran/hadith/dua/adhkar/tafsir/fiqh content | Full — all 7 checklist items, sourcing mandatory |
| Memorization/review mechanics (no new religious content) | Medium — items 4, 5, 7 matter most |
| General app UX (settings, account, non-devotional screens) | Light — items 3, 4, 7 |
| Companion character behavior | Medium — item 3 (UX/reverence) and item 5 (motivation) both apply |

## Practical Rules
- Run this checklist at design time, not just at code review — catching a sourcing gap before content is drafted is much cheaper than catching it after a screen is built.
- Any "Potential risks" item marked high-severity needs an explicit owner/decision before the feature ships, not just a note in a doc.

## Common Mistakes
- Running only the technical/architecture checklist (which Talia already has strong habits around, per its audit history) while skipping the Islamic/educational dimensions for content-adjacent features.
- Treating this checklist as a one-time gate rather than something to revisit when a feature's scope grows (a feature that started as "just UI" but later added a hadith citation needs to graduate to full rigor).

## UX Implications
See item 3 above and `13_islamic_ux.md` directly.

## Engineering Implications
See item 4 above; also worth adding this checklist as a PR template section for any PR touching `lib/features/` content related to Quran/hadith/dua/adhkar, so it's not solely reviewer memory that catches gaps.

## Product Implications
This checklist is what turns "we care about accuracy" from an intention into a repeatable process — worth keeping lightweight enough that it's actually used, rather than so heavy it gets skipped under deadline pressure.

## AI Design Guidelines
When proposing a new feature, walk through this checklist explicitly in the proposal rather than presenting only the UX/technical design — flag gaps (missing source, unclear madhab handling, Kids/Adult ambiguity) as open questions rather than silently resolving them.

## Examples
- ✅ A "verse of the day" feature proposal that explicitly notes: source dataset, tafsir attribution (if included), reverent display treatment, and a reviewer sign-off step before launch.
- ❌ A "verse of the day" feature shipped with placeholder tafsir text and a TODO to "add real sourcing later."

## References
Synthesizes the checklist items from `06`, `07`, `12`, `13`, and `14` into one applied workflow.

## Future Extensions
- Convert this into an actual PR/design-doc template once Talia's team grows beyond solo development.
