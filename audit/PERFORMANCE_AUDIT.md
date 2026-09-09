# Performance Audit Report — Talia Quran

> This report was produced from a fresh independent audit of the current application state. Previous audits, issue lists, scores, and recommendations were excluded from the discovery and evidence process.

---

## 1. Profiling Environment & Methodology

- **Test Target**: Android x86_64 Emulator (`SM-S908E`, API 28)
- **Host System**: Intel Core i7-1265U, 10-core / 12-thread, Windows 10
- **Flutter Build Profile**: `flutter run --profile -d 127.0.0.1:5555`
- **Diagnostics Tools**:
  - Dart Tooling Daemon (DTD) / VM Service (`ws://127.0.0.1:55113/...`)
  - VM Service methods: `getVM`, `getMemoryUsage`
  - ADB frame and package inspection tools (`dumpsys`, `screencap`)
  - Static Code Analysis: `flutter analyze`
  - Test Suite Execution: `flutter test`

---

## 2. Actual Runtime Measurements

### A. Static Code & Test Suite Status
- **Static Analysis (`flutter analyze`)**: 
  - Result: **0 issues found** (completed in 20.4 seconds).
- **Test Suite (`flutter test`)**:
  - Result: **1,480 passed / 1,480 tests** (completed in 2 minutes 07 seconds).

### B. Memory Footprint (Measured via Dart VM Service)

| State / Screen | Isolate ID | Heap Usage | Heap Capacity | External Usage | Process RSS |
|---|---|---|---|---|---|
| **Startup / Onboarding** | `isolates/5295528639996211` | **51.86 MB** | 56.23 MB | 27.7 KB | **467.8 MB** (Peak: 498.0 MB) |
| **Active Quran Reader (Page 93, QCF)** | `isolates/116110127636835` | **61.11 MB** | 63.75 MB | 23.5 KB | **495.6 MB** (Peak: 508.6 MB) |

#### Analysis:
- **Dart Managed Heap**: Exceptionally lean and controlled (~51 MB to 61 MB). Garbage collection is healthy and fast.
- **Process RSS**: Total native + graphics memory sits between 460 MB and 500 MB. This is normal for Flutter apps bundling high-resolution assets (mosque graphics, 3D character renders), SVG assets, and caching in-memory QCF Tajweed font glyphs.

### C. Build & Binary Metrics
- **APK Profile Size (`app-profile.apk`)**: 175.3 MB (175,329,664 bytes)
- **APK Debug Size (`app-debug.apk`)**: 296.7 MB (296,714,188 bytes)
- **Asset Size Dominance**:
  - `assets/fonts/` (Amiri, Noto Naskh, QCF Quran fonts)
  - `assets/images/` (Character 3D renders, onboarding illustrations)

---

## 3. Performance Findings Matrix

| Finding ID | Scope | Problem Summary | Evidence / Measurement | Classification | Severity |
|---|---|---|---|---|---|
| `AUD-PERF-001` | Gradle Build | Legacy Kotlin Gradle Plugin (KGP) warnings on 4 plugins | Flutter assembleProfile warning log | **CONFIRMED** | P2 |
| `AUD-PERF-002` | Onboarding Swiping | Continuous `setState` during PageView drag | `_pageController.addListener(() => setState(() {}))` | **CONFIRMED** | P3 |
| `AUD-PERF-003` | Asset Storage / APK Size | High release APK footprint (> 100MB) due to uncompressed character PNGs | 175 MB profile APK | **INVESTIGATION NEEDED** | P2 |

---

## 4. Detailed Performance Findings

### AUD-PERF-001: Legacy Kotlin Gradle Plugin Warnings
- **Classification**: `CONFIRMED`
- **Measurement**: During `assembleProfile`:
  ```text
  WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP):
  flutter_timezone, mobile_scanner, speech_to_text, workmanager_android.
  Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
  ```
- **User Impact**: No immediate runtime degradation, but risks future build breakage when upgrading Flutter SDK.
- **Recommended Action**: Review and upgrade `flutter_timezone`, `mobile_scanner`, `speech_to_text`, and `workmanager` to their latest pub.dev releases supporting Built-in Kotlin.
- **Severity**: **P2 — Important improvement**
- **Effort**: Medium.

---

### AUD-PERF-002: Redundant Frame Rebuilds During Onboarding Scroll
- **Classification**: `CONFIRMED`
- **Evidence**: In `lib/features/onboarding/presentation/pages/onboarding_page.dart:69`:
  ```dart
  _pageController.addListener(() => setState(() {}));
  ```
- **Root Cause**: Adding a listener to `_pageController` that calls `setState` forces the entire `_OnboardingView` widget tree (including top bar and night scene) to rebuild on every sub-pixel scroll event, rather than isolating the parallax variable to an `AnimatedBuilder` or `ValueListenableBuilder`.
- **User Impact**: Potential micro-stutter during horizontal drag on lower-end devices.
- **Severity**: **P3 — Polish**
- **Effort**: Low.

---

### AUD-PERF-003: High Application APK Size
- **Classification**: `INVESTIGATION NEEDED`
- **Measurement**: `app-profile.apk` is 175.3 MB.
- **Evidence**: The `assets/images/character/` and `assets/images/onboarding/` folders contain multiple large 3D character renders and full-bleed PNGs, in addition to bundled QCF font sets.
- **User Impact**: Slower app downloads and higher cellular data consumption for users in bandwidth-constrained regions.
- **Recommended Action**: Convert non-alpha raster graphics to optimized WebP format and enable split-per-ABI packaging (`flutter build apk --split-per-abi`) to reduce individual download sizes by up to 60%.
- **Severity**: **P2 — Important improvement**
- **Effort**: Medium.
