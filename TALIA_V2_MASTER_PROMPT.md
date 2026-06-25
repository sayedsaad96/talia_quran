# Talia Memorization V2 — Master Implementation Prompt
# For: Cursor / Windsurf Agent Mode
# Scope: Phase A → Phase H (complete migration)
# Version: 1.0 | Date: 2026-06-18

---

## ⚠️ CRITICAL AGENT RULES — READ BEFORE STARTING

```
1. ANALYZE BEFORE CODING
   قبل أي تعديل، اقرأ الملف الكامل أولاً.
   لا تعدّل سطراً واحداً قبل أن تفهم السياق الكامل.

2. STOP RULES ARE MANDATORY
   كل phase ليها STOP POINT واضح.
   عند الوصول لأي STOP POINT: توقف تماماً وانتظر موافقة.
   لا تبدأ الـ phase التالية تلقائياً.

3. MINIMAL SAFE CHANGES
   غيّر أقل قدر ممكن لتحقيق المطلوب.
   إذا شككت في أي تعديل — لا تعمله وسجّله كـ question.

4. NO DELETIONS WITHOUT EXPLICIT APPROVAL
   ممنوع حذف أي ملف أو class أو method إلا في Phase H
   وبعد موافقة صريحة.

5. VALIDATE AFTER EVERY PHASE
   شغّل الأوامر دي بعد كل phase:
   → dart format lib test
   → flutter analyze
   → flutter test
   وسجّل النتائج في تقرير الـ phase.

6. BACKWARD COMPATIBILITY IS NON-NEGOTIABLE
   كل تغيير لازم يكون backward compatible مع الكود الموجود.
   لو V2 اتفعّل والـ feature flag معطّل — التطبيق يشتغل عادي.

7. NON-NEGOTIABLE PRODUCT RULES (لا تخالفها أبداً)
   - Timer-only reading confirmation — مفيش manual confirmation button
   - Email confirmation: معطّل بقرار product
   - Certificates تشمل كل الـ paths (Hifz, Adult, Kids, legacy)
   - Kids Mode: تجربة منفصلة في الـ UI فقط — نفس الـ engine
   - Guest Mode: مسموح بتصميم
   - Cubits فقط — ممنوع Riverpod
   - Hardcoded Supabase fallback: Known Issue (مش P0) — بلّغ عنه بس ما تعدّلوش

8. REPORT FORMAT (لكل phase)
   أنتج في نهاية كل phase:
   ✅ Changed Files (مع سبب كل تغيير)
   🔍 Validation Results (نتيجة flutter analyze + test)
   ⚠️ Risks (لو في أي)
   ❓ Open Questions (لو في قرارات محتاجها)
   🛑 STOP — Awaiting approval for Phase [N+1]
```

---

## PROJECT CONTEXT

**App:** Talia (تالية) — Quran memorization app
**Stack:** Flutter + Clean Architecture (feature-first) | Cubits | GoRouter | GetIt | Supabase | Isar
**State Management:** flutter_bloc (Cubits ONLY)
**DI:** GetIt (manual registration, no injectable annotations, no build_runner)
**Navigation:** GoRouter
**Backend:** Supabase
**Local DB:** Isar
**Quran rendering:** qcf_quran_plus

**Key Feature Directories:**
```
lib/
├── core/
│   └── memorization/          ← shared memorization foundation (READ-MOSTLY)
│       ├── smart_coach_engine.dart
│       ├── smart_coach_recommendation.dart
│       ├── memorization_snapshot.dart
│       ├── memorization_progress_reader.dart
│       ├── memorization_path_resolver.dart
│       ├── review_classification.dart
│       ├── review_due_evaluator.dart
│       ├── review_record_filters.dart
│       └── retention_review_summary.dart
├── features/
│   ├── hifz/                  ← Legacy system (DO NOT TOUCH until Phase H)
│   └── memorization_plus/     ← Current MemorizationPlus system
│       ├── data/
│       ├── domain/
│       │   ├── entities/memorization_entities.dart  ← contains AyahReviewRecord, enums
│       │   ├── entities/memorization_profile.dart   ← MemorizationProfile
│       │   └── repositories/
│       └── presentation/
│           ├── cubits/
│           │   ├── quiz_cubit.dart
│           │   ├── kids_mode_cubit.dart
│           │   ├── daily_plan_cubit.dart
│           │   └── ...
│           └── pages/
```

**STT Package:** `speech_to_text` (on-device, Arabic locale `ar-SA`)
**Evaluation:** `ArabicNormalizer.normalize()` exists at `lib/core/utils/arabic_normalizer.dart`

---

## PHASE A — VERIFICATION (Read-Only)

**Goal:** Confirm that the 8 "already satisfied" requirements are truly present before writing any code.

**Actions:**
1. اقرأ الملفات دي وأكّد وجود كل عنصر:

| Required | File to Check | What to Confirm |
|---------|--------------|-----------------|
| ArabicNormalizer | `lib/core/utils/arabic_normalizer.dart` | Implements: harakat removal, hamza normalization, alif variants, stop symbols, punctuation, spaces |
| AyahReviewRecord | `lib/features/memorization_plus/domain/entities/memorization_entities.dart` | Has: strengthLevel, intervalDays, nextReviewDate, totalReviews, lastRating, createdByMode |
| ReviewClassification | `lib/core/memorization/review_classification.dart` | Pure logic, no side effects |
| ReviewDueEvaluator | `lib/core/memorization/review_due_evaluator.dart` | Pure logic, two modes |
| ScheduleNextReviewUsecase | `lib/features/memorization_plus/domain/usecases/` | Standalone SM-2 scheduling |
| MemorizationProfile | `lib/features/memorization_plus/domain/entities/memorization_profile.dart` | Has: selectedPath, isAdult, isChild |
| KidsJourneyStage | `lib/features/memorization_plus/domain/entities/memorization_entities.dart` | Has: startAyah, endAyah, completedAyahs |
| speech_to_text package | `pubspec.yaml` | Package exists and is imported in hifz_session_cubit.dart |

2. اقرأ `ReviewRecordCreatedByMode` enum — سجّل القيم الموجودة.

