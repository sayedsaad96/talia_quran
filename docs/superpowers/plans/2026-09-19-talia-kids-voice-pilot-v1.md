# Talia Kids Voice Pilot V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a privacy-safe, per-child-consented Arabic Push-to-Talk pilot on the audited Kids simple-exercise surface using on-device recognition, one retry, then visual command buttons, without making online recognition a release dependency.

**Architecture:** The Voice Pilot is a subordinate package inside `talia_companion/voice`. A cancellation-aware controller coordinates consent, the existing audio owners, an on-device recognizer, a closed deterministic classifier, and page-owned command callbacks. `OnlineSpeechRecognizer` is defined as an extension interface only; V1 has no provider implementation and the controller never calls it.

**Tech Stack:** Flutter 3.47.1, Dart, Cubit, `get_it`, `speech_to_text` 7.4.0, `permission_handler` 12.0.3, `just_audio`, `shared_preferences`, existing Parent PIN/profile/account/audio infrastructure, ARB localization.

**Spec:** `docs/superpowers/specs/2026-09-19-talia-companion-v1-design.md`

**Audit:** `docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md`

**Depends on:** Completed and reviewed `docs/superpowers/plans/2026-09-19-talia-companion-v1-core.md` with Core enabled independently and Voice disabled.

## Global Constraints

- V1 launch path is exactly: on-device recognition → one retry after the first unknown/failure → visual command buttons after the second unknown/failure.
- There is no online fallback in V1. Define `OnlineSpeechRecognizer` as an interface, register no implementation, expose no online consent toggle, send no network audio, and assert in tests that the controller does not invoke an online recognizer.
- Voice Pilot remains independently kill-switchable and defaults off. Disabling Voice must not disable or destabilize the visual Core.
- Push-to-Talk only: press/hold begins listening; release stops listening and starts recognition. No wake word, background listening, free-form chat, LLM classification, or runtime TTS.
- Closed intents are exactly `start`, `next`, `repeat`, `back`, `help`, `finish`, and `unknown`.
- Initial production host is the audited simple-exercise surface `KidsGamifiedListenContent`. The mic is absent on Adult screens, Home, Journey Map, Stage Start, completion, Quran Reader, Kids Quran Reader, playback, recording, evaluation, and every unsupported route.
- No stored audio bytes, audio path, full transcript, recognized phrase, child name, or voice history. Recognizer text may exist only in memory until classification, then must be discarded.
- Consent is per stable local child profile, owner scoped, versioned, guardian verified, accepted before OS microphone permission, and immediately revocable.
- Remote child entries (`FamilyChildEntry.isLocal == false`) never expose or mutate device-local consent.
- A stable opaque `MemorizationProfile.profileId` migration must ship and pass isolation/reset tests before any consent is stored.
- Technical faults are neutral system states, never learner failure or encouragement.
- Quran audio/user recording has priority over voice input; voice input has priority over prerecorded Talia response. Starting a higher-priority activity cancels lower-priority work.
- All async results are guarded by request ID, owner ID, child profile ID, route, surface, and stage/session context. Invalid results are discarded without executing commands.
- Approved prerecorded Arabic clips are required for spoken acknowledgments; runtime TTS is prohibited. If clips are unavailable, visual intent execution and buttons may be tested, but the production Voice flag must remain off.
- Approve `consentVersion = 1`, exact Arabic/English consent/privacy copy, local-child migration semantics, clip files, telemetry schema, and Android device matrix before enabling the flag. Do not invent legal/provider claims.
- Keep the documented baseline: any failure beyond the two known date-sensitive Prayer notification fixtures is a regression.

## Review Focus

- A recognizer result arriving after navigation, backgrounding, profile switch, consent revoke, or a newer request must execute no command; Task 6 pins every cancellation dimension.
- A migrated local child must keep one stable `profileId` across ordinary updates but receive a new ID after identity reset/reselection; Tasks 1-2 pin storage and cleanup.
- The controller must never call online recognition, even for low confidence, offline failure, or retry exhaustion; Tasks 5 and 8 use a throwing fake to prove this.
- Permission denied/permanently denied and recognizer/audio failures must show neutral visual controls, not consume a learner retry as a mistake; Task 8 separates technical and unknown paths.
- Press/release races and overlapping requests must leave one active request and one audio owner; Tasks 7-8 test idempotent cancellation and arbitration.

---

## File Map

### New Voice files

