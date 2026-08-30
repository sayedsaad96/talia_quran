# Talia — UI/UX Audit

**Date:** 2026-08-25
**Scope:** Entire Flutter app (351 Dart files, ~40 user-facing surfaces, 5-tab shell + ~25 full-screen routes)
**Method:** Full source inspection of every presentation layer + cross-cutting pattern scans. Native audit playbook (Android/iOS adaptive). All findings carry file:line evidence.
**Design baseline:** DESIGN.md — "The Guided Sanctuary" (Royal Teal guidance / Meaningful Gold rule / warm paper + night neutrals / Amiri + Noto Naskh).

---

## Executive Summary

Talia has an unusually strong foundation: a complete token system (`AppColors`, `AppSpacing`, `AppTypography`, `AppDecorations`), a committed visual identity, mature state coverage on memorization/session screens, disciplined RTL chevron handling in most flows, and a fully migrated `withValues` API. The onboarding surface was recently finished to a documented contract and is the quality benchmark.

The problem is **coherence at scale**: the design system is decorative rather than load-bearing. `AppButton` has 0 feature uses while features hand-roll 87 FilledButtons; `AppTextField` is unusable for forms (no validator) so auth bypasses it; 3 divergent shimmer palettes exist while the sanctioned tokens sit unused; 4 cloned hero headers; ~616 hardcoded colors outside the theme; gold used as routine chrome in the reader and kids flows against the Meaningful Gold Rule; and near-zero semantics on tappable surfaces.

**Audit Health Score: 11/20 — Acceptable (significant work needed)**

| # | Dimension | Score | Key Finding |
|---|-----------|-------|-------------|
| 1 | Accessibility | 1 | ~7 Semantics widgets app-wide; hint-text contrast fails AA in both themes; AppButton itself lacks button semantics |
| 2 | Performance | 2 | Synchronous parse of all 604 mushaf pages on UI thread into a permanent static cache; infinite animations ungated; setState god-pages |
| 3 | Appearance & Theming | 2 | Strong tokens exist but 616 raw color literals bypass them; rainbow palettes on settings/custom-plan/certificates |
| 4 | Platform Conformance | 3 | Material 3 respected; RTL mostly correct with specific back-arrow bugs; system gestures honored |
| 5 | Adaptivity | 2 | Portrait-only by product decision; fixed header budgets clip at large text scale; no max-width on several screens |

---

## Critical Problems (P0)

1. **Raw technical exceptions reach users.** `quran_repository_impl.dart:19,36,55,84,96` wraps `e.toString()` verbatim → rendered by `ErrorStateWidget` on Quran home/reader/kids reader. Same pattern: `login_page.dart:545` backend-message fallthrough, `update_password_page.dart:68→110`, `settings_account_tiles.dart:351-356`, `streak_cubit.dart:39,56`. English dev strings appear in an Arabic-first app.
2. **Hint-text contrast fails WCAG AA everywhere.** `lightTextHint #AA9E92` ≈ 2.3:1 on white, `darkTextHint #5A6370` ≈ 2.7:1 on night surface — used for functional labels/icons across home, progress, quran, achievements.
3. **RTL back arrows point the wrong way on 6 screens.** Hardcoded LTR `arrow_back_ios*`: privacy_policy_page.dart:192, kids_gamified_journey:211, kids_listen:262, kids_stage:196, family_dashboard:59, child_detail:30.
4. **Azkar hub hangs forever on DB error.** `azkar_page.dart:48-76` FutureBuilder has no error branch; also loads 4 categories serially before first frame.
5. **Sub-legible micro-typography.** fontSize 7/8/9 in achievements grid, quick-start card, family badge — below any readability floor.
6. **Layout correctness bugs.** Double page-padding on kids progress card (`progress_smart_memorization.dart:16` inside already-padded parent); kids NavigationBar `selectedIndex: 3` hardcoded (Missions always "active"); certificate page clobbers orientation restore (`certificate_page.dart:42-55`).
7. **i18n bugs in delight/error surfaces.** `celebration_overlay.dart:53-55,139,147` hardcodes Arabic (English users get Arabic); splash init errors hardcoded Arabic; `'PIN'` label unlocalized.

## High Priority (P1)

