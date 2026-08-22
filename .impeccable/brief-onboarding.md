# Onboarding — Surface Brief

**Scope:** lib/features/onboarding — first-run flow (welcome horizon + experience fork), portrait mobile, Arabic-first with English localization.
**Visitor mode:** Persuade folding into Operate — earn trust in one viewport, then complete a single choice.

**Audience:** First-open Quran learners (adults and teens) and parents handing the device to a child.
**Job:** Convince in seconds that Talia is a calm, serious memorization companion, then route each user to their experience in under 20 seconds.
**Action:** One choice (adult vs child path) plus one entry (guest primary, sign-in secondary).
**Proof:** The product's own visual world — a real mushaf-style ayah card for adults, the kids night journey with the Talia mascot — shown as living destination previews, never as feature bullet lists.
**Constraints:** Cubit logic, routing destinations, and SharedPreferences keys stay byte-identical (10 existing behavior tests). No auth wall. Skip always available. No language step (Arabic default; switch lives in Settings). Mascot appears in the child path only. Offline/local-data trust line under the guest CTA. Quranic text never compressed for decoration.

**Chosen direction:** «الرحلة الليلية المتفرّعة» — The Night Journey Fork, assigned by concept-seed (scope surface, mode persuade, seed key 6051da8b, candidate 3 of 7). A deep-teal night prologue committed across both app themes (memorization's real hour is dawn/night): step 1 is the horizon (golden mihrab art, basmala, one promise, one CTA); a cinematic ascent up a path of light; step 2 is the fork where the journey splits into two living destination previews and the chosen path lights up.
**Memorable moment:** the ascent — rising from the horizon up the path of light into the forked journey.

**Finish record (2026-08-22):**
- Built and reviewed (finish review verdict: contract kept end-to-end; contrast fixes applied). 19 tests green; detector clean; full-project analyze clean.
- Surface-specific tokens introduced: `_nightTealText #3BD6AC-family` (lifted teal for small text on night) and `_nightErrorText #E57368` — `#148275`/`#C0392B` lack 4.5:1 headroom as small-text colors on `#021210`. On-gold check icons use night ink, not white.
- CTA radius intentionally uses radiusLg (16), matching the incumbent onboarding precedent (DESIGN.md's 12px button default applies to the app shell's controls).
- Error handling: fallible routing runs before any prefs writes (retry-safe first-run), and the banner shows localized recovery copy, never raw exception strings.
**Unresolved:** none.
