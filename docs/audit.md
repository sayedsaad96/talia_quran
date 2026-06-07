Start fixing.

You are a senior Flutter architect and release-readiness code reviewer.

Goal:
Audit and fix the entire memorization system in Talia Quran app before production release.

Main objective:
Ensure there is no conflict, duplication, or broken logic between:
- Kids memorization path
- Adult memorization path
- Smart memorization system
- Basic memorization system
- Home screen continuation cards
- Progress tracking

Critical release rule:
This is a production app close to publishing.
Do NOT rewrite the whole system.
Do NOT break existing progress.
Do NOT change Quran source files.
Do NOT change storage/database models unless absolutely necessary.
Prefer safe refactoring, routing fixes, and centralized source of truth.

Required final behavior:

1. Path separation
- Kids path and adult path must be fully separated in UI, routing, progress display, and continuation logic.
- No Kids UI should appear for adult path.
- No adult/basic old UI should appear for kids path.
- Switching path should immediately update the visible UI everywhere.

2. Smart memorization behavior
- Smart memorization must be linked to the selected memorization path.
- If selected path is Kids:
  - Smart memorization shows the Kids Gamified UI.
- If selected path is Adult:
  - Smart memorization shows the adult/basic UI.
- Smart memorization must not have a separate inconsistent UI state.

3. Basic memorization behavior
- Basic memorization must also follow the selected path.
- If selected path is Kids:
  - Basic memorization shows Kids Gamified UI.
- If selected path is Adult:
  - Basic memorization shows adult/basic UI.

4. Home screen behavior
- Home screen continuation/progress cards must reflect the currently selected memorization path.
- If selected path changes:
  - Home screen must update accordingly.
- Continue memorization button/card must navigate to the correct UI based on selected path.
- Home screen must not show stale progress from another path.
- Home screen must not mix Kids and Adult progress.

5. Progress logic
- Progress must be based only on actual completed memorization.
- Do not increase progress just because a screen was opened.
- Do not duplicate progress between kids/adult paths incorrectly.
- Do not reset existing user progress.
- Verify locked/current/completed states are calculated correctly.
- Verify stage completion depends on actual ayah completion.
- Verify smart memorization progress and basic memorization progress use the same reliable source of truth where appropriate.

6. Routing consistency
Audit all routes and navigation entry points:
- Home screen continue button
- Memorization tab
- Kids path entry
- Adult path entry
- Smart memorization entry
- Basic memorization entry
- Stage details
- Listen/repeat/test pages
- Back navigation

Required routing rule:
Create or use one central router/wrapper if needed:

MemorizationPathRouterScreen

Pseudo logic:
final selectedPath = selected path source of truth;

if selectedPath == kids:
  return KidsGamifiedMemorizationFlow(...);

return AdultMemorizationFlow(...);

This router must be used by all memorization entry points.

7. Single source of truth
Audit selected memorization path state.
There must be one reliable source of truth for:
- selected path
- current active memorization mode if needed
- current progress
- current surah/stage/ayah

If duplicates exist:
- Identify them.
- Remove or deprecate duplicated state safely.
- Do not introduce another duplicate state.

8. UI consistency
- Kids path uses only Kids Gamified UI.
- Adult path uses only adult/basic UI.
- Smart and basic modes must not decide UI independently.
- UI must depend on selected path, not entry source.

9. Data safety
Before making changes:
- Identify all storage keys, local DB boxes, repositories, or services related to:
  - selected memorization path
  - progress
  - smart memorization settings
  - basic memorization progress
- Do not rename storage keys unless a migration is added.
- Do not delete old user progress.

10. Required audit output before fixing
First provide:
- Current architecture summary
- All memorization-related screens/widgets
- All related Cubits/Bloc/providers
- All repositories/services/storage keys
- All routes/navigation entry points
- Identified conflicts/duplications
- Risk level for each issue
- Safe fix plan

Then implement only after the audit plan is clear.

11. Required fixes
Fix only confirmed issues, including:
- Kids UI not appearing consistently across all flows
- Smart/basic memorization using different UI decisions
- Home screen showing stale or wrong path progress
- Path switching not refreshing related screens
- Duplicated progress calculations
- Any unsafe route bypassing the central router
- Any progress update triggered by screen open instead of actual memorization completion

12. Testing requirements
After fixes, test these scenarios manually and/or with widget/unit tests where possible:

Scenario A:
- Select Kids path
- Open basic memorization
- Expected: Kids Gamified UI appears

Scenario B:
- Select Kids path
- Open smart memorization
- Expected: Kids Gamified UI appears

Scenario C:
- Select Adult path
- Open basic memorization
- Expected: Adult UI appears

Scenario D:
- Select Adult path
- Open smart memorization
- Expected: Adult UI appears

Scenario E:
- Change path from Kids to Adult
- Return to home
- Expected: Home continuation card updates to Adult path

Scenario F:
- Change path from Adult to Kids
- Return to home
- Expected: Home continuation card updates to Kids path

Scenario G:
- Complete an ayah in Kids path
- Expected: Kids progress updates only

Scenario H:
- Complete an ayah in Adult path
- Expected: Adult progress updates only

Scenario I:
- Open a memorization screen without completing anything
- Expected: progress does not increase

Scenario J:
- Restart the app
- Expected: selected path and progress load correctly

13. Verification commands
Run:
- flutter analyze
- flutter test
- flutter pub get if needed

14. Deliverables
At the end, provide:
- Files changed
- Issues found
- Issues fixed
- Remaining risks
- Confirmation that Quran source files were not modified
- Confirmation that user progress was not reset
- Confirmation that Kids and Adult paths are isolated
- Confirmation that home screen follows selected path
- Confirmation that app is safer for release

*** Do the audit first. Do not edit code until you show me the architecture summary and safe fix plan. 