| File | Responsibility |
|---|---|
| `lib/features/talia_companion/voice/domain/voice_consent.dart` | Versioned per-owner/per-child consent value object and scope. |
| `lib/features/talia_companion/voice/domain/voice_intent.dart` | Closed intent and recognition result types. |
| `lib/features/talia_companion/voice/domain/arabic_voice_intent_classifier.dart` | Deterministic MSA/simple-Egyptian normalization and classification. |
| `lib/features/talia_companion/voice/domain/voice_surface_policy.dart` | Exact allow-list for the initial Kids exercise host. |
| `lib/features/talia_companion/voice/domain/prerecorded_voice_catalog.dart` | Exhaustive intent/status-to-approved-clip mapping. |
| `lib/features/talia_companion/voice/data/voice_consent_repository.dart` | Owner+stable-child keyed consent persistence and cleanup. |
| `lib/features/talia_companion/voice/data/voice_consent_profile_lifecycle_hook.dart` | Generic Memorization lifecycle hook implementation that clears consent. |
| `lib/features/talia_companion/voice/infrastructure/device_speech_recognizer.dart` | `speech_to_text` adapter; no persistence. |
| `lib/features/talia_companion/voice/infrastructure/online_speech_recognizer.dart` | Interface only; no provider implementation or DI registration in V1. |
| `lib/features/talia_companion/voice/application/voice_request_context.dart` | Stale-result identity and guard. |
| `lib/features/talia_companion/voice/application/voice_audio_arbiter.dart` | Priority/cancellation around existing playback and recording owners. |
| `lib/features/talia_companion/voice/application/voice_consent_controller.dart` | Accept/revoke flow and active-work cancellation on revoke. |
| `lib/features/talia_companion/voice/application/kids_voice_controller.dart` | Push-to-Talk state machine, retry policy, intent dispatch, clip playback. |
| `lib/features/talia_companion/voice/application/voice_telemetry.dart` | Allow-listed enum/count/bucket event sink. |
| `lib/features/talia_companion/voice/presentation/voice_consent_sheet.dart` | Parent-facing consent UI before permission. |
| `lib/features/talia_companion/voice/presentation/voice_consent_settings_section.dart` | Local-child status/revoke controls. |
| `lib/features/talia_companion/voice/presentation/kids_voice_push_to_talk.dart` | Hold/release mic, state feedback, and six visual buttons. |
| `lib/features/memorization_plus/domain/services/memorization_profile_lifecycle_hook.dart` | Talia-neutral callback contract for destructive profile lifecycle events. |
| `integration_test/talia_kids_voice_runtime_test.dart` | Device permission, cancellation, offline, latency, and audio runtime evidence. |

### Existing files to modify

| File | Exact change |
|---|---|
| `lib/features/memorization_plus/domain/entities/memorization_profile.dart` | Add required stable opaque `profileId` with copy/equality support. |
| `lib/features/memorization_plus/data/models/memorization_models.dart` | Serialize/migrate `profileId` without changing existing identity fields. |
| `lib/features/memorization_plus/data/repositories/collaborators/memorization_profile_store.dart` | Backfill once and persist migrated profile. |
| `lib/features/memorization_plus/data/repositories/collaborators/memorization_profile_service.dart` | Preserve ID on ordinary updates; call lifecycle hook with old ID before reset; generate a new ID after reset/reselection. |
| `lib/features/memorization_plus/data/repositories/collaborators/memorization_parent_access_service.dart` | Clear old device consent on successful unlink/remove through the generic hook. |
| `lib/core/identity/account_data_reset.dart` | Clear all departing owner's Voice consent keys. |
| `lib/core/di/injection.dart` | Register consent, device recognizer, guards, arbiter, controllers; register no online recognizer. |
| `lib/features/talia_companion/data/companion_feature_flags.dart` | Preserve independent Voice flag default false; no online flag enabled. |
| `lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart` | Host Push-to-Talk with existing state/callbacks only when policy allows. |
| `lib/features/memorization_plus/presentation/widgets/memorization_path_settings_sheet.dart` | Add local current-child consent entry behind Parent PIN. |
| `lib/features/memorization_plus/presentation/pages/child_detail_page.dart` | Show Voice section only for `FamilyChildEntry.isLocal`. |
| `lib/features/settings/presentation/pages/privacy_policy_content.dart` | Add accurate on-device voice-command purpose, no-storage, withdrawal, and online-not-enabled disclosure. |
| `lib/core/l10n/app_ar.arb`, `lib/core/l10n/app_en.arb` | Add approved consent, permission, neutral failure, retry, fallback, and command labels. |
| `pubspec.yaml` | Register approved `assets/talia/audio/` clips only after the asset gate passes. |

---

### Task 1: Add and migrate stable child profile identity

**Files:**
- Modify: `lib/features/memorization_plus/domain/entities/memorization_profile.dart`
- Modify: `lib/features/memorization_plus/data/models/memorization_models.dart`
- Modify: `lib/features/memorization_plus/data/repositories/collaborators/memorization_profile_store.dart`
- Modify: `lib/features/memorization_plus/data/repositories/collaborators/memorization_profile_service.dart`
- Test: `test/features/memorization_plus/data/memorization_profile_identity_test.dart`

**Interfaces:**
- Consumes: `MemorizationProfileStore.loadProfile()/saveProfile()`, existing JSON model, `MemorizationProfileService.getMemorizationProfile() -> Future<Either<Failure, MemorizationProfile>>`.
- Produces: required `MemorizationProfile.profileId`; ordinary updates preserve it; reset/reselection generates a new cryptographically opaque UUID-like ID.

- [ ] **Step 1: Write failing migration/lifecycle tests**

```dart
test('legacy profile receives one persisted stable id', () async {
  final first = await store.loadProfile();
  final second = await store.loadProfile();
  expect(first.profileId, isNotEmpty);
  expect(second.profileId, first.profileId);
});

test('ordinary updates preserve id and identity reset replaces it', () async {
  final before = (await service.getMemorizationProfile()).fold(
    (failure) => throw StateError(failure.message),
    (profile) => profile,
  );
  await service.configureChildAge(8);
  final afterUpdate = (await service.getMemorizationProfile()).fold(
    (failure) => throw StateError(failure.message),
    (profile) => profile,
  );
  expect(afterUpdate.profileId, before.profileId);
  await service.resetMemorizationIdentity();
  final afterReset = (await service.getMemorizationProfile()).fold(
    (failure) => throw StateError(failure.message),
    (profile) => profile,
  );
  expect(afterReset.profileId, isNot(before.profileId));
});
```

