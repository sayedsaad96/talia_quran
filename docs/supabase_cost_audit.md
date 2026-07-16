## Executive summary

**No-Go for production at scale.** The app is mostly offline-tolerant and avoids Realtime/storage uploads, but its cloud layer is not delta-based end-to-end. Full pulls on resume, per-event kids uploads, an unbounded parent dashboard, and a guardian-link race will create cost, integrity, and privacy failures.

Scores:

| Area | Score |
|---|---:|
| Production readiness | 47/100 |
| Supabase cost efficiency | 35/100 |
| Sync reliability | 34/100 |
| Offline-first compliance | 62/100 |
| Database quality | 58/100 |
| Flutter architecture | 70/100 |
| Hifz experience | 68/100 |

Positives: Isar is used for review records and the persistent retry queue; review/log/certificate tables have useful uniqueness constraints; the auth sync has an in-flight mutex; no Realtime subscription or app-driven Storage upload was found.

### Findings

#### 1. Guardian pairing can link one child to multiple parents

**Severity:** Critical  
**Category:** Security / Sync  
**Location:** [supabase_schema.sql](D:/Sayed/Flutter/talia_quran/supabase_schema.sql:203)

**Root cause:** The function reads an unused token, inserts a parent-child link, then marks the token used. Two requests can read the same unused token before either update occurs. The primary key allows multiple parents for one child.

**Impact:** Multiple parents can retain RLS-authorized access to a child’s progress. This is a privacy breach.

**Cost impact:** Low direct cost; high legal/support risk.

**Recommended fix:** Atomically consume the token and enforce at most one active guardian per child.

```sql
WITH consumed AS (
  UPDATE public.child_link_requests
  SET used_at = now()
  WHERE token_hash = p_token_hash
    AND used_at IS NULL
    AND expires_at > now()
  RETURNING child_user_id
)
INSERT INTO public.parent_child_links (parent_user_id, child_user_id, status)
SELECT auth.uid(), child_user_id, 'active' FROM consumed;

CREATE UNIQUE INDEX one_active_guardian_per_child
ON public.parent_child_links (child_user_id)
WHERE status = 'active';
```

**Confidence:** High.

#### 2. Every authenticated app resume runs a full cloud-sync workflow

**Severity:** High  
**Category:** Sync / Cost  
**Location:** [app.dart](D:/Sayed/Flutter/talia_quran/lib/app.dart:54), [auth_cubit.dart](D:/Sayed/Flutter/talia_quran/lib/features/auth/presentation/cubits/auth_cubit.dart:143)

**Root cause:** Resuming the app invokes pull-then-push synchronization regardless of whether anything changed. The auth-state listener can invoke the same workflow for session events.

**Impact:** Repeated database reads, bandwidth use, battery drain, and server load. `_syncInFlight` prevents overlapping runs, but not repeated sequential runs.

**Cost impact:** At least five cloud reads per completed sync cycle before any writes: streak, XP, daily activities, review records, and daily plan.

**Recommended fix:** Trigger sync only when the durable outbox is non-empty, a server cursor is stale, or the user explicitly refreshes; debounce lifecycle events.

```dart
if (!outbox.hasPending && !cursor.isStale) return;
await syncCoordinator.runDebounced(reason: SyncReason.resume);
```

**Confidence:** High.

#### 3. Cloud pulls are full-table reads, not delta synchronization

**Severity:** High  
**Category:** Sync / Cost  
**Location:** [auth_repository_impl.dart](D:/Sayed/Flutter/talia_quran/lib/features/auth/data/repositories/auth_repository_impl.dart:433), [memorization_plus_repository_impl.dart](D:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart:1815)

**Root cause:** Reads use unrestricted `select()`/`pull_ayah_review_records()` and do not send a cursor. Local `lastSyncedAt` exists but is not used for downloads; no `sync_version` exists.

**Impact:** A fully memorized user can download all 6,236 review rows on every resume. This violates the stated delta-only requirement.

**Cost impact:** Principal bandwidth and database-compute driver at 10k+ MAU.

**Recommended fix:** Persist one server-issued cursor per dataset and pull only `updated_at > cursor`, with deterministic pagination.

```sql
CREATE FUNCTION pull_ayah_review_records_since(p_cursor timestamptz)
RETURNS SETOF public.ayah_review_records_cloud AS $$
  SELECT *
  FROM public.ayah_review_records_cloud
  WHERE user_id = auth.uid()
    AND updated_at > p_cursor
  ORDER BY updated_at, id
  LIMIT 500;
$$ LANGUAGE sql SECURITY DEFINER SET search_path = public;
```

**Confidence:** High.

#### 4. Kids completion performs immediate, unqueued cloud sync

**Severity:** High  
**Category:** Sync / Cost / Offline-first  
**Location:** [memorization_plus_repository_impl.dart](D:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart:963), [memorization_plus_repository_impl.dart](D:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart:1234)

