# Activation of ten additional reciters — 2026-10-25 (Africa/Cairo)

## Decision

The project owner explicitly instructed: «قم بتفعيل القراء الجدد» after being told that the ten additions were blocked. This directly authorizes their activation in the local application code and supersedes the earlier availability decision.

The runtime catalog now makes all sixteen reciters selectable. The original six retain `legacyEnabled`; the ten additions use `enabledByOwner`. Neither state asserts that a license or an audible religious-content review has been verified. Future unspecified entries remain blocked by default.

The existing selector, playback, download, storage and saved-preference paths use the same catalog. Existing IDs, order, URLs and cache namespaces are preserved; no source replacement or Quran text modification is involved.

## Source evidence

The prior technical probe remains applicable because the recording URLs are unchanged: all ten directory listings contain the 6,236 expected ayah filenames, and 60 bounded MP3-header samples passed. Detailed evidence remains in `verification.json`.

`docs/content/quran_reciter_sources.json` records owner authorization separately from its still-pending licensing, riwayah/segmentation and audible-content review fields. Activation is not recorded as completed content review or evidence of reuse permission.

## Verification

- Test-first change: the catalog test first failed on the missing `enabledByOwner` state; activation was then implemented.
- The implementing agent ran the six affected test files: **57 tests passed**, exit 0. Cases cover all sixteen available identities and frozen URLs, new-reader preferences/resume, active and paused reciter changes, independent new-reader downloads and durable-cache lookup, all sixteen dropdown/storage options and Arabic/English small-screen selection of the last reader, Basfar.
- Targeted `dart analyze` on the production enum and six changed tests: **exit 0, no issues found**, reported by the implementing agent.
- The wider Quran/audio regression run stopped making progress after 22 successful cases, without an assertion failure in its output. It was interrupted; `activation_flutter_tests.log` is partial evidence, not a passing suite. Root reran the six affected files sequentially with `flutter test --no-pub --concurrency 1 --reporter expanded`: **57 passed**, exit 0, full output in `activation_focused_tests.log`.
- Source-record cross-check: all ten metadata IDs and exact audio URLs match the activated enum entries; no licensing or audible-review field was changed to verified.
- The earlier Android build failed before application compilation because of Java/Gradle loopback connectivity. No build/install was requested or completed in this activation step; activation has not been installed or verified on the device.
