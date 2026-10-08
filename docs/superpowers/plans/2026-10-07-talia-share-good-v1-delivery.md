# Talia Share Good / Good Impact V1 — Delivery Plan (reconciled 2026-10-07)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the شارك الخير / أثر الخير worship-invitation loop on Android. Signed-in users invite someone to the exact Quran page, Surah, wird range, or morning/evening adhkar they are reading. Recipients open it from an installed app or after a fresh Play install, complete it as guests, and choose whether to reveal themselves. Inviters see aggregate, non-competitive impact.

**Architecture:** A new `lib/features/share_good/` feature (domain/data/presentation, Cubits, `get_it`) sits on top of a new additive Supabase migration that exposes only `SECURITY INVOKER` public RPC wrappers over `private.*` definer helpers. Existing worship authorities (`QuranReadConfirmationGate` + `QuranPageCubit.confirmRead`, `AzkarCubit`/`AzkarLoaded.allDone`, Khatmah use cases) stay unchanged. Share Good only observes their completion boundaries. Link ingress has two paths: installed recipients come in through verified Android App Links (`app_links`), and fresh installs restore the invite through the Play Install Referrer (`referrer=inv%3D<token>`), which the app already uses for card campaigns. No third-party attribution SDK is added.

**Tech Stack:** Flutter 3.47.1 / Dart 3.12.2, `flutter_bloc`, `get_it`, `go_router`, `dartz`, `equatable`, `supabase_flutter`, `flutter_secure_storage`, `shared_preferences`, `share_plus`, the Dawn social-share stack (`lib/core/widgets/social_share/`), `flutter_local_notifications`, direct `app_links`, and `com.android.installreferrer:installreferrer:2.2` through a small Kotlin method channel.

**Spec:** `docs/superpowers/plans/2026-09-11-talia-share-good-design.md` (product source of truth; not modified).
**Supersedes:** `docs/superpowers/plans/2026-09-11-talia-share-good-v1.md` (reconciled at `3f2b9ad`, never executed). This plan keeps that plan's privacy and backend contracts where they still hold, and changes what HEAD `262e3a38` invalidated. See §2.

---

## 0. الملخص التنفيذي (للمالك)

**الفكرة:** دعوة شخص آخر لنفس العبادة التي تقوم بها (صفحة، سورة، ورد، أذكار الصباح والمساء)، قبل البدء ("تشاركني؟") أو بعد الإتمام ("شارك الخير"). المستلم يفتح الرابط ويقرأ كضيف دون تسجيل، ثم يختار هل يُخبر الداعي أم يحتفظ بإتمامه لنفسه. ويرى الداعي "أثر الخير" كأرقام مجمّعة فقط، بلا ترتيب ولا نقاط ولا ادعاء ثواب.

**التقييم:**
- **الفكرة قوية ومتسقة مع هوية تالية.** المبادئ (العبادة أولًا، لا ادعاء أجر، الخصوصية افتراضيًا، لا منافسة) تتوافق مع سياسة المحتوى وقرارات المنتج الحالية. وهي حلقة نمو طبيعية مبنية على استخدام حقيقي.
- **الجاهزية التقنية عالية.** منظومة بطاقات Dawn للمشاركة مكتملة وفيها QR وروابط حملات، والتوقيع الحقيقي لإصدار أندرويد مُفعّل، والمسارات `/quran/page/:n` و`/quran/surah/:id` و`/azkar/:category` موجودة، وبوابات الإتمام موجودة (`QuranReadConfirmationGate` و`AzkarLoaded.allDone`).
- **الخطة السابقة (2026-09-11-v1) دقيقة لكنها تقادمت وتضخمت:** كانت معلّقة على Dawn (اكتمل الآن)، واعتبرت الاستعادة بعد التثبيت غير ممكنة، وأضافت جدول تحليلات منفصلًا وطابورًا كاملًا للعمليات غير المتصلة. هذه الخطة تقلّص النطاق إلى ما يحقق المواصفة وتقسّمه إلى مراحل قابلة للشحن.
- **أكبر تحسين:** الاستعادة بعد التثبيت (المعيار 19 في المواصفة) ممكنة على أندرويد **بدون SDK خارجي** عبر Play Install Referrer، وهي الآلية نفسها التي تستخدمها بطاقات المشاركة الآن (`utm_campaign`).
- **العوائق الخارجية (قرارات المالك):** (1) نطاق (domain) مملوك لرابط الدعوة مع استضافة ثابتة لملف `assetlinks.json` وتحويل بسيط إلى Play. (2) بصمة SHA-256 لمفتاح التوقيع، ولمفتاح Play App Signing إن كان مفعّلًا. (3) iOS خارج إصدار الروابط في V1، لأن معرّف الحزمة ما زال `com.example.taliaQuran` ولا يوجد تطبيق على App Store.
- **الحكم:** قابلة للتنفيذ بالكامل. تُشحن على 5 مراحل خلف مفتاح ميزة يبقى مغلقًا في الإنتاج حتى تجتاز المرحلة الأخيرة فحص الأجهزة الحقيقية.

---

## 1. Spec evaluation

| Spec area | Verdict | Notes / adjustment |
|---|---|---|
| Principles §2, exclusions §3 | Keep verbatim | They match the content policy, `adult_review_product_decisions`, and the no-leaderboard stance. They become Global Constraints. |
| Quran page / Surah | Keep | Routes `/quran/page/:pageNumber` and `/quran/surah/:surahId` already exist. |
| "Defined wird" | Narrow | Supported: the ordinary daily wird (a page, so it uses the page target) and the active Khatmah daily range (`KhatmahPlan.dailyTargetFor`, a page range). Smart Wird is excluded because its composed item set has no stable target. |
| "Other adhkar collections" | Narrow | `AzkarCategory { morning, evening, general, duas }`: only morning and evening have a counted completion (`allDone`). General and duas are libraries with no completion state. |
| Before/after CTAs, personal/public modes | Keep | Mode is chosen in our sheet before `SharePlus`. |
| Editable share text, immutable link | Keep | The message field is editable and the link line is appended outside it. |
| Installed recipient → preview → exact activity | Keep | App Links plus the `/invite/:token` route. |
| Not installed → deferred restore §12, AC19 | **Upgrade over the old plan** | Android: the hosted redirect sends the user to Play with `referrer=inv%3D<token>`, and the Install Referrer API returns it on first launch. iOS: an explicit, documented limitation (no iOS store app). |
| Guest-first §13 | Keep | Anonymous Supabase Auth stays disabled. Guests use `anon`-executable RPCs keyed by an installation-scoped participant key. These would be the **first** `anon` grants in the schema, so the contract verifier must pin them exactly. |
| Identity modes §14 | Keep | Full name, first name, display name, anonymous. No photos, and `avatarUrl` is ignored. |
| Completion privacy §15 | Keep | Completion is always private first. Disclosure is a separate, authenticated, explicit action. |
| Smart expiration §17 | Keep, values decided (D6) | Computed by the server at creation and returned as `expiresAt`. |
| Good Chain §18, Good Impact §19, milestones §20 | Keep | Downstream reach is aggregate only. Milestones are labels and never touch `XpService` or `AchievementService`. |
| Notifications §21 | Narrow (D9) | No push stack exists. The inviter gets an in-app "new" indicator. The recipient gets at most one local reminder. |
| Analytics §23, §28 | Simplify (D5) | Metrics are derived from the invite/participation tables through a service-role-only view. Prompt-dismissal and notification-opt-out rates stay device-local and are not collected. |
| Account conversion §24 | Keep | A dismissible CTA after completion, required only for disclosure, chain continuation, and impact history. |
| Kids/guardian audience | **Gap in spec** (D8) | Child profiles (`profile.isChild`) never create invites, never disclose, and never call Share Good RPCs. |

## 2. What changed since the superseded plan (HEAD `262e3a38`)

