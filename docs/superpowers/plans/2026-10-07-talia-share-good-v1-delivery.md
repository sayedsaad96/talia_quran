# Talia Share Good / Good Impact V1 — Delivery Plan (reconciled 2026-11-05)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the شارك الخير / أثر الخير worship-invitation loop on Android. Signed-in users invite someone to the exact Quran page, Surah, wird range, or morning/evening adhkar they are reading. Recipients open it from an installed app or after a fresh Play install, complete it as guests, and choose whether to reveal themselves. Inviters see aggregate, non-competitive impact.

**Architecture:** A new `lib/features/share_good/` feature (domain/data/presentation, Cubits, `get_it`) sits on top of one additive Supabase migration. Public `SECURITY INVOKER` RPCs call narrowly granted `private.*` definer helpers; both layers have exact role/ACL tests. Existing worship authorities (`QuranReadConfirmationGate` + `QuranPageCubit.confirmRead`, `AzkarCubit`/`AzkarLoaded.allDone`, and Khatmah confirmation/recording policy) stay authoritative. Share Good only observes their successful completion boundaries. Installed recipients enter through verified Android App Links (`app_links`); fresh Play installs restore `referrer=inv%3D<token>` through a new Install Referrer bridge. The current social-card URLs carry UTM data in Play's `referrer`, but the app does **not** currently read Install Referrer, so that bridge remains new work.

**Tech Stack:** Current project floor: Dart `^3.12.0`, Flutter `>=3.44.0`, Android compile SDK 37 / Java 17; `flutter_bloc`, `get_it`, `go_router`, `dartz`, `equatable`, `supabase_flutter`, the local `flutter_secure_storage` package, `shared_preferences`, `share_plus ^13.1.0`, the shipped Dawn social-share stack (`lib/core/widgets/social_share/`), `flutter_local_notifications ^22.0.1`, a direct `app_links` dependency (currently transitive only), and `com.android.installreferrer:installreferrer:2.2` through a small Kotlin method channel.

**Spec:** `docs/superpowers/plans/2026-09-11-talia-share-good-design.md` (product source of truth; its 2026-11-05 implementation note points here).
**Supersedes:** `docs/superpowers/plans/2026-09-11-talia-share-good-v1.md` (reconciled at `3f2b9ad`, never executed). This plan was re-audited against HEAD `5a049731`; Share Good itself is still unimplemented. See §2.

---

## 0. الملخص التنفيذي (للمالك)

**الفكرة:** دعوة شخص آخر لنفس العبادة التي تقوم بها (صفحة، سورة، ورد، أذكار الصباح والمساء)، قبل البدء ("تشاركني؟") أو بعد الإتمام ("شارك الخير"). المستلم يفتح الرابط ويقرأ كضيف دون تسجيل، ثم يختار هل يُخبر الداعي أم يحتفظ بإتمامه لنفسه. ويرى الداعي "أثر الخير" كأرقام مجمّعة فقط، بلا ترتيب ولا نقاط ولا ادعاء ثواب.

**التقييم:**
- **الفكرة قوية ومتسقة مع هوية تالية.** المبادئ (العبادة أولًا، لا ادعاء أجر، الخصوصية افتراضيًا، لا منافسة) تتوافق مع سياسة المحتوى وقرارات المنتج الحالية. وهي حلقة نمو طبيعية مبنية على استخدام حقيقي.
- **الجاهزية التقنية عالية.** منظومة بطاقات Dawn للمشاركة مكتملة وفيها QR وروابط حملات، والتوقيع الحقيقي لإصدار أندرويد مُفعّل، والمسارات `/quran/page/:n` و`/quran/surah/:id` و`/azkar/:category` موجودة، وبوابات الإتمام موجودة (`QuranReadConfirmationGate` و`AzkarLoaded.allDone`).
- **الخطة السابقة (2026-09-11-v1) دقيقة لكنها تقادمت وتضخمت:** كانت معلّقة على Dawn (اكتمل الآن)، واعتبرت الاستعادة بعد التثبيت غير ممكنة، وأضافت جدول تحليلات منفصلًا وطابورًا كاملًا للعمليات غير المتصلة. هذه الخطة تقلّص النطاق إلى ما يحقق المواصفة وتقسّمه إلى مراحل قابلة للشحن.
- **أكبر تحسين:** الاستعادة بعد التثبيت (المعيار 19 في المواصفة) ممكنة على أندرويد **بدون SDK إسناد خارجي** عبر Play Install Referrer. بطاقات Dawn الحالية تمرّر UTM إلى Play فقط؛ قراءة referrer داخل التطبيق ما زالت جزءًا جديدًا من هذه الخطة.
- **العوائق الخارجية (قرارات المالك):** (1) نطاق (domain) مملوك لرابط الدعوة مع استضافة ثابتة لملف `assetlinks.json` وتحويل بسيط إلى Play. (2) بصمة SHA-256 لمفتاح التوقيع، ولمفتاح Play App Signing إن كان مفعّلًا. (3) iOS خارج إصدار الروابط في V1، لأن معرّف الحزمة ما زال `com.example.taliaQuran` ولا يوجد تطبيق على App Store.
- **الحكم:** قابلة للتنفيذ، لكن ليست مطبّقة بعد. تُشحن على 6 مراحل خلف `ExperienceFeature.shareGood` الذي يبقى مغلقًا افتراضيًا حتى تجتاز المرحلة الأخيرة فحص قاعدة بيانات مؤقتة وبيئة staging وأجهزة Android موقعة.

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
| Analytics §23, §28 | Defer collection (D5) | Good Impact is served by an authenticated aggregate RPC. No analytics table/view or behavioural event collection ships in V1; operational product analytics require a later privacy-approved consumer. |
| Account conversion §24 | Keep | A dismissible CTA after completion, required only for disclosure, chain continuation, and impact history. |
| Kids/guardian audience | **Gap in spec** (D8) | Child profiles (`profile.isChild`) never create invites, never disclose, and never call Share Good RPCs. |

## 2. What changed in the current repository (HEAD `5a049731`)

