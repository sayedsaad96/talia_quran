# 08 — Adhkar (Remembrances)

## Purpose
Define the categorization schema and metadata model for adhkar content, and — critically — how actual adhkar text must be sourced for Talia rather than generated.

## ⚠️ Sourcing notice (read first)
**This module intentionally does not contain a compiled list of adhkar text.** Adhkar carry specific Arabic wording, transliteration, translation, and authenticity grading that must trace to a real hadith/collection source — errors here (a word changed, a wrong grading, a misattributed source) are exactly the kind of mistake `14_content_validation.md` forbids. Actual adhkar content for Talia should be imported from a vetted, structured collection (see `18_references.md` — e.g., a Hisnul Muslim dataset/API) and reviewed by a qualified person before shipping, not authored by an LLM from memory. This module defines the *shape* that imported content should take.

## Overview
Adhkar are prescribed or recommended remembrances/supplications tied to specific times, states, or occasions. A well-built adhkar feature is one of the highest-value, lowest-controversy content areas for a companion-style app like Talia — but only if sourcing discipline is maintained.

## Core Concepts
- **Time-bound adhkar:** Morning (Adhkar al-Sabah), Evening (Adhkar al-Masa') — the most commonly used category, tied to specific times of day.
- **State-bound adhkar:** before/after sleep, upon waking, entering/leaving the home, entering/leaving the mosque, before/after eating, travel, illness, distress, rain, and similar situational categories.
- **Prayer-bound adhkar:** remembrances said within or immediately after the five daily prayers (adhkar al-salah / adhkar ba'd al-salah).
- **Authenticity grading:** each item's source hadith carries a grading (sahih/hasan/da'if — see `10_hadith.md`) that must travel with the item, not be dropped in display.

## Detailed Explanation
Every adhkar record needs enough metadata to be independently verifiable by a reviewer or a user who wants to check the source themselves — this is both a religious-accuracy requirement and a trust/UX feature (users of serious Islamic apps often want to see the source).

## Important Classifications
| Category | Typical trigger | Notes |
|---|---|---|
| Morning | After Fajr until roughly midday | Time-window, not exact-minute |
| Evening | After Asr until Maghrib/nightfall | Time-window |
| Sleep | Before sleeping | State-bound |
| Waking | Upon waking | State-bound |
| Prayer | Within/after each of the 5 prayers | Prayer-bound |
| Home | Entering/leaving | State-bound |
| Mosque | Entering/leaving | State-bound |
| Food | Before/after eating | State-bound |
| Travel | Starting a journey | State-bound |
| Distress/illness | As needed | State-bound, sensitive — see UX notes |
| Rain and other natural events | As needed | State-bound |

## Required Metadata Schema (for imported content)
```
AdhkarItem {
  id
  category            // one of the classifications above
  arabicText          // verbatim, from source dataset
  transliteration      // from source dataset, not machine-transliterated ad hoc
  translation           // attributed translation, not free paraphrase
  sourceCitation        // e.g., "Muslim 2723" — must resolve to a real, checkable reference
  authenticityGrade      // sahih / hasan / da'if — from the source dataset's grading, not inferred
  recommendedCount       // if the dhikr has a prescribed repetition count
  benefitNote (optional)  // must itself be sourced if quoting a stated virtue/benefit
}
```

## Practical Rules
- Do not populate `arabicText`, `translation`, or `authenticityGrade` from model memory — import from a vetted dataset and keep the dataset's own citations intact.
- If a repetition count or benefit is commonly cited (e.g., "recommended to say a set number of times"), the exact number and its source must come from the dataset, not be assumed.
- Distress/illness-related adhkar content should never be paired with clinical claims (e.g., implying dhikr replaces medical treatment) — keep it framed as spiritual practice alongside, not instead of, appropriate care.

## Common Mistakes
- Mixing translations from different sources/scholars within the same list without noting it, producing inconsistent tone/terminology.
- Dropping the authenticity grade in the UI "to keep it clean" — this removes exactly the information a careful user or reviewer needs.
- Auto-generating a "situational dua for X" when no sourced item exists for that situation, instead of leaving it out.

## UX Implications
- Morning/Evening adhkar are natural candidates for a notification-triggered flow (matching Talia's character companion reacting "after Fajr") — but the content itself must still be dataset-sourced, not generated per notification.
- Show source citation and grading unobtrusively (e.g., a small tappable "source" label) rather than omitting it — respects both accuracy and user trust.
- For distress/illness categories, keep tone calm and non-alarmist; this is adjacent to sensitive emotional territory even though the content itself is devotional.

## Engineering Implications
- Adhkar content should be a bundled/versioned dataset (offline-first, consistent with Talia's architecture) with a clear update/review process when the dataset version changes.
- Build a lightweight internal review checklist (source present, grading present, translation attributed) as a gate before any new adhkar item ships — see `14_content_validation.md`.

## Product Implications
A well-sourced Morning/Evening Adhkar flow, tied to the character companion's daily presence, is a strong retention feature that reinforces Talia's "companion" positioning — but the trust payoff only materializes if sourcing discipline holds from the first release.

## AI Design Guidelines
- If asked to "add adhkar content" and no vetted dataset is connected yet, respond by proposing the sourcing/integration task (see `18_references.md`), not by drafting the text.
- Never invent a "situational dua" for a scenario (e.g., "dua for starting a new business") without a real source — it's fine to say no sourced item is available.

## Examples
- ✅ "Import Hisnul Muslim's Morning Adhkar section as structured data; render with citation + grading intact."
- ❌ "Here are 10 morning adhkar" generated freehand for the app to ship immediately.

## References
See `18_references.md` for vetted adhkar/dua data sources (e.g., Hisnul Muslim-based datasets, sunnah.com-linked collections).

## Future Extensions
- Personalized adhkar reminders (e.g., travel-triggered) once location/context signals are available and content sourcing is in place.