| Superseded-plan assumption | Reality now | Effect |
|---|---|---|
| Dawn share redesign not landed, so Task 7 was blocked | Landed (`c07c83b6`…`b04f4e90`): `share_card_links.dart`, `share_signature_bar.dart`, palettes, moods, off-screen rasterizer | Unblocked. The invitation card is a Dawn category, and the QR encodes the invite URL. |
| Android release used debug signing | `build.gradle.kts` signs release with a keystore from `key.properties` | Android App Links can be verified once the SHA-256 fingerprints are supplied. |
| Deferred restoration "not advertised" | Share cards already ride Play's `referrer` (`ShareCardLinks.forCategory`) | Deferred restoration on Android is in scope (Task 6). |
| Separate `share_good_analytics_events` table + RPC | No analytics consumer exists | Dropped (D5). |
| General mutation outbox | Participation status is monotonic | Replaced by one "highest pending status" per session (D7). |
| `talia_quran` uncommitted overlapping work | Tree is clean at `262e3a38` | No carry-forward needed. Still format only edited files. |
| Icon set | `TaliaIcons` replaced Material icons (`1da5e2d0`) | New UI uses `TaliaIcons` only. |

## 3. Decisions (delegated to Claude; rationale recorded)

| # | Decision | Why |
|---|---|---|
| D1 | Android-only link release for V1. iOS ingress code (`app_links`) still compiles, but iOS association and verification are out of scope. | No production iOS bundle ID and no App Store listing exist. |
| D2 | Link format `https://<SHARE_GOOD_LINK_HOST>/i/<token>`. The host comes from `--dart-define=SHARE_GOOD_LINK_HOST`. If it is empty, creation is unavailable (fails closed). | Mirrors `SupabaseConfig`, and no domain is hard-coded before the owner provides one. |
| D3 | The redirect host is static only (`_redirects` + `/.well-known/assetlinks.json` + a one-paragraph `index.html`). The sources live in `hosting/share_good_links/`. | The spec allows "a minimal technical redirect" but no web product. Static hosting resolves nothing server-side, so the token stays opaque. |
| D4 | Install Referrer through a ~60-line Kotlin channel using `com.android.installreferrer:installreferrer:2.2`, not a pub plugin. | The project already keeps native Kotlin with JVM tests. One fewer third-party Dart dependency. |
| D5 | No analytics table. `public.share_good_metrics_v1` is a view granted to `service_role` only. | YAGNI. It covers every §28 metric that is server-observable. The rest stay local. |
| D6 | Expiry: morning adhkar → the first local 15:30 after creation. Evening adhkar → the first local 04:00 after creation. These are the `AzkarTimeContext.resolvePeriod` boundaries. Wird range → creation + 3 days. Page/Surah → creation + 7 days. Timezone is the creator's IANA zone, and an unknown zone rejects creation. | The spec asks for "several days" for reading targets. Adhkar follow the app's existing period boundaries. |
| D7 | Offline: the first resolve needs the network. After that, a cached safe snapshot opens offline, and the session stores `pendingStatus` (the highest unsynced status), replayed on resume or next open. | Monotonic states make one slot sufficient. |
| D8 | Child profiles: creation entry points are hidden. An opened invite shows "invitations aren't available in the kids space" and offers the activity locally without counting, if the kids route guard allows it. | Children's privacy. The spec is silent on this. |
| D9 | No push. Named acknowledgements and milestones raise a "new" dot on the Good Impact entry. This comes from `get_share_good_impact_v1` on Settings/Home resume, throttled to once per 6 h. | The spec allows limited notifications and none are required. A push stack is a separate privacy design. |
| D10 | Restored-complete adhkar: if today's collection is already `allDone` when an invited session starts, show "أتممتها اليوم" with an explicit confirm. That counts as a completion. Without the tap, nothing counts. | The spec counts "confirmed completion", and silently counting would be inference. |
| D11 | Identity defaults: personal → first name when a real name exists, otherwise anonymous. Public → anonymous. Fallback strings (`مستخدم`, `مستخدم تالية`, empty) count as no name. | §14 privacy defaults. |
| D12 | Feature flag `ShareGoodFeatureFlags.isEnabled` = `--dart-define=SHARE_GOOD_ENABLED=true` && `SupabaseConfig.isConfigured` && link host non-empty. It stays off in production until the Task 16 gate passes. | Ship code incrementally without exposing an unverified link flow. |

## Global Constraints

- Mobile only: no web reader and no general web app. The redirect host serves exactly `_redirects`, `/.well-known/assetlinks.json`, and `index.html`.
- Worship first: no blocking modal before or during worship. Share entry points never compete visually with reading controls.
- Never calculate, promise, or imply religious reward. Banned copy includes "ضاعف ثوابك", "أجر", "حسنات", numeric reward, and "better than X%".
- No friends, contacts, search, feed, chat, leaderboard, ranking, profile photos, live rooms, or chain trees.
- Guests resolve, open, start, and complete without auth or onboarding. Creating, disclosing, continuing a chain, and impact history require auth.
- Invite links, the referrer, notification payloads, and server rows hold activity identifiers only: never Quran or adhkar text, names (outside identity/disclosure snapshots), emails, phones, or user IDs.
- Quran/adhkar display labels come from the existing bundled data (`surahs.json`, the azkar category labels). No religious text is generated. (`docs/TALIA_ISLAMIC_CONTENT_SOURCES_POLICY.md`)
- Unchanged authorities: `quran_page_cubit.dart`, `quran_read_confirmation_gate.dart`, `azkar_cubit.dart`, `azkar_completion_store.dart`, `khatmah_plan.dart`, `khatmah_cubit.dart`, `achievement_service.dart`, `xp_service.dart`, `cloud_sync_queue.dart`, `assets/data/*`.
- Expiry is computed only by `private.share_good_expires_at_v1`. Clients display the returned `expiresAt`.
- New copy goes in `app_ar.arb` and `app_en.arb` (the Arabic file is the template). It must work in RTL and LTR, carry accessibility labels, and have 48 dp targets. Icons come from `TaliaIcons`.
- `dart format` only the files you edited. Before running `flutter test`, set `TEMP`/`TMP` to a `D:` path and never run two test runs at once. (memory: `format_only_edited_files`, `c_drive_full_flutter_temp`)

## Review Focus

1. **Morning adhkar invite created minutes before 15:30.** The sender should be warned before sharing ("تنتهي الدعوة خلال N دقيقة"). A recipient who opens it after expiry gets the expired view with "ابدأ الآن" as an uncounted fresh start, not an error. Tests: Task 10 `warns when fewer than 60 minutes remain`; Task 7 `expired invite starts fresh activity without participation`.
2. **First-ever launch arriving through an invite (fresh install or deferred referrer).** The invite must reach the Invite Preview, not onboarding. Onboarding stays pending for the next ordinary launch. Test: Task 6 `validated pending invite bypasses onboarding once`.
3. **The same invite delivered twice** (the `app_links` initial link plus a re-delivery on activity recreation, or a referrer plus an App Link). Expect exactly one preview push and one `open` call. Test: Task 6 `duplicate deliveries of one token navigate once`.
4. **Adhkar already completed today when the invited session starts.** Nothing counts until the explicit "أتممتها اليوم" tap (D10). Test: Task 9 `restored allDone does not report completion without confirmation`.
5. **Account switch, or sign-in, between private completion and disclosure.** Disclosure uses whoever is signed in at the explicit tap, and nothing auto-discloses on an auth change. Test: Task 9 `auth change does not disclose; disclosure uses current account at tap`.

---

## 4. Locked contracts

### 4.1 Target JSON (v1)

`InviteActivityTarget.fromJson` accepts exactly these shapes and rejects extra or missing keys, non-integers, and out-of-range values:

```json
{"v":1,"type":"quran_page","page":42}                         // 1..604
{"v":1,"type":"quran_surah","surah_id":18}                    // 1..114
{"v":1,"type":"quran_wird","start_page":120,"end_page":124}   // 1<=s<=e<=604, e-s<=19
{"v":1,"type":"azkar_collection","category":"morning"}        // morning|evening
```

The server validates the same rules (`private.share_good_valid_target_v1`).

### 4.2 Domain types (Task 1 defines; everyone else consumes)