| Previous-plan assumption | Reality at `5a049731` | Effect on this plan |
|---|---|---|
| Share Good might have partially landed | No `lib/features/share_good/`, Share Good migration/test, hosting bundle, or runtime-QA file exists | Every implementation task remains open; do not treat this reconciliation as delivery. |
| Dawn was a small/unfinished dependency | Dawn now owns categories, templates, QR/signature, rasterization, export and a broad test suite under `test/core/widgets/social_share*` | Add `invitation` as an extension of Dawn, preserve the existing Play-link fallback for all other categories, and extend its focused link/render/fit tests. |
| Existing cards prove deferred restoration | `ShareCardLinks.forCategory` only puts UTM values in Play's `referrer`; there is no `AppLinks` or Install Referrer reader | Task 6 and the physical Play-install QA remain mandatory; remove the old “already used by app” claim. |
| Startup routing was simple | `lib/app.dart` now has one cold/foreground navigation writer shared with notification and Prayer Companion handling; first-time launch currently always chooses onboarding | Incoming invites must join that coordinator, bypass onboarding once only after strict validation, and preserve notification, widget, audio, password-recovery and onboarding behavior. |
| Feature gating was standalone | `ExperienceFeature`, `RolloutManifest`, `ExperienceFlags.withUserPreferences`, and the features settings page now form the central rollout system | Add `ExperienceFeature.shareGood` with default `off`; availability also requires configured Supabase and link host. Do not add a parallel `SHARE_GOOD_ENABLED` system. |
| Quran/Khatmah completion was a single generic boundary | The reader separates ordinary reading from Khatmah and now requires explicit confirmation at daily/plan completion boundaries | Observe only a successful existing confirmation; never create a second confirmation or advance ordinary/Khatmah progress from Share Good. |
| Notification settings were a few loose keys | `NotificationSettingsCubit`/state, quiet hours, scheduler budgets, and raw response controllers are established | Add the invite reminder through the Cubit/state/scheduler and use an opaque local session payload, never the bearer token. |
| Account cleanup was best effort | Account deletion now has a durable remote-then-local fence; `AccountDataReset` inventories account/device keys; portable backup has an explicit allow-list | Task 2 must classify every new key and test account switch, deletion and backup exclusion. |
| Backend contract verifier was small | Group Khatmah introduced hardened invoker/definer/ACL/session patterns; the main verifier has an exact 137-query security test; latest migration is `20261031211819_reading_checkpoints.sql` | Generate a later migration, add a dedicated Share Good verifier, update the exact query count deliberately, and test on disposable DB then staging. |
| Khatmah sharing used Dawn | `KhatmahCompletionPage._shareAchievement` still calls `SharePlus` directly | Task 10 converts this remaining path to Dawn before layering Share Good continuation. |
| Worktree was clean | Owner work is active: a concurrent tracked edit in `lib/features/home/presentation/pages/home_page.dart` plus untracked `artifacts/` and `marketing/` content | Treat all of it as out of scope. Re-read before implementing Home/impact entry points; do not revert, reformat, delete, or stage owner work. |

## 3. Decisions (delegated to Claude; rationale recorded)

| # | Decision | Why |
|---|---|---|
| D1 | Android-only link release for V1. The Dart ingress service must stay platform-guarded; iOS association and deferred restoration are out of scope. | No verified production iOS association/App Store path is available. |
| D2 | Link format `https://<SHARE_GOOD_LINK_HOST>/i/<token>`. The host comes from `--dart-define=SHARE_GOOD_LINK_HOST`. If it is empty, creation is unavailable (fails closed). | Mirrors `SupabaseConfig`, and no domain is hard-coded before the owner provides one. |
| D3 | The redirect host is static only (`_redirects` + `/.well-known/assetlinks.json` + a one-paragraph `index.html`). The sources live in `hosting/share_good_links/`. | The spec allows "a minimal technical redirect" but no web product. Static hosting resolves nothing server-side, so the token stays opaque. |
| D4 | Install Referrer through a ~60-line Kotlin channel using `com.android.installreferrer:installreferrer:2.2`, not a pub plugin. | The project already keeps native Kotlin with JVM tests. One fewer third-party Dart dependency. |
| D5 | No analytics table or metrics view in V1. The authenticated Good Impact RPC computes only product-facing aggregates; prompt/notification behavior stays local and is not collected. | There is no approved analytics consumer, and a public-schema view adds avoidable exposure risk. |
| D6 | Expiry: morning adhkar → the first local 15:30 after creation. Evening adhkar → the first local 04:00 after creation. These are the `AzkarTimeContext.resolvePeriod` boundaries. Wird range → creation + 3 days. Page/Surah → creation + 7 days. Timezone is the creator's IANA zone, and an unknown zone rejects creation. | The spec asks for "several days" for reading targets. Adhkar follow the app's existing period boundaries. |
| D7 | Offline: the first resolve needs the network. After that, a cached safe snapshot opens offline, and the session stores `pendingStatus` (the highest unsynced status), replayed on resume or next open. | Monotonic states make one slot sufficient. |
| D8 | Child profiles: creation entry points are hidden. An opened invite shows "invitations aren't available in the kids space" and offers the activity locally without counting, if the kids route guard allows it. | Children's privacy. The spec is silent on this. |
| D9 | No push. Named acknowledgements and milestones raise a "new" dot on the Good Impact entry. This comes from `get_share_good_impact_v1` on Settings/Home resume, throttled to once per 6 h. | The spec allows limited notifications and none are required. A push stack is a separate privacy design. |
| D10 | Restored-complete adhkar: if today's collection is already `allDone` when an invited session starts, show "أتممتها اليوم" with an explicit confirm. That counts as a completion. Without the tap, nothing counts. | The spec counts "confirmed completion", and silently counting would be inference. |
| D11 | Identity defaults: personal → first name when a real name exists, otherwise anonymous. Public → anonymous. Fallback strings (`مستخدم`, `مستخدم تالية`, empty) count as no name. | §14 privacy defaults. |
| D12 | Availability = `ExperienceFlags.isEnabled(ExperienceFeature.shareGood)` && `SupabaseConfig.fromDartDefine.isConfigured` && non-empty validated `SHARE_GOOD_LINK_HOST`. `RolloutManifest` ships the flag `off` until Task 16 evidence is accepted. | Reuse the project's single rollout authority and still fail closed when external link infrastructure is absent. |
| D13 | Incoming bearer tokens are never placed in notification payloads, SharedPreferences, logs, analytics, or route-restoration history. Pending ingress/session data lives in secure storage; reminder payloads carry an opaque local session id resolved inside the app. | The current notification system persists native payloads and routes; treating `/invite/<token>` as a payload would leak a reusable secret outside the secure store. |
| D14 | Pending ingress uses read + compare-and-ack, not destructive `take`. Navigation acknowledges only after the preview has accepted the token; crashes leave it retryable and duplicate deliveries remain idempotent. | A destructive read can silently lose the invite between startup and navigation. |

