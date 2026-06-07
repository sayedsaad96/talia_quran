# Feature Specification: Kids Gamified Memorization UI (واجهة الحفظ المُلعبة للأطفال)

**Feature Branch**: `005-kids-gamified-ui`

**Created**: 2026-06-01

**Status**: Draft

**Input**: User description: "Implement a new professional gamified UI for ONLY the Kids Memorization Path in the Talia Quran app, inspired by the provided design reference."

**Design Reference**: `docs/image.png`

## Clarifications

### Session 2026-06-01

- Q: What is the star economy and leveling formula? → A: Fixed rewards — every completed stage = 20 stars, every 100 stars = 1 level up, 1 gem earned per level-up. Simple and predictable for children.
- Q: Should P3 features (Shop, Achievements) ship in the first release? → A: No. Ship P1+P2 first (Home, Journey Map, Stage Details, Listen & Repeat, Completion). Stars are earned and displayed but not yet spendable. Shop and Achievements deferred to a follow-up release.
- Q: How are memorization houses (بيوت الحفظ) defined — reuse existing stages or create new groupings? → A: Reuse existing stages. Each current memorization stage becomes one house. Ayah range and surah read directly from the existing stage entity. No new stage definitions or data model changes.
- Q: How should first-release navigation handle deferred P3 destinations? → A: The first release exposes only active destinations that are implemented in P1+P2: Mushaf, Journey, and Missions/current mission. Profile, Achievements, and Stars Shop are not active destinations until the follow-up P3 release.
- Q: What does instant rollback mean for the feature flag? → A: `useNewKidsGamifiedUi` is a runtime-readable flag. Changing it must switch subsequent kids-path navigation between the new and old kids UI without app restart and without changing or deleting memorization data.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Kids Journey Map Navigation (Priority: P1)

A child user opens the kids memorization section and sees a vertical scrollable journey map with "بيوت الحفظ" (memorization houses). Each house represents a memorization stage (a set of ayahs). Completed stages show bright houses with gold stars, the current stage is highlighted and inviting, and locked future stages appear dimmed with a lock icon. The child taps on their current stage house to begin their memorization mission.

**Why this priority**: The journey map is the central navigation hub for the entire kids memorization experience. Without it, children cannot discover, select, or track their memorization stages. It is the foundational screen that all other screens depend on.

**Independent Test**: Can be fully tested by navigating to the kids path, viewing the journey map, verifying correct visual states (locked/current/completed) for houses, and tapping to navigate to a stage detail screen.

**Acceptance Scenarios**:

1. **Given** a child user with 1 completed stage and 1 current stage, **When** they open the kids journey map, **Then** they see the completed stage house with stars, the current stage highlighted, and remaining stages locked with a dimmed appearance and lock icon.
2. **Given** a child viewing the journey map, **When** they tap a completed stage house, **Then** they can review that stage's details.
3. **Given** a child viewing the journey map, **When** they tap a locked stage, **Then** the app does not navigate away and provides a visual indication that the stage is locked.
4. **Given** a child viewing the journey map, **When** they scroll vertically, **Then** houses are connected by a curved path and the map scrolls smoothly.

---

### User Story 2 - Kids Memorization Home Screen (Priority: P1)

A child opens the Talia app in kids mode and sees a welcoming home screen with their avatar, a personalized greeting ("!مرحباً بطل الحفظ"), their current level/progress bar, total stars earned, a "last mission" card showing their most recent stage, and quick access to the Mushaf and current mission. In the first release, the bottom navigation provides active access to: المصحف (Mushaf), رحلتي (My Journey), and المهام (Missions/current mission). Profile, Achievements, and Stars Shop are deferred and must not appear as active first-release destinations.

**Why this priority**: The home screen is the first impression and daily entry point for children. It must be engaging, motivating, and clearly orient the child to their progress and next action.

**Independent Test**: Can be tested by opening the kids path, verifying the greeting, progress level, star count, last mission card, and bottom navigation are all visible and functional.

**Acceptance Scenarios**:

1. **Given** a child with a saved name and progress data, **When** they open the kids home screen, **Then** they see a welcome greeting, their current level with progress bar (e.g., "المستوى ١ — 60/100"), their star count, and a last mission card.
2. **Given** a child with no completed stages, **When** they open the kids home screen, **Then** the last mission card shows the first available stage with an "استكمل الآن" button.
3. **Given** a child on the home screen, **When** they tap the first-release bottom navigation items, **Then** they navigate to the Mushaf, Journey Map, or Missions/current mission screens respectively.