8. **Meaningful Gold Rule violations** — gold as routine action/chrome:
   - Reader top bar/footer/kids reader chrome entirely gold (routine navigation).
   - Kids listen CTA + completion CTA gold-filled every session.
   - `UnifiedHeroActionCard` dark-mode gold treatment on the daily routine CTA.
   - Kids path selection cards gold-bordered (a navigation moment).
   - Settings section accents, notification switches, tutorial tips pills in gold.
   - Zikr reference citation + authenticity grade text in gold (metadata, not achievement).
9. **Rainbow palettes off-token:** custom_plan_setup_page (purple/blue/orange control accents + purple header gradient), settings (7 hues on one screen), general_azkar rose/crimson family for duas, azkar hub off-palette blues, notification tiles raw purple `#8E44AD`, achievements rank-tier rainbow (19 literals), certificate's 3 competing golds.
10. **Accessibility floor missing:** GestureDetector-as-button everywhere without Semantics (31 sites), icon buttons without tooltips (~21 audited, 2 labeled), touch targets <48dp (mushaf controls ~24dp, login toggle ~34dp, time chip ~26dp), dead tap target advertised to assistive tech (kids avatar).
11. **Quranic text compressed below system floor:** ayah sheet uses `height:1.8` vs the 2.0–2.4 floor; surah title squeezed to h1.2. No adjustable reading size anywhere.
12. **Startup/memory risk:** all 604 QCF pages parsed synchronously on UI thread into a static list pinned for app lifetime (`app_quran_page_view.dart:53,72-79`).
13. **Missing states:** achievements grid has no empty state; blank `SizedBox.shrink()` initial frames on Home/Quran; silent data failure in kids completion/stage pages (no retry/explanation).
14. **Fixed budgets break at large text scale:** Quran home header hard `Size.fromHeight(104)` clips search+tabs; reader footer 3-item Row overflows ≥1.5×; ayah sheet 4-button row can overflow narrow devices.

## Medium Priority (P2)

15. **Design-system bypass:** AppButton (0 uses) / AppTextField (0 uses, API gap) / AppScaffold (1 vs 36 raw Scaffolds) / AppCard (2 uses); dead variants & widgets (GlassCard, SpiritualCard, AchievementCard, EmptyJourneyWidget, ghost/danger/goldPrimary variants, orphaned kids_loading_widget).
16. **Duplication clusters:** 4 stat-box implementations; twin dismissible banners (110 lines); share menu ×2; path-confirm sheet + path card duplicated hub↔path_selection; kids app bar ×3; night-scaffold wrapper ×5; hero header ×4; `_showSettingsError` ×3; skeleton/shimmer ×3 with diverged palettes; drag handle ×2; gold circular icon button ×3; PIN gate re-implemented privately.
17. **Spacing/radius erosion:** ~314 raw spacing literals (off-grid values 2,3,5,6,10,13,14,18,22,28,30…), 67 literal BorderRadius.circular calls, magic bottom insets `120` ×5 screens, hero app-bar heights 140/150/160 for the same component, bottom spacers 96/100/120 ad hoc.
18. **setState god-pages:** custom_plan_setup_page (16 setState; rebuilds two 114-item dropdowns per slider tick), quran_reader_page (12, whole-reader rebuilds for badge/focus toggles), settings_notification_tiles (9), login (12).
19. **Animation discipline:** infinite repeat() animators on kids surfaces/splash/home never visibility-gated; index-staggered entrance animations replay during scroll (`index*50ms` bookmarks/grid); flutter_animate pulses ignore `disableAnimations`; BackdropFilter in home hero button.
20. **Feedback idioms fragmented:** 82 SnackBars vs 5 ErrorInfoBanners vs ErrorStateWidget — inconsistent error surfacing incl. neutral snackbars for kids-flow errors.

## Low Priority / Polish (P3)

21. Diagonal gradients don't flip under RTL (cosmetic; 12+ copies of `Alignment.topLeft→bottomRight` that should use token gradients).
22. Manual `fontFamily:'Amiri'` copyWith ×20+; invented w800 weights; `monospace` fallback font reference; fractional sizes (13.5/12.5/14.5).
23. Emoji embedded in production strings (XP level label, settings notification copy).
24. Hand-rolled date formatting (`progress_certificates.dart:211`) vs existing MaterialLocalizations usage.
25. Physical watermark placements mixed with directional ones across azkar/settings/tutorial.
26. Dead code: empty `didChangeDependencies`, unused KidsTheme hues, unused shimmer tokens, `amber` deprecated alias still referenced.
27. Dev POC page (`qcf_rendering_poc_page.dart`) shipped in production pages folder (debug-gated route exists — file location only).
28. 4 leftover print/debugPrint statements; brittle test-detection hack in state_widgets.