## Global Constraints

- Mobile only: no web reader and no general web app. The redirect host serves exactly `_redirects`, `/.well-known/assetlinks.json`, and `index.html`.
- Worship first: no blocking modal before or during worship. Share entry points never compete visually with reading controls.
- Never calculate, promise, or imply religious reward. Banned copy includes "ضاعف ثوابك", "أجر", "حسنات", numeric reward, and "better than X%".
- No friends, contacts, search, feed, chat, leaderboard, ranking, profile photos, live rooms, or chain trees.
- Guests resolve, open, start, and complete without auth or onboarding. Creating, disclosing, continuing a chain, and impact history require auth.
- Invite links/referrers contain only the opaque invite token. Notification payloads contain only opaque local session ids. Server responses never expose creator UUIDs, hashes, email, phone, Quran text, or adhkar text; names exist only in the explicit identity/disclosure snapshots.
- Quran/adhkar display labels come from the existing bundled data (`surahs.json`, the azkar category labels). No religious text is generated. (`docs/TALIA_ISLAMIC_CONTENT_SOURCES_POLICY.md`)
- Unchanged authorities: `quran_page_cubit.dart`, `quran_read_confirmation_gate.dart`, `khatmah_read_confirmation_policy.dart`, `khatmah_cubit.dart`, `azkar_cubit.dart`, `azkar_completion_store.dart`, `achievement_service.dart`, `xp_service.dart`, reading checkpoints/cloud sync, and `assets/data/*`.
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

Tables are RLS-enabled, with every privilege revoked from `PUBLIC`, `anon`, `authenticated`, and `service_role` unless an exact function grant below requires otherwise:

- `share_good_invites(id uuid pk, token_hash text unique, creator_user_id uuid null references auth.users on delete set null, mode, moment, identity_mode, target jsonb, parent_invite_id uuid null references share_good_invites, root_invite_id uuid not null, timezone text, created_at, expires_at, revoked_at null)`
- `share_good_invite_identities(invite_id pk/fk cascade, user_id fk auth.users on delete cascade, visible_name text not null check (char_length between 1 and 40))`
- `share_good_participations(id uuid pk, invite_id fk, participant_key_hash text, opened_as_guest bool, status text, opened_at, started_at, completed_at, unique(invite_id, participant_key_hash))`
- `share_good_completion_disclosures(participation_id pk/fk cascade, user_id fk auth.users on delete cascade, visible_name text not null)`
- `share_good_rate_limits(scope_hash text, action text, window_start timestamptz, attempts int, primary key(scope_hash, action, window_start))`

Public RPCs (`SECURITY INVOKER`, `set search_path = ''`; each calls one `private.*` `SECURITY DEFINER` helper):

```text
create_share_good_invite_v1(p_target jsonb, p_moment text, p_mode text, p_identity_mode text, p_visible_name text, p_timezone text) -> jsonb   authenticated
create_share_good_chain_invite_v1(p_parent_token text, p_participant_key text, <same 6 args>) -> jsonb                                         authenticated
resolve_share_good_invite_v1(p_token text, p_participant_key text) -> jsonb                                                                     anon, authenticated
advance_share_good_participation_v1(p_token text, p_participant_key text, p_status text) -> jsonb   -- opened|started|completed_private        anon, authenticated
disclose_share_good_completion_v1(p_token text, p_participant_key text, p_visible_name text) -> jsonb                                           authenticated
get_share_good_impact_v1() -> jsonb                                                                                                            authenticated
```

Security and behavior rules:
- `private` remains outside `supabase/config.toml` exposed schemas. Each public wrapper is `SECURITY INVOKER`; each privileged helper is `SECURITY DEFINER SET search_path = ''` and schema-qualifies every object.
- Revoke every function/helper from `PUBLIC, anon, authenticated, service_role` first. Grant `USAGE` on `private` plus `EXECUTE` on only the required helper signatures: `anon` gets the resolve and advance helpers only; `authenticated` gets the six operations it needs. The public wrappers receive the matching exact grants. No blanket schema/function grant is allowed.
- Every authenticated helper validates both `auth.uid()` and the live `auth.sessions` row from the JWT `session_id`, following the current Group Khatmah security pattern. Role-only or stale-session calls fail closed.
- Tokens are 32 random bytes encoded as base64url without padding (43 characters). They are returned once; the database stores only `pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(value, 'UTF8')), 'hex')`, matching the current Group Khatmah fingerprint pattern. Participant keys are hashed the same way.
- Caps: 30 creations per user per rolling 24 h. 60 resolves per participant key per hour. 20 advances per (invite, key) per day. A breach returns `{"error":"rate_limited"}` and never raises.
- Advancing after `expires_at` or `revoked_at` → `{"error":"expired"}`. A repeated or backward advance → returns the current status (idempotent).
- Disclosure requires `auth.uid()` and a completed participation. It upserts the disclosure row and sets the status to `completed_shared_identity`.
- A chain needs the parent participation completed under the same participant key. It sets `parent_invite_id` and `root_invite_id` from the parent and sets the parent participation to `continued_as_new_invite`.
- The resolve response carries `target, moment, mode, inviter{mode, visible_name?}, status, expires_at, participation_status?`. It never includes IDs, hashes, or creator UUIDs.
- Impact returns the caller's own invites (active, plus those expired in the last 30 days), direct counts, named acknowledgements for direct invites only, and `downstream_reach` = distinct completed participations in invites whose `root_invite_id` is one of the caller's roots, excluding direct invites. It returns no tree, depth, or hashes.
- Account deletion: this migration does **not** redefine `public.delete_current_user()`. The current hardened function deletes `auth.users`; FKs remove identity/disclosure rows, set `creator_user_id = null`, and preserve invite/chain lineage. A behavioural SQL test exercises the real deletion RPC with a live session fixture and proves `A → B → C` survives deletion of B without B's identity.

