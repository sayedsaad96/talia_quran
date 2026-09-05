# Talia Unreachable / Hidden Features

| Feature | Exists in Code | Route Exists | Intended Visibility | Reachability Blocker | Recommendation | Status |
|---|---:|---:|---|---|---|---|
| QCF Rendering POC (`QcfRenderingPocPage`) | Yes | Yes (`/debug/qcf-rendering-poc`) | Internal Debug Only | `kDebugMode` guard + No UI button or link anywhere in app | Keep as debug route or remove if obsolete | Working as intended (Debug POC) |
| Dua Khatm Al-Quran (`KhatmDuaPage`) | Yes | Yes (`/quran/khatm-dua`) | User-facing | Accessible ONLY via `KhatmahCompletionPage` (after reading 604 pages of Khatmah). No entry point in Quran reader (end of Surah An-Nas / Page 604) or Azkar Duas list | Add entry point in: 1) Page 604 of Quran reader, and 2) General Azkar / Duas hub | P2 - Unintentionally Hidden |
| Child Onboarding (`childOnboarding`) | Route only | Yes (`/onboarding/child`) | Not applicable | Hardcoded redirect to `memorizationPlusKidsHome` | Remove dead route alias or document as legacy alias | Obsolete route alias |
| Family Dashboard (`FamilyDashboardPage`) | Yes | Yes (`/family-dashboard`) | Remote Parents | Hidden if user is unauthenticated or not marked as Parent | Visible in Settings under "Kids & Guardian" section when parent mode is enabled | Working as intended (Gated) |

## Root-cause categories
- Missing navigation entry point: `KhatmDuaPage` is only linked from `KhatmahCompletionPage`. A normal user finishing reading the Quran freely or looking for Khatm Dua in the Azkar section has no way to open this page.
- Stale implementation / route alias: `AppRoutes.childOnboarding` redirects directly to `AppRoutes.memorizationPlusKidsHome`.
- Intentional debug gating: `QcfRenderingPocPage` guarded by `kDebugMode`.
- Intentional auth/role gating: `FamilyDashboardPage` guarded by `_remoteProtectedRoutes` and `ParentModeToggle`.
