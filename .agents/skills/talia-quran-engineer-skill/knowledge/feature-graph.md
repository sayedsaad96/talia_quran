# Feature Graph

Verified source navigation on 2026-10-06 at `d37da52d72f721adee09b5b9526dff03ad576b58`; medium confidence, runtime unverified. Relationships must be retraced when affected code changes.

| From → To | Boundary to inspect | Source evidence |
|---|---|---|
| Splash → full app/router/services | Readiness gate and initialization | `lib/app.dart`, `lib/core/services/app_initializer.dart` |
| Auth → local owner/queue/cloud consumers | Owner readiness/account switch and cache isolation | `lib/core/identity/record_owner_provider.dart`, `lib/features/auth/application/cloud_sync_coordinator.dart`, `lib/core/sync/cloud_sync_queue.dart` |
| Adult V2 session → review/progress/effects | Durable commit then adult deferred effects/refresh; kids use a separate committer/reward path | `lib/core/memorization/v2/review_outcome_committer.dart`, `review_effect_outbox_processor.dart`, `lib/core/progress/progress_events_bus.dart` |
| Quran reader → khatmah recording | Confirmation before recording reading credit | `lib/features/quran/presentation/services/quran_read_confirmation_gate.dart`, `lib/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart` |
| Home → reading/hifz/khatmah/prayer context | Shared journey and action resolution, not a second progress calculator | `lib/core/journey/`, `lib/features/home/domain/services/home_primary_action_resolver.dart` |
| Prayer companion → notification delivery | Policy/planning versus OS delivery | `lib/features/prayer_companion/domain/services/prayer_companion_scheduler_planner.dart`, `lib/core/prayer_delivery/` |
| Governed corpus → azkar/share/notifications | Exact output and approval boundaries | `lib/core/content/approved_azkar_content.dart`, `test/core/content/no_ungoverned_religious_output_test.dart`, `test/core/widgets/social_share_quran_exactness_test.dart` |

A relationship is an impact-analysis starting point, not proof of synchronous calls or a supported runtime path. Shared identifiers require regression coverage across consumers even if no direct import exists.
