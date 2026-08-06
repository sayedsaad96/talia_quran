# 10 — Hadith (Prophetic Narrations)

## Purpose
Give agents the authentication framework needed to handle hadith responsibly anywhere they appear in Talia (adhkar sourcing, dua sourcing, tafsir bi-l-ma'thur, educational content) — and to make explicit that this KB does not itself supply hadith text.

## ⚠️ Sourcing notice (read first)
**This module contains no hadith text.** Hadith are precisely-worded, chain-of-narration-dependent reports; any use in Talia must be pulled from a vetted hadith database with published grading (see `18_references.md`), never generated or recalled freehand.

## Overview
Hadith are reports of the sayings, actions, and approvals of the Prophet ﷺ. Because they were transmitted through chains of narrators (isnad) rather than preserved as a single fixed text the way the Quran was, hadith scholarship developed a rigorous authentication methodology to grade reliability — and any AI system touching hadith content must respect, not flatten, that grading.

## Core Concepts
- **Isnad (إسناد):** the chain of narrators through which a hadith was transmitted; its reliability (each narrator's trustworthiness and memory, and whether the chain is unbroken) drives the hadith's grading.
- **Matn (متن):** the actual text/content of the hadith, evaluated for internal consistency and non-contradiction with more established sources.
- **The major collections:** Sahih al-Bukhari and Sahih Muslim are considered the two most rigorously authenticated collections (together often called "the two Sahihs"); Sunan Abi Dawud, Jami' al-Tirmidhi, Sunan al-Nasa'i, and Sunan Ibn Majah round out "the six books" (al-Kutub al-Sittah) commonly referenced alongside them.

## Detailed Explanation — Grading Tiers
| Grade | Meaning | Implication for app use |
|---|---|---|
| Sahih (صحيح) | Authentic — unbroken reliable chain, no defects | Safe to present with normal confidence, still cited |
| Hasan (حسن) | Good — reliable but slightly weaker chain than Sahih | Present with citation; acceptable for general use |
| Da'if (ضعيف) | Weak — chain has a significant defect | Use cautiously if at all; if included, must be explicitly labeled weak, never presented as equal to Sahih/Hasan |
| Mawdu' (موضوع) | Fabricated | Never present as a hadith at all — if referenced (e.g., in an educational "common misconceptions" context), it must be explicitly labeled fabricated, not left ambiguous |

Grading is itself sometimes a matter of scholarly disagreement (different hadith scholars/critics have graded some narrations differently) — a good source dataset will reflect that (e.g., citing which scholar's grading is being shown) rather than presenting grading as universally settled for every hadith.

## Important Classifications
- **Marfu' (مرفوع):** attributed directly to the Prophet ﷺ.
- **Mawquf (موقوف):** attributed to a companion, not directly to the Prophet ﷺ (this is closer to "Athar" territory — see `14_content_validation.md`'s source-type list).
- **Mutawatir (متواتر):** transmitted through so many independent chains that fabrication is effectively impossible — a small category, mostly relevant to core textual matters (like aspects of Quran transmission) rather than typical daily-use hadith.
- **Ahad (آحاد):** transmitted through a limited number of chains — the vast majority of hadith fall here; "Ahad" is not itself a weakness indicator, it just means the chain-count category, separate from the sahih/hasan/da'if reliability grading.

## Practical Rules
- Every hadith surfaced in the app needs: collection name, book/number reference, and authenticity grade with its grading source (e.g., "graded sahih by Al-Albani" vs. "graded sahih by the collection's own internal standard, as with Bukhari/Muslim").
- Weak (da'if) hadith should generally be excluded from devotional/practical content (adhkar, dua, rulings); if ever included for educational/historical discussion, label prominently.
- Never present a hadith's authenticity as a fact this KB or an AI agent determined — grading comes from hadith-science scholarship and sourced databases, not from the app's own inference.

## Common Mistakes
- Treating "widely shared" or "commonly heard" as a proxy for authenticity — many popular quotes attributed to the Prophet ﷺ circulate without a real chain, or are outright fabricated.
- Citing a hadith by vague reference ("a hadith says...") instead of collection + number.
- Using a weak or fabricated hadith in motivational/educational content because it "sounds nice" — the sourcing discipline applies regardless of how appealing the content is.

## UX Implications
- Hadith citations should be tappable/expandable to show grading and source, consistent with the adhkar/dua citation pattern.
- If Talia ever surfaces "hadith of the day" style content, it must draw only from a pre-vetted Sahih/Hasan pool, not a broad unfiltered dataset.

## Engineering Implications
- Hadith data source should carry structured `collection`, `bookNumber`, `hadithNumber`, `grade`, and `gradedBy` fields — not a single freeform "reference" string.
- Any content-generation pipeline (including AI-assisted drafting of educational copy) should be blocked from inserting hadith text that doesn't resolve to a record in the vetted dataset.

## Product Implications
Hadith-sourced content (adhkar, dua, educational "did you know") is a meaningful trust surface for a serious Islamic app — getting grading and attribution right consistently is worth the extra engineering discipline it requires.

## AI Design Guidelines
- Default response to "add a hadith about X" without a connected vetted dataset: propose sourcing it properly, don't produce hadith-sounding text from memory.
- If genuinely uncertain whether a narration is authentic (memory of a widely-circulated quote, no clear source), say so plainly rather than presenting it with false confidence — this is exactly the escalate-over-invent principle from `00_system_prompt.md`.

## Examples
- ✅ "Narrated by Abu Hurayrah, Sahih al-Bukhari [number] — graded Sahih." (pulled from vetted dataset)
- ❌ "There's a hadith that says..." with no collection, number, or grading, recalled from general impression.

## References
See `18_references.md` for vetted hadith databases with published grading (e.g., sunnah.com-linked datasets).

## Future Extensions
- A "grading source transparency" UI pattern if Talia ever surfaces hadith where scholars have historically disagreed on grading.
