# Audit evidence identity — 6 October 2026

The application source audit targets D:\Flutter\talia_quran current working tree, including pre-existing uncommitted and untracked family/guardian changes, based on HEAD 718228d0ee00dcb0ef2d2382ec6e3b1679af77b5.

source_snapshot.json records SHA-256 fingerprints for 1,394 source, asset, test and configuration files. An early comparison returned zero changed/deleted files. A later final comparison detected only pubspec.lock drift: sqflite 2.4.4 to 2.4.4+1 and sqflite_common 2.5.13 to 2.5.13+1 with updated hashes. The origin is not established; the audit used --no-pub and made no intentional dependency edits. The change is preserved, not reverted over possible concurrent work. See source_drift_final.json and lock_drift.patch. The other 1,393 fingerprinted files remained unchanged. QCF stayed at 0.1.0.

The screenshots home.png, launch_after_wait.png, kids_quran_audio.png and kids_stage.png were captured from an earlier installed DEBUG application. Installed lastUpdateTime was 2026-10-05 00:06:54 (device clock), APK on disk was dated 5 October 2026. They are exploration leads ONLY, excluded from verification of the current working tree, release readiness, current visual behavior, and end-to-end success claims. The user explicitly required a fresh current build; testing that older installation stopped.

Fresh APK and release AAB build attempts from the current tree with the existing .env compile-time definitions failed in Gradle host loopback/Unix-domain sockets. No fresh current APK was installed and no installed-artifact hash match has been established.

backend_metadata.json contains read-only production migration metadata, security/performance advisor output, RLS table flags and selected RPC definitions. It contains no queried user account contents or tokens. Metadata verification is not owner/non-owner authorization execution testing.

No application source, assets, configuration or backend settings were intentionally changed by the audit. Only new audit evidence files and normal tool-generated build/cache files were allowed.
