# 13 — Islamic UX Principles

## Purpose
Define UX principles specific to building respectful, appropriate interfaces around sacred text and devotional practice, for any agent designing or reviewing Talia screens.

## Overview
Standard mobile UX conventions (auto-playing media, dense notification badges, aggressive ad placement, casual error copy) can clash with the reverence expected around Quran text and worship. This module defines where Talia should deliberately diverge from generic app patterns.

## Core Concepts
- **Reverence for the Mushaf:** Quran text should never be visually obscured, cropped mid-word by ads/banners, or animated in ways that trivialize it (no bouncing/spinning transitions on verse text).
- **RTL-first, not RTL-retrofitted:** Arabic is Talia's primary reading direction; English/LTR UI is the secondary accommodation, not the base layout that Arabic gets mirrored into.
- **Silence as a valid state:** unlike most apps, moments of quiet (during recitation, during a memorization recall attempt) are the point, not a loading state to fill with motion or sound.

## Detailed Explanation
| Area | Principle | Rationale |
|---|---|---|
| Fonts | Use a proper Uthmani/Mushaf font family for Quran text (never a generic Arabic UI font for verse display) | Mushaf fonts preserve correct letterforms/diacritics essential to accurate reading, not just aesthetics |
| RTL | Full RTL layout mirroring for Arabic locale, not just text direction flip | Partial RTL (mirrored text, LTR icons/nav) reads as broken to native users |
| Dark mode | Support it, but keep Quran text contrast high and avoid pure-black backgrounds behind Uthmani script (mid-tone dark backgrounds preserve diacritic legibility better) | Diacritics (tashkeel) are easy to lose at low contrast |
| Animations | Reserve motion for non-sacred UI elements (buttons, character reactions); keep Quran text itself close to static during display/recitation | Motion on the verse itself can feel disrespectful and is also a legibility risk |
| Audio | Never auto-play unrelated sound (notification chimes, character sound effects) over active Quran audio playback | Basic reverence + prevents jarring audio conflicts |
| Notifications | Time-aware (e.g., not during typical prayer windows unless it's a prayer-time notification itself), and tastefully worded — companion-character voice, not generic push-marketing tone | Matches the "companion" positioning already defined for Talia |
| Gamification limits | Streaks/badges/leveling are support mechanisms, not the primary framing (see `12_islamic_education.md`) — avoid casino-style variable-reward patterns (randomized loot-box-style rewards) entirely | Those patterns are manipulative regardless of context, and especially inappropriate paired with worship |
| Ads | If Talia ever considers ads, they must never appear adjacent to or overlapping Quran text, audio, or active memorization sessions | Baseline reverence requirement, independent of general ad-UX best practice |
| Content hierarchy | Quran text > user's own memorization/review state > companion character > secondary chrome (settings, promos) | Keeps the actual devotional content as the visual/informational priority |
| Error handling | Calm, humble tone ("something went wrong, let's try again") rather than blame-toned or overly casual/jokey copy | Matches the overall register appropriate to a worship-adjacent app |
| Offline mode | Core reading/memorization/review must work fully offline (already Talia's architecture) — treat any online-only devotional feature as a design smell, not just a technical gap | Users often engage with Quran in settings without reliable connectivity (mosque, travel, prayer times) |
| Accessibility | Arabic diacritic legibility, adjustable font size for Quran text specifically (independent from general UI font scaling), and screen-reader support for Arabic content | Standard accessibility needs are compounded by the precision-legibility requirements of Mushaf script |

## Important Classifications
See the table above — this module's core content is inherently tabular/classificatory rather than needing a separate list here.

## Practical Rules
- Never place Quran text inside a component that can be partially obscured (tooltips, banner overlays, autoplay video backgrounds).
- Companion character animations (per Talia's character spec) should never overlap or distract during an active recall/recitation moment — the character's "watching quietly" state exists for exactly this reason.
- Kids Mode gamification should stay reward-generous but never randomized/variable-ratio in the addictive-mechanics sense — predictable, earned rewards only.

## Common Mistakes
- Applying a generic "delightful micro-interactions everywhere" design philosophy uniformly, without carving out the Quran-text and active-recall zones as motion-quiet exceptions.
- Treating dark mode as a simple color inversion without re-checking Uthmani script contrast specifically.
- Notification copy that's generically "engagement-y" ("You're on fire! 🔥 Come back now!") rather than matching Talia's calmer companion voice.

## UX Implications
This entire module *is* the UX implications layer for the rest of the KB — cross-reference it whenever another module says "see UX Implications."

## Engineering Implications
- Build a distinct `QuranTextDisplay` component with its own font/contrast/motion rules enforced at the component level, so individual screens can't accidentally violate reverence principles by using a generic text component for verse display.
- Notification scheduling logic should be prayer-time-aware if prayer times are ever integrated, to avoid poorly-timed pushes.

## Product Implications
These principles are a differentiator against more generic Quran apps that treat verse text like any other app content — but they only work as a differentiator if consistently enforced across every screen, not just the main reading view.

## AI Design Guidelines
- When designing or reviewing any screen that includes Quran text, explicitly check it against this module's table before finalizing.
- Push back (in review) on any proposed feature that would animate, obscure, or casually-tone the presentation of Quran text, even if it "matches" a generic mobile design trend.

## Examples
- ✅ A subtle, static Mushaf-style card for the verse of the day, character reaction happening in a separate area of the screen.
- ❌ A verse-of-the-day card that slides/bounces in with a confetti animation identical to a badge-unlock animation.

## References
Synthesizes general accessibility/UX best practice with Islamic-app-specific reverence conventions already reflected in Talia's existing design decisions (character companion restraint, offline-first architecture).

## Future Extensions
- A formal "Quran Text Display" component spec/checklist, once/if a design system doc is created for Talia.
