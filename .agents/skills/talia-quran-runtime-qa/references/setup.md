# Setup — Windows First

## Required tools

Verify:

```powershell
flutter --version
patrol --version
adb --version
flutter devices
```

`ANDROID_HOME` should point to the Android SDK, for example:

```text
D:\Android\Sdk
```

## Patrol package

Keep the Patrol package version compatible with the globally installed Patrol CLI. Do not downgrade working application dependencies merely to satisfy `patrol_mcp`.

## Patrol MCP

Optional. The skill works without it.

If adding `patrol_mcp` to the application causes dependency solving conflicts, do NOT use dependency overrides to force incompatible versions. Use Patrol CLI directly.

## Antigravity / Cursor / Codex

The runtime agent must have terminal execution permission sufficient to run:
- `adb`
- `flutter devices`
- `flutter emulators`
- Patrol CLI

If an agent only runs ordinary Flutter/Dart tests, invoke the skill explicitly and require the Device Gate + Runtime Gate outputs before any code review or completion claim.