---

### User Story 3 - Stage Details & Mission Start (Priority: P1)

A child taps on a memorization house from the journey map and sees a detailed stage screen. This screen shows the house name (e.g., "بيت الحفظ ١"), the ayah range and surah name displayed on a decorative ribbon banner, and three mission steps: "استمع" (Listen), "ردد" (Repeat), "اختبر نفسك" (Test Yourself). Each step has a descriptive subtitle. A large green "ابدأ المهمة" (Start Mission) button at the bottom initiates the learning flow.

**Why this priority**: This is the gateway to the actual memorization activity. Without clear stage details and a prominent call-to-action, children cannot begin or understand their memorization missions.

**Independent Test**: Can be tested by navigating to a stage from the journey map, verifying the house header, ayah range, surah name, three steps, and start button are displayed correctly.

**Acceptance Scenarios**:

1. **Given** a child taps on "بيت الحفظ ١", **When** the stage details screen loads, **Then** they see a ribbon banner with "بيت الحفظ ١", the ayah range (e.g., "الآيات ١-٥"), the surah name (e.g., "سورة الفاتحة"), and three listed steps with icons.
2. **Given** a child on the stage details screen, **When** they tap "ابدأ المهمة", **Then** they are taken to the listen-and-repeat flow for that stage's ayahs.
3. **Given** a child on the stage details screen, **When** they tap the back button, **Then** they return to the journey map with their scroll position preserved.

---

### User Story 4 - Listen & Repeat Flow (Priority: P2)

A child starts a mission and enters the "استمع وكرر" (Listen & Repeat) screen. They see the Quran ayah displayed on a parchment-style card with proper Uthmani script. Audio controls allow them to play, pause, and seek through the recitation. A microphone button lets them record their own repetition. The existing audio playback and recording logic is preserved; only the visual presentation changes.

**Why this priority**: This is the core learning activity, but it reuses existing playback and recording logic. The visual redesign adds engagement value while relying on proven underlying functionality.

**Independent Test**: Can be tested by starting a mission, verifying the ayah card displays correct text, audio controls function (play/pause/seek), and the microphone button initiates recording if supported.

**Acceptance Scenarios**:

1. **Given** a child starts a mission for ayahs 1-5 of Al-Fatiha, **When** the listen screen loads, **Then** the current ayah is displayed in Uthmani script on a styled card with audio playback controls.
2. **Given** a child playing audio, **When** they tap pause, **Then** playback pauses and can be resumed.
3. **Given** a child on the listen screen, **When** they tap the microphone button, **Then** recording begins with a visual indicator, and they can stop to hear their playback.

---

### User Story 5 - Stage Completion & Rewards (Priority: P2)

After completing all three steps of a mission, the child sees a celebration screen with "!أحسنت" (Well done!), animated stars, their earned star count (e.g., +20 stars), and any bonus rewards (e.g., gems). Two buttons are available: "التالي" (Next — advance to the next stage) and "العودة للخريطة" (Return to Map). Upon returning to the map, the completed house now shows full stars.

**Why this priority**: Completion rewards are critical for child motivation and retention, but they depend on the journey map and mission flow being functional first.

**Independent Test**: Can be tested by completing all steps of a stage and verifying the completion screen appears with correct star count, reward animations, and both navigation buttons function.

**Acceptance Scenarios**:

1. **Given** a child completes all three steps of a stage, **When** the completion screen appears, **Then** they see "!أحسنت" with animated stars and their earned rewards (+20 stars, gems if applicable).
2. **Given** a child on the completion screen, **When** they tap "التالي", **Then** they advance to the next stage's detail screen.
3. **Given** a child on the completion screen, **When** they tap "العودة للخريطة", **Then** they return to the journey map where the completed stage now shows full stars.

---

### Future Scope - Kids Profile & Achievements (Deferred P3)

A child navigates to their profile ("ملفي") to see their avatar, title (e.g., "بطل الحفظ"), overall progress bar, and summary stats: total stars, houses completed, and missions done. Below the stats, they see a list of earned achievements/badges (e.g., "أول بيت" — completed first house, "مستمع رائع" — listened 10 times). Achievements show progress indicators for incomplete ones.

**Deferred scope note**: This is not part of the first release. The profile provides long-term motivation and a sense of accomplishment, but it must be planned and tasked separately after the P1+P2 memorization loop ships.