```dart
sealed class InviteActivityTarget extends Equatable { Map<String, Object> toJson(); static InviteActivityTarget fromJson(Object? json); /* throws FormatException */ }
final class QuranPageInviteTarget extends InviteActivityTarget { const QuranPageInviteTarget(this.pageNumber); final int pageNumber; }
final class QuranSurahInviteTarget extends InviteActivityTarget { const QuranSurahInviteTarget(this.surahId); final int surahId; }
final class QuranWirdInviteTarget extends InviteActivityTarget { const QuranWirdInviteTarget(this.startPage, this.endPage); final int startPage, endPage; }
final class AzkarCollectionInviteTarget extends InviteActivityTarget { const AzkarCollectionInviteTarget(this.category); final AzkarCategory category; }

enum InviteMode { personal, public }
enum InviteMoment { beforeActivity, afterActivity }
enum InviteIdentityMode { fullName, firstName, displayName, anonymous }
enum InviteLifecycleStatus { active, expired, revoked }
enum InviteParticipationStatus { opened, started, completedPrivate, completedSharedIdentity, continuedAsNewInvite }
  // bool canAdvanceTo(InviteParticipationStatus next) — strictly forward by index, except
  // completedPrivate -> continuedAsNewInvite and completedSharedIdentity -> continuedAsNewInvite are allowed,
  // completedPrivate -> completedSharedIdentity allowed, nothing goes backwards.

final class InviterIdentity extends Equatable { const InviterIdentity({required this.mode, this.visibleName}); final InviteIdentityMode mode; final String? visibleName; } // anonymous => visibleName == null
final class InviteContext extends Equatable { InviteActivityTarget target; InviteMoment moment; InviteMode mode; InviterIdentity identity; } // lineage only via continueChain
final class CreatedInvite extends Equatable { String token; Uri shareUrl; InviteContext context; DateTime createdAt; DateTime expiresAt; }
final class ResolvedInvite extends Equatable { String token; InviteActivityTarget target; InviteMoment moment; InviteMode mode; InviterIdentity inviter; InviteLifecycleStatus status; DateTime expiresAt; }
final class InviteSession extends Equatable { String token; ResolvedInvite snapshot; InviteParticipationStatus? serverStatus; InviteParticipationStatus? pendingStatus; bool awaitingConsent; }
final class InviteImpactSummary extends Equatable { String token; InviteActivityTarget target; InviteLifecycleStatus status; DateTime expiresAt; int opens, starts, completions; }
final class NamedAcknowledgement extends Equatable { InviteActivityTarget target; String visibleName; DateTime completedAt; }
final class GoodImpact extends Equatable { List<InviteImpactSummary> invites; int responses; int completions; int downstreamReach; List<NamedAcknowledgement> acknowledgements; DateTime fetchedAt; }
enum GoodImpactMilestone { firstChainStarted, fiveReach, tenResponses, twentyFiveReach }
enum ShareGoodFailure { featureUnavailable, network, invalidInvite, expired, rateLimited, authRequired, notEligible }
```

### 4.3 Backend (Task 3)

Tables are RLS-enabled, with every privilege revoked from `PUBLIC`, `anon`, and `authenticated`:

- `share_good_invites(id uuid pk, token_hash text unique, creator_user_id uuid null references auth.users on delete set null, mode, moment, identity_mode, target jsonb, parent_invite_id uuid null references share_good_invites, root_invite_id uuid not null, timezone text, created_at, expires_at, revoked_at null)`
- `share_good_invite_identities(invite_id pk/fk cascade, user_id fk auth.users on delete cascade, visible_name text not null check (char_length between 1 and 40))`
- `share_good_participations(id uuid pk, invite_id fk, participant_key_hash text, opened_as_guest bool, status text, opened_at, started_at, completed_at, unique(invite_id, participant_key_hash))`
- `share_good_completion_disclosures(participation_id pk/fk cascade, user_id fk auth.users on delete cascade, visible_name text not null)`
- `share_good_rate_limits(scope_hash text, action text, window_start timestamptz, attempts int, primary key(scope_hash, action, window_start))`
- View `share_good_metrics_v1` (daily counts of created / opened / started / completed / disclosed / continued / chain depth histogram), granted to `service_role` only.

Public RPCs (`SECURITY INVOKER`, `set search_path = ''`; each calls one `private.*` `SECURITY DEFINER` helper):

```text
create_share_good_invite_v1(p_target jsonb, p_moment text, p_mode text, p_identity_mode text, p_visible_name text, p_timezone text) -> jsonb   authenticated
create_share_good_chain_invite_v1(p_parent_token text, p_participant_key text, <same 6 args>) -> jsonb                                         authenticated
resolve_share_good_invite_v1(p_token text, p_participant_key text) -> jsonb                                                                     anon, authenticated
advance_share_good_participation_v1(p_token text, p_participant_key text, p_status text) -> jsonb   -- opened|started|completed_private        anon, authenticated
disclose_share_good_completion_v1(p_token text, p_participant_key text, p_visible_name text) -> jsonb                                           authenticated
get_share_good_impact_v1() -> jsonb                                                                                                            authenticated
```

Rules:
- Tokens are 32 random bytes encoded as base64url without padding (43 characters). They are returned once, and only `lower(encode(sha256(...),'hex'))` is stored. Participant keys are hashed the same way.
- Caps: 30 creations per user per rolling 24 h. 60 resolves per participant key per hour. 20 advances per (invite, key) per day. A breach returns `{"error":"rate_limited"}` and never raises.
- Advancing after `expires_at` or `revoked_at` → `{"error":"expired"}`. A repeated or backward advance → returns the current status (idempotent).
- Disclosure requires `auth.uid()` and a completed participation. It upserts the disclosure row and sets the status to `completed_shared_identity`.
- A chain needs the parent participation completed under the same participant key. It sets `parent_invite_id` and `root_invite_id` from the parent and sets the parent participation to `continued_as_new_invite`.
- The resolve response carries `target, moment, mode, inviter{mode, visible_name?}, status, expires_at, participation_status?`. It never includes IDs, hashes, or creator UUIDs.
- Impact returns the caller's own invites (active, plus those expired in the last 30 days), direct counts, named acknowledgements for direct invites only, and `downstream_reach` = distinct completed participations in invites whose `root_invite_id` is one of the caller's roots, excluding direct invites. It returns no tree, depth, or hashes.
- Account deletion (`public.delete_current_user()`): identities and disclosures cascade away, invites keep `creator_user_id = null`, and descendants survive.

### 4.4 Link and referrer

- Share URL: `https://$SHARE_GOOD_LINK_HOST/i/<token>`. The parser accepts exactly that host, path `^/i/[A-Za-z0-9_-]{43}$`, no query or fragment, and `https` only.
- Redirect: `/i/:token → https://play.google.com/store/apps/details?id=com.talia.quran&referrer=inv%3D:token` (302).
- Referrer parse: `inv=<43-char token>` → a pending invite. Any other referrer (for example `utm_source=tc&...`) → ignored. The referrer is read once per install, and the flag is stored in prefs `share_good_referrer_checked`.

---

## 5. File map

```text
lib/features/share_good/
  share_good_config.dart                         # ShareGoodFeatureFlags, link host, buildShareUrl/parseShareUri
  domain/entities/{invite_activity_target,invite_types,good_impact}.dart
  domain/repositories/share_good_repository.dart
  domain/services/{inviter_identity_resolver,good_impact_milestone_policy,share_prompt_policy,invite_target_labeler}.dart
  data/datasources/{share_good_local_store,share_good_remote_datasource}.dart
  data/repositories/share_good_repository_impl.dart
  application/{incoming_invite_link_service,install_referrer_channel,active_invite_sessions}.dart
  presentation/cubits/{invite_preview_cubit,invite_create_cubit,good_impact_cubit}.dart
  presentation/pages/{invite_preview_page,good_impact_page}.dart
  presentation/widgets/{share_good_action,invite_mode_sheet,invite_activity_banner,invite_completion_sheet,share_good_settings_tiles}.dart
android/app/src/main/kotlin/com/talia/quran/referrer/InstallReferrerPlugin.kt (+ JVM test)
hosting/share_good_links/{_redirects,index.html,.well-known/assetlinks.json.template,README.md}
supabase/migrations/<generated>_share_good_v1.sql
test/features/share_good/**  test/supabase/share_good_v1_contract_test.dart  test/integration/share_good_*_test.dart
qa/share_good_runtime_qa.md
```