- [ ] **Step 2: Run the test and verify failure**

Run: `flutter test test/features/memorization_plus/data/memorization_profile_identity_test.dart`

Expected: FAIL because `profileId` is absent.

- [ ] **Step 3: Implement schema migration and stable semantics**

Update entity constructor/copy/equality and model constructor, `fromJson`, `fromEntity`, `toJson`. When legacy JSON lacks `profileId`, generate once, immediately save the migrated profile, and return the persisted value. Never derive it from child name, age, `linkedChildId`, or owner ID.

- [ ] **Step 4: Run focused existing profile tests and analysis**

Run: `dart format lib/features/memorization_plus/domain/entities/memorization_profile.dart lib/features/memorization_plus/data/models/memorization_models.dart lib/features/memorization_plus/data/repositories/collaborators/memorization_profile_store.dart lib/features/memorization_plus/data/repositories/collaborators/memorization_profile_service.dart test/features/memorization_plus/data/memorization_profile_identity_test.dart && flutter test test/features/memorization_plus/data/memorization_profile_identity_test.dart test/features/memorization_plus/data && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/memorization_plus/domain/entities/memorization_profile.dart lib/features/memorization_plus/data/models/memorization_models.dart lib/features/memorization_plus/data/repositories/collaborators/memorization_profile_store.dart lib/features/memorization_plus/data/repositories/collaborators/memorization_profile_service.dart test/features/memorization_plus/data/memorization_profile_identity_test.dart
git commit -m "feat(profile): add stable local child identity"
```

### Task 2: Persist versioned per-child consent and clean every destructive path

**Files:**
- Create: `lib/features/talia_companion/voice/domain/voice_consent.dart`
- Create: `lib/features/talia_companion/voice/data/voice_consent_repository.dart`
- Create: `lib/features/memorization_plus/domain/services/memorization_profile_lifecycle_hook.dart`
- Create: `lib/features/talia_companion/voice/data/voice_consent_profile_lifecycle_hook.dart`
- Modify: `lib/features/memorization_plus/data/repositories/collaborators/memorization_profile_service.dart`
- Modify: `lib/features/memorization_plus/data/repositories/collaborators/memorization_parent_access_service.dart`
- Modify: `lib/core/identity/account_data_reset.dart`
- Modify: `lib/core/di/injection.dart`
- Test: `test/features/talia_companion/voice/domain/voice_consent_test.dart`
- Test: `test/features/talia_companion/voice/data/voice_consent_repository_test.dart`
- Test: `test/features/talia_companion/voice/data/voice_consent_profile_reset_test.dart`
- Test: `test/features/talia_companion/voice/data/voice_consent_guardian_unlink_test.dart`
- Test: `test/features/talia_companion/voice/data/voice_consent_remove_child_test.dart`
- Test: `test/integration/account_switch_isolation_test.dart`

**Interfaces:**
- Consumes: `RecordOwnerProvider.currentOwnerId`, stable `profileId`, `SharedPreferences`, and `AccountDataReset.clearAccountOwnedData({String? departingOwnerId, bool preservePendingBookmarkRecovery = true})`.
- Produces: `VoiceConsentRepository.read/accept/revoke/clearChild/clearOwner`, generic `MemorizationProfileLifecycleHook`, and `VoiceConsentProfileLifecycleHook`.

- [ ] **Step 1: Write failing model/repository/isolation tests**

```dart
const consent = VoiceConsent(
  ownerId: 'owner-a', childProfileId: 'child-a', consentVersion: 1,
  acceptedAt: DateTime.utc(2026, 9, 20),
  scopes: {VoiceConsentScope.onDeviceCommands},
);
expect(await repository.read('owner-a', 'child-a'), consent);
expect(await repository.read('owner-a', 'child-b'), isNull);
expect(await repository.read('owner-b', 'child-a'), isNull);
```

Also test cleanup before reset loses old ID, after successful guardian unlink but before local IDs clear, on `removeChild`, and on account reset.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/voice/domain/voice_consent_test.dart test/features/talia_companion/voice/data/voice_consent_repository_test.dart test/features/talia_companion/voice/data/voice_consent_profile_reset_test.dart test/features/talia_companion/voice/data/voice_consent_guardian_unlink_test.dart test/features/talia_companion/voice/data/voice_consent_remove_child_test.dart test/integration/account_switch_isolation_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement exact contracts**

```dart
enum VoiceConsentScope { onDeviceCommands }

abstract interface class VoiceConsentRepository {
  Future<VoiceConsent?> read(String ownerId, String childProfileId);
  Future<void> accept(VoiceConsent consent);
  Future<void> revoke(String ownerId, String childProfileId);
  Future<void> clearOwner(String ownerId);
}

abstract interface class MemorizationProfileLifecycleHook {
  Future<void> beforeIdentityReset(String oldProfileId);
  Future<void> afterGuardianUnlinked(String oldProfileId);
  Future<void> afterChildRemoved(String childProfileId);
}
```

Use key prefix `talia_voice.v1.owner.<ownerId>.child.<profileId>.consent`. Do not store `onlineFallbackAllowed`; online is not offered in V1.

- [ ] **Step 4: Run cleanup and isolation tests**