**Independent Test**: Can be tested by navigating to the profile tab, verifying the avatar, stats, and achievements list display correctly with accurate data from the child's progress.

**Acceptance Scenarios**:

1. **Given** a child with 125 stars and 1 completed house, **When** they open the profile screen, **Then** they see their avatar, "بطل الحفظ" title, progress bar, and stats showing 125 stars, 1/10 houses, 3 missions.
2. **Given** a child with 2 achievements earned, **When** they view the achievements section, **Then** completed achievements show a checkmark and incomplete ones show progress (e.g., "6/10").

---

### Future Scope - Stars Shop (Deferred P3)

A child visits the "متجر النجوم" (Stars Shop) to spend earned stars on cosmetic rewards: character skins/outfits ("شخصيات"), background themes ("خلفيات"), and tools/items ("أدوات"). Items are displayed in a grid with their star price. Locked items show a lock icon and their required star count. A daily reward chest ("صندوق المكافآت اليومي") is available at the bottom.

**Deferred scope note**: This is not part of the first release. Stars are earned and displayed in P1+P2, but spending stars, purchasing items, and claiming daily rewards must be planned and tasked separately.

**Independent Test**: Can be tested by opening the stars shop, verifying the tabs (شخصيات/خلفيات/أدوات), item display with prices, and that purchasing an affordable item deducts stars.

**Acceptance Scenarios**:

1. **Given** a child with 125 stars opens the stars shop, **When** the shop loads, **Then** they see three tabs, items displayed in a grid with star prices, and affordable items are highlighted while expensive ones show a lock.
2. **Given** a child with enough stars, **When** they tap on an affordable item, **Then** the item is "purchased" (marked as owned), stars are deducted, and the item becomes available.
3. **Given** a child visits the shop, **When** a daily reward chest is available, **Then** an "افتح الآن" button is visible for them to claim daily rewards.

---

### Edge Cases

- What happens when a child has completed all available stages? The journey map should show a congratulatory state with all houses starred, and the last house should indicate "completion of the current journey."
- What happens when the gamified UI encounters an error? The app must fall back to the existing (old) kids memorization UI seamlessly via a feature flag (`useNewKidsGamifiedUi`).
- What happens when there is no audio available for a particular ayah? The listen step should show a clear message that audio is loading or unavailable, without crashing.
- What happens on very small screens? The journey map and all screens must use responsive layouts to avoid overflow on devices with small screen widths.
- What happens when the child's progress data is empty (first-time user)? The home screen should still render correctly with zero stars, Level 1, and the first stage as the "current" stage.
- What happens when the child navigates back from the listen screen mid-mission? Progress within the current step should be preserved, and the child can resume from where they left off.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST display a vertical scrollable journey map with memorization "houses" (بيوت الحفظ) connected by a curved path.
- **FR-002**: Each house on the journey map MUST show one of three visual states: locked (dimmed with lock icon), current (highlighted and inviting), or completed (bright with gold stars).
- **FR-003**: The system MUST display each house's label, ayah range, and progress count (e.g., "0/5") on the journey map.
- **FR-004**: The kids home screen MUST display: a personalized welcome greeting, current level with progress bar, total stars earned, a last-mission card with a continue button, and bottom navigation.
- **FR-005**: The first-release bottom navigation MUST include only active implemented destinations: المصحف (Mushaf), رحلتي (Journey), and المهام (Missions/current mission). Profile, Achievements, and Stars Shop MUST remain inactive or hidden until their deferred P3 release.
- **FR-006**: The stage details screen MUST display the house name on a ribbon banner, ayah range, surah name, and three mission steps (استمع, ردد, اختبر نفسك) with descriptive subtitles and icons.
- **FR-007**: The stage details screen MUST include a prominently styled "ابدأ المهمة" (Start Mission) button.
- **FR-008**: The listen-and-repeat screen MUST display Quran ayahs in proper Uthmani script on a styled card with audio playback controls (play, pause, seek) and a microphone button for recording. If audio is loading or unavailable, the screen MUST show a clear non-crashing message.
- **FR-009**: The completion screen MUST display a success message ("!أحسنت"), animated star rewards, earned points/gems, and navigation buttons for "التالي" (Next) and "العودة للخريطة" (Return to Map).
- **FR-010**: The system MUST reuse existing memorization progress data, stage definitions, audio playback logic, and recording functionality without modifying the underlying business logic.
- **FR-011**: The new gamified UI MUST be isolated to the kids path only and MUST NOT affect adult memorization paths or any other app feature.
- **FR-012**: A runtime-readable feature flag (`useNewKidsGamifiedUi`) MUST control whether the new or old kids UI is shown. Changing the flag MUST affect subsequent kids-path navigation without app restart. If the new UI encounters an error before or during screen loading, the system MUST fall back to the old kids UI without data loss.
- **FR-013**: All first-release screens MUST support Arabic RTL layout correctly with proper Uthmani font rendering for Quran text.
- **FR-014**: All first-release screens MUST use a consistent Islamic-themed color palette: deep night blue backgrounds, green accents, gold/amber highlights, and cream/parchment content cards.
- **FR-015**: The system MUST use responsive layouts to avoid overflow on devices of varying screen sizes.

