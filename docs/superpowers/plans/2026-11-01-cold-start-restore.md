# Cold-start guest restore — continuation contract

User authorized finishing the remaining initiatives on 2026-11-01. Current branch is `codex/three-initiatives-completion`; preserve all earlier uncommitted work. No production deployment, paid resources, new license acceptance or religious-content approval is implied.

## Decision and invariants

Full replacement is guest-only and runs before the normal progress runtime is created. Normal settings only schedule a random request ID; the file is chosen, previewed and confirmed again in maintenance. No plaintext payload is staged. The normal DI restorer stays mechanically disabled. Only a validated maintenance permit can enable a private replacement instance.

Android admission must cover separate Flutter engines in one process and separate processes. Dart file locks alone are insufficient on Unix. An in-repository Flutter plugin uses a synchronized Java broker, one aggregated shared OS lock for readers, and exclusive maintenance locking. A process that served foreground progress never becomes maintenance; its foreground holder survives Dart/Activity/GetIt teardown until process exit. Unsupported platforms cannot replace data.

Acquire before prefs/progress initialization. Workers acquire shared admission, inspect the encrypted journal read-only, then read business preferences or open Isar, and retain admission through the awaited task. Pending/unreadable journals return retry. Default production Isar opening must require a valid non-probe capability on Android.

At cold startup probe the private request marker and journal before normal DI. Pending recovery/request requires exclusive admission and a private bootstrap. Recover first. Do not initialize AuthCubit, home widget, group environment, progress migrations, notifications or warmups during maintenance. Normal promotion must not leave an unlocked gap.

Recheck real authentication, deletion markers, account lease and guest ownership before destructive writes and commit. Forced sign-out may retain account-owned unscoped stores despite a guest owner provider; record preservation before sign-out, clear only after successful destructive cleanup, and refuse ambiguous old account history.

The guest checkpoint authority is `reading_checkpoint_v1_guest`, in addition to the compatibility key. Journal both including absence, expose the key from its repository owner, and write through the existing under-lease repository/AppSession path. Old backup versions or missing checkpoint sections preserve both.

## Ownership and execution

- Terra: `packages/talia_data_admission/**`, `lib/core/storage/data_admission.dart`, notification worker admission + focused tests.
- Root: shared dependency registration, Isar entrypoint, startup/private maintenance bootstrap and UI, guest ownership marker, checkpoint/journal integration, localized settings entry and combined validation.
- Astra: narrow read-only design investigation completed. No full application audit.

## Steps

- [x] Investigate existing writer/isolate exposure and choose enforceable admission design.
- [x] Native broker and thin all-engine Flutter plugin; Java contention harness (same JVM and separate JVMs).
- [x] Dart admission and worker guard; 8 focused tests passed in worker evidence.
- [x] Add read-only journal admission check; journal/checkpoint group passed 31 tests.
- [ ] Wire path dependency and verify generated plugin registration/build. Dependency and generated registration verified; Android compile remains incomplete (Gradle configuration stalls before plugin task).
- [x] Enforce admission on default Isar open and normal activation order.
- [x] Implement opaque request persistence and private maintenance startup/screen. Scheduling never stages payloads; current gated Android workflow explains a full stop from app info before reopening.
- [x] Add preserved-account ownership guard and guest checkpoint restore/rollback.
- [x] Host/JVM checks: both admission orders, sticky foreground/warm-process denial, cancellation, request consumption, private recovery and absent checkpoint rollback. This does not claim Android engine/process-death acceptance.
- [ ] Run native build/host tests; actual Android cold/headless/runtime acceptance remains separate.

## Independent verification work

The connected Supabase account has only the default Talia branch, so do not use it as a disposable test target. A portable PostgreSQL 17.6 archive is being fetched into `.tmp/pg-verification` from the publisher linked by postgresql.org. Verify its published SHA-256 before execution. Local auth fixtures must be labeled as fixtures, not full Supabase Auth or deployed RLS proof. Do not accept any cost for a new cloud branch without explicit agreement.

Completed locally on 2026-11-02: checksum-verified PostgreSQL 17.6, migration, existing SQL tests, additional role/direct-write/replay/deletion checks, coordinated two-connection CAS race, and shutdown all passed. See `.tmp/pg-verification/verification-transcript.txt`; fixtures do not prove deployed Auth/PostgREST behavior. No production migration was applied.

Android SDK tools and a valid JDK 21.0.10 exist. No AVD or system-image payload is installed; C: is nearly full, D: has about 11 GB. Do not install a system service, change Hyper-V settings, or download multi-GB images without evaluating these constraints. Human content approval is still separate from technical source preparation.

## Related cold identity defect — 2026-11-02

The read-only investigation confirmed that a restarted forced-preserve logout without Khatmah could admit a fresh guest barrier and expose unscoped account XP. Added a pre-progress identity guard, private same-owner authentication recovery, durable guest fencing, deferred startup reconciliation, resumption of interrupted cleanup, and awaited initial deletion cleanup. No data is silently discarded. Ambiguous legacy ownership may require signing back into the previous account; no guest-clean proof is inferred.

Focused verification: 368 tests passed before final presentation/format refactors. Real initializer integration verifies no Isar/AuthCubit/progress activation on retained guest data. Java plugin source compiled cleanly with real cached Android/Flutter APIs under Java 17. Complete APK packaging/device acceptance and the final full-suite result remain separately tracked in the release report.

## Combined verification closure — 2026-11-03

Fresh `flutter test --no-pub --concurrency=8`: **5991 passed, exit 0** (13:49). Fresh `flutter analyze --no-pub`: **No issues found, exit 0**. Exact logs are linked in the release report. Native Java plugin compilation passed; Android APK/device acceptance is a separate gate. Actual source archives and a human-review packet now exist outside application assets; no religious-content approval is inferred.