Run: `dart format lib/features/talia_companion/voice lib/features/memorization_plus/domain/services lib/features/memorization_plus/data/repositories/collaborators lib/core/identity/account_data_reset.dart lib/core/di/injection.dart test/features/talia_companion/voice test/integration/account_switch_isolation_test.dart && flutter test test/features/talia_companion/voice/domain/voice_consent_test.dart test/features/talia_companion/voice/data test/integration/account_switch_isolation_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/voice/domain/voice_consent.dart lib/features/talia_companion/voice/data lib/features/memorization_plus/domain/services/memorization_profile_lifecycle_hook.dart lib/features/memorization_plus/data/repositories/collaborators lib/core/identity/account_data_reset.dart lib/core/di/injection.dart test/features/talia_companion/voice test/integration/account_switch_isolation_test.dart
git commit -m "feat(talia-voice): isolate versioned child consent"
```

### Task 3: Add guardian consent UI and immediate withdrawal

**Files:**
- Create: `lib/features/talia_companion/voice/application/voice_consent_controller.dart`
- Create: `lib/features/talia_companion/voice/presentation/voice_consent_sheet.dart`
- Create: `lib/features/talia_companion/voice/presentation/voice_consent_settings_section.dart`
- Modify: `lib/features/memorization_plus/presentation/widgets/memorization_path_settings_sheet.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/child_detail_page.dart`
- Modify: `lib/core/l10n/app_ar.arb`
- Modify: `lib/core/l10n/app_en.arb`
- Test: `test/features/talia_companion/voice/presentation/voice_consent_sheet_test.dart`
- Test: `test/features/talia_companion/voice/presentation/voice_consent_settings_section_test.dart`
- Test: `test/features/talia_companion/voice/application/voice_consent_revocation_test.dart`

**Interfaces:**
- Consumes: existing Parent PIN verification, `FamilyChildEntry.isLocal`, Task 2 repository.
- Produces: `VoiceConsentController.load/accept/revoke`, `VoiceConsentSheet`, `VoiceConsentSettingsSection`.

- [ ] **Step 1: Approve the consent gate**

Before coding, record approved `consentVersion = 1` and final Arabic/English copy covering purpose, on-device OS processing, no app audio/transcript storage, withdrawal, and the fact that online recognition is not enabled. If review rejects copy, stop; do not invent replacement legal text.

- [ ] **Step 2: Write failing UI/controller tests**

Test local visible/remote hidden, PIN success/failure, consent saved before any permission request, revoke cancels active work and hides mic, and Child A/B isolation.

- [ ] **Step 3: Implement consent-first flow**

```dart
Future<void> accept({required String ownerId, required String profileId}) async {
  final verified = await _parentPin.verify();
  if (!verified) return;
  await _repository.accept(VoiceConsent(
    ownerId: ownerId, childProfileId: profileId, consentVersion: 1,
    acceptedAt: _clock.now().toUtc(),
    scopes: const {VoiceConsentScope.onDeviceCommands},
  ));
  emit(VoiceConsentState.accepted);
}
```

Do not request microphone permission in this controller.

- [ ] **Step 4: Generate l10n and run tests**

Run: `flutter gen-l10n && dart format lib/features/talia_companion/voice lib/features/memorization_plus/presentation test/features/talia_companion/voice && flutter test test/features/talia_companion/voice/presentation/voice_consent_sheet_test.dart test/features/talia_companion/voice/presentation/voice_consent_settings_section_test.dart test/features/talia_companion/voice/application/voice_consent_revocation_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/voice/application/voice_consent_controller.dart lib/features/talia_companion/voice/presentation lib/features/memorization_plus/presentation/widgets/memorization_path_settings_sheet.dart lib/features/memorization_plus/presentation/pages/child_detail_page.dart lib/core/l10n test/features/talia_companion/voice
git commit -m "feat(talia-voice): add guardian consent controls"
```

### Task 4: Define closed intents and Arabic classifier

**Files:**
- Create: `lib/features/talia_companion/voice/domain/voice_intent.dart`
- Create: `lib/features/talia_companion/voice/domain/arabic_voice_intent_classifier.dart`
- Test: `test/features/talia_companion/voice/domain/arabic_voice_intent_classifier_test.dart`

**Interfaces:**
- Consumes: an in-memory recognizer transcript plus confidence.
- Produces: `VoiceIntentClassification classify(String text, {double? confidence})`; result contains only `VoiceIntent` and `VoiceConfidenceBucket`, never original text.

- [ ] **Step 1: Write table-driven failing tests**

Include MSA/simple Egyptian forms, Arabic diacritics/tatweel, alef/yaa variants, whitespace, low confidence, overlapping/ambiguous phrases, unsupported navigation, empty text, and mixed noise. Expected intents remain exactly the six plus unknown.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/voice/domain/arabic_voice_intent_classifier_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement deterministic normalization and exact phrase sets**

```dart
enum VoiceIntent { start, next, repeat, back, help, finish, unknown }

final class VoiceIntentClassification {
  const VoiceIntentClassification(this.intent, this.confidenceBucket);
  final VoiceIntent intent;
  final VoiceConfidenceBucket confidenceBucket;
}
```

Return `unknown` below the approved confidence threshold or when multiple intents match. Do not use nearest-match/fuzzy guessing.

- [ ] **Step 4: Run tests and source scan**