**Root cause:** Each new kids log calls `unawaited(syncKidsProgressToCloud())`. It always upserts the whole kids-progress snapshot; failed `Either` results are ignored and never enqueued.

**Impact:** Rapid completions can overlap uploads. If the final upload fails and the child stops using the app, logs remain unsynced indefinitely.

**Cost impact:** About two RPCs per completed ayah in the normal path: progress upsert plus log batch.

**Recommended fix:** Mark the progress snapshot and logs dirty locally, merge them into the Isar outbox, and let one serialized sync coordinator upload them.

```dart
await outbox.upsert(SyncOp.kidsProgress, payloadHash: progress.hash);
await outbox.upsertMany(SyncOp.kidsLog, pendingLogs);
syncCoordinator.schedule();
```

**Confidence:** High.

#### 5. Cloud conflict resolution can make weak recitation appear stronger

**Severity:** High  
**Category:** Sync / Architecture  
**Location:** [supabase_schema.sql](D:/Sayed/Flutter/talia_quran/supabase_schema.sql:1246)

**Root cause:** `upsert_ayah_review_records` uses `GREATEST` for strength, interval, ease factor, and review count. A legitimate weak review that should reduce mastery cannot reduce those fields in cloud state.

**Impact:** A later pull can restore an overly optimistic SRS record, causing under-review of weak ayahs. This is particularly harmful for memorization retention.

**Cost impact:** Indirect: extra support, retries, and data corrections.

**Recommended fix:** Use a row version or event sequence, and apply the complete record from the latest legitimate review event—not independent field-wise maxima.

```sql
... ON CONFLICT (user_id, surah_id, ayah_number) DO UPDATE
SET strength_level = EXCLUDED.strength_level,
    interval_days = EXCLUDED.interval_days,
    ease_factor = EXCLUDED.ease_factor,
    sync_version = EXCLUDED.sync_version
WHERE EXCLUDED.sync_version > ayah_review_records_cloud.sync_version;
```

**Confidence:** High.

#### 6. Parent dashboard constructs an unbounded JSON document

**Severity:** High  
**Category:** Database / Performance / Cost  
**Location:** [supabase_schema.sql](D:/Sayed/Flutter/talia_quran/supabase_schema.sql:1343)

**Root cause:** `get_remote_children_dashboard()` aggregates all review rows, all rewards, and all certificates for every linked child into one JSON result.

**Impact:** Query time, memory, response size, and mobile decoding scale with child count and history. A child’s review dataset can reach 6,236 rows.

**Cost impact:** Large database egress and CPU spikes whenever a parent opens or refreshes the dashboard.

**Recommended fix:** Return summary rows only; fetch paginated detail on demand.

```sql
SELECT user_id, count(*) AS review_count, max(updated_at) AS latest_review_at
FROM ayah_review_records_cloud
WHERE user_id = ANY(p_child_ids)
GROUP BY user_id;
```

**Confidence:** High.

#### 7. Retry queue can reset backoff and eventually deletes unsynced work

**Severity:** High  
**Category:** Sync / Data integrity  
**Location:** [cloud_sync_queue.dart](D:/Sayed/Flutter/talia_quran/lib/core/sync/cloud_sync_queue.dart:25)

**Root cause:** `enqueue()` recreates the unique queue item with `attemptCount = 0`; repeated failures can reset backoff. Conversely, `markFailure()` deletes the item at eight attempts.

**Impact:** The queue is neither a stable bounded retry mechanism nor a recoverable dead-letter queue. Failed sync work can be lost.

**Cost impact:** Request storms during unstable connectivity; later manual recovery/support cost.

**Recommended fix:** Preserve retry state on duplicate enqueue, add jitter, and retain exhausted items as user-visible dead letters.

```dart
existing ??= CloudSyncQueueItem()..kind = kind;
existing.nextRetryAt = min(existing.nextRetryAt, now);
await items.put(existing); // never reset attemptCount
```

**Confidence:** High.

#### 8. Every sync re-uploads all earned certificates

**Severity:** Medium  
**Category:** Cost / Sync  
**Location:** [auth_cubit.dart](D:/Sayed/Flutter/talia_quran/lib/features/auth/presentation/cubits/auth_cubit.dart:311), [achievement_service.dart](D:/Sayed/Flutter/talia_quran/lib/core/services/achievement_service.dart:238)

**Root cause:** Every sync loads all local certificates and calls `pushCertificatesToCloud`; newly earned certificates are also pushed immediately.

**Impact:** The uniqueness constraint prevents duplicate rows, but not duplicate API calls.

**Cost impact:** One unnecessary upsert per sync cycle for every user with any certificate.

**Recommended fix:** Store per-certificate dirty state or a local synchronized certificate-ID set.