3. اقرأ `ReviewRecordFilters.isAdultCompatible()` — سجّل المنطق الموجود.

**Output:**
```
## Phase A Report
✅ Confirmed: [list each confirmed item]
❌ Missing: [list anything not found]
📝 Notes: [any discrepancies]
```

**🛑 STOP — انتظر موافقة قبل Phase B**

---

## PHASE B — PREPARATION (Additive Only, Zero Risk)

**Goal:** إضافة 6 building blocks — 3 ملفات جديدة + 3 تعديلات بسيطة على موجود.

**Constraint:** ADDITIVE ONLY. لا حذف. لا تعديل في سلوك موجود.

---

### B1 — Add `v2Session` to `ReviewRecordCreatedByMode` enum

**File:** `lib/features/memorization_plus/domain/entities/memorization_entities.dart`

ابحث عن:
```dart
enum ReviewRecordCreatedByMode {
  adultMemPlus,
  kidsMode,
  migration,
}
```

استبدل بـ:
```dart
enum ReviewRecordCreatedByMode {
  adultMemPlus,
  kidsMode,
  migration,
  /// Created by a Memorization V2 session.
  /// Treated as adult-compatible for Smart Coach and Quiz filtering.
  v2Session,
}
```

⚠️ بعد التعديل: شغّل `flutter analyze` — هتظهر "missing case" warnings على أي switch
يغطي هذا الـ enum. سجّلها كلها في الـ report — لا تعدّلها الآن (هتتعدّل في Phase E).

---

### B2 — Update `ReviewRecordFilters.isAdultCompatible()`

**File:** `lib/core/memorization/review_record_filters.dart`

ابحث عن الـ predicate اللي بتفلتر `adultMemPlus` records وأضيف `v2Session`:

```dart
// BEFORE (exact match depends on file — adapt accordingly):
record.createdByMode == ReviewRecordCreatedByMode.adultMemPlus
    || record.createdByMode == ReviewRecordCreatedByMode.migration

// AFTER:
record.createdByMode == ReviewRecordCreatedByMode.adultMemPlus
    || record.createdByMode == ReviewRecordCreatedByMode.migration
    || record.createdByMode == ReviewRecordCreatedByMode.v2Session
```

إذا كانت بـ Set:
```dart
// أضف v2Session للـ Set:
static const _adultCompatibleModes = {
  ReviewRecordCreatedByMode.adultMemPlus,
  ReviewRecordCreatedByMode.migration,
  ReviewRecordCreatedByMode.v2Session, // ← ADD
};
```

⚠️ لا تلمس `AchievementService` — يقرأ كل الـ records بدون فلتر وده مقصود.

---

### B3 — Add `childAge` to `MemorizationProfile`

**File:** `lib/features/memorization_plus/domain/entities/memorization_profile.dart`

أضف field اختياري:
```dart
// أضف هذا الـ field داخل MemorizationProfile:
/// Age of the child in years. Null for adult profiles or when unknown.
/// Used by V2 Block Review exception (Product Rules §14.3):
///   childAge < 8  → Block Review optional
///   childAge >= 8 → Block Review required
///   null          → Block Review required (safe default)
final int? childAge;
```

أضف للـ constructor ولـ copyWith ولـ props/Equatable إذا موجودة.

إذا كان الـ class بـ freezed:
```dart
// أضف في factory:
final int? childAge,
```

⚠️ Default value = null (Block Review required) — ده الـ safe default.

---

### B4 — Create `lib/core/memorization/v2/session_phase.dart` (New File)

```dart
// lib/core/memorization/v2/session_phase.dart

/// Official V2 session phase state machine.
/// Matches Product Rules §11 verbatim.
enum V2SessionPhase {
  created,
  learning,
  memorizing,
  reciting,
  remediation,
  blockReviewPending,
  blockReview,
  completed,
}

extension V2SessionPhaseX on V2SessionPhase {
  /// Whether STT recording should be active.
  bool get requiresSTT =>
      this == V2SessionPhase.reciting || this == V2SessionPhase.blockReview;

  /// Whether the ayah text must be hidden from user.
  bool get textHidden =>
      this == V2SessionPhase.reciting || this == V2SessionPhase.blockReview;

  /// Whether the hint system is available (Product Rules §5: memorizing ONLY).
  bool get hintsAllowed => this == V2SessionPhase.memorizing;

  /// Whether this is a terminal phase.
  bool get isTerminal => this == V2SessionPhase.completed;

  /// Human-readable label for logging.
  String get debugLabel => switch (this) {
    V2SessionPhase.created            => 'CREATED',
    V2SessionPhase.learning           => 'LEARNING',
    V2SessionPhase.memorizing         => 'MEMORIZING',
    V2SessionPhase.reciting           => 'RECITING',
    V2SessionPhase.remediation        => 'REMEDIATION',
    V2SessionPhase.blockReviewPending => 'BLOCK_REVIEW_PENDING',
    V2SessionPhase.blockReview        => 'BLOCK_REVIEW',
    V2SessionPhase.completed          => 'COMPLETED',
  };
}
```

---

### B5 — Create `lib/core/memorization/v2/hint_usage.dart` (New File)