### 4.4 Link and referrer

- Share URL: `https://$SHARE_GOOD_LINK_HOST/i/<token>`. The parser accepts exactly that host, path `^/i/[A-Za-z0-9_-]{43}$`, no query or fragment, and `https` only.
- Redirect: `/i/:token → https://play.google.com/store/apps/details?id=com.talia.quran&referrer=inv%3D:token` (302).
- Referrer parse: `inv=<43-char token>` → a pending invite. Any other referrer (for example `utm_source=tc&...`) → ignored. The referrer is read once per install, and the flag is stored in prefs `share_good_referrer_checked`.

---

## 5. File map

```text
lib/features/share_good/
  share_good_config.dart                         # availability facade, link host, buildShareUrl/parseShareUri
  domain/entities/{invite_activity_target,invite_types,good_impact}.dart
  domain/repositories/share_good_repository.dart
  domain/services/{inviter_identity_resolver,good_impact_milestone_policy,share_prompt_policy,invite_target_labeler}.dart
  data/datasources/{share_good_local_store,share_good_remote_datasource}.dart
  data/repositories/share_good_repository_impl.dart
  application/{incoming_invite_link_service,install_referrer_channel,active_invite_sessions,share_good_notification_controller}.dart
  presentation/cubits/{invite_preview_cubit,invite_create_cubit,good_impact_cubit}.dart
  presentation/pages/{invite_preview_page,good_impact_page}.dart
  presentation/widgets/{share_good_action,invite_mode_sheet,invite_activity_banner,invite_completion_sheet,share_good_settings_tiles}.dart
android/app/src/main/kotlin/com/talia/quran/referrer/InstallReferrerPlugin.kt (+ JVM test)
hosting/share_good_links/{_redirects,index.html,.well-known/assetlinks.json.template,README.md}
supabase/migrations/<generated>_share_good_v1.sql
test/features/share_good/**  test/supabase/share_good_v1_contract_test.dart  test/integration/share_good_*_test.dart
qa/share_good_runtime_qa.md
```

Modified: `pubspec.yaml` (`app_links` becomes direct; do not change the SDK floor), `android/app/build.gradle.kts` (installreferrer dep), `AndroidManifest.xml` (App Link filter), `MainActivity.kt` (register channel), `lib/app.dart`, `lib/core/router/{app_router,launch_destination}.dart`, `lib/core/experience/{experience_feature_flags,rollout_manifest}.dart`, `lib/core/identity/account_data_reset.dart`, `lib/core/di/injection.dart` (or a new `share_good_injection.dart` called from it), `lib/core/l10n/app_{ar,en}.arb`, Dawn files under `lib/core/widgets/social_share/`, `quran_reader_page.dart`, `reader_overflow_sheet.dart`, `azkar_category_page.dart`, `khatmah_dashboard_page.dart`, `khatmah_completion_page.dart`, `daily_wird_card.dart`, `settings_hub_body.dart`, `notification_settings_{cubit,state}.dart`, `settings_notification_tiles.dart`, `notification_scheduler.dart`, `scripts/verify_supabase_contract.ps1`, and `test/scripts/verify_supabase_contract_security_test.ps1`. `build.yaml` changes only if unavoidable; prefer `mocktail`.

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
  - `Future<InviteSession?> session(String token)`, `Future<void> saveSession(InviteSession)`, `Future<List<InviteSession>> sessionsWithPending()`. Snapshots and their opaque local session ids are stored as JSON in secure storage under `share_good_session_v1_<sha256(token)>`, with a secure index capped at the 20 most recent.
  - `Future<String?> pendingIncomingToken()`, `Future<void> setPendingIncomingToken(String)`, `Future<bool> acknowledgePendingIncomingToken(String expected)`. The token is secure-storage data; acknowledge is compare-and-clear and happens only after accepted navigation (D14).
  - `InviteIdentityMode personalIdentityPreference(String ownerId)` / setter, stored as `share_good_identity_pref_v1|<ownerId>` (default `firstName`).
  - Owner-scoped `SharePromptState` (`share_good_prompt_v1|<ownerId>`) and Good Impact seen fingerprint (`share_good_impact_seen_v1|<ownerId>`).
  - Explicit classification: participant key, secure sessions and pending ingress survive account switch/deletion; identity/prompt/seen preferences are added to `AccountDataReset.clearedPreferencePrefixes`; no Share Good token/session/identity preference is added to `BackupPreferencePolicy`.

- [ ] **Step 1: Failing tests** (with `FlutterSecureStorage.setMockInitialValues({})` and `SharedPreferences.setMockInitialValues({})`):
  - `participant key is stable and 43 chars`
  - `session round-trip preserves pendingStatus and awaitingConsent`
  - `session store keeps only the 20 most recent`
  - `pending token survives read and compare-and-ack clears only the expected token`
  - `stored session JSON contains no visible text beyond inviter visibleName` → the serialized JSON has no key other than the allow-list.
  - `account reset clears owner preferences but retains installation participant and guest sessions`
  - `portable backup excludes every share-good key and token`
- [ ] **Step 2: Run** `flutter test test/features/share_good/data/share_good_local_store_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(share-good): add installation-scoped local invite store`

### Task 3: Supabase migration, SQL tests, contract verification

**Files:**
- Create: `supabase/migrations/<generated>_share_good_v1.sql` (generate the filename with `supabase migration new share_good_v1`; never backdate it)
- Create: `test/supabase/share_good_v1_contract_test.dart` (static migration assertions, in the style of `review_events_contract_test.dart`)
- Create: `scripts/verify_share_good_contract.ps1` (exact signatures, modes, ACLs, RLS/FKs/indexes, result shape)
- Modify: `scripts/verify_supabase_contract.ps1` (dot-source the dedicated verifier and add only its summary checks)
- Modify: `test/scripts/verify_supabase_contract_security_test.ps1` (the exact query count is 137 before this task; increase by the exact number of added checks)
- Modify: `test/supabase/migration_history_test.dart` (only if it enumerates migrations)

**Interfaces:**
- Produces: exactly the tables, RPCs, grants, indexes, deletion behavior, and JSON shapes in §4.3. Task 4 depends on these RPC and argument names.

