# Talia Quran - Home Page UI/UX Overhaul

## 1. Overview & Goals
**Vision**: Upgrade the Talia Quran home page to a "Modern Islamic Luxury" (الفخامة الإسلامية العصرية) aesthetic. 
**Objective**: Create a context-driven, spiritually minimalist dashboard that focuses the user on their primary Quranic habits while eliminating redundant navigation elements (Action Tiles, Quick Access) that already exist in the App's Bottom Navigation Bar.

## 2. Core Principles
* **Context over Clutter**: Only show what the user needs right now.
* **Editorial Typography**: Break the "everything in a box" AI pattern. Use free-floating, beautifully typeset text for inspiration.
* **Tactile Interactions**: Elements should feel physical (e.g., subtle scale down on press) rather than flat static buttons.
* **Consistent Lighting & Surfaces**: Deep night backgrounds (mosque silhouette) with subtle frosted glass (Glassmorphism) and single-color accents (Emerald/Gold).
* **Accessibility First**: All text over imagery meets WCAG AA contrast (4.5:1). All animations respect `AccessibilityFeatures.disableAnimations`. All layouts work correctly in both RTL and LTR.

## 3. Component Architecture & UI Specification

### 3.1. Header & Prayer Timeline (`HomeNightHeader`)
* **Top Bar**: Symmetrical layout. "Talia" logo centered. Thin-stroke Notification icon (Left), Profile/Settings icon (Right).
* **Consolidated Badge**: Replace scattered Occasion/Level/Streak chips with a single, elegant glass pill beneath the logo (e.g., "🌙 يوم الجمعة • المستوى الرابع"). Uses `AppTypography.labelMedium` (w600).
* **Prayer Timeline**:
  * Keep all 5 prayers + Sunrise visible horizontally.
  * Encapsulate in a unified `Frosted Glass` panel.
  * **Highlight**: The *Next/Active* prayer uses a larger font weight, an accent color (Gold/Emerald), and the **existing breathing pulse animation** (1600ms repeating `AnimationController` — already implemented in `HomePrayerTimeline`). Preserve and refine this animation.
  * **Mute**: Past and future prayers use 70% opacity (verified to meet WCAG AA contrast ratio ≥ 4.5:1 against the hero banner scrim) to reduce visual noise while maintaining context.
  * Include the Hijri date seamlessly within this panel.
* **Parallax Depth**: The mosque background image scrolls at 0.3× the scroll speed of the content (parallax ratio 0.3), adding a sense of physical depth to the header as the user scrolls down.

### 3.2. Primary Actions
* **Hero Card (`HomeContinueCard` / `HomeStartKhatmahCard`)**:
  * **Visuals**: Deep emerald/night-blue base, soft mesh gradient, and faint Islamic geometric texture on the edges.
  * **Typography**: Surah name in `Amiri` font, 28-32px, `FontWeight.w700`, color `skin.textOnHero`. Ayah/Juz number in `AppTypography.bodySmall`, color `skin.gold`.
  * **Interaction**: Entire card is a tactile touch target (Spring physics: damping 0.7, stiffness 200, `scale(0.98)` on press). No nested buttons inside.
* **Dynamic Contextual Slot (`HomeContextualSlot`)**:
  * **Visibility**: Invisible by default. Mounts *only* based on time/event (e.g., Morning Azkar, Friday Kahf).
  * **Visuals**: Outlined or soft-blurred glass card, clearly secondary to the Hero Card to avoid stealing attention.
  * **Entry/Exit**: Appears with `AnimatedSwitcher` (300ms `FadeTransition` + `SlideTransition` from bottom) — never pops in abruptly.

### 3.3. Habits, Inspiration & Activity
* **Unified Progress Panel (`HomeDailyChallengeCard` + `HomeJourneyRingCard` + `HomeMomentumStrip`)**:
  * Merge the side-by-side generic cards into a single asymmetrical Bento-grid glass panel containing:
    * The **Streak flame** with current count and weekly activity dots (from `HomeMomentumStrip`).
    * The **Journey Ring** (memorization/khatmah circular progress) with an **ambient breathing pulse** (extending the existing `HomePrayerTimeline` animation pattern to the ring indicator).
    * Total **XP** and current **achievement level**.
  * This consolidation eliminates three separate widgets into one cohesive view.
* **Editorial Ayah of the Day (`HomeAyahOfDayCard`)**:
  * Remove the card background entirely.
  * Render as floating, large Arabic typography using `AppTypography.quranMedium` at 22-24px, `height: 2.0`, with elegant quotation marks surrounded by generous whitespace.
  * Small, ghost-style icons (Listen, Share) beneath the text.
* **Activity Feed (`HomeActivityFeed`)**:
  * Minimal, borderless list of recent sessions fading out to transparent at the bottom.
  * Cap off the page with the signature tagline "رتل وارتقِ".

