# UI Contract: QCF Rendering Proof of Concept

## Route

`/debug/qcf-rendering-poc`

The route is temporary and intended for developer/QA access only. It must not appear as a normal Hifz or Memorization Plus navigation option.

## Screen Contract

The screen must present a localized title and one section per required rendering case:

| Section | Required Content | Pass Condition |
|---|---|---|
| Single verse | Al-Baqarah 255 rendered visually | Verse is visible and labelled |
| Multiple verses | Al-Fatiha 1-7 rendered visually when supported | Group appears or limitation note is shown |
| Multiple verses | Al-Ikhlas 1-4 rendered visually when supported | Group appears or limitation note is shown |
| Last verse | Ash-Sharh 8 rendered visually | Verse is visible and labelled as the final verse |
| Full page | Full mushaf page attempt | Page appears or limitation note is shown |
| Findings | Support/limitation summary | Every unsupported/limited mode is visible |

## Interaction Contract

- Back navigation returns to the previous screen.
- No action on the POC screen writes memorization progress, locks, unlocks, checkpoints, or selected plans.
- Any local toggles or page controllers are ephemeral and reset when the screen is disposed.

## Accessibility and Localisation Contract

- All visible labels and limitation messages are localized through the app localisation system.
- Quran text remains RTL and uses the QCF rendering behavior.
- Buttons or controls meet the project touch target minimum.
- Limitation messages are readable in light and dark themes.

## Revert Contract

The POC can be reverted by removing:

- The temporary route entry and route constant.
- `qcf_rendering_poc_page.dart`.
- POC-specific localisation keys.
- POC-specific tests.