- [ ] **Step 1: Failing static contract test.** Assertions on the normalized migration text:
  - `create table if not exists public.share_good_invites` … for each table, plus `enable row level security` on each.
  - `revoke all on table public.share_good_` appears for every table, and there is no `grant select|insert|update|delete on table public.share_good_` to `anon` or `authenticated`.
  - Every public function contains `security invoker` and `set search_path = ''`. Every `private.share_good_` function contains `security definer`, `set search_path = ''`, schema-qualified objects and the required ownership/session checks.
  - The anon public-wrapper and private-helper allow-lists are exactly resolve and advance; `anon` has only the minimum `private` usage plus those two helper signatures. All other helpers reject `anon`, and there is no blanket function grant.
  - `on delete set null` is used for `creator_user_id`, and `on delete cascade` for identity and disclosure `user_id`.
  - `advance_share_good_participation_v1` rejects `completed_shared_identity` and `continued_as_new_invite` as `p_status`.
  - No Share Good table/view is directly readable or writable by `PUBLIC`, `anon`, `authenticated`, or `service_role`.
  - `supabase/config.toml` `schemas` does not contain `private`.
- [ ] **Step 2: Run** `flutter test test/supabase/share_good_v1_contract_test.dart`. Expected: FAIL.
- [ ] **Step 3: Write the migration.** The expiry helper `private.share_good_expires_at_v1(target jsonb, created_at timestamptz, tz text)` implements D6. Reject `tz` not in `pg_timezone_names`. Morning: `(date_trunc('day', created_at at time zone tz) + interval '15:30')`, plus a day if not strictly after creation, then back to timestamptz. Evening: the same with `04:00`.
- [ ] **Step 4: Write behavioural SQL** in `supabase/tests/share_good_v1_test.sql`, run as real `anon`/`authenticated` roles against a fresh migrated disposable DB. Cover expiry boundaries, idempotent/backward/expired advance, rate limits, exact anon allow/deny cases, stale/missing authenticated session rejection, disclosure without auth rejection, and `A → B → C` deletion of B through the current `delete_current_user()` RPC while lineage survives and B's identity/disclosures disappear.
- [ ] **Step 5: Run** the Dart static contract test and `test/scripts/verify_supabase_contract_security_test.ps1`, then `scripts/verify_supabase_migrations.ps1` with `TALIA_SUPABASE_FRESH_DB_URL` against a disposable DB. After the migration is applied through the normal staging pipeline, run `scripts/verify_supabase_contract.ps1` with `SUPABASE_DB_URL` against staging and record schema-cache/RPC smoke evidence. Do not apply to production from this task.
- [ ] **Step 6: Commit** `feat(share-good): add invite schema, private helpers and anon-safe RPCs`

### Task 4: Remote datasource, repository, DI, feature flag

**Files:**
- Create: `lib/features/share_good/share_good_config.dart`, `domain/repositories/share_good_repository.dart`, `data/datasources/share_good_remote_datasource.dart`, `data/repositories/share_good_repository_impl.dart`, `domain/services/inviter_identity_resolver.dart`, `lib/core/di/share_good_injection.dart`
- Modify: `lib/core/experience/experience_feature_flags.dart`, `lib/core/experience/rollout_manifest.dart`, `lib/core/di/injection.dart`
- Test: `test/features/share_good/data/share_good_repository_impl_test.dart`, `test/features/share_good/share_good_config_test.dart`, `test/features/share_good/domain/inviter_identity_resolver_test.dart`

**Interfaces:**
- Consumes: Tasks 1–3.
- Produces:
  - `ShareGoodAvailability(ExperienceFlags, SupabaseConfig)` implementing D12. Add `ExperienceFeature.shareGood` and an explicit `RolloutManifest` default `off` with release-gate reason. `ShareGoodLinks.build(String token) -> Uri`; strict `parse(Uri)` and `parseReferrer(String)` follow §4.4.
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
  - `feature disabled when rollout is off, Supabase is unavailable, or link host is empty/invalid`
- [ ] **Step 2: Run** `flutter test test/features/share_good`. Expected: FAIL.
- [ ] **Step 3: Implement**, then add the DI registrations.
- [ ] **Step 4: Run** `flutter test test/features/share_good` and `flutter analyze`. Expected: PASS, and no issues.
- [ ] **Step 5: Commit** `feat(share-good): add repository, link codec and feature flag`

---

## Phase B — Recipient path

### Task 5: Invite Preview page, cubit, route and states

**Files:**
- Create: `presentation/cubits/invite_preview_cubit.dart`, `presentation/pages/invite_preview_page.dart`, `application/active_invite_sessions.dart`
- Modify: `lib/core/router/app_router.dart` (`AppRoutes.invite = '/invite/:token'`, public and auth-exempt), `lib/app.dart` / `AppSessionService` route persistence (never persist an invite-token route), `app_ar.arb`, `app_en.arb`
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
  - Privacy: pausing on `/invite/<token>` never writes that route/token to `last_restorable_location`, logs, or ordinary preferences.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement**, then run `flutter gen-l10n`.
- [ ] **Step 4: Run** the tests, then `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(share-good): add guest invite preview and public route`

### Task 6: Link ingress — App Links, Install Referrer, startup precedence

**Files:**
- Create: `application/incoming_invite_link_service.dart`, `application/install_referrer_channel.dart`, `android/app/src/main/kotlin/com/talia/quran/referrer/InstallReferrerPlugin.kt`, `android/app/src/test/kotlin/com/talia/quran/referrer/InstallReferrerParserTest.kt`
- Modify: `pubspec.yaml` (`app_links` direct at the version already locked; do not edit the SDK floor), `android/app/build.gradle.kts` (`implementation("com.android.installreferrer:installreferrer:2.2")`), `AndroidManifest.xml` (set `flutter_deeplinking_enabled=false` because `app_links` owns delivery; on `MainActivity` add `<intent-filter android:autoVerify="true">` VIEW/DEFAULT/BROWSABLE, `https`, host `${shareGoodLinkHost}`, `pathPrefix="/i/"`), `MainActivity.kt`, `lib/app.dart`, `lib/core/router/launch_destination.dart`, `lib/core/router/app_router.dart`
- Test: `test/features/share_good/application/incoming_invite_link_service_test.dart`, `test/app_launch_navigation_test.dart` (extend or create), `test/core/router/launch_destination_test.dart` (extend)

