# Talia â€” UI/UX Implementation Plan

Tracker for the remediation of `docs/ui_ux_audit.md`.
Status: `[ ]` not started Â· `[~]` in progress Â· `[x]` completed

---

## Track 1 â€” Foundation (design system makes the right thing the easy thing)

| # | Screen/Area | Problem | Solution | Priority | Files | Status |
|---|---|---|---|---|---|---|
| 1.1 | Tokens | Hint text fails AA both themes (#AA9E92 â‰ˆ2.3:1, #5A6370 â‰ˆ2.7:1) | Darken/lighten hint tokens to â‰¥4.5:1 on their surfaces | P0 | `core/theme/app_colors.dart` | [ ] |
| 1.2 | Errors | Raw exceptions/backend messages reach users | Localized failure-message mapper used by error surfaces; replace e.toString() in cubits/repos | P0 | `core/error/*`, quran repo, streak cubit, auth pages, settings tiles | [ ] |
| 1.3 | AppButton | GestureDetector base: no ripple, no button semantics, hardcoded danger hexes, literal paddings | InkWell-based, Semantics(button), token colors/spacing | P0 | `core/widgets/app_button.dart` | [ ] |
| 1.4 | AppTextField | No validator/errorText â†’ forms bypass it | Add validator/enabled-error/textDirection support | P0 | `core/widgets/app_text_field.dart` | [ ] |
| 1.5 | Shimmer | 3 diverged shimmer palettes; tokens unused | Unify on AppColors.shimmerBase/shimmerHighlight via SkeletonBox | P0 | skeleton_loader.dart, state_widgets.dart, quran_page_font_guard.dart | [ ] |
| 1.6 | CelebrationOverlay | Hardcoded Arabic copy breaks EN locale | l10n keys; tokenize colors | P0 | `core/widgets/celebration_overlay.dart`, arb files | [ ] |
| 1.7 | SectionHeader | Action tap target <48dp, no semantics | IconButton-based action with tooltip | P1 | section_header.dart | [ ] |

## Track 2 â€” Correctness sweep (P0 bugs)

| # | Screen/Area | Problem | Solution | Priority | Files | Status |
|---|---|---|---|---|---|---|
| 2.1 | Privacy Policy | LTR back arrow in RTL | Directional BackButtonIcon | P0 | privacy_policy_page.dart | [ ] |
| 2.2 | Kids Journey/Listen/Stage | LTR back arrows | Same | P0 | kids_gamified_journey/listen/stage_page.dart | [ ] |
| 2.3 | Family Dashboard + Child Detail | LTR back arrows; 'PIN' unlocalized | Same + l10n label | P0 | family_dashboard_page.dart, child_detail_page.dart, arb | [ ] |
| 2.4 | Azkar Hub | Infinite spinner on error; serial loads | Error branch + retry; parallel futures | P0 | azkar_page.dart | [ ] |
| 2.5 | Kids Home | NavigationBar selectedIndex hardcoded 3; dead avatar tap | Correct index binding; remove dead target | P0 | kids_gamified_home_page.dart | [ ] |
| 2.6 | Progress/Kids card | Double page padding misaligns card | Remove inner margin | P0 | progress_smart_memorization.dart | [ ] |
| 2.7 | Achievements/QuickStart/Family | fontSize 7/8/9 sub-legible | Bump to â‰¥10â€“11 per type floor | P0 | progress_achievements.dart, tutorial_guide_quick_start_card.dart, family_dashboard_page.dart | [ ] |
| 2.8 | Certificate Page | Orientation clobbered on dispose | Save/restore prior orientation correctly | P0 | certificate_page.dart | [ ] |
| 2.9 | Splash | Hardcoded Arabic init-error strings | l10n | P0 | splash_page.dart, arb | [ ] |
| 2.10 | Login | Backend message fallthrough; brittle substring email-confirm detection; toggle enabled while loading | Map messages via failure codes; robust detection; disable while submitting | P0 | login_page.dart (+auth cubit if needed) | [ ] |
| 2.11 | Update Password | Raw error shown; no visibility toggle on confirm field | Localized mapping + toggle | P0 | update_password_page.dart | [ ] |

## Track 3 â€” Restore the Meaningful Gold Rule

| # | Screen/Area | Problem | Solution | Priority | Files | Status |
|---|---|---|---|---|---|---|
| 3.1 | Mushaf Reader + Kids Reader | Routine chrome gold (top bar, footer, hint, close) | Teal-led chrome; keep read-confirmed badge gold | P1 | quran_reader_page.dart, kids_quran_reader_page.dart | [ ] |
| 3.2 | Kids Listen/Completion CTAs | Gold-filled routine primary buttons | Primary variant teal; stars stay gold | P1 | kids_gamified_listen_page.dart, kids widgets | [ ] |
| 3.3 | Unified Hero Card | Dark-mode gold treatment on daily CTA | Teal gradient treatment both themes | P1 | unified_hero_action_card.dart | [ ] |
| 3.4 | Hub/PathSelection kids cards | Gold border/glow on navigation cards | Teal-led selection; gold only inside achievement content | P1 | memorization_hub_page.dart, path_selection_page.dart | [ ] |
| 3.5 | Settings | Section accents rainbow incl. gold; notification switches gold/purple | Calm teal-led accents; semantic colors only where meaningful | P1 | settings_page.dart, settings_notification_tiles.dart | [ ] |
| 3.6 | Azkar Category | Reference citation + grade in gold (metadata) | Muted ink styling | P1 | azkar_category_page.dart | [ ] |
| 3.7 | Tutorial Guide | Tips pills gold-on-gold | Neutral/muted treatment | P1 | tutorial_guide_section_card.dart | [ ] |
| 3.8 | Progress | Streak orange gradient off-vocab; "Pages read" gold; engagement glow | Tokenized calm treatments | P1 | progress_stat_cards.dart, progress_page.dart, home_page_widgets.dart | [ ] |

## Track 4 â€” De-rainbow palettes

| # | Screen/Area | Problem | Solution | Priority | Files | Status |
|---|---|---|---|---|---|---|
| 4.1 | Custom Plan Setup | Purple/blue/orange control accents; purple header gradient | Palette tokens; teal-led header | P1 | custom_plan_setup_page.dart | [ ] |
| 4.2 | General Azkar | Rose/crimson duas family | Map to palette-adjacent tones | P1 | general_azkar_page.dart | [ ] |
| 4.3 | Azkar Hub | Off-palette blues in header/cards | Token gradients | P1 | azkar_page.dart | [ ] |
| 4.4 | Achievements tiers | 19-literal rainbow rank palette | Constrain to gold/silver/bronze from palette + neutrals | P2 | progress_achievements.dart | [ ] |
| 4.5 | Quran Home | Meccan/Madani off-palette hexes | desertSand/success-family tokens | P1 | quran_page.dart | [ ] |
| 4.6 | Reader copy accent | Colors.blue | AppColors.info | P2 | quran_reader_page.dart | [ ] |
| 4.7 | Notification tiles | Raw purple #8E44AD | Palette token | P1 | settings_notification_tiles.dart | [ ] |

## Track 5 â€” Accessibility pass

| # | Screen/Area | Problem | Solution | Priority | Files | Status |
|---|---|---|---|---|---|---|
| 5.1 | Mushaf top bar | 24dp unlabeled GestureDetectors Ã—3; focus exit 38dp | 48dp IconButtons + tooltips | P1 | quran_reader_page.dart | [ ] |
| 5.2 | Quran Home | Reciter chip ~26dp unlabeled; search clear unlabeled | Min-height 48 + Semantics + tooltip | P1 | quran_page.dart | [ ] |
| 5.3 | Ayah options sheet | Flat 4-button row, no roles | Semantics buttons; play emphasized | P2 | quran_reader_page.dart | [ ] |
| 5.4 | Bookmarks | Share <48dp unlabeled; chevron direction | Fix target + directional chevron | P1 | bookmarks_page.dart | [ ] |
| 5.5 | Azkar counter | Primary action unlabeled | Semantics(button+value) | P1 | azkar_category_page.dart | [ ] |
| 5.6 | Login/UpdatePassword | Toggle <48dp; missing tooltips on visibility toggles | 48dp + tooltips | P1 | login_page.dart, update_password_page.dart | [ ] |
| 5.7 | Settings notification time chip | ~26dp target | 48dp chip | P1 | settings_notification_tiles.dart | [ ] |
| 5.8 | Tappable cards hub/path/family/practice | No button semantics | Semantics(button) wrappers | P2 | respective files | [ ] |
| 5.9 | Home gear/share icon | Unlabeled; share 18dp | Tooltips + 48dp | P1 | home_page_widgets.dart | [ ] |

## Track 6 â€” Duplication consolidation

| # | Area | Problem | Solution | Priority | Files | Status |
|---|---|---|---|---|---|---|
| 6.1 | Home banners | Twin dismissible banners (~110 lines) | Single DismissibleBanner widget | P2 | home_page_widgets.dart | [ ] |
| 6.2 | Stat boxes Ã—4 | Four interchangeable stat-box impls | Shared StatBox primitive | P2 | home_page_widgets, progress_stat_cards, progress_smart_memorization | [ ] |
| 6.3 | Kids app bars Ã—3 | Triplicated app bar | Shared KidsAppBar | P2 | kids journey/listen/stage | [ ] |
| 6.4 | Path sheet/card twins | Hub vs PathSelection drift | Shared widget in feature | P2 | memorization_hub_page.dart, path_selection_page.dart | [ ] |
| 6.5 | _showSettingsError Ã—3 | Triplicated helper | One extension/helper | P2 | settings files | [ ] |
| 6.6 | Share menu Ã—2 | Sheet vs PopupMenu divergence | One shared share-sheet entry | P3 | home_page_widgets.dart, progress_page.dart | [ ] |
| 6.7 | Drag handles / gold circle buttons | Repeated micro-patterns | Small shared widgets (quran-local) | P3 | quran files | [ ] |

## Track 7 â€” Responsiveness & large-text safety

| # | Screen/Area | Problem | Solution | Priority | Files | Status |
|---|---|---|---|---|---|---|
| 7.1 | Quran Home header | Fixed 104pt bottom clips at text scale | Measure content / flexible budget | P1 | quran_page.dart | [ ] |
| 7.2 | Reader footer | 3-item Row overflows at scale | Expanded/Flexible + ellipsis | P1 | quran_reader_page.dart | [ ] |
| 7.3 | Certificates rail | Slot 240 vs card 140 mismatch | Card fills slot | P2 | progress_certificates.dart | [ ] |
| 7.4 | Skeleton width mismatch | 600 vs 840 caps | Align to 840 | P2 | skeleton_loader.dart | [ ] |
| 7.5 | Quick actions grid | Fixed aspect distorts | Responsive aspect | P3 | home_page_widgets.dart | [ ] |

## Track 8 â€” Performance

| # | Area | Problem | Solution | Priority | Files | Status |
|---|---|---|---|---|---|---|
| 8.1 | Mushaf | Sync parse of 604 pages on UI thread; static cache forever | Async/isolate init + windowed cache | P1 | app_quran_page_view.dart | [ ] |
| 8.2 | Custom plan form | 16 setState; dropdowns rebuilt per tick | Scoped stateful controls; const items | P2 | custom_plan_setup_page.dart | [ ] |
| 8.3 | Reader setState scope | Whole-page rebuilds for badge/focus | Scoped builders | P2 | quran_reader_page.dart | [ ] |
| 8.4 | Animation gating | Infinite anims ungated; stagger replay in lists | disableAnimations honored; play-once entrances | P2 | kids screens, splash, bookmarks, quran grid | [ ] |
| 8.5 | Debug leftovers | print/debugPrint Ã—4 | Remove | P3 | social_share_sheet.dart, settings_notification_tiles.dart | [ ] |

## Track 9 â€” i18n completeness

| # | Area | Problem | Solution | Priority | Files | Status |
|---|---|---|---|---|---|---|
| 9.1 | Certificate widget | All copy Arabic-only incl. ordinals | l10n migration | P2 | certificate_widget.dart, arb | [ ] |
| 9.2 | Settings notifications | 23 isArabic ternaries + emoji copy | l10n keys | P2 | settings_notification_tiles.dart, arb | [ ] |
| 9.3 | Tutorial guide | Hardcoded Arabic empty-state copy | l10n | P2 | tutorial_guide_page.dart, section_card, arb | [ ] |
| 9.4 | Azkar category | Hardcoded 'Ù…Ù† ${total}' | existing l10n key | P2 | azkar_category_page.dart | [ ] |
| 9.5 | Splash/settings misc | Remaining hardcoded strings | l10n | P3 | splash, settings_page, account tiles | [ ] |

## Track 10 â€” Polish sweep

| # | Area | Problem | Solution | Priority | Files | Status |
|---|---|---|---|---|---|---|
| 10.1 | Global | Off-grid spacings/radii in touched files | Tokenize during each fix | P3 | various | [ ] |
| 10.2 | Gradients | Inline diagonal gradients | Hoist to AppColors tokens | P3 | various | [ ] |
| 10.3 | Dead code | GlassCard/SpiritualCard/AchievementCard/EmptyJourneyWidget/kids_loading_widget orphaned | Delete or adopt | P3 | core widgets, mem_plus widgets | [ ] |
| 10.4 | Typography drift | Manual Amiri copyWith, w800, fractional sizes | Sanctioned styles | P3 | various | [ ] |
| 10.5 | Emoji-in-strings | XP label emoji | Remove glyph or use asset | P3 | home_page_widgets.dart | [ ] |

---

## Execution order

Track 1 â†’ 2 â†’ 3 â†’ 4 â†’ 5 â†’ (6,7,8 interleaved by file proximity) â†’ 9 â†’ 10.
Every track's edits run `flutter analyze` + targeted tests before marking complete.

## Regression guardrails

- Memorization routing/cubits/SharedPreferences keys untouched (onboarding contract).
- No business logic changes in Track fixes beyond error-message surfacing.
- Visual changes respect DESIGN.md; Kids Mode keeps shared system identity.