Modified: `pubspec.yaml` (app_links direct; `sdk: ^3.12.0`), `android/app/build.gradle.kts` (installreferrer dep), `AndroidManifest.xml` (App Link filter), `MainActivity.kt` (register channel), `lib/app.dart`, `lib/core/router/{app_router,launch_destination}.dart`, `lib/core/di/injection.dart`, `lib/core/l10n/app_{ar,en}.arb`, `social_share_model.dart`, `social_share_sheet.dart`, `share_card_shell.dart`, `share_card_template_resolver.dart`, `quran_reader_page.dart`, `reader_overflow_sheet.dart`, `azkar_category_page.dart`, `khatmah_dashboard_page.dart`, `daily_wird_card.dart`, `settings_hub_body.dart`, `settings_notification_tiles.dart`, `notification_scheduler.dart`, `scripts/verify_supabase_contract.ps1`, `build.yaml` (only if a task adds `@GenerateMocks`; prefer `mocktail`).

---

## Phase A — Foundations (no UI)

### Task 1: Domain types and target codec

**Files:**
- Create: `lib/features/share_good/domain/entities/invite_activity_target.dart`, `invite_types.dart`, `good_impact.dart`
- Create: `lib/features/share_good/domain/services/invite_target_labeler.dart`
- Test: `test/features/share_good/domain/invite_activity_target_test.dart`, `invite_types_test.dart`, `invite_target_labeler_test.dart`

**Interfaces:**
- Produces: every type in §4.2. `InviteTargetLabeler(QuranRepository)` with `Future<Either<ShareGoodFailure, InviteTargetLabel>> label(InviteActivityTarget, {required bool arabic})`, where `InviteTargetLabel { String title; int startPage; int endPage; }` is resolved from bundled data. Azkar labels come from existing l10n keys.

- [ ] **Step 1: Write failing tests**
  - `round-trips all four v1 shapes` → `fromJson(t.toJson()) == t` for each sample in §4.1.
  - `rejects malformed targets` → `throwsFormatException` for `{"v":2,...}`, extra key `"text"`, `page: 0`, `page: 605`, `page: 4.0`, `surah_id: 115`, wird `start>end`, wird span 20 pages, `category: "general"`, a non-map value.
  - `participation status only moves forward` → `opened.canAdvanceTo(started)` is true; `started.canAdvanceTo(opened)` is false; `completedPrivate.canAdvanceTo(completedSharedIdentity)` is true; `completedSharedIdentity.canAdvanceTo(completedPrivate)` is false; `completedPrivate.canAdvanceTo(continuedAsNewInvite)` is true.
  - `anonymous identity carries no name` → the `InviterIdentity(mode: anonymous, visibleName: 'x')` constructor asserts or throws.
  - `labeler resolves surah 18 pages from QuranRepository and never returns ayah text` → title equals the surah's Arabic name from a fake repository; start and end pages match the fake `SurahDetail`.
- [ ] **Step 2: Run** `flutter test test/features/share_good/domain`. Expected: FAIL (missing files).
- [ ] **Step 3: Implement** the types as `Equatable`. `fromJson` checks the exact key set per type.
- [ ] **Step 4: Run** the same command. Expected: PASS.
- [ ] **Step 5: Commit** `feat(share-good): add invite domain types and target codec`

### Task 2: Local store (participant key, sessions, identity prefs, prompt state)

**Files:**
- Create: `lib/features/share_good/data/datasources/share_good_local_store.dart`
- Test: `test/features/share_good/data/share_good_local_store_test.dart`

**Interfaces:**
- Consumes: Task 1 types.
- Produces: `ShareGoodLocalStore(FlutterSecureStorage, SharedPreferences)` with:
  - `Future<String> participantKey()`: 32 random bytes as base64url, created once, kept in secure storage under `share_good_participant_key_v1`. **Installation-scoped**: not cleared by `AccountDataReset`.
  - `Future<InviteSession?> session(String token)`, `Future<void> saveSession(InviteSession)`, `Future<List<InviteSession>> sessionsWithPending()`. Snapshots are stored as JSON in secure storage under `share_good_session_v1_<sha256(token)>`, with an index list, capped at the 20 most recent.
  - `Future<String?> takePendingIncomingToken()`, `Future<void> setPendingIncomingToken(String)` (prefs `share_good_pending_token_v1`).
  - `InviteIdentityMode personalIdentityPreference()` / `setPersonalIdentityPreference` (prefs; default `firstName`).
  - `SharePromptState promptState()` / `savePromptState` (`{shownCount, dismissCount, lastShownAt, educationSeen, invitesCreated}`).

- [ ] **Step 1: Failing tests** (with `FlutterSecureStorage.setMockInitialValues({})` and `SharedPreferences.setMockInitialValues({})`):
  - `participant key is stable and 43 chars`
  - `session round-trip preserves pendingStatus and awaitingConsent`
  - `session store keeps only the 20 most recent`
  - `pending incoming token is taken once` → the second `take` returns null.
  - `stored session JSON contains no visible text beyond inviter visibleName` → the serialized JSON has no key other than the allow-list.
- [ ] **Step 2: Run** `flutter test test/features/share_good/data/share_good_local_store_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(share-good): add installation-scoped local invite store`

### Task 3: Supabase migration, SQL tests, contract verification

**Files:**
- Create: `supabase/migrations/<generated>_share_good_v1.sql` (generate the filename with `supabase migration new share_good_v1`; never backdate it)
- Create: `test/supabase/share_good_v1_contract_test.dart` (static migration assertions, in the style of `review_events_contract_test.dart`)
- Modify: `scripts/verify_supabase_contract.ps1` (functions, grants, and the anon allow-list)
- Modify: `test/supabase/migration_history_test.dart` (only if it enumerates migrations)

**Interfaces:**
- Produces: exactly the tables, view, RPCs, grants, and JSON shapes in §4.3. Task 4 depends on these RPC names and argument names.

- [ ] **Step 1: Failing static contract test.** Assertions on the normalized migration text:
  - `create table if not exists public.share_good_invites` … for each table, plus `enable row level security` on each.
  - `revoke all on table public.share_good_` appears for every table, and there is no `grant select|insert|update|delete on table public.share_good_` to `anon` or `authenticated`.
  - Every public function contains `security invoker` and `set search_path = ''`. Every `private.share_good_` function contains `security definer` and `set search_path = ''`.
  - The anon allow-list is exactly `resolve_share_good_invite_v1` and `advance_share_good_participation_v1`; the test parses every `grant execute … to anon`.
  - `on delete set null` is used for `creator_user_id`, and `on delete cascade` for identity and disclosure `user_id`.
  - `advance_share_good_participation_v1` rejects `completed_shared_identity` and `continued_as_new_invite` as `p_status`.
  - `share_good_metrics_v1` is granted to `service_role` only.
  - `supabase/config.toml` `schemas` does not contain `private`.
- [ ] **Step 2: Run** `flutter test test/supabase/share_good_v1_contract_test.dart`. Expected: FAIL.
- [ ] **Step 3: Write the migration.** The expiry helper `private.share_good_expires_at_v1(target jsonb, created_at timestamptz, tz text)` implements D6. Reject `tz` not in `pg_timezone_names`. Morning: `(date_trunc('day', created_at at time zone tz) + interval '15:30')`, plus a day if not strictly after creation, then back to timestamptz. Evening: the same with `04:00`.
- [ ] **Step 4: Write behavioural SQL** in `supabase/tests/share_good_v1_test.sql`, run against a migrated local DB. It covers: expiry boundaries (morning created 15:29 → 15:30 same day; 15:31 → next day 15:30; evening created 03:59 → 04:00 same day), the idempotent advance, an expired advance, the rate limit at 61 resolves, disclosure without auth rejected, and the `A → B → C` deletion of B keeping A's `downstream_reach`.
- [ ] **Step 5: Run** `flutter test test/supabase/share_good_v1_contract_test.dart` (expected: PASS), then `./scripts/verify_supabase_migrations.ps1` (expected: exit 0). Run the SQL tests against a local stack if one is available. If not, record "not run" in the task summary. Never apply to a remote project.
- [ ] **Step 6: Commit** `feat(share-good): add invite schema, private helpers and anon-safe RPCs`

