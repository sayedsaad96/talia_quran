# Share Good V1 acceptance evidence — 2026-11-14

**Status: implemented and locally test verified. Release: BLOCKED (external).** Automated verification does not establish deployed, signed-device or Play-install acceptance. The acceptance criteria below are from [design §29](2026-09-11-talia-share-good-design.md#29-v1-acceptance-criteria), with the Android/iOS clarification required by [delivery plan Task 16](2026-10-07-talia-share-good-v1-delivery.md#task-16-full-regression-and-acceptance-gate).

The final whole-project run passed **6141 tests** with no failures. Static analysis reported **no issues**, and dependency/lockfile and generated-file checks passed. Exact verification and remaining release gates are recorded below.

External blockers remain: **B1** approved HTTPS host and hosting; **B2** release upload-key and Play App Signing SHA-256 fingerprints; **B3** staging migration, schema-cache refresh and deployed contract/RPC verification. Keep rollout off until these and the signed-device acceptance checks pass. No production deployment is implied.

The named Flutter tests below are covered by the successful whole-project run. SQL assertions require execution against an appropriate disposable database; static SQL checks do not prove deployed behavior. All rows in [signed Android runtime QA](../../../qa/share_good_runtime_qa.md) are currently **UNVERIFIED**. File paths below are repository-relative.

| AC | Acceptance criterion | Evidence mapped and remaining gap |
|---|---|---|
| AC1 | Invite before or after eligible Quran/Adhkar activity | `test/features/share_good/presentation/share_good_action_test.dart` — “eligible adult sees invitation action”; `invite_create_cubit_test.dart` — “chain asks for sign in and retains parent on return” checks `afterActivity`. **Gap:** named end-to-end coverage of every before/after entry point is not established here. |
| AC2 | Explicit personal/public choice before OS sharing | `test/features/share_good/presentation/invite_create_cubit_test.dart` — “create button remains disabled until a mode is selected” and “mode is required; personal uses saved preference and public defaults anonymous”. **Gap:** real OS share-sheet ordering remains unverified. |
| AC3 | Preserve exact activity context | `test/features/share_good/domain/invite_activity_target_test.dart` — “round-trips all four v1 shapes”; `test/features/share_good/presentation/invite_preview_cubit_test.dart` — “starting a surah invite opens the exact surah route”. **Gap:** real end-to-end routing for every target is not established. |
| AC4 | Contextual copy, Talia branding and invite link | `test/core/widgets/social_share/share_invitation_test.dart` — “invitation QR uses invitation URL and card only shows activity title” and “caption keeps the immutable invitation link after editing”. **Gap:** these named tests do not alone establish branding and contextual copy for every activity/moment; real share remains unverified. |
| AC5 | Installed recipient reaches preview and correct activity | `test/features/share_good/presentation/invite_preview_cubit_test.dart` — “opens once, starts and activates” and “starting a surah invite opens the exact surah route”; runtime QA rows “Installed, cold launch from WhatsApp and Telegram” and “Installed, warm and background launch” — **UNVERIFIED**. |
| AC6 | Guest can complete invited activity | `test/integration/share_good_guest_flow_test.dart` — “guest opens, starts, confirms and keeps completion private”. This is an automated flow; signed-device execution remains unverified. |
| AC7 | No account required before reading | `test/features/share_good/presentation/invite_preview_page_test.dart` — “ready invitation offers start without sign in: $locale”; guest integration test in AC6. |
| AC8 | Completion differs by activity | `test/features/share_good/presentation/quran_invite_completion_test.dart` — “shows only the matching range and requires successful end confirmation”; `azkar_invite_completion_test.dart` — “fresh transition reports once” and “already completed requires confirmation”; `test/features/quran/presentation/pages/quran_reader_page_mode_test.dart` — “invite waits for the explicit Khatmah save to finish”. |
| AC9 | No identity disclosure without explicit consent | `test/features/share_good/presentation/invite_completion_sheet_test.dart` — “private clears consent without disclosure” and “sign in returns to sheet and current account requires explicit disclosure”; `test/features/share_good/data/share_good_local_store_test.dart` — “completion consent survives replay and explicit privacy choice wins”. Runtime QA row “Account switch and account deletion” remains **UNVERIFIED**. |
| AC10 | Private completions contribute only aggregate counts | `supabase/tests/share_good_v1_test.sql` assertion “impact returns aggregates and explicitly disclosed names only”; `test/supabase/share_good_v1_contract_test.dart` — “ordinary advance has an allowlist and impact omits bearer tokens”. Disposable DB and staging execution must be separately evidenced. |
| AC11 | Chain lineage attributes downstream aggregate impact | `supabase/tests/share_good_v1_test.sql` assertions “B invite lineage survives”, “C lineage survives”, and “downstream reach survives deletion”; `test/features/share_good/presentation/invite_create_cubit_test.dart` — “chain asks for sign in and retains parent on return”. **Gap:** deployed chain attribution remains unverified. |
| AC12 | Impact shows aggregates without ranking | `test/features/share_good/presentation/good_impact_page_test.dart` — “shows aggregates, opted-in name and separate invitation sections”; SQL assertion “impact returns aggregates and explicitly disclosed names only”. **Gap:** the named widget test is not a comprehensive negative scan for ranking UI. |
| AC13 | Milestones grant no worship points | `test/features/share_good/presentation/good_impact_cubit_test.dart` — “milestones follow aggregate thresholds” exercises the pure policy. The real-cubit test “refreshing reached milestones never invokes reward services” registers XP and achievement spies and verifies zero interactions. |
| AC14 | Central context-aware expiration | `supabase/tests/share_good_v1_test.sql` assertions “morning before boundary”, “morning at boundary”, “evening before boundary”, “evening at boundary”, “page expiry”, and “wird expiry”. **Gap:** execution and deployed behavior must be evidenced separately. |
| AC15 | Expired invitations offer fresh start | `test/features/share_good/presentation/invite_preview_cubit_test.dart` — “expired allows fresh reading without participation”; `invite_create_cubit_test.dart` — “expired parent offers a new standalone invitation”. Runtime QA row “Expired and invalid link” remains **UNVERIFIED**. |
| AC16 | Prompt frequency and dismissal | `test/features/share_good/domain/share_prompt_policy_test.dart` — “first completion prompts and the 72 hour boundary is inclusive”, “dismissals double the gap up to eight times”, and “frequent creators and lifetime cap stop hints”; `presentation/share_prompt_cubit_test.dart` — “education appears once and dismissal persists cooldown across screens”. |
| AC17 | Limited, configurable invite notifications | `test/core/services/notification_scheduler_share_good_test.dart` — “permission or setting off prevents scheduling; payload is opaque”, “never schedules after fifteen-minute expiry margin”, and “refresh after the due time does not reissue the reminder”; `test/features/share_good/application/share_good_notification_controller_test.dart` — “clearing the active session cancels its reminder”. Runtime QA row “Reminder delivery and tap” remains **UNVERIFIED**. |
| AC18 | No prohibited social features or web reader | **Gap:** no named comprehensive negative acceptance test was identified for the complete exclusion list. Review the final scope and shipped UI before sign-off; the hosting landing page alone does not establish this criterion. |
| AC19 | Deferred installation on supported platforms | `test/features/share_good/application/incoming_invite_link_service_test.dart` — “referrer is checked once and rejects marketing data”; `test/features/share_good/platform_link_contract_test.dart` — “invite redirect carries the token only inside Play referrer”. These do not prove a real installation. Runtime QA row “Not installed → real Play listing → install → first open” is **UNVERIFIED** on both devices; Android requires end-to-end Play verification. iOS deferred invites are explicitly **unsupported in V1**. |
| AC20 | Automated state/privacy/expiration/completion/chain tests and runtime paths | Mapped named tests appear in AC3, AC8–AC11 and AC14; SQL assertions are in `supabase/tests/share_good_v1_test.sql`. Runtime QA rows cover installed cold/warm/background, duplicate, Play install and share cancellation, all **UNVERIFIED**. The full Flutter suite passed; target-Supabase disposable DB, deployed staging and signed-device evidence remain outstanding. |

## Local verification

Run from the repository root on 2026-11-14:

```powershell
./scripts/verify_v1_release.ps1 -EvidenceDirectory .superpowers/sdd/2026-10-07-talia-share-good-v1-delivery/nov14-release-check-3 -TestConcurrency 8 -TestTimeout 2m
```

| Check | Result |
|---|---|
| Verifier exit | 0; **LOCAL PASS — RELEASE NO-GO** |
| Dependency restore / lockfile | Passed; lockfile unchanged |
| Localization / build generation | Passed; **NO DRIFT** |
| Whole-project analysis | No issues, exit 0 |
| Complete Flutter suite | **6141 passed**, exit 0 |
| Supabase verifier-security PowerShell harness | Passed; does not contact staging |
| Source identity | `1071e6814eaead5d158ee39e1d221907dec04abcc7d5ce4bdb97470e52192b66` |
| Candidate state during run | Uncommitted implementation tree; no frozen signed artifact |

Detailed local evidence is in `.superpowers/sdd/2026-10-07-talia-share-good-v1-delivery/nov14-release-check-3/summary.md` and its numbered logs. Source identity covers the verifier's source allowlist; it does not certify a signed Android artifact.

Earlier runs exposed a stale generated Home mock, Windows generated-file line endings, a missing backup-fixture directory, non-Talia icons, duplicate ARB keys and a repeated expiry notice. These were corrected, and the final full suite supersedes their failing results. Build-runner outputs now have explicit LF checkout rules. Canonical data and generated production schemas have no semantic changes. The verifier recorded Dart 3.13.1 while Flutter's cached version output reports Dart 3.12.2; the initial generation warned about the analyzer language version. No SDK/dependency upgrade was performed.

Account writes for prompt counts, identity preferences and seen fingerprints use the existing barrier. Delayed-storage tests cover accepted and queued writes during account cleanup. Other focused coverage includes consent replay, current-account disclosure, 50-minute expiry warning, Arabic plural forms, invitation card fit/render in both languages, and English 800×600 / Arabic 320×640 reader confirmation/save gates. A scoped source scan found no XP/achievement or social-network dependencies in the Share Good feature.

## Remaining release gates

- B1–B3 and every signed-device QA row remain outstanding. Release defines, fresh/staging/production DB URLs and `psql` were absent; `adb devices -l` returned no devices.
- Signed AAB, association verification, real Play installation, deployed RPC smoke, Android asset/alignment checks and qualified review were **NOT RUN**. Store identity/signing configuration detection alone is not a verified artifact.
- AC1, AC3 and AC4 need the real entrypoint/share checks in the QA matrix; AC11 and AC14 need deployed database verification. AC12 and AC18 still require final UI/scope sign-off against the frozen candidate.
- Keep `ExperienceFeature.shareGood` **off** until the external and signed-runtime gates pass. Android deferred install remains **UNVERIFIED**; iOS deferred invites are **unsupported in V1**.