```dart
// lib/core/memorization/v2/hint_usage.dart

import 'package:equatable/equatable.dart';

/// Hint levels — Product Rules §5 & §14.6
enum V2HintLevel {
  none,       // Full score
  firstWord,  // Reduced score
  fullAyah;   // Minimum passing score — Smart Coach records dependency

  bool get hasPenalty => this != V2HintLevel.none;
  bool get isReading  => this == V2HintLevel.fullAyah;
  int  get value      => index; // 0, 1, 2

  /// Level never decreases within a session.
  V2HintLevel max(V2HintLevel other) =>
      index >= other.index ? this : other;
}

/// Immutable record of hint usage for one ayah in a session.
final class V2HintUsage extends Equatable {
  const V2HintUsage({
    required this.surahId,
    required this.ayahNumber,
    required this.level,
    required this.usedAt,
  });

  final int surahId;
  final int ayahNumber;
  final V2HintLevel level;
  final DateTime usedAt;

  String get ayahKey => '$surahId:$ayahNumber';

  V2HintUsage escalate(V2HintLevel newLevel) {
    if (newLevel.index <= level.index) return this;
    return V2HintUsage(
      surahId: surahId,
      ayahNumber: ayahNumber,
      level: newLevel,
      usedAt: DateTime.now().toUtc(),
    );
  }

  @override
  List<Object?> get props => [surahId, ayahNumber, level, usedAt];
}

/// Tracks all hint usages within a single V2 session.
final class V2HintTracker extends Equatable {
  const V2HintTracker({Map<String, V2HintUsage>? usages})
      : _usages = usages ?? const {};

  final Map<String, V2HintUsage> _usages;

  static const empty = V2HintTracker();

  V2HintLevel levelFor(int surahId, int ayahNumber) =>
      _usages['$surahId:$ayahNumber']?.level ?? V2HintLevel.none;

  V2HintTracker record({
    required int surahId,
    required int ayahNumber,
    required V2HintLevel level,
  }) {
    final key = '$surahId:$ayahNumber';
    final existing = _usages[key];
    final updated = existing == null
        ? V2HintUsage(
            surahId: surahId,
            ayahNumber: ayahNumber,
            level: level,
            usedAt: DateTime.now().toUtc(),
          )
        : existing.escalate(level);

    if (existing != null && updated.level == existing.level) return this;
    return V2HintTracker(usages: {..._usages, key: updated});
  }

  Iterable<V2HintUsage> get allUsages           => _usages.values;
  Iterable<V2HintUsage> get fullAyahDependencies =>
      _usages.values.where((u) => u.level == V2HintLevel.fullAyah);
  bool get hasAnyHint    => _usages.isNotEmpty;
  int  get hintedAyahCount => _usages.length;

  @override
  List<Object?> get props => [_usages];
}
```

---

### B6 — Create `lib/core/memorization/v2/ayah_failure_tracker.dart` (New File)

```dart
// lib/core/memorization/v2/ayah_failure_tracker.dart

import 'package:equatable/equatable.dart';

/// Failure threshold for Weak Ayah classification (Product Rules §14.5).
const int kWeakAyahFailureThreshold = 3;

/// Remediation escalation levels (Product Rules §14.4).
enum V2RemediationLevel {
  standard,  // 1st failure — replay + re-memorize
  guided,    // 2nd failure — additional guided memorization
  weakAyah,  // 3rd+ failure — Smart Coach signal
}

/// Immutable failure record for one ayah in a session.
final class V2AyahFailureRecord extends Equatable {
  const V2AyahFailureRecord({
    required this.surahId,
    required this.ayahNumber,
    required this.failureCount,
    required this.lastFailedAt,
  }) : assert(failureCount > 0);

  final int surahId;
  final int ayahNumber;
  final int failureCount;
  final DateTime lastFailedAt;

  String get ayahKey => '$surahId:$ayahNumber';

  bool get isWeak => failureCount >= kWeakAyahFailureThreshold;

  V2RemediationLevel get remediationLevel => switch (failureCount) {
    1 => V2RemediationLevel.standard,
    2 => V2RemediationLevel.guided,
    _ => V2RemediationLevel.weakAyah,
  };

  V2AyahFailureRecord increment() => V2AyahFailureRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    failureCount: failureCount + 1,
    lastFailedAt: DateTime.now().toUtc(),
  );

  @override
  List<Object?> get props => [surahId, ayahNumber, failureCount, lastFailedAt];
}

/// Tracks all recitation failures within a single V2 session.
final class V2AyahFailureTracker extends Equatable {
  const V2AyahFailureTracker({Map<String, V2AyahFailureRecord>? records})
      : _records = records ?? const {};

  final Map<String, V2AyahFailureRecord> _records;

  static const empty = V2AyahFailureTracker();

  int failureCountFor(int surahId, int ayahNumber) =>
      _records['$surahId:$ayahNumber']?.failureCount ?? 0;

  bool isWeak(int surahId, int ayahNumber) =>
      _records['$surahId:$ayahNumber']?.isWeak ?? false;

  V2RemediationLevel remediationLevelFor(int surahId, int ayahNumber) =>
      _records['$surahId:$ayahNumber']?.remediationLevel
      ?? V2RemediationLevel.standard;

  V2AyahFailureTracker recordFailure({
    required int surahId,
    required int ayahNumber,
  }) {
    final key = '$surahId:$ayahNumber';
    final existing = _records[key];
    final updated = existing == null
        ? V2AyahFailureRecord(
            surahId: surahId,
            ayahNumber: ayahNumber,
            failureCount: 1,
            lastFailedAt: DateTime.now().toUtc(),
          )
        : existing.increment();

    return V2AyahFailureTracker(records: {..._records, key: updated});
  }

  Iterable<V2AyahFailureRecord> get allFailures => _records.values;
  Iterable<V2AyahFailureRecord> get weakAyahs  =>
      _records.values.where((r) => r.isWeak);
  Set<String> get weakAyahKeys => weakAyahs.map((r) => r.ayahKey).toSet();
  bool get hasWeakAyahs  => _records.values.any((r) => r.isWeak);
  int  get totalFailures =>
      _records.values.fold(0, (sum, r) => sum + r.failureCount);

  @override
  List<Object?> get props => [_records];
}
```

---

### B — Validation Commands
```bash
dart format lib/core/memorization/v2/ lib/features/memorization_plus/domain/
flutter analyze
flutter test
```

**Expected:** analyze warnings فقط على الـ missing switch cases من B1 — ده مقصود.

**🛑 STOP — انتظر موافقة قبل Phase C**

---

## PHASE C — SESSION ENGINE (Pure Domain, No UI)

**Goal:** بناء الـ Session Engine كـ pure domain layer — لا Flutter imports، لا Cubits.

**New Directory:** `lib/core/memorization/v2/`

---

### C1 — Create `recitation_evaluator.dart`

