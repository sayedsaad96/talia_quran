#!/usr/bin/env bash
set -u

echo '=== Talia Quran Runtime QA v2.1 - Environment Check ==='
if [[ ! -f pubspec.yaml ]]; then echo 'FAIL: pubspec.yaml not found'; exit 2; fi
if ! grep -Eq '^name:[[:space:]]*talia_quran[[:space:]]*$' pubspec.yaml; then echo 'FAIL: not talia_quran'; exit 3; fi
echo '[PASS] Project Identity Gate: talia_quran'
for cmd in flutter adb patrol; do
  if command -v "$cmd" >/dev/null 2>&1; then echo "[PASS] $cmd -> $(command -v "$cmd")"; else echo "[FAIL] $cmd not found"; fi
done
echo "ANDROID_HOME=${ANDROID_HOME:-}"
adb devices || true
flutter devices || true
patrol --version || true