**Interfaces:**
- Consumes: `ShareGoodLinks.parse/parseReferrer`, the secure `pendingIncomingToken/set/acknowledge` contract, and the existing `TaliaApp._applyLaunchNavigation` single-writer flow.
- Produces:
  - `InstallReferrerChannel.readOnce() -> Future<String?>`: method channel `talia/install_referrer`, method `getReferrer`. Kotlin returns `installReferrer` or null, and returns null on `FEATURE_NOT_SUPPORTED`, `SERVICE_UNAVAILABLE`, or after a 3 s timeout.
  - `IncomingInviteLinkService(AppLinks, InstallReferrerChannel, ShareGoodLocalStore, SharedPreferences)`: `Future<String?> initialToken()` (initial App Link, else a referrer when `share_good_referrer_checked` is unset, after which it sets the flag), and `Stream<String> tokens` (warm links). It deduplicates the same token within one process and drops tokens while the flag is disabled.
  - Extend the existing startup coordinator rather than making `LaunchDestination` a second token store: password recovery stays first; a strictly validated pending invite wins over onboarding and ordinary notification navigation; Prayer Companion/raw notification handling remains single-delivery. A first-time invite bypasses onboarding once, but does not mark onboarding complete.
- `manifestPlaceholders["shareGoodLinkHost"]` is read from the Gradle property `shareGoodLinkHost` (`-PshareGoodLinkHost=`). It defaults to `invalid.localhost`, so an unconfigured build never claims a real host.
- Release automation supplies the same canonical host in the Dart define file and `ORG_GRADLE_PROJECT_shareGoodLinkHost`; the release gate rejects a mismatch between generated share URLs and the manifest-claimed host.

- [ ] **Step 1: Failing tests:**
  - `validated pending invite bypasses onboarding once` → with first-time true, an invite token gives `/invite/<t>`. The next launch with no token gives `/onboarding`.
  - `duplicate deliveries of one token navigate once` → initial plus stream re-delivery of the same token gives one `router.go`.
  - `referrer read only on first launch and ignored for utm` → the second `initialToken` does not call the channel; `utm_source=tc` gives null.
  - `invite token does not override password recovery deep link`
  - `disabled feature ignores links and keeps ordinary startup`
  - `Flutter default deep-link handler is disabled so app_links is the only delivery owner`
  - `crash before preview acceptance leaves pending token retryable; accepted preview compare-and-acks it`
  - `widget/audio/notification launch paths retain their existing destinations when no invite exists`
  - Kotlin: `parses inv token`, `ignores utm referrer`, `rejects 42-char token`.
- [ ] **Step 2: Run** `flutter test test/features/share_good/application test/core/router` and `cd android && ./gradlew :app:testDebugUnitTest`. Expected: FAIL.
- [ ] **Step 3: Implement.** Instantiate `AppLinks` early enough to capture the initial link, but route only after app initialization through `_applyLaunchNavigation`. Register the Install Referrer bridge alongside the existing native channels. Do not add a second navigation writer and do not acknowledge a token until Invite Preview accepts it.
- [ ] **Step 4: Run** both suites, then `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Manual smoke (debug):** `adb shell am start -a android.intent.action.VIEW -d "https://invalid.localhost/i/<43 chars>" com.talia.quran` with the dev host placeholder. Expected: the preview opens, cold and warm.
- [ ] **Step 6: Commit** `feat(share-good): add App Link and install-referrer invite ingress`

### Task 7: Quran completion adapter (page, Surah, wird range)

**Files:**
- Create: `presentation/widgets/invite_activity_banner.dart`
- Modify: `lib/features/quran/presentation/pages/quran_reader_page.dart` (mount the banner when `ActiveInviteSessions.forTarget` matches the current page range)
- Test: `test/features/share_good/presentation/quran_invite_completion_test.dart`, plus a regression run of `test/features/quran/`

**Interfaces:**
- Consumes: `ActiveInviteSessions`, `InviteTargetLabel.endPage`, the reader's existing successful `QuranPageCubit.confirmRead` / `_confirmThenRecordKhatmah` result and `QuranReadConfirmationGate` state.
- Produces: `InviteActivityBanner({required InviteSession session, required bool canComplete, required VoidCallback onComplete})`. It is a slim bar below the reader controls with label "دعوة: {activity}" and the button "أتممت القراءة". `canComplete` is true when the reader is on `endPage` **and** the gate has confirmed that page. `onComplete` calls `advance(completedPrivate)` and then opens the Task 9 completion sheet.

- [ ] **Step 1: Failing widget tests** (fake repository, fake `QuranPageCubit` state):
  - `banner hidden when no active invite for this page`
  - `complete disabled until the target end page is gate-confirmed`
  - `completing a surah invite calls advance(completedPrivate) once and does not call confirmRead again` → the spy on the cubit shows exactly the gate's own call count.
  - `expired invite mid-session shows the expired notice and keeps ordinary progress` (`advance` returns `expired` → the banner turns to the notice; no exception).
  - `reader without invite behaves exactly as before` (existing reader tests pass unchanged).
  - `Khatmah final/daily target uses the existing explicit confirmation and Share Good never records the page twice`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Use no new progress writes. The banner observes the existing success boundary; it never calls `confirmRead`, `recordDigitalPage`, `advanceDailyWird`, checkpoint sync, XP, achievements, or streak services.
- [ ] **Step 4: Run** `flutter test test/features/share_good/presentation/quran_invite_completion_test.dart test/features/quran`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(share-good): report invited Quran completion from the read gate`

### Task 8: Adhkar completion adapter (morning/evening)