```dart
// lib/core/memorization/v2/recitation_evaluator.dart

import '../../../../core/utils/arabic_normalizer.dart';

/// V2 recitation evaluation — Product Rules §14.2 & §14.7
///
/// Evaluation strategy:
///   Exact normalized match  → Pass (ideal)
///   Normalized similarity >= [passThreshold] → Pass (STT tolerance)
///   Below threshold → Fail → Remediation
///
/// Why 0.92 not 1.0:
///   `speech_to_text` on-device ASR produces minor variations even for
///   correct recitations (e.g., shadda omission, alif variation).
///   0.92 is high enough to enforce accuracy while absorbing ASR noise.
///   This implements the spirit of "100% match" from the product rules.
const double kV2PassThreshold = 0.92;

final class V2RecitationEvaluator {
  const V2RecitationEvaluator({double passThreshold = kV2PassThreshold})
      : _threshold = passThreshold;

  final double _threshold;

  /// Evaluates a single ayah recitation.
  ///
  /// Returns [V2RecitationResult] with pass/fail and similarity score.
  /// Empty [spokenText] is treated as no-attempt — returns [V2RecitationResult.noAttempt].
  V2RecitationResult evaluate({
    required String targetText,
    required String spokenText,
  }) {
    final normalizedTarget = ArabicNormalizer.normalize(targetText);
    final normalizedSpoken = ArabicNormalizer.normalize(spokenText);

    // No-attempt guard — do not count empty STT as failure.
    if (normalizedSpoken.isEmpty) {
      return V2RecitationResult.noAttempt;
    }

    // Exact match — perfect recitation.
    if (normalizedSpoken == normalizedTarget) {
      return V2RecitationResult(
        passed: true,
        similarityScore: 1.0,
        normalizedTarget: normalizedTarget,
        normalizedSpoken: normalizedSpoken,
      );
    }

    // Similarity-based match for STT tolerance.
    final similarity = _computeSimilarity(normalizedTarget, normalizedSpoken);
    return V2RecitationResult(
      passed: similarity >= _threshold,
      similarityScore: similarity,
      normalizedTarget: normalizedTarget,
      normalizedSpoken: normalizedSpoken,
    );
  }

  /// Token-overlap similarity (word-level Jaccard).
  /// More robust than character-level Dice for Arabic word boundaries.
  double _computeSimilarity(String target, String spoken) {
    final targetTokens  = target.split(' ').where((t) => t.isNotEmpty).toSet();
    final spokenTokens  = spoken.split(' ').where((t) => t.isNotEmpty).toSet();

    if (targetTokens.isEmpty) return 0.0;

    final intersection = targetTokens.intersection(spokenTokens).length;
    final union        = targetTokens.union(spokenTokens).length;

    if (union == 0) return 0.0;
    return intersection / union;
  }
}

/// Result of a single recitation evaluation.
final class V2RecitationResult {
  const V2RecitationResult({
    required this.passed,
    required this.similarityScore,
    required this.normalizedTarget,
    required this.normalizedSpoken,
  }) : isNoAttempt = false;

  const V2RecitationResult._noAttempt()
      : passed          = false,
        similarityScore = 0.0,
        normalizedTarget = '',
        normalizedSpoken = '',
        isNoAttempt     = true;

  static const noAttempt = V2RecitationResult._noAttempt();

  final bool   passed;
  final double similarityScore;
  final String normalizedTarget;
  final String normalizedSpoken;

  /// True if STT returned empty — not counted as a failure.
  final bool isNoAttempt;
}
```

---

### C2 — Create `session_state.dart` (V2 Session Domain State)

```dart
// lib/core/memorization/v2/session_state.dart

import 'package:equatable/equatable.dart';
import '../../../features/memorization_plus/domain/entities/memorization_entities.dart';
import '../../../features/quran/domain/entities/quran_entities.dart';
import 'session_phase.dart';
import 'hint_usage.dart';
import 'ayah_failure_tracker.dart';

/// Immutable domain state for a single V2 memorization session.
///
/// This is a pure domain object — no Flutter imports, no Cubit dependency.
/// The Cubit wraps this and converts it to UI states.
final class V2SessionState extends Equatable {
  const V2SessionState({
    required this.surahId,
    required this.blockAyahs,
    required this.currentAyahIndex,
    required this.phase,
    required this.passedAyahNumbers,
    required this.hintTracker,
    required this.failureTracker,
    required this.blockReviewRequired,
    this.lastRecitationResult,
  });

  /// Creates the initial session state for a new block.
  factory V2SessionState.initial({
    required int surahId,
    required List<Ayah> blockAyahs,
    required bool blockReviewRequired,
  }) {
    return V2SessionState(
      surahId: surahId,
      blockAyahs: blockAyahs,
      currentAyahIndex: 0,
      phase: V2SessionPhase.created,
      passedAyahNumbers: const {},
      hintTracker: V2HintTracker.empty,
      failureTracker: V2AyahFailureTracker.empty,
      blockReviewRequired: blockReviewRequired,
    );
  }

  final int surahId;

  /// All ayahs in this block (e.g., ayahs 1–5 of a surah).
  final List<Ayah> blockAyahs;

  /// Index within [blockAyahs] — points to the current ayah being worked on.
  final int currentAyahIndex;

  /// Current phase in the V2 state machine.
  final V2SessionPhase phase;

  /// Ayah numbers that have individually passed recitation.
  final Set<int> passedAyahNumbers;

  /// Hint usage tracker for this session.
  final V2HintTracker hintTracker;

  /// Failure tracker for this session.
  final V2AyahFailureTracker failureTracker;

  /// Whether block review is required (false for children < 8 per §14.3).
  final bool blockReviewRequired;

  /// Result of the most recent recitation evaluation.
  final V2RecitationResult? lastRecitationResult;

  // ── Computed Properties ──────────────────────────────────

  Ayah get currentAyah => blockAyahs[currentAyahIndex];

  int get totalAyahsInBlock => blockAyahs.length;

  bool get allAyahsPassed =>
      passedAyahNumbers.length >= blockAyahs.length;

  bool get isLastAyah => currentAyahIndex >= blockAyahs.length - 1;

  bool get isComplete => phase == V2SessionPhase.completed;

  double get blockProgress =>
      passedAyahNumbers.length / blockAyahs.length.clamp(1, blockAyahs.length);

  // ── Mutation Helpers ─────────────────────────────────────

  V2SessionState copyWith({
    V2SessionPhase?      phase,
    int?                 currentAyahIndex,
    Set<int>?            passedAyahNumbers,
    V2HintTracker?       hintTracker,
    V2AyahFailureTracker? failureTracker,
    V2RecitationResult?  lastRecitationResult,
    bool                 clearLastResult = false,
  }) {
    return V2SessionState(
      surahId: surahId,
      blockAyahs: blockAyahs,
      currentAyahIndex: currentAyahIndex ?? this.currentAyahIndex,
      phase: phase ?? this.phase,
      passedAyahNumbers: passedAyahNumbers ?? this.passedAyahNumbers,
      hintTracker: hintTracker ?? this.hintTracker,
      failureTracker: failureTracker ?? this.failureTracker,
      blockReviewRequired: blockReviewRequired,
      lastRecitationResult: clearLastResult
          ? null
          : (lastRecitationResult ?? this.lastRecitationResult),
    );
  }

  @override
  List<Object?> get props => [
    surahId, blockAyahs, currentAyahIndex, phase,
    passedAyahNumbers, hintTracker, failureTracker,
    blockReviewRequired, lastRecitationResult,
  ];
}

// Forward declare V2RecitationResult here if needed for import simplicity.
// (Already defined in recitation_evaluator.dart — import from there)
```