Run: `dart format lib/features/talia_companion/voice/domain test/features/talia_companion/voice/domain && flutter test test/features/talia_companion/voice/domain/arabic_voice_intent_classifier_test.dart && rg -n "levenshtein|fuzzy|closest" lib/features/talia_companion/voice && flutter analyze`

Expected: tests/analyze PASS; no fuzzy-guessing implementation.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/voice/domain/voice_intent.dart lib/features/talia_companion/voice/domain/arabic_voice_intent_classifier.dart test/features/talia_companion/voice/domain/arabic_voice_intent_classifier_test.dart
git commit -m "feat(talia-voice): classify closed Arabic intents"
```

### Task 5: Implement on-device recognizer and disable online path by construction

**Files:**
- Create: `lib/features/talia_companion/voice/infrastructure/device_speech_recognizer.dart`
- Create: `lib/features/talia_companion/voice/infrastructure/online_speech_recognizer.dart`
- Test: `test/features/talia_companion/voice/infrastructure/device_speech_recognizer_test.dart`
- Test: `test/features/talia_companion/voice/infrastructure/online_speech_recognizer_contract_test.dart`

**Interfaces:**
- Consumes: `speech_to_text`, `kArabicSpeechLocaleId`, microphone permission supplied by controller.
- Produces: `KidsVoiceRecognizer.initialize/start/stop/cancel`; extension-only `OnlineSpeechRecognizer.recognize(Uint8List ephemeralAudio) -> Future<VoiceRecognitionSample>` interface with no implementation/registration.

- [ ] **Step 1: Write failing adapter tests**

Test Arabic locale selection, availability false, one final in-memory result, cancel ignores late callback, no file/audio/transcript persistence call, and lifecycle disposal.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/voice/infrastructure/device_speech_recognizer_test.dart test/features/talia_companion/voice/infrastructure/online_speech_recognizer_contract_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement the contracts**

```dart
abstract interface class KidsVoiceRecognizer {
  Future<VoiceRecognitionAvailability> initialize();
  Future<void> start({required ValueChanged<VoiceRecognitionSample> onResult});
  Future<VoiceRecognitionSample?> stop();
  Future<void> cancel();
}

abstract interface class OnlineSpeechRecognizer {
  Future<VoiceRecognitionSample> recognize(Uint8List ephemeralAudio);
}
```

Do not add a concrete online class, DI registration, HTTP dependency, online flag, or controller field for this interface. It exists only as a future extension seam.

- [ ] **Step 4: Run tests and prove no online implementation/registration**

Run: `dart format lib/features/talia_companion/voice/infrastructure test/features/talia_companion/voice/infrastructure && flutter test test/features/talia_companion/voice/infrastructure && rg -n "implements OnlineSpeechRecognizer|register.*OnlineSpeechRecognizer|OnlineSpeechRecognizer\(" lib --glob '!**/online_speech_recognizer.dart' && flutter analyze`

Expected: adapter tests/analyze PASS; `rg` has no matches.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/voice/infrastructure test/features/talia_companion/voice/infrastructure
git commit -m "feat(talia-voice): add on-device recognition boundary"
```

### Task 6: Reject stale request results

**Files:**
- Create: `lib/features/talia_companion/voice/application/voice_request_context.dart`
- Test: `test/features/talia_companion/voice/application/voice_request_context_test.dart`

**Interfaces:**
- Consumes: request ID, owner ID, profile ID, route, `CompanionSurface`, exercise/stage identity, lifecycle/consent generation.
- Produces: `VoiceRequestGuard.begin`, `isCurrent`, `invalidate`, and immutable `VoiceRequestContext`.

- [ ] **Step 1: Write failing cancellation matrix tests**

Test same context valid; newer request, route change, profile switch, background, reader focus, consent revoke, feature disable, and exercise change invalid. Test late callback after guard disposal is ignored.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/voice/application/voice_request_context_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement generation/context equality guard**

```dart
final class VoiceRequestContext extends Equatable {
  const VoiceRequestContext({required this.requestId, required this.ownerId,
    required this.childProfileId, required this.route,
    required this.surface, required this.exerciseId,
    required this.generation});
  final String requestId;
  final String ownerId;
  final String childProfileId;
  final String route;
  final CompanionSurface surface;
  final String exerciseId;
  final int generation;
  @override
  List<Object?> get props => <Object?>[
    requestId, ownerId, childProfileId, route, surface, exerciseId, generation,
  ];
}
```

`isCurrent` must compare all fields, not request ID alone.

- [ ] **Step 4: Run tests**

Run: `dart format lib/features/talia_companion/voice/application/voice_request_context.dart test/features/talia_companion/voice/application/voice_request_context_test.dart && flutter test test/features/talia_companion/voice/application/voice_request_context_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/voice/application/voice_request_context.dart test/features/talia_companion/voice/application/voice_request_context_test.dart
git commit -m "feat(talia-voice): reject stale recognition results"
```

### Task 7: Arbitrate Quran, recording, mic, and response audio

**Files:**
- Create: `lib/features/talia_companion/voice/application/voice_audio_arbiter.dart`
- Test: `test/features/talia_companion/voice/application/voice_audio_arbiter_test.dart`
- Modify: `test/core/services/audio_lifecycle_manager_test.dart` only where new client behavior is exercised

