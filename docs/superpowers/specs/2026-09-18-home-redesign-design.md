# Talia Quran - Home Page UI/UX Overhaul

## 1. Overview & Goals
**Vision**: Upgrade the Talia Quran home page to a "Modern Islamic Luxury" (الفخامة الإسلامية العصرية) aesthetic. 
**Objective**: Create a context-driven, spiritually minimalist dashboard that focuses the user on their primary Quranic habits while eliminating redundant navigation elements (Action Tiles, Quick Access) that already exist in the App's Bottom Navigation Bar.

## 2. Core Principles
* **Context over Clutter**: Only show what the user needs right now.
* **Editorial Typography**: Break the "everything in a box" AI pattern. Use free-floating, beautifully typeset text for inspiration.
* **Tactile Interactions**: Elements should feel physical (e.g., subtle scale down on press) rather than flat static buttons.
* **Consistent Lighting & Surfaces**: Deep night backgrounds (mosque silhouette) with subtle frosted glass (Glassmorphism) and single-color accents (Emerald/Gold).

## 3. Component Architecture & UI Specification

### 3.1. Header & Prayer Timeline (`HomeNightHeader`)
* **Top Bar**: Symmetrical layout. "Talia" logo centered. Thin-stroke Notification icon (Left), Profile/Settings icon (Right).
* **Consolidated Badge**: Replace scattered Occasion/Level/Streak chips with a single, elegant glass pill beneath the logo (e.g., "🌙 يوم الجمعة • المستوى الرابع").
* **Prayer Timeline**:
  * Keep all 5 prayers + Sunrise visible horizontally.
  * Encapsulate in a unified `Frosted Glass` panel.
  * **Highlight**: The *Next/Active* prayer uses a larger font weight, an accent color (Gold/Emerald), and a subtle glow indicator.
  * **Mute**: Past and future prayers use 70% opacity to reduce visual noise while maintaining context.
  * Include the Hijri date seamlessly within this panel.

### 3.2. Primary Actions
* **Hero Card (`HomeContinueCard` / `HomeStartKhatmahCard`)**:
  * **Visuals**: Deep emerald/night-blue base, soft mesh gradient, and faint Islamic geometric texture on the edges.
  * **Typography**: Massive, elegant Arabic font for the Surah name. Gold/Silver secondary text for Ayah/Juz number.
  * **Interaction**: Entire card is a tactile touch target (Spring physics: `scale(0.98)` on press). No nested buttons inside.
* **Dynamic Contextual Slot (`HomeContextualSlot`)**:
  * **Visibility**: Invisible by default. Mounts *only* based on time/event (e.g., Morning Azkar, Friday Kahf).
  * **Visuals**: Outlined or soft-blurred glass card, clearly secondary to the Hero Card to avoid stealing attention.

### 3.3. Habits, Inspiration & Activity
* **Unified Progress Panel (`HomeDailyChallengeCard` + `HomeJourneyRingCard`)**:
  * Merge the side-by-side generic cards into a single asymmetrical Bento-grid glass panel containing the Streak (Flame) and Journey Ring. 
* **Editorial Ayah of the Day (`HomeAyahOfDayCard`)**:
  * Remove the card background entirely.
  * Render as floating, large Arabic typography with elegant quotation marks surrounded by generous whitespace.
  * Small, ghost-style icons (Listen, Share) beneath the text.
* **Activity Feed (`HomeActivityFeed`)**:
  * Minimal, borderless list of recent sessions fading out to transparent at the bottom.
  * Cap off the page with the signature tagline "رتل وارتقِ".

### 3.4. Deprecations (Redundancy Removal)
* **Removed**: `HomeActionTiles` (Quick access to Mushaf, Azkar, etc.).
* **Removed**: `HomeQuickAccess` (Bottom shortcuts to Surahs/Index).
* *Reasoning*: These destinations belong in the Bottom Navigation Bar. Removing them from the Home Page enforces focus on the user's primary daily habit (The Hero Action).

### 3.5. Motion & Animation (الحيوية والتفاعل)
* **Staggered Entry (دخول متدرج)**: Widgets on the home page will cascade in with slight delays and a soft vertical translation (fade + slide up) upon loading, making the page feel organic and avoiding abrupt UI popping.
* **Spring Physics (فيزياء مرنة)**: All interactive surfaces, particularly the Hero Card and Bento grids, will utilize smooth spring-based animations for touch feedback (e.g., smoothly scaling to 0.98 on press) rather than rigid, instant transitions.
* **Ambient Breathing (توهج حيوي)**: Gentle, continuous ambient motion, such as a soft pulse on the "Next Prayer" indicator or the Khatmah progression ring, ensuring the interface feels premium, alive, and responsive to the user.

## 4. Technical Constraints
* **Stack**: Flutter / Dart.
* **Styling**: Update existing `HomeSkin` to support the new glass materials and mesh gradients. Avoid creating parallel component trees where possible; modify existing widgets (`_TopRow`, `HomePrayerTimeline`, `HomeContinueCard`) to adopt the new UI constraints.
* **State**: No changes to `HomeCubit` or `HomeState` logic are required. This is purely a presentation-layer (UI/UX) overhaul.