---

### C3 — Create `session_engine.dart`

```dart
// lib/core/memorization/v2/session_engine.dart
//
// Pure domain class — no Flutter imports, no Cubit, no BuildContext.
// Implements the V2 phase state machine (Product Rules §11).
//
// Usage: MemorizationSessionCubit wraps this and drives UI.

import 'session_phase.dart';
import 'session_state.dart';
import 'hint_usage.dart';
import 'ayah_failure_tracker.dart';
import 'recitation_evaluator.dart';
import '../../../features/quran/domain/entities/quran_entities.dart';

/// Pure domain session engine for Memorization V2.
///
/// All methods are synchronous and return a new [V2SessionState].
/// Side effects (persistence, services) are handled by the Cubit via callbacks.
final class V2SessionEngine {
  V2SessionEngine({V2RecitationEvaluator? evaluator})
      : _evaluator = evaluator ?? const V2RecitationEvaluator();

  final V2RecitationEvaluator _evaluator;

  // ── Phase Transitions ────────────────────────────────────

  /// Transitions from [created] → [learning].
  V2SessionState startLearning(V2SessionState state) {
    assert(state.phase == V2SessionPhase.created);
    return state.copyWith(phase: V2SessionPhase.learning);
  }

  /// Transitions from [learning] → [memorizing].
  V2SessionState startMemorizing(V2SessionState state) {
    assert(state.phase == V2SessionPhase.learning);
    return state.copyWith(phase: V2SessionPhase.memorizing);
  }

  /// Transitions from [memorizing] → [reciting].
  V2SessionState startReciting(V2SessionState state) {
    assert(state.phase == V2SessionPhase.memorizing
        || state.phase == V2SessionPhase.remediation);
    return state.copyWith(
      phase: V2SessionPhase.reciting,
      clearLastResult: true,
    );
  }

  /// Records a hint usage during [memorizing].
  /// Returns unchanged state if called outside memorizing phase.
  V2SessionState useHint(V2SessionState state, V2HintLevel level) {
    if (!state.phase.hintsAllowed) return state; // silent guard
    return state.copyWith(
      hintTracker: state.hintTracker.record(
        surahId: state.surahId,
        ayahNumber: state.currentAyah.numberInSurah,
        level: level,
      ),
    );
  }

  /// Evaluates a recitation attempt.
  ///
  /// On pass  → marks ayah passed, advances to next or blockReviewPending.
  /// On fail  → increments failure counter, transitions to remediation.
  /// No-attempt → returns state unchanged (STT returned empty).
  V2SessionState evaluateRecitation(V2SessionState state, String spokenText) {
    assert(state.phase == V2SessionPhase.reciting);

    final result = _evaluator.evaluate(
      targetText: state.currentAyah.text,
      spokenText: spokenText,
    );

    // No-attempt: STT returned empty — don't penalize.
    if (result.isNoAttempt) {
      return state.copyWith(phase: V2SessionPhase.reciting);
    }

    final stateWithResult = state.copyWith(lastRecitationResult: result);

    if (result.passed) {
      return _handlePass(stateWithResult);
    } else {
      return _handleFail(stateWithResult);
    }
  }

  /// Evaluates a block review recitation.
  ///
  /// On pass  → transitions to [completed].
  /// On fail  → identifies weak ayahs, loops back for targeted remediation.
  V2SessionState evaluateBlockReview(V2SessionState state, String spokenText) {
    assert(state.phase == V2SessionPhase.blockReview);

    // Build expected text: all ayahs in block joined.
    final fullText = state.blockAyahs.map((a) => a.text).join(' ');
    final result = _evaluator.evaluate(
      targetText: fullText,
      spokenText: spokenText,
    );

    if (result.isNoAttempt) {
      return state.copyWith(phase: V2SessionPhase.blockReview);
    }

    if (result.passed) {
      return state.copyWith(
        phase: V2SessionPhase.completed,
        lastRecitationResult: result,
      );
    }

    // On block review fail: identify weak ayahs for targeted remediation.
    // Re-enter remediation for first weak ayah.
    final weakAyah = _findFirstWeakAyah(state);
    if (weakAyah == null) {
      // All passed individually — treat as completed (edge case).
      return state.copyWith(phase: V2SessionPhase.completed);
    }

    final weakIndex = state.blockAyahs
        .indexWhere((a) => a.numberInSurah == weakAyah);

    return state.copyWith(
      phase: V2SessionPhase.remediation,
      currentAyahIndex: weakIndex >= 0 ? weakIndex : state.currentAyahIndex,
      lastRecitationResult: result,
    );
  }

  /// Completes remediation and returns to memorizing for retry.
  V2SessionState completeRemediation(V2SessionState state) {
    assert(state.phase == V2SessionPhase.remediation);
    return state.copyWith(
      phase: V2SessionPhase.memorizing,
      clearLastResult: true,
    );
  }

  // ── Private Helpers ──────────────────────────────────────

  V2SessionState _handlePass(V2SessionState state) {
    final ayahNumber = state.currentAyah.numberInSurah;
    final newPassed = {...state.passedAyahNumbers, ayahNumber};

    final allPassed = newPassed.length >= state.blockAyahs.length;

    if (allPassed) {
      // All ayahs individually passed — determine next phase.
      final nextPhase = state.blockReviewRequired
          ? V2SessionPhase.blockReviewPending
          : V2SessionPhase.completed;

      return state.copyWith(
        phase: nextPhase,
        passedAyahNumbers: newPassed,
      );
    }

    // Advance to next un-passed ayah.
    final nextIndex = _nextUnpassedIndex(state, newPassed);
    return state.copyWith(
      phase: V2SessionPhase.learning, // restart cycle for next ayah
      currentAyahIndex: nextIndex,
      passedAyahNumbers: newPassed,
      clearLastResult: true,
    );
  }

  V2SessionState _handleFail(V2SessionState state) {
    final ayahNumber = state.currentAyah.numberInSurah;
    final newTracker = state.failureTracker.recordFailure(
      surahId: state.surahId,
      ayahNumber: ayahNumber,
    );

    return state.copyWith(
      phase: V2SessionPhase.remediation,
      failureTracker: newTracker,
    );
  }

  int _nextUnpassedIndex(V2SessionState state, Set<int> passed) {
    for (int i = 0; i < state.blockAyahs.length; i++) {
      if (!passed.contains(state.blockAyahs[i].numberInSurah)) return i;
    }
    return state.currentAyahIndex;
  }

  int? _findFirstWeakAyah(V2SessionState state) {
    for (final record in state.failureTracker.weakAyahs) {
      return record.ayahNumber;
    }
    // If no explicitly weak ayahs, return first un-passed.
    for (final ayah in state.blockAyahs) {
      if (!state.passedAyahNumbers.contains(ayah.numberInSurah)) {
        return ayah.numberInSurah;
      }
    }
    return null;
  }
}
```