**Interfaces:**
- Consumes: `AudioLifecycleManager`, `QuranAudioPlayerState.hasActiveAudio`, `MSActive`, `KidsModeLoaded`.
- Produces: `VoiceAudioArbiter.canStartListening`, `beginListening`, `endListening`, `playResponse`, `cancelAll`.

- [ ] **Step 1: Write failing priority/race tests**

Assert paused Quran audio still blocks; Kids playing/buffering/recording blocks; Quran start cancels mic/response; recording start cancels response; second press is idempotent; disposal releases ownership once.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/voice/application/voice_audio_arbiter_test.dart test/core/services/audio_lifecycle_manager_test.dart`

Expected: FAIL for new arbiter behavior.

- [ ] **Step 3: Implement existing-owner arbitration**

Do not create a second audio session manager. Use the existing lifecycle manager and conservative `hasActiveAudio`; local suppression reads exact `MSActive.isRecording/isPlaying/isEvaluating` and `KidsModeLoaded.isPlaying/isBuffering/isRecording`.

- [ ] **Step 4: Run audio tests**

Run: `dart format lib/features/talia_companion/voice/application/voice_audio_arbiter.dart test/features/talia_companion/voice/application/voice_audio_arbiter_test.dart test/core/services/audio_lifecycle_manager_test.dart && flutter test test/features/talia_companion/voice/application/voice_audio_arbiter_test.dart test/core/services/audio_lifecycle_manager_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/voice/application/voice_audio_arbiter.dart test/features/talia_companion/voice/application/voice_audio_arbiter_test.dart test/core/services/audio_lifecycle_manager_test.dart
git commit -m "feat(talia-voice): arbitrate voice audio safely"
```

### Task 8: Implement the two-attempt Push-to-Talk state machine

**Files:**
- Create: `lib/features/talia_companion/voice/application/kids_voice_controller.dart`
- Modify: `lib/core/di/injection.dart`
- Modify: `lib/features/talia_companion/data/companion_feature_flags.dart`
- Test: `test/features/talia_companion/voice/application/kids_voice_controller_test.dart`

**Interfaces:**
- Consumes: consent repository, `permission_handler`, device recognizer, classifier, request guard, audio arbiter, command callbacks, clock, telemetry; no online recognizer.
- Produces: `KidsVoiceController`, `KidsVoiceState`, `press`, `release`, `selectVisualIntent`, `cancel`.

- [ ] **Step 1: Write failing state-machine tests**

Cover: flag/consent/surface suppression; consent before permission; denied/permanently denied; idle→listening→recognizing→success; first unknown→retryPrompt with `attempt=1`; second unknown→visualFallback; technical error→neutral visual fallback without learner blame; stale result discarded; overlap cancellation; online fake never called.

```dart
verifyNever(() => throwingOnlineRecognizer.recognize(any()));
expect(controller.state.mode, VoiceMode.visualFallback);
```

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/voice/application/kids_voice_controller_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement explicit states and retry policy**

```dart
enum VoiceMode { idle, listening, recognizing, retryPrompt, responding,
  visualFallback, permissionDenied, technicalUnavailable }

Future<void> _handleUnknown() async {
  if (state.attempt == 0) {
    emit(state.copyWith(mode: VoiceMode.retryPrompt, attempt: 1));
  } else {
    emit(state.copyWith(mode: VoiceMode.visualFallback, attempt: 2));
  }
}
```

Discard transcript immediately after classification. `selectVisualIntent` uses the same command dispatcher as recognized intents.

- [ ] **Step 4: Run controller tests and privacy source scan**

Run: `dart format lib/features/talia_companion/voice/application/kids_voice_controller.dart lib/core/di/injection.dart lib/features/talia_companion/data/companion_feature_flags.dart test/features/talia_companion/voice/application/kids_voice_controller_test.dart && flutter test test/features/talia_companion/voice/application/kids_voice_controller_test.dart && rg -n "transcript|spokenPhrase|rawAudio|audioFilePath|voiceHistory" lib/features/talia_companion/voice && flutter analyze`

Expected: PASS; matches exist only for ephemeral recognizer input/type names or explicit prohibited-field tests, never persistence/telemetry.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/voice/application/kids_voice_controller.dart lib/core/di/injection.dart lib/features/talia_companion/data/companion_feature_flags.dart test/features/talia_companion/voice/application/kids_voice_controller_test.dart
git commit -m "feat(talia-voice): add safe push-to-talk flow"
```

### Task 9: Add approved prerecorded response catalog

**Files:**
- Create: `lib/features/talia_companion/voice/domain/prerecorded_voice_catalog.dart`
- Create: `assets/talia/audio/ar/start_ack.mp3`
- Create: `assets/talia/audio/ar/next_ack.mp3`
- Create: `assets/talia/audio/ar/repeat_ack.mp3`
- Create: `assets/talia/audio/ar/back_ack.mp3`
- Create: `assets/talia/audio/ar/help_ack.mp3`
- Create: `assets/talia/audio/ar/finish_ack.mp3`
- Create: `assets/talia/audio/ar/retry_once.mp3`
- Create: `assets/talia/audio/ar/fallback.mp3`
- Create: `assets/talia/audio/ar/unavailable.mp3`
- Modify: `pubspec.yaml`
- Test: `test/features/talia_companion/voice/domain/prerecorded_voice_catalog_test.dart`

