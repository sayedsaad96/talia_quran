# 09 — Dua (Supplication)

## Purpose
Define the categorization schema and sourcing discipline for dua content — parallel to `08_adhkar.md`, with the distinction that dua spans Quranic supplications, authenticated prophetic supplications, and broader situational supplication (a wider, less tightly bounded category than adhkar).

## ⚠️ Sourcing notice (read first)
As with adhkar, **actual dua text must come from a vetted dataset, not be generated.** This module defines structure and categorization only.

## Overview
Dua (دعاء) is personal supplication to Allah — broader than adhkar, ranging from verbatim Quranic supplications, to authenticated prophetic duas, to a Muslim's own words in any language. Talia's dua feature should be honest about which of these three tiers a given piece of content belongs to.

## Core Concepts
- **Quranic duas:** supplications that appear directly in the Quran text (e.g., prayers of prophets recorded in the text) — these carry the same textual-accuracy requirements as any Quran content (see `01_quran_foundations.md`, `14_content_validation.md`) since the words *are* Quran.
- **Authentic prophetic duas:** supplications reported from the Prophet ﷺ via hadith, with their own authenticity grading (see `10_hadith.md`).
- **Situational/free-form dua:** the broadest tier — a Muslim may supplicate in their own words on any matter, in any language. Content here is guidance/inspiration, not a fixed "correct wording" to imitate exactly.

## Detailed Explanation
These three tiers require different handling:
- Quranic duas: verbatim, sourced identically to any Quran text — zero tolerance for paraphrase presented as the verse.
- Prophetic duas: verbatim Arabic + attributed source + grading, same discipline as adhkar.
- Free-form dua guidance: here alone is where more flexible, educational content (e.g., "some scholars suggest structuring dua as praise, then request, then closing") is appropriate — but it should be clearly framed as guidance/etiquette (adab al-du'a), not as fixed wording.

## Important Classifications
| Tier | Wording flexibility | Sourcing requirement |
|---|---|---|
| Quranic dua | None — verbatim only | Quran dataset, same as any ayah |
| Prophetic dua | None — verbatim only | Hadith dataset with grading |
| Situational/free-form | High — user's own words | Guidance only; no fixed "correct" text to source |

## Required Metadata Schema (for imported verbatim content)
```
DuaItem {
  id
  tier                 // quranic / prophetic / guidance
  category              // e.g., travel, exam, difficulty, gratitude, forgiveness
  arabicText (if tier = quranic or prophetic)
  transliteration
  translation
  sourceCitation         // Quran ref, or hadith ref (book + number)
  authenticityGrade (if tier = prophetic)
  contextNote (optional)  // when it's typically said, sourced if quoting a stated context
}
```

## Practical Rules
- Never blur the line between "prophetic dua" and "commonly circulated dua of unclear origin" — a great deal of dua content circulates online without solid attribution; if a source can't be verified, either mark it clearly as "commonly recited, source unverified" or exclude it.
- For situational categories (exams, job interviews, grief, illness) it's tempting to want a "perfect dua for this" — resist inventing one; either surface a genuinely applicable sourced dua, or present it as free-form guidance rather than fixed wording.
- Quranic duas must match the exact Uthmani text used elsewhere in the app — never a simplified or re-typed version.

## Common Mistakes
- Treating widely-shared "dua for X" social media content as authoritative without checking its actual source.
- Presenting free-form dua guidance with fixed Arabic wording, implying there's one correct phrasing when the tier is meant to be flexible.
- Omitting authenticity grading for prophetic duas "to keep the UI simple."

## UX Implications
- A visible tier indicator (Quranic / Prophetic / Guidance) helps users understand what kind of confidence to place in the wording they're seeing.
- Situational dua search/browse (e.g., "dua for exams") is a natural, high-engagement feature — build it on top of correctly-tiered content rather than generating on demand.

## Engineering Implications
- Keep `tier` as a required, non-nullable field on every dua record — it drives both display treatment and sourcing requirements.
- Situational/free-form guidance content can be authored/edited more like normal app copy (with religious-content review, not hadith-level sourcing rigor) since it doesn't claim fixed authenticity.

## Product Implications
Dua is an emotionally resonant feature area (exam anxiety, grief, gratitude) that fits Talia's companion positioning well — precisely because of that emotional weight, sourcing errors here are more likely to be noticed and to erode trust than in a purely informational feature.

## AI Design Guidelines
- If asked to generate "a dua for [situation]" and no sourced item fits, offer free-form guidance framed as guidance (adab al-du'a), not as if it were a fixed authoritative text.
- Always preserve the tier distinction in any AI-assisted content pipeline — don't let a prophetic-dua and a guidance-tier item look identical in the data model.

## Examples
- ✅ "Dua for travel (Prophetic, Sahih Muslim [ref]): [sourced Arabic + translation]."
- ❌ "Here's a nice dua for job interviews" with invented Arabic wording and no source.

## References
See `18_references.md` for dua data sources; see `10_hadith.md` for authenticity grading methodology applied to prophetic duas.

## Future Extensions
- A "dua journal" free-form feature (user's own words, private) as a natural extension of the guidance tier, requiring no religious-content sourcing at all since it's user-authored.