### Task 4: Remote datasource, repository, DI, feature flag

**Files:**
- Create: `lib/features/share_good/share_good_config.dart`, `domain/repositories/share_good_repository.dart`, `data/datasources/share_good_remote_datasource.dart`, `data/repositories/share_good_repository_impl.dart`, `domain/services/inviter_identity_resolver.dart`
- Modify: `lib/core/di/injection.dart`
- Test: `test/features/share_good/data/share_good_repository_impl_test.dart`, `test/features/share_good/share_good_config_test.dart`, `test/features/share_good/domain/inviter_identity_resolver_test.dart`

**Interfaces:**
- Consumes: Tasks 1–3.
- Produces:
  - `ShareGoodFeatureFlags.isEnabled` (D12). `ShareGoodLinks.build(String token) -> Uri`. `ShareGoodLinks.parse(Uri) -> String?` (token or null, per §4.4). `ShareGoodLinks.parseReferrer(String) -> String?`.
  - `abstract class ShareGoodRepository`:
    - `Future<Either<ShareGoodFailure, CreatedInvite>> create(InviteContext ctx)` (sends the device IANA zone obtained the same way `TaliaNotificationService` resolves it; extract that lookup into a shared function rather than duplicating it)
    - `Future<Either<ShareGoodFailure, CreatedInvite>> continueChain(String parentToken, InviteContext ctx)`
    - `Future<Either<ShareGoodFailure, InviteSession>> resolve(String token)` (caches the snapshot; offline with a cached snapshot → Right(cached))
    - `Future<Either<ShareGoodFailure, InviteSession>> advance(String token, InviteParticipationStatus status)` (sets `pendingStatus` first; clears it on server ack; a network failure → Right(session with pending))
    - `Future<Either<ShareGoodFailure, InviteSession>> disclose(String token, String visibleName)`
    - `Future<Either<ShareGoodFailure, GoodImpact>> impact()`
    - `Future<void> replayPending()`
  - `InviterIdentityResolver.resolve(InviteIdentityMode, {String? profileName, String? authDisplayName}) -> InviterIdentity` (D11 fallback rules; first name = the first whitespace token; trimmed; max 40 characters).
- DI: register the store, datasource, and repository as lazy singletons. Register the Cubits from later tasks as factories in their own tasks.

- [ ] **Step 1: Failing tests** (mocktail `SupabaseClient`/`PostgrestFilterBuilder` fakes, matching the neighbouring repository tests):
  - `PGRST202 or a missing-function error maps to featureUnavailable`
  - `{"error":"expired"} maps to ShareGoodFailure.expired`, and the same for `rate_limited` and `invalid`
  - `create sends target JSON, the IANA timezone and never sends text fields`
  - `advance offline keeps pendingStatus and replayPending flushes in order then clears`
  - `resolve offline returns cached snapshot; offline without cache returns network`
  - `parse accepts only https host /i/<43 chars>` (cases: http, other host, extra path, a query string, 42 characters)
  - `parseReferrer extracts inv token and ignores utm referrers`
  - `identity resolver treats مستخدم تالية as no name and falls back to anonymous`
  - `feature disabled when link host empty`
- [ ] **Step 2: Run** `flutter test test/features/share_good`. Expected: FAIL.
- [ ] **Step 3: Implement**, then add the DI registrations.
- [ ] **Step 4: Run** `flutter test test/features/share_good` and `flutter analyze`. Expected: PASS, and no issues.
- [ ] **Step 5: Commit** `feat(share-good): add repository, link codec and feature flag`

---

## Phase B — Recipient path

### Task 5: Invite Preview page, cubit, route and states

**Files:**
- Create: `presentation/cubits/invite_preview_cubit.dart`, `presentation/pages/invite_preview_page.dart`, `application/active_invite_sessions.dart`
- Modify: `lib/core/router/app_router.dart` (`AppRoutes.invite = '/invite/:token'`, a public route exempt from the auth redirect and the onboarding redirect), `app_ar.arb`, `app_en.arb`
- Test: `test/features/share_good/presentation/invite_preview_cubit_test.dart`, `invite_preview_page_test.dart`, `test/core/router/app_router_route_policy_test.dart` (extend)

**Interfaces:**
- Consumes: `ShareGoodRepository.resolve/advance`, `InviteTargetLabeler`.
- Produces:
  - `InvitePreviewCubit` with states `Loading | Ready(session, label) | Expired(label?, target) | Invalid | Unavailable(target?) | Offline | KidsBlocked(target)` and methods `load(String token)`, `startActivity() -> String route`, `startFresh() -> String route`.
  - `ActiveInviteSessions` (singleton): `void activate(InviteSession)`, `InviteSession? forTarget(InviteActivityTarget)`, `void clear(String token)`, `Stream<InviteSession> changes`. It restores sessions with `started` and no completion from the local store on app start.
  - Routes for targets: page → `/quran/page/<n>`, Surah → `/quran/surah/<id>`, wird → `/quran/page/<start>`, adhkar → `/azkar/<category>`.

Copy (ARB keys, Arabic shown): `inviteFromNamed` "{name} يدعوك", `inviteFromAnonymous` "دعوة من أحد مستخدمي تالية", `inviteStartNow` "ابدأ الآن", `inviteExpiredTitle` "انتهت مدة هذه الدعوة", `inviteExpiredBody` "يمكنك أن تبدأ القراءة الآن لنفسك، ولن تُحتسب ضمن الدعوة.", `inviteInvalid` "تعذّر فتح هذه الدعوة", `inviteOfflineRetry` "تحتاج الدعوة إلى اتصال لفتحها أول مرة", `inviteKidsBlocked` "الدعوات غير متاحة في مساحة الأطفال", `inviteExpiresIn` "تنتهي خلال {duration}". English equivalents go in `app_en.arb`.

- [ ] **Step 1: Failing tests:**
  - `active invite → Ready and records opened once` → `advance(opened)` is called exactly once across two `load` calls.
  - `startActivity records started and activates the session` → it returns `/quran/surah/18`, and `ActiveInviteSessions.forTarget` is non-null.
  - `expired invite starts fresh activity without participation` → `startFresh` returns the route; `advance` is never called; the session is not activated.
  - `invalid token shows Invalid and never fabricates inviter or target`
  - `offline without cache → Offline with retry, pending token retained`
  - `child profile → KidsBlocked and zero repository mutations`
  - `labeler failure (unavailable surah) → Unavailable with safe hub route`
  - Widget: `preview primary action is ابدأ الآن and no sign-in control is present`. Golden-free semantic checks on RTL and LTR. Each button has a semantics label.
  - Route policy: `/invite/:token is reachable signed-out and first-time`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement**, then run `flutter gen-l10n`.
- [ ] **Step 4: Run** the tests, then `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(share-good): add guest invite preview and public route`

### Task 6: Link ingress — App Links, Install Referrer, startup precedence