---

## Screen-by-Screen Audit

Legend: complexity = implementation effort (S/M/L/XL). Priority = urgency of fixes.

| Screen | Key issues | Priority | Complexity |
|---|---|---|---|
| Splash | Infinite animators; hardcoded Arabic error strings | P0(i18n)/P3 | S |
| Onboarding | Finished per surface brief 2026-08-22 — contract kept. Residual: page-scroll listener setState rebuilds tree each frame | P3 | S |
| Login | Raw backend message fallthrough; brittle Arabic substring matching for email-confirm detection; toggle not disabled while submitting; toggle <48dp; TextFields bypass system | P0/P1 | M |
| Update Password | Raw error message shown; confirm-field lacks visibility toggle | P0 | S |
| Home | 11 stacked sections compete; 4 duplicate action rows; hardcoded hero colors; gold-rule violations (dark hero CTA, engagement glow); infinite bob/pulse animations; BackdropFilter; skeleton width mismatch (600 vs 840); unlabeled gear button; emoji XP label | P1/P2 | L |
| Quran Home | Header clips at large text; reciter chip ~26dp unlabeled; Meccan/Madani off-palette hexes; forward chevrons wrong direction RTL; static decorative stats (114/6236/30); blank unknown-state frame; stagger replay in lists | P0/P1 | M |
| Mushaf Reader | All-routine chrome gold; 24dp unlabeled controls; setState whole-page rebuilds; footer overflow at text scale; ayah sheet compresses Quran line-height to 1.8; Colors.blue copy accent; sync 604-page parse; eager AudioPlayer | P0/P1 | L |
| Kids Reader | Gold routine chrome; manual arrow mirroring; otherwise clean | P1 | S |
| Bookmarks | Stagger replay; compact share button <48dp unlabeled; chevron direction | P1/P2 | S |
| Azkar Hub | **Infinite spinner on error**; serial loads; off-palette blues; physical watermarks | P0/P1 | M |
| Azkar Category | Counter (primary action) unlabeled; reference/grade gold metadata; 160px ring + gradient button + undo compete; off-grid radii/spacings; hardcoded 'من' string; heavy layered shadows; counter taps rebuild whole page | P1/P2 | M |
| General Azkar | Rose/crimson off-palette family; white70-on-gradient contrast; stagger replay; filter row fixed height | P1/P2 | M |
| Memorization Hub | Triplicated path cards/sheets; kids card gold border (nav moment); hero heights diverge; GestureDetector cards without semantics | P1/P2 | M |
| Path Selection | Duplicates hub versions with drifted styling | P2 | S |
| Practice Surah | Hero height drift; banner blue-led gradient; tile chevron fine but row needs semantics | P2 | S |
| Custom Plan Setup | Worst single file: 16 setState, ~18 raw colors (purple/blue/orange), purple header gradient, 114-item dropdowns rebuilt per drag frame, off-grid spacings, cramped mini-slider rows | P1/P2 | XL |
| Daily Plan | Solid states; generic error message only | P3 | S |
| V2 Session Flow (learning/memorizing/recitation/remediation/block review/completion) | Excellent edge-case handling (mic permission, STT fallback, PopScope guard); minor: shared scaffold fine | P3 | S |
| Kids Gamified Home | selectedIndex:3 bug; dead avatar tap target; infinite pulse/shimmer stack; mission card gold border decoration | P0/P1 | M |
| Kids Journey | Fixed 172×230 cards; back arrow LTR; heavy per-card glows; locked-stage msg duplicated | P1/P2 | M |
| Kids Listen | Gold primary CTA (routine); waveform repeat ungated; monospace fallback font; neutral snackbars for errors; no PopScope mid-recording | P1 | M |
| Kids Stage | Silent stage-load failure; back arrow LTR; parchment shadow over vocabulary | P1/P2 | S |
| Kids Completion | Silent next-mission failure hides CTA without explanation | P1 | S |
| Family Dashboard | PIN label unlocalized; QR scanner lacks camera-permission state/unthrottled detect; back arrow LTR; fontSize 9 badge; grid emoji overflow risk | P0/P1 | M |
| Child Detail | fontSize 32 override; off-token green gradient end; back arrow LTR | P1/P3 | S |
| Guardian Linking | Exemplary states (guest/expired/blocked/slow-load); minor tooltip gaps | P3 | S |
| Progress | Streak card loud-vs-quiet asymmetry; orange gradient off-vocabulary; "Pages read" gold; double padding kids card; achievements rainbow tiers + 7/8/9px text + no empty state; certificates slot/card width mismatch; hand date format | P0/P1 | L |
| Settings | Rainbow section accents; 3× `_showSettingsError`; raw AuthError messages; notification tiles: raw purple, emoji copy, 9 setState, time chip <48dp; dialogs duplicated 5× | P1/P2 | L |
| Privacy Policy | **LTR back arrow in RTL**; manual directional padding anti-pattern | P0 | S |
| Tutorial Guide | Search rebuilds everything per keystroke (no debounce); 5-hue tinted sub-blocks; gold tips pills; hardcoded Arabic empty-state copy; fixed chip/tile dims | P1/P2 | M |
| Certificate | Landscape forced + wrongly restored; 34 hardcoded colors; parallel type system (10 inline styles); 3 competing golds; physical layout acceptable for fixed-art export | P1/P2 | L |
| Certificate Celebration | Known-good pattern; shares celebration overlay i18n bug | P0(inherited) | S |
| Dialogs/Banners/Snackbars | 82 snackbars vs 5 banners; alert chrome duplicated 5×; neutral error snackbars in kids flows | P2 | M |