### 3.4. Deprecations (Redundancy Removal)
* **Removed**: `HomeActionTiles` (Quick access to Mushaf, Azkar, etc.).
* **Removed**: `HomeQuickAccess` (Bottom shortcuts to Surahs/Index).
* *Reasoning*: These destinations belong in the Bottom Navigation Bar. Removing them from the Home Page enforces focus on the user's primary daily habit (The Hero Action).

### 3.5. Motion & Animation (الحيوية والتفاعل)

#### Preserved Animations (موجودة بالفعل في الكود)
* **Prayer Breathing Pulse** (`HomePrayerTimeline`): `AnimationController` 1600ms repeating in reverse on the next prayer node. Produces a glowing halo (`glowAlpha = 0.3 + 0.4 * value`). Already respects `MediaQuery.disableAnimationsOf`. **Keep and refine.**
* **Hero Card AnimatedContainer** (`UnifiedHeroActionCard`): 200ms duration for padding/color/shadow transitions on theme change. **Keep.**

#### New Animations
* **Staggered Entry (دخول متدرج)**: Widgets cascade in with a soft vertical translation (fade + slide up, 20px offset) upon loading. Duration: 400-600ms per widget. Delay between widgets: 80-120ms. Uses `CurvedAnimation` with `Curves.easeOutCubic`.
* **Spring Physics (فيزياء مرنة)**: All interactive surfaces use smooth spring-based touch feedback. Spring constants: `damping: 0.7`, `stiffness: 200`. Applies to Hero Card, Bento panels, and Ayah of the Day tap area.
* **Ambient Breathing (توهج حيوي)**: Extend the existing Prayer Timeline pulse pattern to the Journey Ring progress indicator — gentle continuous pulse on the ring's accent stroke.
* **State Transitions (انتقالات الحالات)**: `AnimatedSwitcher` (300ms, `FadeTransition` + `SlideTransition`) wraps the primary action area, so switching between Hero Card ↔ Contextual Slot ↔ First Run is smooth, never abrupt.
* **Scroll Physics (فيزياء السحب)**: Replace `AlwaysScrollableScrollPhysics` with `BouncingScrollPhysics` for an elastic, natural pull feel consistent with the spring physics philosophy.

#### Accessibility Gate
* All animations check `MediaQuery.disableAnimationsOf(context)` before running.
* All repeating animations (`breathing`, `pulse`) use `AnimationController.dispose()` correctly.
* Staggered entry fires once on load, not on every rebuild.

### 3.6. Edge Cases & Fallbacks

#### First-Run Experience (`HomeFirstRun`)
* Redesign the current 3-stacked-buttons onboarding into a **single luxurious welcome card** matching the Hero Card aesthetic (emerald gradient, mesh texture).
* Content: Amiri-font welcome title, brief description, and a single prominent CTA "ابدأ رحلتك" that opens a path-selection flow.
* The entire first-run card receives the same staggered entry animation as the regular Hero Card.

#### Parent/Family View (`HomeParentChildren`)
* **Retained** in the new design. Positioned **after the Hero Card** and **before the Unified Progress Panel** — for a parent/teacher, their children's progress is the second-highest priority after their own daily wird.
* Visual upgrade: Each child row gets a small circular progress ring (daily completion %) instead of a simple check/clock icon.

#### Momentum Strip (`HomeMomentumStrip`)
* **Absorbed** into the Unified Progress Panel (§3.3). Its data (streak days, XP, weekly dots, achievement level, streak freezes) is rendered inside the new Bento panel. The standalone `HomeMomentumStrip` widget is deprecated from the home page layout.

#### Fallback Cards (`ResumeSessionCard`, `NextBestActionCard`)
* When the Unified Journey system is disabled, these fallback cards adopt the **same Hero Card visual treatment** (emerald gradient, mesh texture, Amiri typography, spring physics tap feedback) to maintain visual consistency regardless of feature-flag state.

## 4. Technical Constraints
* **Stack**: Flutter / Dart.
* **Styling**: Update existing `HomeSkin` with the following new tokens:

| Token | Purpose |
|-------|---------|
| `meshGradient` | Mesh gradient for the Hero Card background |
| `editorialBackground` | Transparent/subtle background for the Editorial Ayah section |
| `consolidatedBadgeFill` | Glass fill for the consolidated status badge |
| `consolidatedBadgeBorder` | Border for the consolidated status badge |
| `heroCardTexture` | Color/opacity for the faint Islamic geometric pattern overlay |
| `springCurve` | Unified spring animation curve reference |

* **Widget Modifications**: Modify existing widgets (`_TopRow`, `HomePrayerTimeline`, `HomeContinueCard`, `HomeAyahOfDayCard`, `HomeDailyChallengeCard`) to adopt new UI. Avoid creating parallel component trees.
* **State**: No changes to `HomeCubit` or `HomeState` logic are required. This is purely a presentation-layer (UI/UX) overhaul.
* **RTL/LTR**: All layouts use directional-aware widgets (`PositionedDirectional`, `EdgeInsetsDirectional`, `TextDirection.rtl` aware alignment). Verified in both Arabic and English.