**Interfaces:**
- Consumes: approved files for `start_ack`, `next_ack`, `repeat_ack`, `back_ack`, `help_ack`, `finish_ack`, `retry_once`, `fallback`, `unavailable`.
- Produces: `PrerecordedVoiceCatalog.assetFor(VoiceResponseId) -> String`.

- [ ] **Step 1: Enforce the clip gate**

Verify all nine reviewed Arabic clips exist and have approval IDs. If any is absent, keep the Voice feature flag false and stop this task; do not generate audio or use TTS.

- [ ] **Step 2: Write failing exhaustive asset tests**

Assert every response ID maps to one bundled file, every file is non-empty, no unused clip exists, and no TTS dependency/API appears in Voice source.

- [ ] **Step 3: Implement the finite catalog and registration**

```dart
enum VoiceResponseId { startAck, nextAck, repeatAck, backAck, helpAck,
  finishAck, retryOnce, fallback, unavailable }

abstract final class PrerecordedVoiceCatalog {
  static String assetFor(VoiceResponseId id) => switch (id) {
    VoiceResponseId.startAck => 'assets/talia/audio/ar/start_ack.mp3',
    VoiceResponseId.nextAck => 'assets/talia/audio/ar/next_ack.mp3',
    VoiceResponseId.repeatAck => 'assets/talia/audio/ar/repeat_ack.mp3',
    VoiceResponseId.backAck => 'assets/talia/audio/ar/back_ack.mp3',
    VoiceResponseId.helpAck => 'assets/talia/audio/ar/help_ack.mp3',
    VoiceResponseId.finishAck => 'assets/talia/audio/ar/finish_ack.mp3',
    VoiceResponseId.retryOnce => 'assets/talia/audio/ar/retry_once.mp3',
    VoiceResponseId.fallback => 'assets/talia/audio/ar/fallback.mp3',
    VoiceResponseId.unavailable => 'assets/talia/audio/ar/unavailable.mp3',
  };
}
```

- [ ] **Step 4: Run asset/catalog tests**

Run: `flutter pub get && dart format lib/features/talia_companion/voice/domain/prerecorded_voice_catalog.dart test/features/talia_companion/voice/domain/prerecorded_voice_catalog_test.dart && flutter test test/features/talia_companion/voice/domain/prerecorded_voice_catalog_test.dart && rg -n "flutter_tts|TextToSpeech|speak\(" lib/features/talia_companion/voice pubspec.yaml && flutter analyze`

Expected: tests/analyze PASS; no runtime TTS match.

- [ ] **Step 5: Commit**

```bash
git add assets/talia/audio/ar pubspec.yaml lib/features/talia_companion/voice/domain/prerecorded_voice_catalog.dart test/features/talia_companion/voice/domain/prerecorded_voice_catalog_test.dart
git commit -m "feat(talia-voice): add reviewed response clips"
```

### Task 10: Enforce surface policy and integrate the local mic/buttons

**Files:**
- Create: `lib/features/talia_companion/voice/domain/voice_surface_policy.dart`
- Create: `lib/features/talia_companion/voice/presentation/kids_voice_push_to_talk.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart`
- Test: `test/features/talia_companion/voice/presentation/voice_surface_scope_test.dart`
- Test: `test/features/talia_companion/voice/presentation/kids_voice_push_to_talk_test.dart`
- Test: `test/features/memorization_plus/presentation/pages/kids_gamified_listen_page_test.dart`

**Interfaces:**
- Consumes: `KidsGamifiedListenContent` exact existing callbacks (`onBack`, play/pause, record/stop, optional manual complete), `KidsModeLoaded`, Task 8 controller.
- Produces: `VoiceSurfacePolicy.isEligible(context)`, `KidsVoicePushToTalk(state, onPress, onRelease, onIntentSelected)`.

- [ ] **Step 1: Write failing route/suppression/accessibility tests**

Prove mic present only on eligible simple exercise with consent/flag; absent on all listed unsupported surfaces and during playing/buffering/recording/evaluating; hold/release semantics; visual buttons after second failure; six buttons use the same actions; RTL, semantics, 48dp targets, reduced motion, 320/360 widths, text scale 2.0.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/voice/presentation/voice_surface_scope_test.dart test/features/talia_companion/voice/presentation/kids_voice_push_to_talk_test.dart test/features/memorization_plus/presentation/pages/kids_gamified_listen_page_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement local host without parallel business state**

Build context from existing `KidsModeLoaded` and route/exercise identity. Dispatch `start/next/repeat/back/help/finish` into existing page callbacks/navigation. Do not copy Kids progression logic into Voice.

- [ ] **Step 4: Run widget and page tests**

Run: `dart format lib/features/talia_companion/voice/presentation lib/features/talia_companion/voice/domain/voice_surface_policy.dart lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart test/features && flutter test test/features/talia_companion/voice/presentation test/features/memorization_plus/presentation/pages/kids_gamified_listen_page_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/voice/domain/voice_surface_policy.dart lib/features/talia_companion/voice/presentation/kids_voice_push_to_talk.dart lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart test/features/talia_companion/voice/presentation test/features/memorization_plus/presentation/pages/kids_gamified_listen_page_test.dart
git commit -m "feat(talia-voice): host accessible visual fallback"
```

### Task 11: Add privacy-safe telemetry and disclosure

