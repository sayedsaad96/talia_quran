# B1 candidate study review packet

**Owner decision, 2026-11-03:** The user states that all previously blocked content has been approved and authorizes displaying it. This records the decision as given; it does not identify an individual reviewer, establish the terms of a third-party license, or verify a converted bundle. Technical integration and source-specific reuse conditions still require verification.

**Packet date:** 2026-11-03 (Africa/Cairo)  
**Status:** The owner has authorized display as recorded above. Source terms, conversion and display validation remain to be completed.  
**Scope:** Verify source identity, version, hashes, archive inventory, and documented schema for two candidate datasets. This packet does not publish or reproduce their religious text.

## Handling

Raw archives are retained as ignored local review material under `../../.tmp/content-review/b1-2026-11-03/`; the original archives themselves are not application assets. Both archives are under the 15 MiB per-file limit and had no absolute, traversal, or symlink entries. After the initial inventory, the CSV and SQLite content were read for conversion and fidelity checks; no SQL from the archives was executed. The resulting assets and manifest are in `assets/data/quran_study/`.

## Candidate A: King Fahd Complex Tafseer Muyassar

- **Official source page:** https://qurancomplex.gov.sa/quran-dev/
- **Actual download link discovered in that page HTML:** https://download.qurancomplex.gov.sa/resources_dev/hafs_tafseerMouaser_v3.zip
- **Item/version:** Tafseer Muyassar, update 3.0. The page lists creation date 2020-12-15 and last modification 2023-08-01.
- **Publisher description:** King Fahd Complex says this is a trusted, Complex-approved service for developers, researchers, and publishers to use in application content and research. It contains Hafs Quran data and the corresponding Tafseer Muyassar per ayah.
- **Retrieval:** HTTP 200 from `download.qurancomplex.gov.sa`; 7,885,418 bytes; retrieved 2026-11-02 22:14:49 UTC.
- **Local review file:** `hafs_tafseerMouaser_v3.zip`.
- **SHA-256:** `443A6927DBBF9DF0FB63792DC83B83511F7D308F3EC322C9230FBEBFE3C69C86`.
- **Publisher-published MD5:** `b38703983d438a5cd22269b746eaac0c`; local file matched.
- **Publisher-published SHA-1:** `a8f054411c6cd14a258d5ba7bc4e30c9ea79b336`; local file matched.
- **ZIP inventory:** 12 entries; no unsafe paths. Entries include `read.me` (1,558 bytes), `tafseerMouaser_v03.csv` (4,408,127), `.html` (7,202,603), `.sql` (5,431,012), `.txt` (4,358,351), `.xlsx` (1,797,975), `.xml` (6,216,583), and three font files. Sizes are uncompressed entry sizes. No entry was extracted or opened.
- **Officially documented schema:** `id`, `jozz`, `page`, `sura_no`, `sura_name_en`, `sura_name_ar`, `line_start`, `line_end`, `aya_no`, `aya_text_unicode`, `aya_text_emlaey`, `aya_tafseer`. The source page identifies `aya_text_unicode` as the Hafs Uthmanic text, `aya_text_emlaey` as search text, and `aya_tafseer` as the tafsir text.
- **Rights status:** The official page describes use in app content and research. A separate license text and explicit attribution, update, and commercial-use conditions were not located in this review. Confirm those terms before any product integration.

## Candidate B: QuranEnc English Rwwad

- **Official API documentation:** https://quranenc.com/en/home/api/
- **Refreshed official catalog endpoint:** https://quranenc.com/api/v1/translations/list/en/?localization=en
- **Catalog record:** key `english_rwwad`; title `English Translation - Rowwad Translation Center`; language `en`; version `1.0.20`; `last_update` Unix timestamp `1792534351` = 2026-10-20 22:12:31 UTC (2026-10-21 00:12:31 Africa/Cairo).
- **Archive URL:** https://quranenc.com/downloads/sqlite/english_rwwad.zip
- **Retrieval:** HTTP 200 from `quranenc.com`; 527,324 bytes; retrieved 2026-11-02 22:14:56 UTC.
- **Local review file:** `english_rwwad-1.0.20.zip`.
- **SHA-256:** `6A735B83104EC204F36FD4F1B10A29BB8F8679859324045E075BF96741544C5B`.
- **ZIP inventory:** one entry, `english_rwwad.sqlite`, 1,245,184 uncompressed bytes; no unsafe paths. At the initial inventory the database had not been opened.
- **Subsequent local inspection, 2026-11-03:** the SQLite file was extracted to the ignored review directory and opened locally. Its `translations` table has `id`, `sura`, `aya`, `translation`, and `footnotes`; it contains 6,236 distinct surah/ayah pairs, no empty translations, and 2,215 rows with footnotes. Counts alone do not prove canonical mapping or verbatim conversion.
- **Official API response schema:** catalog objects document `key`, `language_iso_code`, `version`, `last_update`, `title`, and `description`. Sura translation items document `sura`, `aya`, `translation`, and `footnotes`. This is API schema evidence, not confirmation of the downloaded SQLite table schema.
- **Reuse terms on the official API page:** do not modify, add to, or delete content; identify the publisher and QuranEnc.com; include the version and transcript information when republishing; notify QuranEnc of translation notes; update to the latest issued version; and do not include inappropriate advertisements when displaying translations.

## Review status and next decisions

- Neither dataset has been assessed verse by verse in this packet. Hash verification confirms the King Fahd archive matches the official page fingerprints; it does not approve religious accuracy or product use.
- A qualified Quran-content reviewer must examine exact source rows, ayah identifiers, text boundaries, footnotes, and presentation context, and record reviewer role, name, date, evidence, and decision.
- For QuranEnc, preserve the translation exactly with its attribution, version, transcript information, footnotes, and update obligation. Do not normalize the published translation in place.
- Resolve King Fahd reuse details before publishing. Keep both candidates blocked from application integration until the required human review and rights evidence are recorded.
- No content text, application code, or asset was changed as part of this preparation.