**Files:**
- Create: `application/incoming_invite_link_service.dart`, `application/install_referrer_channel.dart`, `android/app/src/main/kotlin/com/talia/quran/referrer/InstallReferrerPlugin.kt`, `android/app/src/test/kotlin/com/talia/quran/referrer/InstallReferrerParserTest.kt`
- Modify: `pubspec.yaml` (`app_links` direct at the version already locked; `environment.sdk: ^3.12.0`), `android/app/build.gradle.kts` (`implementation("com.android.installreferrer:installreferrer:2.2")`), `AndroidManifest.xml` (on `MainActivity`: `<intent-filter android:autoVerify="true">` VIEW/DEFAULT/BROWSABLE, `https`, host `${shareGoodLinkHost}` via `manifestPlaceholders`, `pathPrefix="/i/"`), `MainActivity.kt`, `lib/app.dart`, `lib/core/router/launch_destination.dart`, `lib/core/router/app_router.dart` (onboarding redirect yields to `/invite/*`)
- Test: `test/features/share_good/application/incoming_invite_link_service_test.dart`, `test/app_launch_navigation_test.dart` (extend or create), `test/core/router/launch_destination_test.dart` (extend)

**Interfaces:**
- Consumes: `ShareGoodLinks.parse/parseReferrer`, `ShareGoodLocalStore.set/takePendingIncomingToken`.
- Produces:
  - `InstallReferrerChannel.readOnce() -> Future<String?>`: method channel `talia/install_referrer`, method `getReferrer`. Kotlin returns `installReferrer` or null, and returns null on `FEATURE_NOT_SUPPORTED`, `SERVICE_UNAVAILABLE`, or after a 3 s timeout.
  - `IncomingInviteLinkService(AppLinks, InstallReferrerChannel, ShareGoodLocalStore, SharedPreferences)`: `Future<String?> initialToken()` (initial App Link, else a referrer when `share_good_referrer_checked` is unset, after which it sets the flag), and `Stream<String> tokens` (warm links). It deduplicates the same token within one process and drops tokens while the flag is disabled.
  - `LaunchDestination.resolve(..., String? inviteToken)`: an invite token wins over onboarding and over the notification payload. Password-recovery handling stays first.
- `manifestPlaceholders["shareGoodLinkHost"]` is read from the Gradle property `shareGoodLinkHost` (`-PshareGoodLinkHost=`). It defaults to `invalid.localhost`, so an unconfigured build never claims a real host.

- [ ] **Step 1: Failing tests:**
  - `validated pending invite bypasses onboarding once` → with first-time true, an invite token gives `/invite/<t>`. The next launch with no token gives `/onboarding`.
  - `duplicate deliveries of one token navigate once` → initial plus stream re-delivery of the same token gives one `router.go`.
  - `referrer read only on first launch and ignored for utm` → the second `initialToken` does not call the channel; `utm_source=tc` gives null.
  - `invite token does not override password recovery deep link`
  - `disabled feature ignores links and keeps ordinary startup`
  - Kotlin: `parses inv token`, `ignores utm referrer`, `rejects 42-char token`.
- [ ] **Step 2: Run** `flutter test test/features/share_good/application test/core/router` and `cd android && ./gradlew :app:testDebugUnitTest`. Expected: FAIL.
- [ ] **Step 3: Implement.** Instantiate `AppLinks` early in `TaliaApp` init, next to the notification launch capture. Route through the existing `_applyLaunchNavigation`. Do not add a second navigation writer.
- [ ] **Step 4: Run** both suites, then `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Manual smoke (debug):** `adb shell am start -a android.intent.action.VIEW -d "https://invalid.localhost/i/<43 chars>" com.talia.quran` with the dev host placeholder. Expected: the preview opens, cold and warm.
- [ ] **Step 6: Commit** `feat(share-good): add App Link and install-referrer invite ingress`

### Task 7: Quran completion adapter (page, Surah, wird range)

**Files:**
- Create: `presentation/widgets/invite_activity_banner.dart`
- Modify: `lib/features/quran/presentation/pages/quran_reader_page.dart` (mount the banner when `ActiveInviteSessions.forTarget` matches the current page range)
- Test: `test/features/share_good/presentation/quran_invite_completion_test.dart`, plus a regression run of `test/features/quran/`

**Interfaces:**
- Consumes: `ActiveInviteSessions`, `InviteTargetLabel.endPage`, the reader's existing `_readConfirmationGate.hasConfirmed(page)`.
- Produces: `InviteActivityBanner({required InviteSession session, required bool canComplete, required VoidCallback onComplete})`. It is a slim bar below the reader controls with label "دعوة: {activity}" and the button "أتممت القراءة". `canComplete` is true when the reader is on `endPage` **and** the gate has confirmed that page. `onComplete` calls `advance(completedPrivate)` and then opens the Task 9 completion sheet.

- [ ] **Step 1: Failing widget tests** (fake repository, fake `QuranPageCubit` state):
  - `banner hidden when no active invite for this page`
  - `complete disabled until the target end page is gate-confirmed`
  - `completing a surah invite calls advance(completedPrivate) once and does not call confirmRead again` → the spy on the cubit shows exactly the gate's own call count.
  - `expired invite mid-session shows the expired notice and keeps ordinary progress` (`advance` returns `expired` → the banner turns to the notice; no exception).
  - `reader without invite behaves exactly as before` (existing reader tests pass unchanged).
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Use no new progress writes. The banner reads the gate; it never drives it.
- [ ] **Step 4: Run** `flutter test test/features/share_good/presentation/quran_invite_completion_test.dart test/features/quran`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(share-good): report invited Quran completion from the read gate`

### Task 8: Adhkar completion adapter (morning/evening)

**Files:**
- Modify: `lib/features/azkar/presentation/pages/azkar_category_page.dart` (the existing `BlocListener<AzkarCubit, AzkarState>` at line ~311)
- Test: `test/features/share_good/presentation/azkar_invite_completion_test.dart`, plus a regression run of `test/features/azkar/`

**Interfaces:**
- Consumes: `ActiveInviteSessions.forTarget(AzkarCollectionInviteTarget(category))`, `AzkarLoaded.allDone`.
- Produces: completion is reported only on an observed `allDone` `false → true` transition while a session is active. If the first observed state is already `allDone == true`, show the banner variant "أتممتها اليوم" with an explicit confirm button (D10).

- [ ] **Step 1: Failing tests:**
  - `false→true transition reports completedPrivate once` (a second emission of `allDone` gives no second call).
  - `restored allDone does not report completion without confirmation` → zero `advance` calls until the tap, then one.
  - `general and duas pages never mount the banner`
  - `counts, auto-advance and haptics unchanged` → the existing azkar tests still pass.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** inside the existing listener (`listenWhen` compares previous and current `allDone`).