**Files:**
- Modify: `lib/features/azkar/presentation/pages/azkar_category_page.dart` (extend or add a listener without replacing the existing current-index/page-controller listener)
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
- [ ] **Step 3: Implement** with a dedicated completion listener or a carefully composed listener (`listenWhen` compares previous/current `allDone`) while preserving the existing current-index/page-controller behavior.
- [ ] **Step 4: Run** `flutter test test/features/share_good/presentation/azkar_invite_completion_test.dart test/features/azkar`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(share-good): report invited adhkar completion on fresh allDone`

### Task 9: Completion consent sheet, disclosure, account conversion

**Files:**
- Create: `presentation/widgets/invite_completion_sheet.dart`
- Modify: `lib/features/auth/presentation/pages/login_page.dart` only if required for a generic `?from=share_good` marker. The bearer token stays in secure session storage; never put `/invite/<token>` in a login return query.
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
  - `account deletion and account switch clear only owner-scoped identity/prompt/seen state; installation guest sessions remain private and usable`
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
- Modify: Dawn's `social_share_model.dart` (add `SocialShareCategory.invitation`, `linkUrl`, and invitation factory), `share_card_shell.dart` (invite URL QR; preserve `ShareCardLinks.forCategory` for every existing category), `share_card_template_resolver.dart` (existing text hero, title only; **no sacred text**), and `social_share_sheet.dart` (editable message, immutable appended link). Add entry points to `ReaderOverflowSheet`, `azkar_category_page.dart`, `khatmah_dashboard_page.dart`, `daily_wird_card.dart`; convert `KhatmahCompletionPage._shareAchievement` from direct `SharePlus` to Dawn and then expose the post-completion invitation action.
- Test: `test/features/share_good/presentation/invite_create_cubit_test.dart`, `invite_mode_sheet_test.dart`, `share_good_action_test.dart`; extend `test/core/widgets/social_share_test.dart`, `test/core/widgets/social_share/share_card_copy_links_test.dart`, `share_card_render_test.dart`, `share_invitation_fit_test.dart`, and `test/features/khatmah/presentation/pages/khatmah_completion_page_test.dart`.

**Interfaces:**
- Consumes: `ShareGoodRepository.create`, `InviterIdentityResolver`, `InviteTargetLabeler`, owner-scoped identity preference, and `ShareGoodAvailability`.
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
  - `all pre-existing Dawn categories retain their Play/UTM QR and export output`
  - `Khatmah completion no longer bypasses Dawn and still shares without creating an invite when the user chooses ordinary share`.
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
- Create: `presentation/cubits/good_impact_cubit.dart`, `presentation/pages/good_impact_page.dart`, `domain/services/good_impact_milestone_policy.dart`, `application/good_impact_indicator_controller.dart`, `presentation/widgets/share_good_settings_tiles.dart`
- Modify: `app_router.dart` (`AppRoutes.goodImpact = '/settings/good-impact'`, auth required), `settings_hub_body.dart` (one nav tile "أثر الخير" with a "new" dot), `lib/app.dart` (ask the controller on eligible resume), and Share Good DI
- Test: `good_impact_cubit_test.dart`, `good_impact_milestone_policy_test.dart`, `good_impact_indicator_controller_test.dart`, `good_impact_page_test.dart`

**Interfaces:**
- Consumes: `ShareGoodRepository.impact`.
- Produces: `GoodImpactMilestonePolicy.derive(GoodImpact) -> Set<GoodImpactMilestone>`, using `firstChainStarted` (`downstreamReach >= 1`), `fiveReach` (`responses + downstreamReach >= 5`), `tenResponses` (`responses >= 10`), and `twentyFiveReach` (`>= 25`). `GoodImpactCubit.hasNew` compares acknowledgements and milestones against owner-scoped `share_good_impact_seen_v1|<ownerId>`. Refresh is throttled to once per 6 h (D9), resets on account switch, and never exposes the prior owner's fingerprint.
- Copy: "{count} أشخاص استجابوا لدعوتك", "{count} أتمّوا القراءة", "امتد أثر دعوتك إلى {count} شخصًا". Use ARB plural forms for Arabic (zero/one/two/few/many/other).

- [ ] **Step 1: Failing tests:**
  - `milestones never call XpService or AchievementService` (DI spy with zero interactions).
  - `page shows only aggregates and opted-in names; no ranking or comparison text`
  - `active and recently expired lists are separated`
  - `new dot clears after the page is viewed`
  - `Arabic plural forms render for 0, 1, 2, 3, 11, 100`
  - `signed-out user is sent to sign-in with return to good impact`
  - `resume refresh is owner-scoped, throttled for 6 h, and never runs while rollout/auth is unavailable`
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
- Create: `application/share_good_notification_controller.dart` (validates/claims opaque `sg1|<localSessionId>` responses and resolves the secure session)
- Modify: `lib/features/settings/presentation/cubits/notification_settings_{cubit,state}.dart`, `lib/features/settings/presentation/widgets/settings_notification_tiles.dart`, `lib/core/services/notification_scheduler.dart`, `lib/app.dart` raw-response coordination, and `share_good_settings_tiles.dart` (owner-scoped identity preference)
- Test: `test/core/services/notification_scheduler_share_good_test.dart`, `test/features/share_good/application/share_good_notification_controller_test.dart`, `share_good_settings_tiles_test.dart`, and extend `test/core/router/notification_payload_route_guard_test.dart`

**Interfaces:**
- Consumes: the `ActiveInviteSessions.changes` stream and the existing quiet-hours keys (`TaliaNotificationService.quietHoursPreferenceKey`/`StartKey`/`EndKey`).
- Produces: `scheduleInviteReminder(InviteSession)` fires at `expiresAt − 2h`, or at `started + 1h` if that is later, but never after `expiresAt − 15m`. It follows the scheduler's existing quiet-hours and notification-budget rules, is cancelled on completion/expiry, and keeps at most one pending invite reminder. The native payload is `sg1|<opaqueLocalSessionId>`; the controller looks up the token from secure storage only after validation. Body: "دعوتك لقراءة {activity} ما زالت متاحة". The feature never requests notification permission itself.
- `NotificationSettingsState.inviteReminder` defaults on, is loaded/saved only through `NotificationSettingsCubit`, and appears only while Share Good is available. Turning it off cancels the pending invite reminder immediately.

- [ ] **Step 1: Failing tests:** `schedules once for a started incomplete invite`, `cancelled on completion`, `respects quiet hours and global budget`, `not scheduled when Cubit toggle off or permission denied`, `payload contains no token or slash route`, `valid opaque id opens its secure session once`, `unknown/tampered id is a no-op`, and `Prayer Companion/legacy notification handling remains unchanged`.
- [ ] **Step 2–4:** Run (expected FAIL), implement, run (expected PASS). Run the notification Cubit/state tests, scheduler tests, raw-controller tests and `notification_payload_route_guard_test.dart` together.
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
  - `manifest disables Flutter's default deep-link handler because app_links owns ingress`
  - `redirect passes the token only inside referrer=inv%3D and targets com.talia.quran`
  - `index.html contains no script tag and no external resources`
  - `assetlinks template declares delegate_permission/common.handle_all_urls for com.talia.quran`
  - `unconfigured release host fails closed and cannot claim a production domain`
  - `release Dart host and Gradle manifest host are identical after normalization`
