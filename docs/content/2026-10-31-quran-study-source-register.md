# Quran study source register — 2026-10-31

**Update 2026-11-03:** The owner authorized display of both works. Bundles and their manifest are now under `assets/data/quran_study/`; see [the review packet](2026-11-03-study-review-packet.md) and `docs/release/rollout-evidence.md` for the decision, source conditions, and validation limits. Historical blocked statements below describe the earlier review state.

Both datasets: **BLOCKED from product integration**. Selection is provisional, not editorial approval. Exact upstream archives are now stored as isolated, ignored review copies; no religious content or source asset was added to the application. See the [2026-11-03 review packet](2026-11-03-study-review-packet.md).

## Tafsir candidate

- Source: King Fahd Complex, Tafsir Muyassar; [developer page](https://qurancomplex.gov.sa/quran-dev/), accessed 2026-10-31. The previously recorded English developer URL returns 404. The current page describes application use and provides a file fingerprint (MD5 `b38703983d438a5cd22269b746eaac0c`, SHA-1 `a8f054411c6cd14a258d5ba7bc4e30c9ea79b336`).
- Rechecked 2026-11-03: item version **3.0**, last modified **2023-08-01**. The [official archive](https://download.qurancomplex.gov.sa/resources_dev/hafs_tafseerMouaser_v3.zip) is 7,885,418 bytes; published MD5 and SHA-1 both matched. Raw archive SHA-256: `443a6927dbbf9df0fb63792dc83b83511f7d308f3ec322c9230fbebfe3c69c86`. The page describes use by app developers, researchers and publishers. Exact redistribution/update/attribution scope still requires confirmation; the local copy is review material, not an imported application bundle.
- The documented `aya_tafseer` field distinguishes embedded Quran quotations through `aya` markup and separate fonts. A plain-text conversion must not silently discard that distinction; source-format inspection and presentation approval are required.
- Footnote format and coverage: unknown. Human reviewer, date, decision and review evidence: missing. Status: **blocked**.

## English meaning translation candidate

- [QuranEnc API documentation](https://quranenc.com/en/home/api/) describes translation downloads, redistribution and conditions including attribution and updates. Its `english_saheeh` identifier is a documentation example, not an approved selection.
- Provisional technical candidate, rechecked 2026-11-02: **English Translation — Rowwad Translation Center**, key `english_rwwad`, version **1.0.20**, catalog `last_update=1792534351`. [Official catalog](https://quranenc.com/api/v1/translations/list/en/?localization=en); [catalog-provided SQLite archive](https://quranenc.com/downloads/sqlite/english_rwwad.zip). The archive URL is mutable; the version does not establish an immutable dataset checksum.
- API terms permit republication under conditions: unchanged content, publisher/QuranEnc attribution, version and transcript information, forwarding translation notes, current versions and appropriate advertising. Preserve footnotes separately. Exact selected-work rights evidence, full coverage and source bytes still need review.
- Metadata caution: the current `english_saheeh` entry is titled **English Translation — Noor International Center**, version **1.1.2**. Do not label a dataset from its key alone.
- The initial metadata response is ignored `.tmp/content-review/english-translations-list.json`; SHA-256 `60eaa12ab95bd03aaab251e2223e86e6d42fb4a8f77fd26412a98a9fc54c0180`. A refreshed catalog and the official 527,324-byte archive were retrieved for the review packet. Raw translation archive SHA-256: `6a735b83104ec204f36fd4f1b10a29bb8f8679859324045e075bf96741544c5b`. Neither hash approves a converted application bundle. Human reviewer, approval date and evidence remain missing. Status: **blocked**.

Before release, record the exact work and immutable version, source item URL, retrieval date, license evidence and scope (local storage, redistribution and commercial use), attribution, modification and update obligations, coverage, footnote encoding, SHA-256, reviewer identity/role, date, and documented approval. Validate the source text verbatim and compare presentation with the approved original. Automated checks do not substitute for these decisions.
