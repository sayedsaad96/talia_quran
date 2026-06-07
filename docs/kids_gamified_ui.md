You are a senior Flutter UI/UX engineer.

Task:
Implement a new professional gamified UI for ONLY the Kids Memorization Path in the Talia Quran app, inspired by the provided design reference.

Critical rules:
- Do NOT change the logic of memorization progress.
- Do NOT change database models unless absolutely necessary.
- Do NOT affect adult memorization paths or any other path.
- Do NOT remove existing features.
- Keep all current Cubit/BLoC/state management behavior working.
- UI changes must be isolated behind the Kids Path only.
- Before editing, inspect the full current flow and identify all files related to kids memorization path.

Design direction:
Create a child-friendly Quran memorization game experience:
- Each stage becomes "بيت الحفظ"
- Stages are shown as houses on a journey map
- Locked stages appear grey/dimmed with lock icon
- Completed stages appear bright with stars
- Current stage is highlighted
- Use Quranic/Islamic calm style: green, gold, cream, night blue
- Avoid cartoon exaggeration that breaks the Quranic identity

Required screens:
1. Kids memorization home
   - Welcome child
   - Current level/progress
   - Last mission card
   - Stars/points
   - Bottom navigation if already used

2. Kids journey map
   - Vertical scrollable map
   - Houses connected by curved path
   - Each house represents a memorization stage
   - Show ayah range and progress count
   - Locked/completed/current visual states

3. Stage details screen
   - House header
   - Ayah range
   - Surah name
   - Steps:
     - Listen
     - Repeat
     - Test yourself
   - Start mission button

4. Listen & repeat screen
   - Quran/ayah card
   - Audio controls
   - Record/repeat button if current logic supports it
   - Keep existing playback behavior

5. Completion screen
   - Success message
   - Stars earned
   - Next button
   - Return to map button

Implementation requirements:
- Reuse existing progress/stage data from current code.
- Create reusable widgets instead of large files:
  - KidsJourneyHeader
  - KidsProgressCard
  - KidsMissionCard
  - KidsHouseStageCard
  - KidsJourneyMap
  - KidsStageDetailsCard
  - KidsRewardDialog
- Use responsive layout.
- Support Arabic RTL correctly.
- Keep English text only if it already exists in app localization.
- Prefer Arabic labels for kids path:
  - بيت الحفظ
  - رحلة الحفظ
  - المهمة
  - استمع
  - ردد
  - اختبر نفسك
  - أحسنت
  - النجوم
  - المستوى

Safety:
- Do not delete old UI immediately.
- Keep the old UI available behind a fallback widget or feature flag.
- Add a boolean flag:
  `useNewKidsGamifiedUi = true`
- If any error happens, app should fallback to old kids UI.

Code quality:
- Follow the existing project architecture.
- Use existing theme colors where possible.
- Add new colors only in a dedicated kids theme/constants file.
- Avoid hardcoded sizes where responsive values are better.
- Avoid breaking current navigation routes.
- Do not introduce unnecessary packages unless essential.

Testing:
After implementation, run:
- flutter analyze
- flutter test
- test the kids path manually
- test adult path to ensure it is not affected
- test locked/current/completed stages
- test navigation from map to stage details and back
- test Arabic RTL layout

Deliverables:
1. List of changed files.
2. Summary of what was implemented.
3. Confirmation that adult paths were not modified.
4. Any risks or TODOs.
5. Screenshots or emulator notes if possible.

Start by auditing the current kids memorization path files, then make an implementation plan, then apply the UI changes safely./speckit-clarify
