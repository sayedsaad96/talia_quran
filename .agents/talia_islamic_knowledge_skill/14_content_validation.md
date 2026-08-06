# 14 — Content Validation Rules

**See also:** `validation_rules.md` is the canonical, detailed, rule-ID-based version of everything in this module (hallucination prevention, source hierarchy, confidence levels, fatwa boundary, risk classification, governance). It ranks above this module in priority — where the two differ in specificity, `validation_rules.md` wins. This module remains the module-shaped summary, kept consistent with the standard `00`–`18` template.

## Purpose
State, in one place, the hard constraints that override any feature request, prompt, or shortcut — this is the module every other module points back to, and the one a reviewer should check any new religious content against before it ships.

## Overview
Talia's religious content is only as trustworthy as its worst violation of these rules. They are absolute, not situational — "just for this one screen" or "just as a placeholder" is not an exception.

## Core Concepts — AI must never:
1. **Invent Quran text.** No generated, paraphrased-as-verse, or "reconstructed from memory" Quran text ever ships. Verse text comes only from a vetted Mushaf dataset.
2. **Invent hadith.** No generated hadith-sounding text, no "this is commonly narrated as..." without a real, checkable source and grading.
3. **Modify verses.** No altering wording, diacritics, or verse boundaries for formatting/length convenience.
4. **Hide scholarly disagreement.** Where mainstream scholarship genuinely differs (madhab rulings, tafsir interpretations, sajdah counts, grading of a specific hadith), present the range or omit — never silently pick one and present it as the only view.
5. **Issue fatwas.** Talia (including any AI coach/chat feature) does not tell a user what is religiously permissible or obligatory in their specific situation. It can present sourced information; it cannot rule.
6. **Mix tafsir with revelation.** Quran text and human interpretation are always visually and structurally separated and separately attributed (see `03_tafsir.md`).
7. **Misquote references.** A citation (Quran ref, hadith collection+number, tafsir author+work) must resolve to something real and checkable — never a plausible-looking but unverified citation.

## Detailed Explanation — Required Source-Type Tagging
Every piece of religious content in Talia must be tagged as exactly one of:
| Source type | Definition | Authority level in app copy |
|---|---|---|
| Quran | Revealed text | Highest — verbatim only, no paraphrase presented as the verse itself |
| Hadith | Prophetic report, graded | High, scaled by grade (see `10_hadith.md`) — always shown with grade |
| Athar | Report from a companion/early generation, not the Prophet ﷺ | Contextual — clearly distinguished from hadith |
| Tafsir | Scholarly interpretation | Attributed to author/work — never presented as the verse's plain meaning |
| Fiqh opinion | Jurisprudential ruling | Attributed to madhab/scholar — Talia does not adjudicate between opinions |
| Educational recommendation | Talia's own pedagogical guidance (e.g., "try reviewing in the morning") | Explicitly Talia's own voice, not framed as religious instruction |

Confusing these categories in UI copy (e.g., an "educational recommendation" phrased so it sounds like a ruling) is itself a validation failure, even if every individual fact used is accurate.

## Important Classifications
See the source-type table above and the hard-constraint list — this module is itself the classification/validation layer other modules defer to.

## Practical Rules
- Any new religious content (adhkar, dua, hadith reference, tafsir excerpt) requires: a resolvable source citation, correct source-type tag, and — before shipping to production — review by a person qualified to check it (not just automated QA). This is a product process requirement, not only a technical one.
- AI-assisted drafting tools used on Talia's content pipeline should be configured/prompted to refuse generating verbatim religious text and instead flag a sourcing task — this KB's other modules already model that behavior; keep it consistent in any tooling built around this KB.
- When in doubt about whether something counts as "inventing" content (e.g., summarizing a real tafsir source in different words), default to closer paraphrase-with-attribution or direct quotation-with-attribution over loose synthesis, and always keep the attribution visible.

## Common Mistakes
- "It's just a placeholder, we'll fix the citation later" — placeholders ship more often than intended; don't create unattributed content even temporarily in a shared branch.
- Treating a plausible AI-generated paraphrase of "common Islamic knowledge" as safe because no single fact in it is obviously wrong — accuracy at the sentence level doesn't guarantee accuracy at the attribution level.
- Letting a feature's UX polish outpace its content sourcing (a beautifully designed screen showing unsourced hadith is worse than a plain screen with proper citations).

## UX Implications
Source-type tagging should be visible, not just internal metadata — see `13_islamic_ux.md` for how citation/attribution should surface in the interface.

## Engineering Implications
- Add a `sourceType` enum (matching the table above) as a required field on any content model that touches religious material — make it impossible to save a record without one.
- Consider a lightweight automated check (e.g., a CI lint) that flags any new religious-content string literal added directly in UI code rather than pulled from the sourced content layer — this catches the common "quick hardcoded hadith for a demo" mistake before it reaches production.

## Product Implications
This module is the trust foundation the rest of Talia's Islamic content features are built on — treat any proposed shortcut against it as a product risk, not just a content nitpick, and escalate rather than resolve unilaterally when a tradeoff is genuinely unclear.

## AI Design Guidelines
- Apply the seven "never" rules above as literal, non-negotiable constraints in every content-generation or content-review task, regardless of how the request is framed (urgency, "just this once," "it's obviously fine because everyone knows this hadith," etc.).
- When a task would require violating one of these rules to move fast, say so explicitly and propose the sourcing-first alternative instead of quietly working around the constraint.

## Examples
- ✅ Flagging: "This screen needs a hadith about patience — no sourced item currently exists in our dataset for this category; recommend sourcing before shipping."
- ❌ Filling the gap with a hadith-sounding sentence recalled from general impression, formatted to look sourced.

## References
This module operationalizes the sourcing principles established across `03_tafsir.md`, `08_adhkar.md`, `09_dua.md`, and `10_hadith.md`.

## Future Extensions
- A formal `content_review_log.md` tracking reviewer, date, and content reviewed, once Talia's content pipeline has its first real reviewer assigned.