- [ ] **Step 4: Run** `flutter test test/features/share_good/presentation/azkar_invite_completion_test.dart test/features/azkar`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(share-good): report invited adhkar completion on fresh allDone`

### Task 9: Completion consent sheet, disclosure, account conversion

**Files:**
- Create: `presentation/widgets/invite_completion_sheet.dart`
- Modify: `lib/features/auth/presentation/pages/login_page.dart` (only to accept `?from=/invite/<t>` and return there; reuse an existing return mechanism if one exists)
- Test: `test/features/share_good/presentation/invite_completion_sheet_test.dart`, `test/integration/share_good_guest_flow_test.dart`, `test/integration/share_good_account_switch_test.dart`

**Interfaces:**
- Consumes: `ShareGoodRepository.disclose`, `InviterIdentityResolver`, `AuthCubit`.
- Produces: `InviteCompletionSheet.show(context, InviteSession)`. It is non-blocking and dismissible. Choices: "احتفظ بإتمامي لنفسي" (default, nothing more) and "أخبره أنني أتممت". If not signed in, the second choice opens sign-in with a return path. After return, the sheet shows the **current** account's resolved name and requires one more explicit tap before calling `disclose`. A secondary CTA "استمر في سلسلة الخير" opens Task 11. Guests see "أنشئ حسابك واحفظ أثرك" (dismissible). Before the user chooses, the session persists `awaitingConsent = true`, and the sheet is re-offered from the preview if the process dies.

- [ ] **Step 1: Failing tests:**
  - `keep private makes no further calls and closes`
  - `auth change does not disclose; disclosure uses current account at tap` → sign in as A, switch to B, and the tap discloses with B's name. No call happens on the auth stream.
  - `guest choosing tell is routed to sign-in and returns to the sheet`
  - `process restart restores awaitingConsent without disclosing`
  - `named disclosure for a public invite still requires the explicit tap`
  - Integration (`share_good_guest_flow_test`): signed-out first-time user → link → preview → Surah → complete → keep private. The repository saw `opened, started, completedPrivate` in that order, and onboarding was never shown.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/features/share_good test/integration/share_good_guest_flow_test.dart test/integration/share_good_account_switch_test.dart test/integration/account_switch_isolation_test.dart`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(share-good): add explicit completion disclosure and post-value sign-in`

---

## Phase C — Inviter path

### Task 10: Invitation share package on Dawn + creation flow + entry points

**Files:**
- Create: `presentation/cubits/invite_create_cubit.dart`, `presentation/widgets/invite_mode_sheet.dart`, `presentation/widgets/share_good_action.dart`
- Modify: `social_share_model.dart` (add `SocialShareCategory.invitation` with icon `TaliaIcons.people`; add `final Uri? linkUrl`; add factory `SocialShareData.invitation({required String activityTitle, required InviteMoment moment, String? inviterName, required Uri linkUrl, required String message})`), `share_card_shell.dart` (`qrData: data.linkUrl?.toString() ?? ShareCardLinks.forCategory(data.category)`), `share_card_template_resolver.dart` (map invitation → the existing Dawn text hero with title only; **no sacred text**), `social_share_sheet.dart` (for `invitation`: hide the "إظهار اسمي" toggle, show an editable message field, and build the shared text as `message + '\n' + linkUrl` with the link not editable), `quran_reader_page.dart` / `reader_overflow_sheet.dart` (a "تشاركني؟" overflow item for the current page and Surah), `azkar_category_page.dart` (app-bar action before completion "تشاركني؟"; after `allDone`, "شارك الخير" in the existing completion area), `khatmah_dashboard_page.dart` (the today range), `daily_wird_card.dart` (the today page), `injection.dart`
- Test: `test/features/share_good/presentation/invite_create_cubit_test.dart`, `invite_mode_sheet_test.dart`, `share_good_action_test.dart`; extend `test/core/widgets/social_share_test.dart`

**Interfaces:**
- Consumes: `ShareGoodRepository.create`, `InviterIdentityResolver`, `InviteTargetLabeler`, `ShareGoodLocalStore` (identity preference), `ShareGoodFeatureFlags`.
- Produces:
  - `ShareGoodAction({required InviteActivityTarget target, required InviteMoment moment, ShareGoodActionStyle style})`. It renders nothing when the flag is off, on a child profile, or for an ineligible target.
  - `InviteCreateCubit` with states `Idle | ChoosingMode(defaults) | Creating | Created(CreatedInvite, SocialShareData) | NeedsSignIn | Failed(ShareGoodFailure)`.
- Copy (ARB): before, personal: "{name} يدعوك لقراءة {activity} معه 🤍". Before, anonymous: "أدعوك لقراءة {activity} معي 🤍". After, named: "{name} أتمّ قراءة {activity} اليوم، ويدعوك لتقرأها أنت أيضًا 🤍". After, anonymous: "أتممتُ قراءة {activity} اليوم، وأدعوك لتقرأها أنت أيضًا 🤍". Mode labels: "دعوة شخصية" / "مشاركة عامة". Expiry warning: "تنتهي الدعوة خلال {duration}". Each has an English equivalent. Gendered phrasing is an owner copy review item (UX copy pass), not a blocker.

- [ ] **Step 1: Failing tests:**
  - `mode must be chosen before the OS sheet opens` → `SharePlus` is never invoked from `ChoosingMode`.
  - `public defaults to anonymous; personal defaults to the saved preference`
  - `signed-out user gets NeedsSignIn and worship screen stays usable`
  - `warns when fewer than 60 minutes remain` (morning target, clock 14:40, server `expiresAt` 15:30 → the warning is shown with 50 minutes)
  - `invitation card QR encodes the invite URL, not the Play listing`
  - `invitation share text is message + link; editing the message never alters the link`
  - `invitation copy contains no reward vocabulary` → for all ARB values under `invite*`/`shareGood*`, none contain `ثواب|أجر|حسنات|reward|blessing points`.
  - `ShareGoodAction hidden for child profile, flag off, general/duas`
  - Existing `social_share_test.dart` stays green for all other categories.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Reuse `SocialShareSheet.show`, and create no second renderer or exporter.
- [ ] **Step 4: Run** `flutter test test/features/share_good test/core/widgets test/features/quran test/features/azkar test/features/khatmah`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(share-good): create invitations from Quran, adhkar, wird and khatmah`

### Task 11: Good Chain continuation

**Files:**
- Modify: `invite_create_cubit.dart` (`startChain(String parentToken)`), `invite_completion_sheet.dart` (CTA wiring)
- Test: extend `invite_create_cubit_test.dart`; add `test/features/share_good/presentation/chain_continuation_test.dart`

**Interfaces:**
- Consumes: `ShareGoodRepository.continueChain`.
- Produces: the chain invite targets the **same** activity, with moment `afterActivity`. It is available after a private or shared completion, but only when signed in, and continuing never discloses the completion identity.

- [ ] **Step 1: Failing tests:** `chain requires sign-in and returns to the sheet`, `chain after private completion does not call disclose`, `chain uses same target and afterActivity`, `chain on expired parent shows notice but allows a fresh standalone invite`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(share-good): continue the good chain from a completed invite`

---

## Phase D — Good Impact

### Task 12: Good Impact page, milestones, "new" indicator

**Files:**
- Create: `presentation/cubits/good_impact_cubit.dart`, `presentation/pages/good_impact_page.dart`, `domain/services/good_impact_milestone_policy.dart`, `presentation/widgets/share_good_settings_tiles.dart`
- Modify: `app_router.dart` (`AppRoutes.goodImpact = '/settings/good-impact'`, auth required), `settings_hub_body.dart` (one nav tile "أثر الخير" with a "new" dot), `injection.dart`
- Test: `good_impact_cubit_test.dart`, `good_impact_milestone_policy_test.dart`, `good_impact_page_test.dart`

**Interfaces:**
- Consumes: `ShareGoodRepository.impact`.
- Produces: `GoodImpactMilestonePolicy.derive(GoodImpact) -> Set<GoodImpactMilestone>`, using `firstChainStarted` (`downstreamReach >= 1`), `fiveReach` (`responses + downstreamReach >= 5`), `tenResponses` (`responses >= 10`), and `twentyFiveReach` (`>= 25`). `GoodImpactCubit.hasNew` compares acknowledgements and milestones against the last-seen fingerprint in prefs `share_good_impact_seen_v1`. Refresh is throttled to once per 6 h (D9).
- Copy: "{count} أشخاص استجابوا لدعوتك", "{count} أتمّوا القراءة", "امتد أثر دعوتك إلى {count} شخصًا". Use ARB plural forms for Arabic (zero/one/two/few/many/other).

- [ ] **Step 1: Failing tests:**
  - `milestones never call XpService or AchievementService` (DI spy with zero interactions).
  - `page shows only aggregates and opted-in names; no ranking or comparison text`
  - `active and recently expired lists are separated`
  - `new dot clears after the page is viewed`
  - `Arabic plural forms render for 0, 1, 2, 3, 11, 100`
  - `signed-out user is sent to sign-in with return to good impact`
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(share-good): add Good Impact page and symbolic milestones`

---

## Phase E — Prompts and notifications

### Task 13: Smart share prompt policy and one-time education

**Files:**
- Create: `domain/services/share_prompt_policy.dart`
- Modify: the after-completion areas in `azkar_category_page.dart` and the Task 9 sheet / Quran completion moment (an inline, dismissible hint only)
- Test: `share_prompt_policy_test.dart`

**Interfaces:**
- Produces: `SharePromptPolicy.shouldPrompt(SharePromptState s, DateTime now) -> bool`. It returns false if `now - lastShownAt < 72h` × 2^`min(dismissCount, 3)`, if `invitesCreated >= 3` (frequent users stop seeing promos), or if `shownCount >= 12`. Education shows once (`educationSeen`). The prompt is an inline chip under the completion state, never a modal, and the permanent share action always stays available.

