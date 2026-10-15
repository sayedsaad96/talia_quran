# Google Play in-app updates

Scope: Android distribution through Google Play (`com.talia.quran`).

## Behavior

After initialization and when the app returns to the foreground, Talia checks Google Play. Native download consent is offered on the home or settings screen, with a 24-hour reminder limit for the installed build and offered version. A downloaded update can offer installation on any screen. Users can dismiss the installation message and choose it again after returning to the app; installation requires the explicit **Install and restart** action. The messages support Arabic and English. Google Play supplies its own consent UI.

Checks do not block startup, and expected platform failures leave normal app use available. Debug builds and platforms other than Android skip the native integration. No immediate/mandatory update flow is enabled. The app uses the package's downloaded-state event and foreground checks to recover a pending installation.

The package's Android installation method does not resolve its method-channel reply. Talia limits that wait to four seconds and restores the installation choice if the process has not restarted. The full store/device scenario below remains necessary to validate actual installation.

## Dependency decision

Checked on 2026-10-15: [`in_app_update` 5.0.0](https://pub.dev/packages/in_app_update) wraps Google's native update API. It is MIT licensed and declares only Flutter as a direct Dart dependency. Its Android implementation uses Play App Update 2.1.0. Version 5 requires Flutter 3.44 / Dart 3.12 or newer; the local Flutter 3.47.1 SDK satisfies this requirement. See the [package changelog](https://pub.dev/packages/in_app_update/changelog).

The alternative is a custom Android platform-channel implementation. The package avoids maintaining that bridge in Talia. `upgrader` was considered; its Android lookup scrapes public Play Store pages, whereas this integration uses Play's native availability and user-consent flow. No new backend or app-version endpoint is required.

Binary-size impact has not been measured. Play processes device and app metadata to determine update availability; see [Google's data safety information](https://developer.android.com/guide/playcore/in-app-updates#data-safety). No Quran text or memorization progress is sent by Talia's update integration.

## Publishing and verification

The installed version must already contain this integration. Previously published versions without update support cannot gain an in-app prompt until users install a version containing it.

Publish each subsequent release with a higher Android `versionCode` (the number after `+` in `pubspec.yaml`, or the `--build-number` override). Google Play decides availability for the current account, device and rollout; uploading a build alone does not make it available to every user.

For a real-device check, follow [Google's internal app sharing procedure](https://developer.android.com/guide/playcore/in-app-updates/test):

1. Install a release build containing this feature through an internal app sharing link.
2. Upload another build with the same application ID and a higher version code.
3. Open that newer build's sharing link on the device, then leave its Play page without installing it.
4. Launch Talia and exercise the update prompt. Verify that declining leaves the app usable.
5. Accept the update, let it download, then explicitly choose the install/restart action. Check that the new version opens and existing local progress remains available.
6. Repeat with the app backgrounded during download, then return and verify that the installation action appears.

The testing account must own the app, and the installation/signing must meet Google's testing prerequisites. A locally installed debug APK cannot establish that Play's real update flow works. Unit/widget tests and a successful build establish different evidence from this store/device check.

## Removal

To roll back the integration in a future release, remove the app-update host and DI registrations, its feature code and strings, and the `in_app_update` dependency. Keep normal version/build numbering and the rest of startup intact.

## Local validation (2026-10-15)

- `flutter analyze --no-pub --no-fatal-infos lib/features/app_update test/features/app_update lib/app.dart lib/core/di/injection.dart`: passed with no issues.
- `flutter test --no-pub test/features/app_update test/core/l10n/localization_regression_test.dart test/features/splash test/core/services/app_initializer_permission_defer_test.dart`: all 25 tests passed. The update UI tests exercise Arabic/English, enlarged text and a narrow screen with `MaterialApp.router`.
- `flutter build apk --debug --no-pub`: could not reach compilation because Gradle's Java process failed to establish its local connection (`Unable to establish loopback connection`). IPv4 and Windows selector-provider retries also failed. Android native compilation and the real Google Play update/install scenario remain unverified.
