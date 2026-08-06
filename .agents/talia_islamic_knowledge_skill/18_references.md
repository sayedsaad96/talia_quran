# 18 — References & Sourcing Strategy

## Purpose
The single place every other module points to when it says "source this from a vetted dataset" — defines source-type tiers and the kind of provider each content type needs. This module deliberately does not hardcode specific dataset URLs/versions here, since those should be verified and pinned at integration time (API availability, licensing terms, and dataset versions change) — treat the categories below as a sourcing checklist to verify, not a final vendor list.

## Overview
This KB repeatedly says "don't generate this, source it." This module explains what "source it" concretely means for each content type, and how to distinguish a primary source from a secondary one.

## Core Concepts — Source Tiers
- **Primary sources:** the Quran text itself (a canonical Mushaf dataset), and hadith collections in their original compiled form (Bukhari, Muslim, the six books) with published isnad-based grading.
- **Secondary sources:** tafsir works (human interpretation of the primary text), fiqh works (human derivation of rulings), and curated devotional compilations (e.g., adhkar/dua collections that gather primary-source material by theme).
- **Scholarly opinions:** individually attributed positions (a specific scholar's fatwa, a specific madhab's ruling) — always tagged with who holds the position, never presented as "the Islamic view."
- **Educational methodologies:** modern pedagogical/learning-science material (spaced repetition research, educational psychology) — not religious sources at all, but load-bearing for `06`, `07`, and `12`.

## Detailed Explanation — What Each Content Type Needs
| Content type | Needs | Where this KB uses it |
|---|---|---|
| Quran text (Uthmani + simple script, per-ayah, per-riwayah) | A licensed/public-domain, versioned Mushaf dataset with correct ayah/juz/hizb/page metadata | `01`, `04`, `05` |
| Hadith text + isnad grading | A structured hadith database with collection/book/number/grade fields, ideally with grading-scholar attribution | `10`, feeding `08`/`09` |
| Tafsir text | A licensed tafsir dataset, attributed per work/author, ideally with per-verse indexing | `03` |
| Adhkar collections | A structured adhkar dataset (commonly sourced from compilations like Hisnul Muslim), with citations intact | `08` |
| Dua collections | Structured, tiered (Quranic/prophetic/guidance) dataset, citations intact | `09` |
| Tajweed rule annotations | A tajweed-tagged version of the Mushaf text (rule-per-letter/word span) | `04` |
| Reciter audio | A reciter/audio API indexed by riwayah, with per-ayah or per-surah file addressing | `05`, engineering skill `quran-islamic-apps` |
| Qira'at reference data | A dataset or reference work enumerating actual per-verse qira'at differences (only needed if/when a second riwayah is added) | `05` |
| Learning-science sources | Standard educational psychology / spaced-repetition literature — citable but non-religious | `06`, `07`, `12` |

## Important Classifications
See the tiers above (Primary / Secondary / Scholarly opinion / Educational methodology) — every citation used anywhere in Talia's content should be traceable to one of these tiers, with the tier itself visible in the source-type tagging defined in `14_content_validation.md`.