---

### C — Validation
```bash
dart format lib/core/memorization/v2/
flutter analyze lib/core/memorization/v2/
flutter test test/core/memorization/v2/   # إذا موجود
```

**🛑 STOP — انتظر موافقة قبل Phase D**

---

## PHASE D — ADAPTER LAYER

**Goal:** ربط الـ Session Engine بالـ infrastructure الموجودة بدون أن يلمس الـ Engine الـ repositories مباشرة.

**New File:** `lib/core/memorization/v2/session_adapters.dart`

```dart
// lib/core/memorization/v2/session_adapters.dart
//
// Adapters connect V2SessionEngine to existing infrastructure.
// The engine never imports from data layer — adapters handle that.

import '../../../features/memorization_plus/domain/entities/memorization_entities.dart';
import '../../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/services/xp_service.dart';
import '../../../core/services/achievement_service.dart';
import '../../../core/utils/talia_logger.dart';
import 'session_state.dart';
import 'hint_usage.dart';

/// Writes V2 session results to the existing AyahReviewRecord infrastructure.
///
/// Uses MemorizationPlusRepository.evaluateAyah() — the same path as QuizCubit.
/// Mode tag: ReviewRecordCreatedByMode.v2Session
final class V2SessionReviewAdapter {
  const V2SessionReviewAdapter(this._repository);

  final MemorizationPlusRepository _repository;

  /// Called when an individual ayah passes recitation in a V2 session.
  Future<void> onAyahPassed({
    required int surahId,
    required int ayahNumber,
    required V2HintLevel hintLevel,
  }) async {
    // Map hint level to PerformanceRating for SM-2 scheduling.
    // Level 0 (no hint)    → excellent
    // Level 1 (first word) → average
    // Level 2 (full ayah)  → weak (but still passes — §14.6)
    final rating = switch (hintLevel) {
      V2HintLevel.none      => PerformanceRating.excellent,
      V2HintLevel.firstWord => PerformanceRating.average,
      V2HintLevel.fullAyah  => PerformanceRating.weak,
    };

    final result = await _repository.evaluateAyah(
      surahId: surahId,
      ayahNumber: ayahNumber,
      rating: rating,
      createdByMode: ReviewRecordCreatedByMode.v2Session,
    );

    result.fold(
      (failure) => TaliaLogger.e('V2: Failed to save ayah review record', failure),
      (_) => TaliaLogger.d('V2: AyahReviewRecord saved [$surahId:$ayahNumber]'),
    );
  }

  /// Called when an ayah is marked as Weak (3+ failures in session).
  Future<void> onAyahWeak({
    required int surahId,
    required int ayahNumber,
  }) async {
    // Write a weak rating to signal Smart Coach (Priority 1: weakDue).
    final result = await _repository.evaluateAyah(
      surahId: surahId,
      ayahNumber: ayahNumber,
      rating: PerformanceRating.weak,
      createdByMode: ReviewRecordCreatedByMode.v2Session,
    );

    result.fold(
      (failure) => TaliaLogger.e('V2: Failed to save weak ayah signal', failure),
      (_) => TaliaLogger.d('V2: Weak ayah signal saved [$surahId:$ayahNumber]'),
    );
  }
}

/// Wraps gamification services for V2 session completion.
final class V2SessionProgressAdapter {
  const V2SessionProgressAdapter({
    required StreakService streakService,
    required XpService xpService,
    required AchievementService achievementService,
  })  : _streak = streakService,
        _xp = xpService,
        _achievements = achievementService;

  final StreakService     _streak;
  final XpService        _xp;
  final AchievementService _achievements;

  /// Called on successful block completion (all ayahs + block review).
  /// Returns any newly unlocked certificate awards.
  Future<List<CertificateAward>> onBlockCompleted(V2SessionState session) async {
    try {
      await _streak.recordActivity(activityDelta: session.totalAyahsInBlock);
      await _xp.addXp('v2_block_completed');
      return await _achievements.checkAndUnlockCertificates();
    } catch (e, stack) {
      TaliaLogger.e('V2: Non-critical — gamification error on block complete', e, stack);
      return [];
    }
  }
}
```