**Files:**
- Create: `lib/features/talia_companion/voice/application/voice_telemetry.dart`
- Modify: `lib/features/settings/presentation/pages/privacy_policy_content.dart`
- Modify: `lib/core/l10n/app_ar.arb`
- Modify: `lib/core/l10n/app_en.arb`
- Test: `test/features/talia_companion/voice/application/voice_telemetry_test.dart`
- Test: `test/features/settings/privacy_policy_page_test.dart`
- Test: `test/features/settings/voice_pilot_privacy_disclosure_test.dart`

**Interfaces:**
- Consumes: Core `CompanionTelemetry` sink or a no-op sink when no backend is configured.
- Produces: enum-only `VoiceTelemetry.record(VoiceTelemetryEvent)` and accurate user-facing disclosure.

- [ ] **Step 1: Write failing property allow-list tests**

Allow only event kind, intent enum, `onDevice` path, retry count, coarse latency/confidence bucket, fallback boolean, cancellation reason. Reject serialization keys `rawAudio`, `audioFilePath`, `fullTranscript`, `spokenPhrase`, `childName`.

- [ ] **Step 2: Write failing privacy page tests**

Assert Arabic/English disclose voice-command purpose, on-device OS recognizer, no app storage/history, revocation path, and that online recognition is not enabled in V1.

- [ ] **Step 3: Implement no-op-compatible telemetry and reviewed disclosure**

```dart
final class VoiceTelemetryEvent {
  const VoiceTelemetryEvent({required this.kind, this.intent,
    required this.path, required this.retryCount,
    this.latencyBucket, required this.fallbackToButtons});
  Map<String, Object?> toProperties() => <String, Object?>{
    'intent': intent?.name, 'recognitionPath': path.name,
    'retryCount': retryCount, 'latencyBucket': latencyBucket?.name,
    'fallbackToButtons': fallbackToButtons,
  };
}
```

- [ ] **Step 4: Generate localization and run tests**

Run: `flutter gen-l10n && dart format lib/features/talia_companion/voice/application/voice_telemetry.dart lib/features/settings/presentation/pages/privacy_policy_content.dart test/features && flutter test test/features/talia_companion/voice/application/voice_telemetry_test.dart test/features/settings/privacy_policy_page_test.dart test/features/settings/voice_pilot_privacy_disclosure_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/voice/application/voice_telemetry.dart lib/features/settings/presentation/pages/privacy_policy_content.dart lib/core/l10n test/features/talia_companion/voice/application/voice_telemetry_test.dart test/features/settings/privacy_policy_page_test.dart test/features/settings/voice_pilot_privacy_disclosure_test.dart
git commit -m "feat(talia-voice): disclose and measure pilot safely"
```

### Task 12: Verify device runtime and release independence

**Files:**
- Create: `integration_test/talia_kids_voice_runtime_test.dart`

**Interfaces:**
- Consumes: completed Voice Pilot and approved Android device/emulator.
- Produces: runtime evidence; no production API.

- [ ] **Step 1: Add runtime scenarios**

Cover first-use consent→permission, allowed/denied/permanently denied, offline device recognition, first unknown retry, second unknown visual buttons, navigation/profile/background/consent-revoke cancellation, Quran audio/user recording interruption, overlapping press/release, closed intent execution, latency buckets, and Core-on/Voice-off.

- [ ] **Step 2: Run the complete Voice test set**

Run: `flutter test test/features/talia_companion/voice test/features/memorization_plus/data/memorization_profile_identity_test.dart test/features/memorization_plus/presentation/pages/kids_gamified_listen_page_test.dart test/features/settings/voice_pilot_privacy_disclosure_test.dart test/integration/account_switch_isolation_test.dart --concurrency=1`

Expected: PASS.

- [ ] **Step 3: Run runtime tests on approved Android targets**

First run `flutter devices` and ensure exactly the project-approved Android test target is connected, then run: `flutter test integration_test/talia_kids_voice_runtime_test.dart --profile`

Expected: PASS with measured on-device latency buckets and no network request.

- [ ] **Step 4: Prove online/TTS/storage are absent**

Run: `rg -n "implements OnlineSpeechRecognizer|register.*OnlineSpeechRecognizer|http\.|dio\.|flutter_tts|TextToSpeech|voiceHistory|fullTranscript|spokenPhrase|rawAudio" lib/features/talia_companion/voice lib/core/di/injection.dart pubspec.yaml`

Expected: no provider implementation/registration, HTTP speech path, TTS, voice history, or persisted transcript/audio. Interface/type/test references are acceptable only when they prove the prohibition.

- [ ] **Step 5: Run final repository verification**

Run: `dart format --output=none --set-exit-if-changed lib test integration_test && flutter analyze && flutter test --concurrency=1 && git diff --check`

Expected: format/analyze/diff PASS; suite PASS apart from only the two documented date-sensitive Prayer notification fixture failures if still present. Investigate every other failure.

- [ ] **Step 6: Commit**

```bash
git add integration_test/talia_kids_voice_runtime_test.dart
git commit -m "test(talia-voice): verify on-device pilot runtime"
```

## Completion Gate

- Voice Pilot can be enabled only after stable profile migration, consent cleanup, approved copy/clips, permission/runtime tests, privacy review, telemetry allow-list review, and the Android matrix pass.
- Lack of an online provider is explicitly non-blocking: V1 remains on-device → retry → visual buttons. `OnlineSpeechRecognizer` stays interface-only and disabled.
- If approved clips or consent/privacy review are not complete, mergeable foundation work may remain behind the Voice kill switch, but the flag must not be enabled for users.