## Practical Rules
- Before integrating any dataset, verify: (a) licensing terms permit the intended use (including offline bundling, given Talia's offline-first architecture), (b) the dataset publishes its own sourcing/grading methodology rather than being an unattributed aggregation, (c) versioning so updates can be tracked and re-reviewed.
- Prefer datasets that preserve original attribution/grading fields end-to-end rather than ones that flatten everything into plain text.
- When multiple candidate datasets exist for the same content type, a brief comparison (coverage, licensing, update frequency, attribution completeness) is worth doing once and recording, rather than re-deciding each time a new feature needs the same content type.

## Common Mistakes
- Scraping content from a website without checking whether it preserves grading/attribution, or whether its own sourcing is reliable.
- Treating "it's on a big well-known Islamic site" as equivalent to "it's a primary source" — many sites are themselves secondary aggregators of varying quality.
- Bundling a dataset without checking its license permits offline redistribution inside a commercial app.

## UX Implications
Whatever is sourced should carry through to the citation UI defined in `13_islamic_ux.md` — a dataset chosen specifically because it preserves attribution is wasted if the UI then drops that attribution before display.

## Engineering Implications
- Treat dataset integration as its own reviewable task per content type (see `15_feature_design_guidelines.md`), not a side effect of building the feature that consumes it.
- Version-pin religious content datasets the same way dependencies are pinned — an unreviewed silent dataset update could introduce sourcing regressions.

## Product Implications
The one-time cost of properly sourcing each content type is small compared to the ongoing trust cost of getting caught with unsourced or incorrectly sourced religious content — treat sourcing tasks as first-class roadmap items, not background chores.

## AI Design Guidelines
- Whenever a task in this KB says "see `18_references.md` for sourcing," the correct next step is a sourcing/integration task (evaluate candidate datasets against the criteria above), not filling the gap with generated text in the meantime.
- If no suitable dataset exists yet for a content type, say so plainly rather than treating an AI-generated placeholder as a stopgap that "will be replaced later" — placeholders in religious content have a way of shipping.

## Examples
- ✅ "We need a licensed adhkar dataset before building the Morning Adhkar screen — here's what to evaluate it against."
- ❌ Shipping the Morning Adhkar screen with AI-drafted text and a comment `// TODO: verify against real source`.

## Candidate Sources (researched Aug 2026 — verify licensing/terms before integrating)
Sayed asked for concrete candidates. These were identified via web research and should each be re-verified (current terms, rate limits, coverage) at integration time — this list is a starting point for evaluation, not a final decision.

**Quran text, tafsir, audio, verse metadata (juz/hizb/page) — Primary tier**
- **Quran Foundation / Quran.com Content API v4** (`api-docs.quran.foundation`) — the official, actively maintained API behind quran.com: Uthmani/IndoPak/tajweed-colored script, translations, multiple tafsir sources, audio per reciter, full verse metadata (juz/hizb/rub'/page). Strongest overall candidate — covers most of `01`, `03`, and `04`'s data needs in one place. Requires app credentials (backend calls, not embedded client-side).
- **Al Quran Cloud API** (`alquran.cloud/api`) — alternative/backup: editions, surah/juz/ayah, search, audio, image CDN, 50+ translations.

**Hadith text + authenticity grading — Primary tier**
- **sunnah.com official API** (`sunnah.com/developers`, repo `sunnah-com/api`) — the most recognized English-language hadith reference platform; API key requested via a GitHub issue on their repo. Covers the six books plus other major collections, with English + Arabic text. Note: sunnah.com states their API currently exposes only a portion of their data as they complete manual verification — check current coverage for the specific books Talia needs.
- **Dorar Alsaniyah / الموسوعة الحديثية (dorar.net)** — a Saudi-based, widely trusted Arabic hadith encyclopedia (backed by a standing panel of scholars) that grades hundreds of thousands of hadith and explicitly distinguishes sahih/hasan/da'if/mawdu', with alternate-authentic-hadith suggestions when a searched hadith is weak. Strong fit for Talia specifically because it's Arabic-first and carries real credibility with an Egyptian/Arabic-speaking audience. Official JSON endpoint exists (`dorar.net`'s own API notice) plus a documented open-source wrapper (`AhmedElTabarani/dorar-hadith-api`) — verify current official-access terms before depending on either.

**Adhkar + Dua with authenticity grading — Primary tier**
- **Dorar's own Adhkar/Dua platform** (`dorar.net/azkar`, "الجامع الصحيح في الأذكار والأدعية") — purpose-built by the same scholarly body as their hadith encyclopedia, explicitly built to let users "know the authentic from the weak" (سحيح من الضعيف) and set a daily wird. This is the closest match to the exact schema `08_adhkar.md`/`09_dua.md` ask for (grading attached, not just text) — worth prioritizing over generic Hisnul Muslim JSON dumps for that reason.
- **Hisnul Muslim (Fortress of the Muslim) datasets** — several community-maintained JSON/CSV versions exist (e.g., `wafaaelmaandy/Hisn-Muslim-Json`, entries in `khDev01/islamic-data`). Useful as a lightweight, offline-friendly, well-known-structure supplementary source, but these are community compilations, not an official scholarly platform — spot-check entries against Dorar or another primary source before shipping, and don't treat community JSON structure alone as proof of authenticity grading accuracy.

**General index of further options**
- `khDev01/islamic-data` and `AhmedKamal/awesome-Islam` on GitHub are curated lists of further Quran/hadith/adhkar datasets and APIs if the above don't fully cover a need — treat anything sourced from them with the same primary-vs-community-compilation scrutiny as above.

## Future Extensions
- Once specific datasets are actually selected and integrated, record them here (name, version, license, integration date) so this becomes a living sourcing log rather than only a category checklist.