**🛑 STOP — انتظر موافقة قبل Phase E**

---

## PHASE E — ADULT UI FLOW (Behind Feature Flag)

**Goal:** بناء الـ Cubit + 6 screens للـ adult V2 flow خلف feature flag.

**Feature Flag Key:** `'enable_memorization_v2'` في `SharedPreferences` (default: false)

### E1 — Feature Flag Helper

**New File:** `lib/core/memorization/v2/v2_feature_flag.dart`

```dart
// lib/core/memorization/v2/v2_feature_flag.dart

import 'package:shared_preferences/shared_preferences.dart';

abstract final class V2FeatureFlag {
  static const _keyAdult = 'enable_memorization_v2';
  static const _keyKids  = 'enable_memorization_v2_kids';

  static Future<bool> isAdultEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAdult) ?? false;
  }

  static Future<bool> isKidsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyKids) ?? false;
  }

  /// For testing: enable V2 programmatically.
  static Future<void> setAdultEnabled({required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdult, enabled);
  }
}
```

### E2 — MemorizationSessionCubit

**New File:** `lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart`

اكتب Cubit يـ:
1. يستخدم `V2SessionEngine` للـ domain logic
2. يستخدم `V2SessionReviewAdapter` للـ persistence
3. يستخدم `V2SessionProgressAdapter` للـ gamification
4. يستخدم `SpeechToText` للـ STT (نفس الـ setup في `HifzSessionCubit`)
5. يستخدم `AudioCacheService` للـ audio في Learning phase
6. يـ emit UI-friendly states بناءً على `V2SessionState`

**State classes مطلوبة:**
```dart
sealed class MemorizationSessionCubitState {}
class MSInitial extends MemorizationSessionCubitState {}
class MSLoading extends MemorizationSessionCubitState {}
class MSError extends MemorizationSessionCubitState { final String message; }
class MSActive extends MemorizationSessionCubitState {
  final V2SessionState sessionState;
  final bool isRecording;
  final bool isPlaying;
  final String recognizedText;
  final bool isEvaluating;
  final HifzSpeechIssue? speechIssue; // reuse existing enum
}
class MSCompleted extends MemorizationSessionCubitState {
  final V2SessionState finalState;
  final List<CertificateAward> awards;
}
```

**Methods:**
- `startSession(int surahId, int startAyah, int blockSize)`
- `advanceToMemorizing()`
- `advanceToReciting()`
- `useHint(V2HintLevel level)`
- `startRecording()`
- `stopRecording()`
- `completeRemediation()`
- `startBlockReview()`
- `close()` — dispose audio + STT

### E3 — New V2 Pages

أنشئ 6 صفحات في `lib/features/memorization_plus/presentation/pages/v2/`:

| File | Role |
|------|------|
| `v2_learning_page.dart` | عرض الآية + صوت. زر "Ready to Memorize" |
| `v2_memorizing_page.dart` | إخفاء/إظهار الآية. Hint buttons (Level 0/1/2) |
| `v2_recitation_page.dart` | Full-screen STT. لا نص. زر تسجيل |
| `v2_remediation_page.dart` | نتيجة الفشل. إعادة التعلم. Remediation level badge |
| `v2_block_review_page.dart` | مراجعة الـ block كامل. STT. لا نص. لا hints |
| `v2_completion_page.dart` | نتيجة الجلسة. Progress. Certificates إذا موجودة |

**UI Rules:**
- V2 pages تستخدم `BlocBuilder<MemorizationSessionCubit, MemorizationSessionCubitState>`
- لا يوجد نص آية في `v2_recitation_page` و `v2_block_review_page` — حتى لو المستخدم طلب
- الـ hint buttons تظهر فقط في `v2_memorizing_page`

### E4 — GoRouter Wiring

أضف V2 routes في الـ router الموجود:

```dart
// أضف داخل الـ routes الموجودة — لا تعدّل routes موجودة:
GoRoute(
  path: '/memorization-v2/session',
  builder: (_, state) {
    final extra = state.extra as Map<String, dynamic>;
    return BlocProvider(
      create: (_) => getIt<MemorizationSessionCubit>()
        ..startSession(
          extra['surahId'] as int,
          extra['startAyah'] as int,
          extra['blockSize'] as int? ?? 5,
        ),
      child: const V2LearningPage(),
    );
  },
),
```

### E5 — GetIt Registration

أضف الـ cubit للـ DI:

```dart
// في ملف الـ DI setup الموجود — أضف:
getIt.registerFactory<MemorizationSessionCubit>(
  () => MemorizationSessionCubit(
    sessionEngine: V2SessionEngine(),
    reviewAdapter: V2SessionReviewAdapter(getIt<MemorizationPlusRepository>()),
    progressAdapter: V2SessionProgressAdapter(
      streakService: getIt<StreakService>(),
      xpService: getIt<XpService>(),
      achievementService: getIt<AchievementService>(),
    ),
    memorizationRepository: getIt<MemorizationPlusRepository>(),
  ),
);
```

### E — Validation
```bash
dart format lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart
dart format lib/features/memorization_plus/presentation/pages/v2/
flutter analyze
flutter test
```

**🛑 STOP — انتظر موافقة قبل Phase F**

---

## PHASE F — BLOCK REVIEW IMPLEMENTATION

**Goal:** تفعيل الـ Block Review flow كاملاً وربطه بالـ session engine.

### F1 — Block Review في SessionEngine (مكتمل من Phase C)
`evaluateBlockReview()` في `V2SessionEngine` مكتوب — لا تعديل مطلوب.

### F2 — Block Review Trigger في Cubit

في `MemorizationSessionCubit`، عند وصول `V2SessionPhase.blockReviewPending`:
1. اشتغل block review audio prefetch للآيات كلها
2. انتقل تلقائياً لـ `V2SessionPhase.blockReview`
3. عدّل الـ state المـ emit ليشمل `isBlockReview: true`

### F3 — Block Review Failure — Targeted Remediation