### Deferred Requirements (Not First Release)

- **DFR-001**: The profile screen with avatar, title, overall progress bar, summary stats, and achievement progress indicators is deferred to a follow-up P3 release.
- **DFR-002**: The stars shop with cosmetic item purchasing, tabs, star prices, and daily reward chest is deferred to a follow-up P3 release.

### Key Entities

- **Memorization House (بيت الحفظ)**: Represents a memorization stage. Maps directly 1:1 to the existing memorization stage entity in the app's data model. Contains: house number, ayah range, surah reference, completion state (locked/current/completed), stars earned, and progress count. No new stage definitions needed — the UI reads from existing stage data.
- **Mission (المهمة)**: Represents a single memorization session within a house. Contains three steps: Listen (استمع), Repeat (ردد), Test (اختبر نفسك).
- **Star (النجوم)**: A reward count earned upon completing missions. Fixed rate: 20 stars per completed stage. Every 100 stars = 1 level up. In the first release, stars are displayed but not spendable.
- **Gem (الجوهرة)**: A premium reward count earned at a rate of 1 gem per level-up. In the first release, gems may be displayed as rewards but are not spendable.
- **Deferred Achievement (الإنجاز)**: A future badge or milestone earned by reaching specific progress thresholds. Not implemented in the first release.
- **Deferred Shop Item**: A future cosmetic reward purchasable with stars. Not implemented in the first release.
- **Child Profile (ملفي)**: The child's identity concept within the app. In the first release, only avatar/name/progress values needed by the home header are displayed; the full profile screen is deferred.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Children can navigate from the home screen to their current memorization stage in 2 taps or fewer.
- **SC-002**: The journey map correctly reflects the child's actual progress — all completed stages show stars, the current stage is highlighted, and future stages are locked.
- **SC-003**: A child can complete a full memorization mission (listen → repeat → test) and see the completion reward screen within the existing app flow time.
- **SC-004**: The feature flag allows instant rollback to the old kids UI without app restart or data loss.
- **SC-005**: All adult memorization paths remain completely unaffected — zero changes to adult screens, routes, cubits, or data.
- **SC-006**: All screens render correctly in RTL Arabic layout on devices with screen widths from 320px to 428px (common mobile range).
- **SC-007**: The kids path loads and displays the journey map within 2 seconds on mid-range devices.
- **SC-008**: Star counts and level progress accurately reflect the child's completed memorization stages without data corruption or loss; achievement data is deferred to P3.
- **SC-009**: 90% of child users (or test users simulating children) can identify their current stage and start a mission without external guidance.

---

## Assumptions

- The existing memorization progress data model (stages, ayah ranges, completion status) is sufficient to drive the new UI without schema changes.
- The existing audio playback and recording logic will be reused as-is; only the visual presentation layer changes.
- The app already has a concept of "kids mode" or a kids memorization path that can be identified and targeted for UI changes.
- The existing color theme system in the app can be extended with kids-specific colors without conflicting with the adult theme.
- The old kids UI will remain in the codebase as a fallback and can be activated via the feature flag.
- Star and level displays for the first release are derived from existing stage completion data. Achievement storage, shop purchases, and daily reward storage are deferred to a follow-up release.
- Character avatars used by the first-release home header are pre-defined assets and do not require user-uploaded images.
- **Release scope**: The first release includes P1+P2 features only (User Stories 1–5). P3 features (User Stories 6–7: Profile/Achievements and Stars Shop) are deferred to a follow-up release. Stars are earned and displayed in the UI but not yet spendable.