- [ ] **Step 1: Failing tests:** `first eligible completion prompts`, `second within 72h does not`, `each dismissal doubles the gap up to 8x`, `stops after three created invites`, `never more than 12 lifetime`.
- [ ] **Step 2–4:** Run (expected FAIL), implement, run (expected PASS).
- [ ] **Step 5: Commit** `feat(share-good): add frequency-capped share prompts`

### Task 14: Recipient reminder + settings

**Files:**
- Modify: `lib/core/services/notification_scheduler.dart` (one `share_good_reminder` channel id), `settings_notification_tiles.dart` (toggle "تذكير الدعوات", default on), `share_good_settings_tiles.dart` (personal identity preference: full, first, display, anonymous)
- Test: `test/core/services/notification_scheduler_share_good_test.dart`, `share_good_settings_tiles_test.dart`

**Interfaces:**
- Consumes: the `ActiveInviteSessions.changes` stream and the existing quiet-hours keys (`TaliaNotificationService.quietHoursPreferenceKey`/`StartKey`/`EndKey`).
- Produces: `scheduleInviteReminder(InviteSession)` fires at `expiresAt − 2h`, or at `started + 1h` if that is later, but never after `expiresAt − 15m`. It is skipped inside quiet hours (then shifted to the quiet-hours end if that is still before expiry, otherwise skipped). It is cancelled on completion or expiry. At most one per invite, at most one pending in total, and the payload is `/invite/<token>`. Body: "دعوتك لقراءة {activity} ما زالت متاحة". No permission prompt is triggered by this feature.

- [ ] **Step 1: Failing tests:** `schedules once for a started incomplete invite`, `cancelled on completion`, `respects quiet hours`, `not scheduled when toggle off or permission denied`, `payload route is the invite route and passes notification payload route guard`.
- [ ] **Step 2–4:** Run (expected FAIL), implement, run (expected PASS). Also run `test/core/router/notification_payload_route_guard_test.dart`.
- [ ] **Step 5: Commit** `feat(share-good): add single local invite reminder and settings`

---

## Phase F — Platform links and release gate

### Task 15: Link hosting artifacts and platform contract test

**Files:**
- Create: `hosting/share_good_links/_redirects` (`/i/:token  https://play.google.com/store/apps/details?id=com.talia.quran&referrer=inv%3D:token  302` and `/*  /index.html  200`), `index.html` (one paragraph in Arabic and English plus a Play button, no scripts or analytics), `.well-known/assetlinks.json.template` (`com.talia.quran`, the placeholder `__SHA256_FINGERPRINTS__`), `README.md` (deploy steps and the fingerprint sources: upload key + Play App Signing key)
- Create: `test/features/share_good/platform_link_contract_test.dart`
- Create: `qa/share_good_runtime_qa.md`

**Interfaces:**
- Consumes: the `ShareGoodLinks` format, the manifest placeholder.

- [ ] **Step 1: Failing contract test:**
  - `manifest App Link filter uses autoVerify, https, the shareGoodLinkHost placeholder and pathPrefix /i/`
  - `redirect passes the token only inside referrer=inv%3D and targets com.talia.quran`
  - `index.html contains no script tag and no external resources`
  - `assetlinks template declares delegate_permission/common.handle_all_urls for com.talia.quran`
- [ ] **Step 2–4:** Run (expected FAIL), create the artifacts, run (expected PASS).
- [ ] **Step 5: Write `qa/share_good_runtime_qa.md`** with a pass/fail table for a **signed release** build on two physical Android devices (one Android 12+). Cases: installed cold, warm, and background via WhatsApp and Telegram. Not installed → Play → install → first launch reaches the preview (referrer). Verified-link status via `adb shell pm get-app-links com.talia.quran` showing `verified`. Expired, invalid, and offline first open. Arabic and English. Reminder delivery. Share-sheet cancel.
- [ ] **Step 6: Commit** `feat(share-good): add minimal link hosting artifacts and platform contract`

### Task 16: Full regression and acceptance gate

- [ ] **Step 1:** Run `./scripts/verify_v1_release.ps1` (pub get with the enforced lockfile, gen-l10n, build_runner, analyze, the full test suite, and Supabase checks). Expected: all green; the evidence path is reported.
- [ ] **Step 2:** Scope scan: `grep -rniE "leaderboard|rank|friends|followers|ثواب|حسنات|أجر" lib/features/share_good lib/core/l10n/app_*.arb`. Expected: no new hits in Share Good keys.
- [ ] **Step 3:** Privacy scan of the migration plus the datasource. No RPC response includes `creator_user_id`, `participant_key_hash`, `token_hash`, or an email.
- [ ] **Step 4:** Execute `qa/share_good_runtime_qa.md` on signed devices once the owner blockers B1–B3 are closed. Record the results in that file. Until then, the flag stays off in production builds and the status is **BLOCKED (external)**, not done.
- [ ] **Step 5:** Walk the spec §29 acceptance checklist and mark each item with a test name or a QA row. AC19 is marked "Android: verified / iOS: explicitly unsupported in V1 (D1)".
- [ ] **Step 6: Commit** `docs(share-good): record V1 acceptance evidence`

---

## 6. External blockers (owner)

| # | Needed | Blocks |
|---|---|---|
| B1 | A domain or subdomain for invite links plus static hosting that supports `_redirects` and `/.well-known` (for example Cloudflare Pages) | Tasks 15–16 runtime, enabling the flag |
| B2 | SHA-256 fingerprints of the release upload key **and** the Play App Signing key (Play Console → App integrity) | `assetlinks.json` verification |
| B3 | Applying the migration to staging and then production through the normal pipeline, with the contract verifier against the deployed DB | Enabling the flag |
| B4 | (Optional, later) iOS bundle ID, Team ID, and an App Store listing | iOS links (V2) |

Tasks 1–14 do not depend on B1–B4.

## 7. Spec coverage map

| Spec § | Task(s) |
|---|---|
| 2 Principles, 3 exclusions | Global Constraints; 10 (copy scan), 12, 16 |
| 3/9 Exact targets | 1, 5, 7, 8, 10 |
| 6 Before/after entry points | 10 |
| 7 Smart prompts | 13 |
| 8 Personal/public before OS sheet | 10 |
| 10 Share package, editable text | 10 |
| 11 Installed recipient | 5, 6 |
| 12 Not installed / deferred | 6 (referrer), 15, 16; iOS limitation D1 |
| 13 Guest-first | 3, 5, 9 |
| 14 Inviter identity | 4, 10, 14 |
| 15 Recipient privacy | 3, 9 |
| 16 Completion model | 7, 8 (D10) |
| 17 Expiration, expired path | 3, 5, 10 |
| 18 Good Chain | 3, 11, 12 |
| 19–20 Impact, milestones | 12 |
| 21 Notifications | 14, D9 |
| 22 States | 1, 3 |
| 23/28 Metrics | 3 (view), D5 |
| 24 Account conversion | 9 |
| 25 Edge cases | 4, 5, 7, 9, Review Focus |
| 26 UX, RTL/LTR, a11y | 5, 9, 10, 12 |
| 27 Modules | File map §5 |
| 29 Acceptance | 16 |
| Kids audience (spec gap) | 5, 10 (D8) |

## 8. Execution order and exit gates

- Run A → B → C → D → E → F in order. Within B, Task 6 can run in parallel with Tasks 7 and 8 once Task 5 lands.
- **Gate A:** domain, store, and repository tests plus the static SQL contract pass. No UI has changed.
- **Gate B:** the guest integration flow passes. Quran and azkar suites are unchanged and green.
- **Gate C:** invites are created from all four entry points, and the copy scan is clean.
- **Gate D/E:** impact, prompts, and the reminder are tested. There is no XP or achievement coupling.
- **Gate F:** `verify_v1_release.ps1` is green, and the signed-device QA passes before `SHARE_GOOD_ENABLED=true` ships.