عند فشل الـ block review:
1. الـ engine بيحدد الـ weak ayahs تلقائياً
2. الـ Cubit يقرأ `session.failureTracker.weakAyahs`
3. يعيد الـ cycle للـ ayahs الضعيفة فقط
4. الـ ayahs اللي نجحت فردياً — لا تُعاد

### F4 — Review Records on Block Completion

عند `V2SessionPhase.completed`:
```dart
// في الـ Cubit — بعد block review pass:
for (final ayah in session.blockAyahs) {
  await _reviewAdapter.onAyahPassed(
    surahId: session.surahId,
    ayahNumber: ayah.numberInSurah,
    hintLevel: session.hintTracker.levelFor(session.surahId, ayah.numberInSurah),
  );
}
// Weak ayahs — extra signal:
for (final weak in session.failureTracker.weakAyahs) {
  await _reviewAdapter.onAyahWeak(
    surahId: session.surahId,
    ayahNumber: weak.ayahNumber,
  );
}
// Gamification:
final awards = await _progressAdapter.onBlockCompleted(session);
```

**🛑 STOP — انتظر موافقة قبل Phase G**

---

## PHASE G — KIDS MIGRATION (Behind Separate Feature Flag)

**Goal:** استبدال `KidsModeCubit` internals بـ Session Engine مع الحفاظ على Kids UI.

⚠️ **قبل البدء:** تأكد إن قرار Kids STT policy اتخذ (نفس الـ threshold 0.92 ولا مختلف).

### G1 — Age-Based Block Review Skip

في `MemorizationSessionCubit.startSession()`:
```dart
// احسب blockReviewRequired بناءً على childAge:
final profile = await _memorizationRepository.getMemorizationProfile();
final childAge = profile.fold((_) => null, (p) => p.childAge);
final blockReviewRequired = childAge == null || childAge >= 8;
```

### G2 — Kids Session Cubit

أنشئ `KidsMemorizationSessionCubit` أو extend الـ adult cubit:
- نفس الـ `V2SessionEngine`
- نفس الـ `V2SessionReviewAdapter`
- Kids gamification: `awardKidsPoints()` + `saveKidsSessionLog()`
- بعد إكمال كل آية: ادعو `awardKidsPoints()` + `markAyahMemorized()` (existing)

### G3 — Kids UI Adaptation

اعمل Kids-themed wrappers للـ V2 pages:

| V2 Adult Page | Kids Equivalent | UI Change |
|--------------|-----------------|-----------|
| V2LearningPage | KidsListenPage | 🎧 + animations |
| V2MemorizingPage | KidsTryRememberPage | 🧠 + simpler hints |
| V2RecitationPage | KidsChallengeRecitePage | 🎤 + encouragement |
| V2BlockReviewPage | KidsReviewChallengePage | ⭐ + game feel |
| V2CompletionPage | KidsCompletionPage | Stars + level up |

**لا تحذف** الـ pages الحالية للـ kids — تبقى موجودة طول Phase G.

### G4 — Feature Flag

```dart
// في V2FeatureFlag:
static Future<bool> isKidsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyKids) ?? false;
}
```

**🛑 STOP — انتظر موافقة قبل Phase H**

---

## PHASE H — LEGACY CLEANUP (Only After 2 Release Cycles)

⚠️ **هذه الـ phase لا تُنفَّذ تلقائياً — تحتاج موافقة صريحة منفصلة.**

### H1 — Deprecation (لا حذف)
```dart
// أضف @deprecated على:
@Deprecated('Use MemorizationSessionCubit instead. Will be removed in v3.0')
class HifzSessionCubit { ... }

@Deprecated('Use V2 session pages instead. Will be removed in v3.0')
class HifzSessionPage { ... }
```

### H2 — Smart Coach Cleanup
- أزل priority `hifzReviewDue` إذا Hifz مهاجر بالكامل
- أضف priority `continueV2Session` للـ Smart Coach

### H3 — String Similarity Removal
- تحقق إن `string_similarity` مش بيستخدمه غير `HifzSessionCubit`
- أزل من `pubspec.yaml` بعد إزالة الاستخدام

### H4 — AyahProgress Migration (One-Time)
- اكتب migration script يحوّل `AyahProgress` (Hifz legacy) → `AyahReviewRecord`
- شغّله مرة واحدة على المستخدمين الحاليين
- احتفظ بالـ original records كـ backup لـ 30 يوم

**🛑 STOP — Phase H تنتظر موافقة منفصلة وتأكيد V2 stability**

---

## FINAL ACCEPTANCE CRITERIA

قبل اعتبار الـ implementation ناجحة:

```
✅ flutter analyze — zero errors, zero warnings (ما عدا missing switch cases من B1 قبل Phase E)
✅ flutter test — all existing tests pass
✅ Feature flag OFF → التطبيق يشتغل عادي بالـ legacy flow
✅ Feature flag ON  → V2 flow يعمل من Learning → Completed
✅ AyahReviewRecord بيتكتب بـ mode=v2Session بعد كل آية
✅ Smart Coach يقرأ V2 records في Priority 1-4
✅ AchievementService يحتسب V2 records في الـ certificates
✅ Kids Mode — feature flag منفصل
✅ Block Review skip — يعمل للأطفال أقل من 8 سنوات
✅ Weak Ayah signal — يوصل لـ Smart Coach بعد 3 فشل
✅ لا يوجد نص آية في Recitation + Block Review screens
✅ Hint buttons تظهر فقط في Memorizing phase
```

---

## CONTACT QUESTIONS

إذا واجهت أي من هذه المواقف — توقف وأسأل:

1. `MemorizationPlusRepository.evaluateAyah()` signature مختلفة عن المتوقع
2. `ArabicNormalizer.normalize()` لا تطبق كل الـ 7 normalization rules
3. `ReviewRecordCreatedByMode` enum في ملف مختلف عن المتوقع
4. `KidsJourneyStage.startAyah/endAyah` غير موجودة
5. `MemorizationProfile.childAge` تسبب breaking change في أكثر من 3 أماكن
6. أي تعديل يمس `MemorizationPlusRepositoryImpl` (51KB) — توقف فوراً