---

## Patterns & Systemic Issues

1. **Tokens exist; screens ignore them.** Every inconsistency above traces to one root cause: core primitives were built after/beside the screens instead of being the only way to build screens. Fix order: make primitives worthy (validator, semantics, ripple) → migrate highest-traffic call sites → sweep.
2. **Gold inflation.** The Meaningful Gold Rule is documented but unenforced; gold drifted into routine chrome in reader/kids/settings. Restoring scarcity restores meaning.
3. **A11y was designed-in only where someone thought about it** (onboarding, guardian linking, heatmap) and absent elsewhere — proof it must live in the shared components.
4. **Copy-paste divergence.** Every duplication pair listed has already drifted (different radii, colors, paddings) — evidence that consolidation prevents future inconsistency, not just tidiness.
5. **RTL discipline is real but incomplete.** Chevrons are handled carefully almost everywhere; back arrows and a handful of physical constants are the remaining defects.

## Positive Findings

- Complete, well-documented token layer (colors/spacing/type/decorations) with semantic naming.
- `withOpacity` → `withValues` fully migrated (509 uses, 0 legacy).
- Session-flow edge cases (mic permissions, STT fallback grading, interruption guards) handled better than most production apps.
- Guardian-linking state machine (guest/expired/blocked/slow-load) is exemplary.
- ActivityHeatmap widget is a model citizen (colorScheme, l10n, Tooltip, directional insets).
- Zero TODO/FIXME debt; clean DI architecture; StatefulShellRoute preserves tab state correctly.
- Onboarding proves the team can ship to the documented standard.

## Recommended Actions (priority order)

1. **[P0] Foundation fixes:** AA-passing hint tokens; localized failure mapping; AppButton semantics/ripple; AppTextField validator support; unified shimmer tokens.
2. **[P0] Correctness sweep:** RTL back arrows; azkar error branch; kids nav index; double padding; micro font sizes; celebration overlay l10n; certificate orientation.
3. **[P1] Restore the gold rule:** reader chrome, kids CTAs, hero card, settings accents, metadata gold → teal-led; keep gold for stars/milestones/read-confirmation only.
4. **[P1] De-rainbow:** normalize custom plan, settings, azkar categories, achievements tiers onto palette.
5. **[P1] A11y pass:** tooltips/Semantics on icon buttons + tappable cards; 48dp minimums; remove dead targets.
6. **[P2] Consolidate duplicates:** banners, stat boxes, skeletons/shimmer, hero header, kids app bars, settings error helper.
7. **[P2] Responsiveness:** fluid header budgets, overflow-safe footers/rows, max-width caps consistent (840).
8. **[P3] Polish sweep:** spacing/radius tokenization, gradient hoisting, animation gating, print removal.

Re-run this audit after remediation to score improvement.
