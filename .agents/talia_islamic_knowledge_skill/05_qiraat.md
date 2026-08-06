# 05 — Qira'at (Canonical Readings)

## Purpose
Give agents a correct framework for the canonical Quranic reading traditions, so any feature touching "which reading/reciter/text version" is handled with the right vocabulary and doesn't silently assume Hafs is the only legitimate reading.

## Overview
Qira'at (قراءات) are the canonical, scholar-verified traditions of reciting the Quran, each traced through a continuous chain of transmission back to the Prophet ﷺ. They are not "variants" or "errors" in a software-bug sense — they are independently authenticated, textually legitimate traditions, some more geographically prevalent than others.

## Core Concepts
- **Qari' (قارئ) / Imam of Qira'ah:** the scholar a reading tradition is named after (e.g., Imam Nafi', Imam 'Asim).
- **Rawi (راوي) / Narrator:** a transmitter of a specific qari's reading (e.g., Hafs and Shu'bah both narrate from 'Asim, producing "Hafs 'an 'Asim" and "Shu'bah 'an 'Asim" as distinct riwayat).
- **The Seven (Qira'at Sab'ah):** the seven readings most widely accepted as mutawatir (mass-transmitted): Nafi', Ibn Kathir, Abu 'Amr, Ibn 'Amir, 'Asim, Hamzah, Al-Kisa'i.
- **The Ten (Qira'at 'Ashrah):** the above seven plus three more: Abu Ja'far, Ya'qub, Khalaf al-'Ashir.
- **Hafs 'an 'Asim:** the riwayah used in the vast majority of printed/digital Mushafs worldwide today, including what Talia currently uses — this is a practical/distributional fact, not a claim that other riwayat are lesser.
- **Warsh 'an Nafi':** the riwayah most common in North and West Africa — relevant if Talia ever targets that audience.

## Detailed Explanation
Differences between qira'at are generally minor (a word's vowelling, occasionally a word choice) and do not change core meaning or ruling in ways that create contradiction — classical scholarship treats this multiplicity as a mercy/ease in transmission, not a problem to resolve. This is a distinct (though related) phenomenon from the "Seven Ahruf" discussed in `02_ulum_al_quran.md`; scholars differ on the exact relationship between the two, and that technical debate is out of scope for this KB — flag it to a qualified source if a feature ever needs to take a position on it.

## Important Classifications
| Tradition | Status | Practical relevance to Talia |
|---|---|---|
| Hafs 'an 'Asim | Most widely printed/used globally | Current default, matches `qcf_quran_plus` rendering |
| Warsh 'an Nafi' | Widely used in North/West Africa | Future audience-expansion candidate |
| Qalun 'an Nafi', Al-Duri 'an Abi 'Amr, etc. | Regionally used elsewhere | Lower near-term priority |
| Other of the Ten | Scholarly/academic use, rarer in general print | Not a near-term product priority |

## Practical Rules
- Never present qira'at differences as "the Quran has typos" or "variant readings" in a loose, casual sense that implies error — use "canonical reading traditions."
- If Talia ever adds a second riwayah, it needs its own complete, independently-sourced Mushaf dataset (text, ayah numbering, page layout) — not a diff/patch applied to the Hafs dataset, since numbering and page breaks can differ.
- Audio recitation sourcing (`mp3quran.net` and similar) should be filtered/labeled by riwayah so a Hafs-reading user isn't accidentally served Warsh audio or vice versa.

## Common Mistakes
- Assuming all Quran text/audio datasets use the same riwayah by default — mixing sources without checking causes silent text/audio mismatches.
- Explaining qira'at differences to users in a way that sounds like doctrinal dispute rather than a well-established, scholarly-verified transmission phenomenon.

## UX Implications
- If/when multiple riwayat are supported, the reading-mode UI needs an explicit, sticky riwayah selector — never silently mix riwayat text within one reading session.
- Onboarding copy about riwayah choice should be neutral and informative, not imply one is more "correct."

## Engineering Implications
- Data model implication: `riwayahId` should be a first-class field on Mushaf text, audio, and tajweed datasets — not bolted on later.
- Reciter metadata (from `mp3quran.net` or equivalent) must be cross-referenced against its riwayah before being paired with a given text dataset.

## Product Implications
Supporting Warsh (or another widely-used riwayah) is a genuine market-expansion feature for Francophone/West African users, but it is a substantial data-sourcing and QA effort, not a UI toggle — scope it as such if it ever reaches the roadmap.

## AI Design Guidelines
- Default all generated examples, test data, and copy to Hafs 'an 'Asim unless a task explicitly concerns another riwayah.
- Never fabricate a "qira'at difference" example for a specific verse without sourcing it from a real qira'at reference work.

## Examples
- ✅ "Talia currently supports Hafs 'an 'Asim only; Warsh support would require a separate sourced dataset."
- ❌ Describing a specific word-level qira'at difference from memory without a citable source.

## References
Classical enumeration of the Seven/Ten readers is standard across Qira'at scholarship (e.g., al-Shatibiyyah for the Seven, al-Durrah for the completing three); see `18_references.md` for actual riwayah-specific datasets.

## Future Extensions
- A `riwayah_support_roadmap.md` if/when a second riwayah is greenlit for development.