- [ ] **Step 2–4:** Run (expected FAIL), create the artifacts, run (expected PASS).
- [ ] **Step 5: Write `qa/share_good_runtime_qa.md`** with a pass/fail table for a **signed release** build on two physical Android devices (one Android 12+). Cases: installed cold, warm, background and duplicate delivery via WhatsApp/Telegram; first-ever launch bypasses onboarding once; not installed → real Play listing → install → preview restoration; app update/reinstall/referrer already-consumed behavior; `adb shell pm get-app-links com.talia.quran` shows `verified`; upload-key and Play-App-Signing fingerprints; expired/invalid/offline-first-open; Arabic/English; reminder delivery without token leakage; account switch/deletion; share-sheet cancel.
- [ ] **Step 6: Commit** `feat(share-good): add minimal link hosting artifacts and platform contract`

### Task 16: Full regression and acceptance gate

- [ ] **Step 1:** Run focused suites first: Share Good, Dawn link/render/export/fit, router/startup/notification policy, Quran, Azkar, Khatmah, auth/account-switch/account-deletion, backup exclusion, and Supabase static/security tests.
- [ ] **Step 2:** Run `./scripts/verify_v1_release.ps1` with its required release define file and fresh-DB variables (pub/lock check, gen-l10n, build generation, analyze, full tests, Supabase checks, and signed AAB when enabled). Expected: all green and evidence path recorded.
- [ ] **Step 3:** Scope scan with `rg -n -i -g 'app_*.arb' "leaderboard|rank|friends|followers|ثواب|حسنات|أجر|reward|blessing points" lib/features/share_good lib/core/l10n`; review hits, because generic localization files may contain unrelated existing words. Share Good keys must have no banned copy.
- [ ] **Step 4:** Privacy scans prove no RPC response exposes `creator_user_id`, `participant_key_hash`, `token_hash`, email/phone; no prefs/logs/notification payload/last-restorable route contains an invite token; no Share Good key enters portable backup.
- [ ] **Step 5:** Apply through the normal staging pipeline, refresh the API schema cache if required, run the exact contract verifier and smoke every RPC as its intended role. Only after staging passes may the owner schedule production migration deployment; old clients remain safe because the migration is additive and the rollout flag is off.
- [ ] **Step 6:** Execute signed-device `qa/share_good_runtime_qa.md` once B1–B3 are closed. Until every required row passes, `ExperienceFeature.shareGood` stays `off` and status is **BLOCKED (external)**, not done.
- [ ] **Step 7:** Map every design §29 acceptance item to a named automated test or QA row. AC19 reads “Android: verified end-to-end through Play / iOS: explicitly unsupported in V1 (D1)”.
- [ ] **Step 8: Commit** `docs(share-good): record V1 acceptance evidence`

---

## 6. External blockers (owner)

| # | Needed | Blocks |
|---|---|---|
| B1 | A domain or subdomain for invite links plus static hosting that supports `_redirects` and `/.well-known` (for example Cloudflare Pages) | Tasks 15–16 runtime, enabling the flag |
| B2 | SHA-256 fingerprints of the release upload key **and** the Play App Signing key (Play Console → App integrity) | `assetlinks.json` verification |
| B3 | Apply the migration to staging, refresh schema cache if needed, run the deployed contract/RPC tests, then separately approve production deployment through the normal pipeline | Enabling the flag |
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
| 23/28 Metrics | 3/12 product aggregates; behavioural analytics deferred by D5 |
| 24 Account conversion | 9 |
| 25 Edge cases | 4, 5, 7, 9, Review Focus |
| 26 UX, RTL/LTR, a11y | 5, 9, 10, 12 |
| 27 Modules | File map §5 |
| 29 Acceptance | 16 |
| Kids audience (spec gap) | 5, 10 (D8) |

## 8. Execution order and exit gates

- Run A → B → C → D → E → F in order. Within B, Task 6 can run in parallel with Tasks 7 and 8 once Task 5 lands.
- **Gate A:** domain/store/repository tests, backup/reset classification, static SQL/security contract and disposable-DB behavioural SQL pass. No UI has changed.
- **Gate B:** the guest integration flow passes. Quran and azkar suites are unchanged and green.
- **Gate C:** invites are created from all four entry points, and the copy scan is clean.
- **Gate D/E:** impact, prompts, and the reminder are tested. There is no XP or achievement coupling.
- **Gate F:** staging contract/RPC smoke, `verify_v1_release.ps1`, signed AAB and physical-device/Play QA are green before `ExperienceFeature.shareGood` changes from `off`.

## 9. External references rechecked on 2026-11-05

- [Supabase database functions](https://supabase.com/docs/guides/database/functions): prefer invoker; definer helpers require an empty `search_path`, ownership checks and narrow execute grants.
- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security): exposed-schema tables/views need explicit RLS/ACL treatment; `anon` is a database role, not an anonymous Auth user.
- [Supabase database testing](https://supabase.com/docs/guides/database/testing) and [local migrations](https://supabase.com/docs/guides/local-development/database-migrations): test migrations/RLS on a disposable database before deployed contract verification.
- [Flutter Android App Links](https://docs.flutter.dev/cookbook/navigation/set-up-app-links): verified HTTPS links require the owned domain, `assetlinks.json`, signing fingerprints and `flutter_deeplinking_enabled=false` when `app_links` owns ingress.
- [Google Play Install Referrer](https://developer.android.com/google/play/installreferrer): use the Play client library on supported Play Store devices and verify the real install path.
- [Cloudflare Pages redirects](https://developers.cloudflare.com/pages/configuration/redirects/): `_redirects` supports external targets, named path placeholders and query strings; the deployed redirect remains part of runtime QA.