```dart
final unsynced = certificates.where((c) => c.cloudDirty).toList();
if (unsynced.isNotEmpty) await pushCertificates(unsynced);
```

**Confidence:** High.

#### 9. Memorization domain data remains in SharedPreferences, not Isar

**Severity:** Medium  
**Category:** Architecture / Performance  
**Location:** [memorization_plus_local_datasource.dart](D:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart:481)

**Root cause:** Daily plans, kids progress, kids session logs, pairing state, and parent rewards are serialized into SharedPreferences.

**Impact:** This contradicts the required “Isar is the only local source of truth” architecture. Session-log writes reserialize the full log list, which becomes slower and more failure-prone as it grows.

**Cost impact:** Indirect: larger retry payloads and weaker crash recovery.

**Recommended fix:** Move domain records and the sync cursor/outbox into Isar collections; reserve SharedPreferences for UI-only preferences.

```dart
@collection
class IsarKidsSessionLog {
  Id id = Isar.autoIncrement;
  @Index(unique: true) late String localId;
  late bool cloudDirty;
  late DateTime completedAt;
}
```

**Confidence:** High.

#### 10. Older `SECURITY DEFINER` functions lack a fixed search path

**Severity:** Medium  
**Category:** Security  
**Location:** [supabase_schema.sql](D:/Sayed/Flutter/talia_quran/supabase_schema.sql:615)

**Root cause:** Older privileged RPCs use `SECURITY DEFINER` without `SET search_path = public`; newer functions correctly include it.

**Impact:** The source is inconsistent with PostgreSQL’s recommended hardening for privileged functions.

**Cost impact:** None directly.

**Recommended fix:**

```sql
ALTER FUNCTION public.upsert_ayah_progress(JSONB)
  SET search_path = public;
```

**Confidence:** Medium — live database ownership, grants, and schema privileges were not available to verify.

## Cost simulation

This is a transparent upper-bound model, not a measurement from the deployed project: one resume-sync per user/day, 30 days/month, all 6,236 review rows present, and roughly 0.30 KB of API JSON plus indexes per row. The repository cannot provide actual MAU, payload compression, row sizes, usage metrics, or compute tier.

| MAU | Minimum sync requests/month | Review-only egress/month | Review-table footprint | Approx. Pro variable total/month* |
|---:|---:|---:|---:|---:|
| 100 | 15,000 | 5.6 GB | 0.19 GB | $25 |
| 1,000 | 150,000 | 56 GB | 1.9 GB | $25 |
| 10,000 | 1.5 M | 560 GB | 18.7 GB | ~$54 |
| 100,000 | 15 M | 5.6 TB | 187 GB | ~$529 |
| 500,000 | 75 M | 28 TB | 935 GB | ~$3,939 |

\*Excludes compute scaling, backups/PITR, taxes, extra projects, and any unmeasured traffic. Supabase currently lists unlimited API requests, but egress, database disk, and MAU are billed/limited; Pro includes 100k MAU, 8 GB database disk, and 250 GB egress, with published overages thereafter. [Supabase pricing](https://supabase.com/pricing), [billing documentation](https://supabase.com/docs/guides/platform/billing-on-supabase).

Storage and Realtime: no active client Storage call or Realtime subscription was found. The schema contains only commented certificate-bucket examples, so remote bucket state cannot be verified from this repository.

## Top 20 priority actions

1. Atomically consume guardian tokens.
2. Enforce one active guardian per child.
3. Replace resume-driven full sync with an outbox-driven coordinator.
4. Add server cursors and paginated delta pulls.
5. Add `sync_version` and operation IDs.
6. Make SRS conflict resolution event/version based.
7. Queue kids progress and logs; remove fire-and-forget uploads.
8. Preserve queue retry state; retain dead letters.
9. Upload only dirty certificates.
10. Return parent dashboard summaries, not full history.
11. Paginate review history and certificates.
12. Add retention/aggregation for session logs.
13. Move memorization domain data from SharedPreferences to Isar.
14. Add conditional updates to avoid WAL churn on identical data.
15. Add `SET search_path = public` to every privileged function.
16. Use Supabase CLI migrations with a deployed-schema verification step.
17. Add integration tests against a disposable Supabase project for RLS and RPC races.
18. Add tests for cursor sync, duplicate events, and exhausted retry recovery.
19. Monitor egress, response size, queue age, and sync failure rate.
20. Set budget alerts/spend caps before launch.

## Verification limits

I inspected the repository only. I could not verify the deployed schema, active RLS policies, query plans, bucket contents, Edge Functions, Supabase metrics, or billing configuration. The saved July 2 test run records **607 tests with 6 failures**; its static-analysis log is also dated July 2. A fresh `flutter analyze` attempt exceeded three minutes without producing a result.

No project files were changed.