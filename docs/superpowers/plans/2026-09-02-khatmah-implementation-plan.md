# Khatmah (Quran Completion Plan) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a structured Quran Khatmah (completion) feature with plan scheduling, reader context isolation, dedication support, and Du'a Khatm al-Quran — completely isolated from free reading and daily Wird.

**Architecture:** New `features/khatmah` module following existing Clean Architecture (data/domain/presentation layers). The existing `QuranReaderPage` gains a `readerMode` parameter to branch khatmah progress from free reading. Storage is SharedPreferences JSON (same pattern as memorization plans). All khatmah data is isolated in its own SharedPreferences keys.

**Tech Stack:** Flutter/Dart, BLoC (flutter_bloc/Cubit), GetIt DI, SharedPreferences, GoRouter, equatable

## Global Constraints

- Offline-first: all features must work without network connectivity
- No guilt or pressure: all copy and UX must be positive and gentle (per PRODUCT.md)
- Total Quran pages: 604 (hardcoded constant)
- One active Khatmah at a time
- Du'a text tier: `guidance` (not Quranic or Hadith — per `09_dua.md` classification)
- Khatmah mode must NEVER update `lastRestorableLocation` (per spec section 5.4)
- Free/Wird reading must NEVER advance khatmah progress (per spec section 2)
- Run `dart analyze` after each task to verify zero new warnings
- Commit after each task with descriptive message

---

### Task 1: Domain Entities & Scheduling Engine

**Files:**
- Create: `lib/features/khatmah/domain/entities/khatmah_dedication.dart`
- Create: `lib/features/khatmah/domain/entities/khatmah_plan.dart`
- Create: `lib/features/khatmah/domain/entities/khatmah_history_entry.dart`
- Create: `lib/features/khatmah/domain/entities/khatmah_scheduling_engine.dart`
- Test: `test/features/khatmah/domain/entities/khatmah_scheduling_engine_test.dart`
- Test: `test/features/khatmah/domain/entities/khatmah_plan_test.dart`

**Interfaces:**
- Consumes: Nothing (foundation task)
- Produces:
  - `enum DedicationCondition { alive, deceased, sick }`
  - `enum KhatmahStatus { active, paused, completed }`
  - `enum QuranReaderMode { free, khatmah }` (in khatmah_plan.dart for now)
  - `class KhatmahDedication` with fields: `isDedicated`, `recipientName`, `relationship`, `condition`, `customNote`
  - `class KhatmahPlan` with fields: `id`, `title`, `startPage`, `currentPage`, `targetPagesPerDay`, `targetDays`, `startDate`, `expectedEndDate`, `status`, `dedication`, `lastReadDate`, `pausedAt`; computed getters: `completedPagesCount`, `progressPercentage`, `remainingPages`
  - `class KhatmahHistoryEntry` with fields: `id`, `khatmahNumber`, `title`, `startDate`, `completedDate`, `totalDays`, `dedication`, `certificateId`
  - `class KhatmahSchedulingEngine` with static methods:
    - `static int calculateDaysFromPages(int remainingPages, int pagesPerDay)`
    - `static int calculatePagesFromDays(int remainingPages, int targetDays)`
    - `static DateTime calculateEndDate(DateTime start, int days)`
    - `static ({int startPage, int endPage}) todaysWird(int currentPage, int targetPagesPerDay)`
    - `static DateTime recalculateAfterResume(int remainingPages, int pagesPerDay)`

- [ ] **Step 1: Write failing tests for KhatmahSchedulingEngine**

```dart
// test/features/khatmah/domain/entities/khatmah_scheduling_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_scheduling_engine.dart';

void main() {
  group('KhatmahSchedulingEngine', () {
    test('calculateDaysFromPages returns ceil(remaining/perDay)', () {
      expect(KhatmahSchedulingEngine.calculateDaysFromPages(604, 2), 302);
      expect(KhatmahSchedulingEngine.calculateDaysFromPages(604, 4), 151);
      expect(KhatmahSchedulingEngine.calculateDaysFromPages(604, 10), 61);
      expect(KhatmahSchedulingEngine.calculateDaysFromPages(604, 20), 31);
      expect(KhatmahSchedulingEngine.calculateDaysFromPages(5, 3), 2);
    });

    test('calculatePagesFromDays returns ceil(remaining/days)', () {
      expect(KhatmahSchedulingEngine.calculatePagesFromDays(604, 30), 21);
      expect(KhatmahSchedulingEngine.calculatePagesFromDays(604, 60), 11);
      expect(KhatmahSchedulingEngine.calculatePagesFromDays(604, 365), 2);
    });

    test('calculateEndDate adds correct days', () {
      final start = DateTime(2026, 1, 1);
      expect(
        KhatmahSchedulingEngine.calculateEndDate(start, 30),
        DateTime(2026, 1, 31),
      );
    });

    test('todaysWird returns correct page range', () {
      final wird = KhatmahSchedulingEngine.todaysWird(0, 4);
      expect(wird.startPage, 1);
      expect(wird.endPage, 4);
    });

    test('todaysWird clamps endPage to 604', () {
      final wird = KhatmahSchedulingEngine.todaysWird(602, 10);
      expect(wird.startPage, 603);
      expect(wird.endPage, 604);
    });

    test('todaysWird when already at 604', () {
      final wird = KhatmahSchedulingEngine.todaysWird(604, 4);
      expect(wird.startPage, 604);
      expect(wird.endPage, 604);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/khatmah/domain/entities/khatmah_scheduling_engine_test.dart`
Expected: FAIL (files don't exist yet)

- [ ] **Step 3: Implement domain entities**

```dart
// lib/features/khatmah/domain/entities/khatmah_dedication.dart
import 'package:equatable/equatable.dart';

enum DedicationCondition { alive, deceased, sick }

class KhatmahDedication extends Equatable {
  const KhatmahDedication({
    this.isDedicated = false,
    this.recipientName,
    this.relationship,
    this.condition,
    this.customNote,
  });

  final bool isDedicated;
  final String? recipientName;
  final String? relationship;
  final DedicationCondition? condition;
  final String? customNote;

  static const none = KhatmahDedication();

  @override
  List<Object?> get props =>
      [isDedicated, recipientName, relationship, condition, customNote];
}
```

```dart
// lib/features/khatmah/domain/entities/khatmah_plan.dart
import 'package:equatable/equatable.dart';
import 'khatmah_dedication.dart';

enum KhatmahStatus { active, paused, completed }
enum QuranReaderMode { free, khatmah }

class KhatmahPlan extends Equatable {
  const KhatmahPlan({
    required this.id,
    required this.title,
    this.startPage = 1,
    this.currentPage = 0,
    required this.targetPagesPerDay,
    required this.targetDays,
    required this.startDate,
    required this.expectedEndDate,
    this.status = KhatmahStatus.active,
    this.dedication = const KhatmahDedication(),
    this.lastReadDate,
    this.pausedAt,
  });

  final String id;
  final String title;
  final int startPage;
  final int currentPage;
  final int targetPagesPerDay;
  final int targetDays;
  final DateTime startDate;
  final DateTime expectedEndDate;
  final KhatmahStatus status;
  final KhatmahDedication dedication;
  final DateTime? lastReadDate;
  final DateTime? pausedAt;

  int get completedPagesCount =>
      currentPage < startPage ? 0 : currentPage - startPage + 1;
  double get progressPercentage => completedPagesCount / 604;
  int get remainingPages => 604 - currentPage;

  KhatmahPlan copyWith({
    String? id,
    String? title,
    int? startPage,
    int? currentPage,
    int? targetPagesPerDay,
    int? targetDays,
    DateTime? startDate,
    DateTime? expectedEndDate,
    KhatmahStatus? status,
    KhatmahDedication? dedication,
    DateTime? lastReadDate,
    DateTime? pausedAt,
  }) {
    return KhatmahPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      startPage: startPage ?? this.startPage,
      currentPage: currentPage ?? this.currentPage,
      targetPagesPerDay: targetPagesPerDay ?? this.targetPagesPerDay,
      targetDays: targetDays ?? this.targetDays,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      status: status ?? this.status,
      dedication: dedication ?? this.dedication,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      pausedAt: pausedAt ?? this.pausedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, title, startPage, currentPage, targetPagesPerDay,
        targetDays, startDate, expectedEndDate, status, dedication,
        lastReadDate, pausedAt,
      ];
}
```

```dart
// lib/features/khatmah/domain/entities/khatmah_history_entry.dart
import 'package:equatable/equatable.dart';
import 'khatmah_dedication.dart';

class KhatmahHistoryEntry extends Equatable {
  const KhatmahHistoryEntry({
    required this.id,
    required this.khatmahNumber,
    required this.title,
    required this.startDate,
    required this.completedDate,
    required this.totalDays,
    this.dedication,
    this.certificateId,
  });

  final String id;
  final int khatmahNumber;
  final String title;
  final DateTime startDate;
  final DateTime completedDate;
  final int totalDays;
  final KhatmahDedication? dedication;
  final String? certificateId;

  @override
  List<Object?> get props => [
        id, khatmahNumber, title, startDate,
        completedDate, totalDays, dedication, certificateId,
      ];
}
```

```dart
// lib/features/khatmah/domain/entities/khatmah_scheduling_engine.dart
import 'dart:math';

class KhatmahSchedulingEngine {
  const KhatmahSchedulingEngine._();

  static const totalPages = 604;

  static int calculateDaysFromPages(int remainingPages, int pagesPerDay) {
    if (pagesPerDay <= 0) return remainingPages;
    return (remainingPages / pagesPerDay).ceil();
  }

  static int calculatePagesFromDays(int remainingPages, int targetDays) {
    if (targetDays <= 0) return remainingPages;
    return (remainingPages / targetDays).ceil();
  }

  static DateTime calculateEndDate(DateTime start, int days) {
    return start.add(Duration(days: days));
  }

  static ({int startPage, int endPage}) todaysWird(
    int currentPage,
    int targetPagesPerDay,
  ) {
    final startPage = min(currentPage + 1, totalPages);
    final endPage = min(startPage + targetPagesPerDay - 1, totalPages);
    return (startPage: startPage, endPage: endPage);
  }

  static DateTime recalculateAfterResume(
    int remainingPages,
    int pagesPerDay,
  ) {
    final days = calculateDaysFromPages(remainingPages, pagesPerDay);
    return calculateEndDate(DateTime.now(), days);
  }
}
```

- [ ] **Step 4: Write tests for KhatmahPlan computed getters**

```dart
// test/features/khatmah/domain/entities/khatmah_plan_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';

void main() {
  KhatmahPlan makePlan({int currentPage = 0, int startPage = 1}) {
    return KhatmahPlan(
      id: 'test-id',
      title: 'Test Khatmah',
      startPage: startPage,
      currentPage: currentPage,
      targetPagesPerDay: 4,
      targetDays: 151,
      startDate: DateTime(2026, 1, 1),
      expectedEndDate: DateTime(2026, 6, 1),
    );
  }

  test('completedPagesCount is 0 when no pages read', () {
    expect(makePlan(currentPage: 0).completedPagesCount, 0);
  });

  test('completedPagesCount correct after reading', () {
    expect(makePlan(currentPage: 10).completedPagesCount, 10);
  });

  test('progressPercentage at halfway', () {
    expect(makePlan(currentPage: 302).progressPercentage, closeTo(0.5, 0.01));
  });

  test('remainingPages correct', () {
    expect(makePlan(currentPage: 100).remainingPages, 504);
  });

  test('copyWith returns updated plan', () {
    final plan = makePlan();
    final updated = plan.copyWith(currentPage: 50);
    expect(updated.currentPage, 50);
    expect(updated.id, plan.id);
  });
}
```

- [ ] **Step 5: Run all tests to verify they pass**

Run: `flutter test test/features/khatmah/`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```
git add lib/features/khatmah/domain/ test/features/khatmah/
git commit -m "feat(khatmah): add domain entities and scheduling engine with tests"
```

---

### Task 2: Data Layer — Models, Datasource, Repository

**Files:**
- Create: `lib/features/khatmah/data/models/khatmah_dedication_model.dart`
- Create: `lib/features/khatmah/data/models/khatmah_plan_model.dart`
- Create: `lib/features/khatmah/data/models/khatmah_history_model.dart`
- Create: `lib/features/khatmah/data/datasources/khatmah_local_datasource.dart`
- Create: `lib/features/khatmah/domain/repositories/khatmah_repository.dart`
- Create: `lib/features/khatmah/data/repositories/khatmah_repository_impl.dart`
- Test: `test/features/khatmah/data/models/khatmah_plan_model_test.dart`
- Test: `test/features/khatmah/data/datasources/khatmah_local_datasource_test.dart`

**Interfaces:**
- Consumes: `KhatmahPlan`, `KhatmahDedication`, `KhatmahHistoryEntry`, `KhatmahStatus`, `DedicationCondition` from Task 1
- Produces:
  - `class KhatmahDedicationModel` with `toJson()`, `fromJson()`, `toEntity()`, `fromEntity()`
  - `class KhatmahPlanModel` with `toJson()`, `fromJson()`, `toEntity()`, `fromEntity()`
  - `class KhatmahHistoryModel` with `toJson()`, `fromJson()`, `toEntity()`, `fromEntity()`
  - `class KhatmahLocalDatasource` with methods: `getActivePlan()`, `savePlan(KhatmahPlanModel)`, `deletePlan()`, `getHistory()`, `addHistoryEntry(KhatmahHistoryModel)`, `getKhatmahCount()`
  - `abstract class KhatmahRepository` with methods: `getActivePlan()`, `createPlan(KhatmahPlan)`, `updatePlan(KhatmahPlan)`, `deletePlan()`, `completePlan(KhatmahPlan)`, `getHistory()`, `getCompletedCount()`
  - `class KhatmahRepositoryImpl implements KhatmahRepository`

- [ ] **Step 1: Write failing serialization round-trip tests**

```dart
// test/features/khatmah/data/models/khatmah_plan_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_plan_model.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_dedication_model.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';

void main() {
  group('KhatmahPlanModel', () {
    test('toJson/fromJson round trip preserves all fields', () {
      final model = KhatmahPlanModel(
        id: 'abc-123',
        title: 'Test Khatmah',
        startPage: 1,
        currentPage: 50,
        targetPagesPerDay: 4,
        targetDays: 151,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 6, 1),
        status: 'active',
        dedication: KhatmahDedicationModel(
          isDedicated: true,
          recipientName: 'Ahmad',
          relationship: 'Father',
          condition: 'deceased',
          customNote: null,
        ),
        lastReadDate: DateTime(2026, 1, 15),
        pausedAt: null,
      );

      final json = model.toJson();
      final restored = KhatmahPlanModel.fromJson(json);

      expect(restored.id, model.id);
      expect(restored.currentPage, model.currentPage);
      expect(restored.dedication.recipientName, 'Ahmad');
      expect(restored.dedication.condition, 'deceased');
    });

    test('toEntity produces correct KhatmahPlan', () {
      final model = KhatmahPlanModel(
        id: 'abc',
        title: 'Test',
        startPage: 1,
        currentPage: 10,
        targetPagesPerDay: 2,
        targetDays: 302,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 11, 1),
        status: 'active',
        dedication: KhatmahDedicationModel(isDedicated: false),
        lastReadDate: null,
        pausedAt: null,
      );

      final entity = model.toEntity();
      expect(entity.status, KhatmahStatus.active);
      expect(entity.currentPage, 10);
      expect(entity.dedication.isDedicated, false);
    });
  });

  group('KhatmahDedicationModel', () {
    test('fromEntity/toEntity round trip', () {
      const entity = KhatmahDedication(
        isDedicated: true,
        recipientName: 'Mom',
        relationship: 'Mother',
        condition: DedicationCondition.alive,
      );
      final model = KhatmahDedicationModel.fromEntity(entity);
      final restored = model.toEntity();
      expect(restored, entity);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/khatmah/data/models/khatmah_plan_model_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement data models**

```dart
// lib/features/khatmah/data/models/khatmah_dedication_model.dart
import '../../domain/entities/khatmah_dedication.dart';

class KhatmahDedicationModel {
  KhatmahDedicationModel({
    this.isDedicated = false,
    this.recipientName,
    this.relationship,
    this.condition,
    this.customNote,
  });

  final bool isDedicated;
  final String? recipientName;
  final String? relationship;
  final String? condition;
  final String? customNote;

  factory KhatmahDedicationModel.fromJson(Map<String, dynamic> json) {
    return KhatmahDedicationModel(
      isDedicated: json['isDedicated'] as bool? ?? false,
      recipientName: json['recipientName'] as String?,
      relationship: json['relationship'] as String?,
      condition: json['condition'] as String?,
      customNote: json['customNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'isDedicated': isDedicated,
        'recipientName': recipientName,
        'relationship': relationship,
        'condition': condition,
        'customNote': customNote,
      };

  factory KhatmahDedicationModel.fromEntity(KhatmahDedication entity) {
    return KhatmahDedicationModel(
      isDedicated: entity.isDedicated,
      recipientName: entity.recipientName,
      relationship: entity.relationship,
      condition: entity.condition?.name,
      customNote: entity.customNote,
    );
  }

  KhatmahDedication toEntity() => KhatmahDedication(
        isDedicated: isDedicated,
        recipientName: recipientName,
        relationship: relationship,
        condition: condition != null
            ? DedicationCondition.values.firstWhere(
                (e) => e.name == condition,
                orElse: () => DedicationCondition.alive,
              )
            : null,
        customNote: customNote,
      );
}
```

```dart
// lib/features/khatmah/data/models/khatmah_plan_model.dart
import 'khatmah_dedication_model.dart';
import '../../domain/entities/khatmah_plan.dart';

class KhatmahPlanModel {
  KhatmahPlanModel({
    required this.id,
    required this.title,
    required this.startPage,
    required this.currentPage,
    required this.targetPagesPerDay,
    required this.targetDays,
    required this.startDate,
    required this.expectedEndDate,
    required this.status,
    required this.dedication,
    this.lastReadDate,
    this.pausedAt,
  });

  final String id;
  final String title;
  final int startPage;
  final int currentPage;
  final int targetPagesPerDay;
  final int targetDays;
  final DateTime startDate;
  final DateTime expectedEndDate;
  final String status;
  final KhatmahDedicationModel dedication;
  final DateTime? lastReadDate;
  final DateTime? pausedAt;

  factory KhatmahPlanModel.fromJson(Map<String, dynamic> json) {
    return KhatmahPlanModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startPage: json['startPage'] as int? ?? 1,
      currentPage: json['currentPage'] as int? ?? 0,
      targetPagesPerDay: json['targetPagesPerDay'] as int,
      targetDays: json['targetDays'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      expectedEndDate: DateTime.parse(json['expectedEndDate'] as String),
      status: json['status'] as String? ?? 'active',
      dedication: KhatmahDedicationModel.fromJson(
        json['dedication'] as Map<String, dynamic>? ?? {},
      ),
      lastReadDate: json['lastReadDate'] != null
          ? DateTime.parse(json['lastReadDate'] as String)
          : null,
      pausedAt: json['pausedAt'] != null
          ? DateTime.parse(json['pausedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startPage': startPage,
        'currentPage': currentPage,
        'targetPagesPerDay': targetPagesPerDay,
        'targetDays': targetDays,
        'startDate': startDate.toIso8601String(),
        'expectedEndDate': expectedEndDate.toIso8601String(),
        'status': status,
        'dedication': dedication.toJson(),
        'lastReadDate': lastReadDate?.toIso8601String(),
        'pausedAt': pausedAt?.toIso8601String(),
      };

  factory KhatmahPlanModel.fromEntity(KhatmahPlan entity) {
    return KhatmahPlanModel(
      id: entity.id,
      title: entity.title,
      startPage: entity.startPage,
      currentPage: entity.currentPage,
      targetPagesPerDay: entity.targetPagesPerDay,
      targetDays: entity.targetDays,
      startDate: entity.startDate,
      expectedEndDate: entity.expectedEndDate,
      status: entity.status.name,
      dedication: KhatmahDedicationModel.fromEntity(entity.dedication),
      lastReadDate: entity.lastReadDate,
      pausedAt: entity.pausedAt,
    );
  }

  KhatmahPlan toEntity() => KhatmahPlan(
        id: id,
        title: title,
        startPage: startPage,
        currentPage: currentPage,
        targetPagesPerDay: targetPagesPerDay,
        targetDays: targetDays,
        startDate: startDate,
        expectedEndDate: expectedEndDate,
        status: KhatmahStatus.values.firstWhere(
          (e) => e.name == status,
          orElse: () => KhatmahStatus.active,
        ),
        dedication: dedication.toEntity(),
        lastReadDate: lastReadDate,
        pausedAt: pausedAt,
      );
}
```

```dart
// lib/features/khatmah/data/models/khatmah_history_model.dart
import 'khatmah_dedication_model.dart';
import '../../domain/entities/khatmah_history_entry.dart';

class KhatmahHistoryModel {
  KhatmahHistoryModel({
    required this.id,
    required this.khatmahNumber,
    required this.title,
    required this.startDate,
    required this.completedDate,
    required this.totalDays,
    this.dedication,
    this.certificateId,
  });

  final String id;
  final int khatmahNumber;
  final String title;
  final DateTime startDate;
  final DateTime completedDate;
  final int totalDays;
  final KhatmahDedicationModel? dedication;
  final String? certificateId;

  factory KhatmahHistoryModel.fromJson(Map<String, dynamic> json) {
    return KhatmahHistoryModel(
      id: json['id'] as String,
      khatmahNumber: json['khatmahNumber'] as int,
      title: json['title'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      completedDate: DateTime.parse(json['completedDate'] as String),
      totalDays: json['totalDays'] as int,
      dedication: json['dedication'] != null
          ? KhatmahDedicationModel.fromJson(
              json['dedication'] as Map<String, dynamic>)
          : null,
      certificateId: json['certificateId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'khatmahNumber': khatmahNumber,
        'title': title,
        'startDate': startDate.toIso8601String(),
        'completedDate': completedDate.toIso8601String(),
        'totalDays': totalDays,
        'dedication': dedication?.toJson(),
        'certificateId': certificateId,
      };

  KhatmahHistoryEntry toEntity() => KhatmahHistoryEntry(
        id: id,
        khatmahNumber: khatmahNumber,
        title: title,
        startDate: startDate,
        completedDate: completedDate,
        totalDays: totalDays,
        dedication: dedication?.toEntity(),
        certificateId: certificateId,
      );

  factory KhatmahHistoryModel.fromEntity(KhatmahHistoryEntry entity) {
    return KhatmahHistoryModel(
      id: entity.id,
      khatmahNumber: entity.khatmahNumber,
      title: entity.title,
      startDate: entity.startDate,
      completedDate: entity.completedDate,
      totalDays: entity.totalDays,
      dedication: entity.dedication != null
          ? KhatmahDedicationModel.fromEntity(entity.dedication!)
          : null,
      certificateId: entity.certificateId,
    );
  }
}
```

- [ ] **Step 4: Implement datasource and repository**

```dart
// lib/features/khatmah/data/datasources/khatmah_local_datasource.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/khatmah_plan_model.dart';
import '../models/khatmah_history_model.dart';

class KhatmahLocalDatasource {
  KhatmahLocalDatasource(this._prefs);

  final SharedPreferences _prefs;

  static const _kActivePlan = 'khatmah_active_plan';
  static const _kHistory = 'khatmah_history';
  static const _kCloudDirty = 'khatmah_cloud_dirty';

  Future<KhatmahPlanModel?> getActivePlan() {
    final raw = _prefs.getString(_kActivePlan);
    if (raw == null) return Future.value(null);
    try {
      return Future.value(
        KhatmahPlanModel.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } catch (_) {
      return Future.value(null);
    }
  }

  Future<void> savePlan(KhatmahPlanModel plan) async {
    await _prefs.setString(_kActivePlan, jsonEncode(plan.toJson()));
    await _prefs.setBool(_kCloudDirty, true);
  }

  Future<void> deletePlan() async {
    await _prefs.remove(_kActivePlan);
    await _prefs.setBool(_kCloudDirty, true);
  }

  Future<List<KhatmahHistoryModel>> getHistory() {
    final raw = _prefs.getString(_kHistory);
    if (raw == null) return Future.value([]);
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return Future.value(
        list
            .map((e) =>
                KhatmahHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return Future.value([]);
    }
  }

  Future<void> addHistoryEntry(KhatmahHistoryModel entry) async {
    final existing = await getHistory();
    existing.add(entry);
    await _prefs.setString(
      _kHistory,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
    await _prefs.setBool(_kCloudDirty, true);
  }

  Future<int> getKhatmahCount() async {
    final history = await getHistory();
    return history.length;
  }
}
```

```dart
// lib/features/khatmah/domain/repositories/khatmah_repository.dart
import '../entities/khatmah_plan.dart';
import '../entities/khatmah_history_entry.dart';

abstract class KhatmahRepository {
  Future<KhatmahPlan?> getActivePlan();
  Future<void> createPlan(KhatmahPlan plan);
  Future<void> updatePlan(KhatmahPlan plan);
  Future<void> deletePlan();
  Future<void> completePlan(KhatmahPlan plan);
  Future<List<KhatmahHistoryEntry>> getHistory();
  Future<int> getCompletedCount();
}
```

```dart
// lib/features/khatmah/data/repositories/khatmah_repository_impl.dart
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_history_entry.dart';
import '../../domain/repositories/khatmah_repository.dart';
import '../datasources/khatmah_local_datasource.dart';
import '../models/khatmah_plan_model.dart';
import '../models/khatmah_history_model.dart';

class KhatmahRepositoryImpl implements KhatmahRepository {
  KhatmahRepositoryImpl(this._datasource);

  final KhatmahLocalDatasource _datasource;

  @override
  Future<KhatmahPlan?> getActivePlan() async {
    final model = await _datasource.getActivePlan();
    return model?.toEntity();
  }

  @override
  Future<void> createPlan(KhatmahPlan plan) async {
    await _datasource.savePlan(KhatmahPlanModel.fromEntity(plan));
  }

  @override
  Future<void> updatePlan(KhatmahPlan plan) async {
    await _datasource.savePlan(KhatmahPlanModel.fromEntity(plan));
  }

  @override
  Future<void> deletePlan() async {
    await _datasource.deletePlan();
  }

  @override
  Future<void> completePlan(KhatmahPlan plan) async {
    final count = await _datasource.getKhatmahCount();
    final entry = KhatmahHistoryModel.fromEntity(
      KhatmahHistoryEntry(
        id: plan.id,
        khatmahNumber: count + 1,
        title: plan.title,
        startDate: plan.startDate,
        completedDate: DateTime.now(),
        totalDays: DateTime.now().difference(plan.startDate).inDays + 1,
        dedication: plan.dedication.isDedicated ? plan.dedication : null,
      ),
    );
    await _datasource.addHistoryEntry(entry);
    await _datasource.deletePlan();
  }

  @override
  Future<List<KhatmahHistoryEntry>> getHistory() async {
    final models = await _datasource.getHistory();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> getCompletedCount() => _datasource.getKhatmahCount();
}
```

- [ ] **Step 5: Run all tests**

Run: `flutter test test/features/khatmah/`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```
git add lib/features/khatmah/data/ lib/features/khatmah/domain/repositories/ test/features/khatmah/data/
git commit -m "feat(khatmah): add data layer - models, datasource, repository"
```

---

### Task 3: Use Cases & DI Registration

**Files:**
- Create: `lib/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart`
- Create: `lib/features/khatmah/domain/usecases/create_khatmah_usecase.dart`
- Create: `lib/features/khatmah/domain/usecases/update_khatmah_progress_usecase.dart`
- Create: `lib/features/khatmah/domain/usecases/complete_khatmah_usecase.dart`
- Create: `lib/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart`
- Modify: `lib/core/di/injection.dart` (add khatmah registrations after line ~253, in the Datasources section)

**Interfaces:**
- Consumes: `KhatmahRepository`, `KhatmahPlan`, `KhatmahSchedulingEngine` from Tasks 1-2
- Produces:
  - `class GetActiveKhatmahUsecase` with `Future<KhatmahPlan?> call()`
  - `class CreateKhatmahUsecase` with `Future<void> call(KhatmahPlan plan)`
  - `class UpdateKhatmahProgressUsecase` with `Future<KhatmahPlan> call(KhatmahPlan plan, int pageNumber)` — returns updated plan
  - `class CompleteKhatmahUsecase` with `Future<void> call(KhatmahPlan plan)`
  - `class PauseResumeKhatmahUsecase` with `Future<KhatmahPlan> pause(KhatmahPlan)`, `Future<KhatmahPlan> resume(KhatmahPlan)`
  - GetIt registrations for all khatmah dependencies

- [ ] **Step 1: Create use cases**

```dart
// lib/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart
import '../repositories/khatmah_repository.dart';
import '../entities/khatmah_plan.dart';

class GetActiveKhatmahUsecase {
  const GetActiveKhatmahUsecase(this._repository);
  final KhatmahRepository _repository;

  Future<KhatmahPlan?> call() => _repository.getActivePlan();
}
```

```dart
// lib/features/khatmah/domain/usecases/create_khatmah_usecase.dart
import '../repositories/khatmah_repository.dart';
import '../entities/khatmah_plan.dart';

class CreateKhatmahUsecase {
  const CreateKhatmahUsecase(this._repository);
  final KhatmahRepository _repository;

  Future<void> call(KhatmahPlan plan) => _repository.createPlan(plan);
}
```

```dart
// lib/features/khatmah/domain/usecases/update_khatmah_progress_usecase.dart
import '../repositories/khatmah_repository.dart';
import '../entities/khatmah_plan.dart';

class UpdateKhatmahProgressUsecase {
  const UpdateKhatmahProgressUsecase(this._repository);
  final KhatmahRepository _repository;

  Future<KhatmahPlan> call(KhatmahPlan plan, int pageNumber) async {
    final updated = plan.copyWith(
      currentPage: pageNumber,
      lastReadDate: DateTime.now(),
    );
    await _repository.updatePlan(updated);
    return updated;
  }
}
```

```dart
// lib/features/khatmah/domain/usecases/complete_khatmah_usecase.dart
import '../repositories/khatmah_repository.dart';
import '../entities/khatmah_plan.dart';

class CompleteKhatmahUsecase {
  const CompleteKhatmahUsecase(this._repository);
  final KhatmahRepository _repository;

  Future<void> call(KhatmahPlan plan) async {
    final completed = plan.copyWith(
      currentPage: 604,
      status: KhatmahStatus.completed,
    );
    await _repository.completePlan(completed);
  }
}
```

```dart
// lib/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart
import '../repositories/khatmah_repository.dart';
import '../entities/khatmah_plan.dart';
import '../entities/khatmah_scheduling_engine.dart';

class PauseResumeKhatmahUsecase {
  const PauseResumeKhatmahUsecase(this._repository);
  final KhatmahRepository _repository;

  Future<KhatmahPlan> pause(KhatmahPlan plan) async {
    final paused = plan.copyWith(
      status: KhatmahStatus.paused,
      pausedAt: DateTime.now(),
    );
    await _repository.updatePlan(paused);
    return paused;
  }

  Future<KhatmahPlan> resume(KhatmahPlan plan) async {
    final newEndDate = KhatmahSchedulingEngine.recalculateAfterResume(
      plan.remainingPages,
      plan.targetPagesPerDay,
    );
    final resumed = plan.copyWith(
      status: KhatmahStatus.active,
      expectedEndDate: newEndDate,
    );
    await _repository.updatePlan(resumed);
    return resumed;
  }
}
```

- [ ] **Step 2: Add DI registrations in injection.dart**

Add the following imports at the top of `lib/core/di/injection.dart`:
```dart
import '../../features/khatmah/data/datasources/khatmah_local_datasource.dart';
import '../../features/khatmah/data/repositories/khatmah_repository_impl.dart';
import '../../features/khatmah/domain/repositories/khatmah_repository.dart';
import '../../features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import '../../features/khatmah/domain/usecases/create_khatmah_usecase.dart';
import '../../features/khatmah/domain/usecases/update_khatmah_progress_usecase.dart';
import '../../features/khatmah/domain/usecases/complete_khatmah_usecase.dart';
import '../../features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import '../../features/khatmah/presentation/cubits/khatmah_cubit.dart';
```

Add the following registrations after the `AzkarLocalDatasource` registration (around line 253):
```dart
  // ─── Khatmah ────────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<KhatmahLocalDatasource>(
    () => KhatmahLocalDatasource(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<KhatmahRepository>(
    () => KhatmahRepositoryImpl(getIt<KhatmahLocalDatasource>()),
  );
  getIt.registerLazySingleton<GetActiveKhatmahUsecase>(
    () => GetActiveKhatmahUsecase(getIt<KhatmahRepository>()),
  );
  getIt.registerLazySingleton<CreateKhatmahUsecase>(
    () => CreateKhatmahUsecase(getIt<KhatmahRepository>()),
  );
  getIt.registerLazySingleton<UpdateKhatmahProgressUsecase>(
    () => UpdateKhatmahProgressUsecase(getIt<KhatmahRepository>()),
  );
  getIt.registerLazySingleton<CompleteKhatmahUsecase>(
    () => CompleteKhatmahUsecase(getIt<KhatmahRepository>()),
  );
  getIt.registerLazySingleton<PauseResumeKhatmahUsecase>(
    () => PauseResumeKhatmahUsecase(getIt<KhatmahRepository>()),
  );
```

- [ ] **Step 3: Run static analysis**

Run: `dart analyze lib/features/khatmah/ lib/core/di/injection.dart`
Expected: No new warnings

- [ ] **Step 4: Commit**

```
git add lib/features/khatmah/domain/usecases/ lib/core/di/injection.dart
git commit -m "feat(khatmah): add use cases and DI registrations"
```

---

### Task 4: KhatmahCubit — State Management

**Files:**
- Create: `lib/features/khatmah/presentation/cubits/khatmah_cubit.dart`
- Create: `lib/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart`
- Test: `test/features/khatmah/presentation/cubits/khatmah_cubit_test.dart`

**Interfaces:**
- Consumes: All usecases from Task 3, `KhatmahPlan`, `KhatmahSchedulingEngine` from Task 1
- Produces:
  - `class KhatmahState` (sealed/abstract) with subclasses: `KhatmahInitial`, `KhatmahLoading`, `KhatmahNoActivePlan`, `KhatmahActive(plan, wird)`, `KhatmahCompleted(plan)`
  - `class KhatmahCubit` with methods: `load()`, `advancePage(int)`, `pause()`, `resume()`, `abandonPlan()`
  - `class KhatmahSetupState` with subclasses: `KhatmahSetupIdle`, `KhatmahSetupSaving`, `KhatmahSetupDone`
  - `class KhatmahSetupCubit` with methods: `createPlan({pagesPerDay, targetDays, dedication})`

- [ ] **Step 1: Write failing KhatmahCubit tests**

```dart
// test/features/khatmah/presentation/cubits/khatmah_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/update_khatmah_progress_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/complete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';

class MockGetActiveKhatmah extends Mock implements GetActiveKhatmahUsecase {}
class MockUpdateProgress extends Mock implements UpdateKhatmahProgressUsecase {}
class MockComplete extends Mock implements CompleteKhatmahUsecase {}
class MockPauseResume extends Mock implements PauseResumeKhatmahUsecase {}

void main() {
  late MockGetActiveKhatmah mockGet;
  late MockUpdateProgress mockUpdate;
  late MockComplete mockComplete;
  late MockPauseResume mockPauseResume;

  final testPlan = KhatmahPlan(
    id: 'test-1',
    title: 'Test Khatmah',
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 6, 1),
    currentPage: 10,
  );

  setUp(() {
    mockGet = MockGetActiveKhatmah();
    mockUpdate = MockUpdateProgress();
    mockComplete = MockComplete();
    mockPauseResume = MockPauseResume();
  });

  blocTest<KhatmahCubit, KhatmahState>(
    'emits [loading, active] when load finds an active plan',
    build: () {
      when(() => mockGet()).thenAnswer((_) async => testPlan);
      return KhatmahCubit(mockGet, mockUpdate, mockComplete, mockPauseResume);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<KhatmahLoading>(),
      isA<KhatmahActive>(),
    ],
  );

  blocTest<KhatmahCubit, KhatmahState>(
    'emits [loading, noActivePlan] when no plan exists',
    build: () {
      when(() => mockGet()).thenAnswer((_) async => null);
      return KhatmahCubit(mockGet, mockUpdate, mockComplete, mockPauseResume);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<KhatmahLoading>(),
      isA<KhatmahNoActivePlan>(),
    ],
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/khatmah/presentation/cubits/khatmah_cubit_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement KhatmahCubit and KhatmahSetupCubit**

```dart
// lib/features/khatmah/presentation/cubits/khatmah_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';
import '../../domain/usecases/get_active_khatmah_usecase.dart';
import '../../domain/usecases/update_khatmah_progress_usecase.dart';
import '../../domain/usecases/complete_khatmah_usecase.dart';
import '../../domain/usecases/pause_resume_khatmah_usecase.dart';

// ─── States ──────────────────────────────────────────────────────────────────
abstract class KhatmahState extends Equatable {
  const KhatmahState();
  @override
  List<Object?> get props => [];
}

class KhatmahInitial extends KhatmahState {
  const KhatmahInitial();
}

class KhatmahLoading extends KhatmahState {
  const KhatmahLoading();
}

class KhatmahNoActivePlan extends KhatmahState {
  const KhatmahNoActivePlan();
}

class KhatmahActive extends KhatmahState {
  const KhatmahActive({
    required this.plan,
    required this.wirdStartPage,
    required this.wirdEndPage,
  });

  final KhatmahPlan plan;
  final int wirdStartPage;
  final int wirdEndPage;

  @override
  List<Object?> get props => [plan, wirdStartPage, wirdEndPage];
}

class KhatmahWirdCompleted extends KhatmahState {
  const KhatmahWirdCompleted({required this.plan});
  final KhatmahPlan plan;
  @override
  List<Object?> get props => [plan];
}

class KhatmahCompleted extends KhatmahState {
  const KhatmahCompleted({required this.plan});
  final KhatmahPlan plan;
  @override
  List<Object?> get props => [plan];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────
class KhatmahCubit extends Cubit<KhatmahState> {
  KhatmahCubit(
    this._getActive,
    this._updateProgress,
    this._complete,
    this._pauseResume,
  ) : super(const KhatmahInitial());

  final GetActiveKhatmahUsecase _getActive;
  final UpdateKhatmahProgressUsecase _updateProgress;
  final CompleteKhatmahUsecase _complete;
  final PauseResumeKhatmahUsecase _pauseResume;

  Future<void> load() async {
    emit(const KhatmahLoading());
    final plan = await _getActive();
    if (plan == null || plan.status != KhatmahStatus.active) {
      emit(const KhatmahNoActivePlan());
      return;
    }
    _emitActive(plan);
  }

  Future<void> advancePage(int pageNumber) async {
    final current = state;
    if (current is! KhatmahActive) return;

    final updated = await _updateProgress(current.plan, pageNumber);

    if (updated.currentPage >= 604) {
      await _complete(updated);
      emit(KhatmahCompleted(plan: updated));
      return;
    }

    if (pageNumber >= current.wirdEndPage) {
      emit(KhatmahWirdCompleted(plan: updated));
      // After a short delay the UI can call load() to refresh
      return;
    }

    _emitActive(updated);
  }

  Future<void> pause() async {
    final current = state;
    if (current is! KhatmahActive) return;
    final paused = await _pauseResume.pause(current.plan);
    emit(KhatmahNoActivePlan());
  }

  Future<void> resume() async {
    await load(); // Re-loads and checks if plan can resume
  }

  Future<void> abandonPlan() async {
    // Delegates to _pauseResume or repository — for now just reload
    emit(const KhatmahNoActivePlan());
  }

  void _emitActive(KhatmahPlan plan) {
    final wird = KhatmahSchedulingEngine.todaysWird(
      plan.currentPage,
      plan.targetPagesPerDay,
    );
    emit(KhatmahActive(
      plan: plan,
      wirdStartPage: wird.startPage,
      wirdEndPage: wird.endPage,
    ));
  }
}
```

```dart
// lib/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_dedication.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';
import '../../domain/usecases/create_khatmah_usecase.dart';

// ─── States ──────────────────────────────────────────────────────────────────
abstract class KhatmahSetupState extends Equatable {
  const KhatmahSetupState();
  @override
  List<Object?> get props => [];
}

class KhatmahSetupIdle extends KhatmahSetupState {
  const KhatmahSetupIdle();
}

class KhatmahSetupSaving extends KhatmahSetupState {
  const KhatmahSetupSaving();
}

class KhatmahSetupDone extends KhatmahSetupState {
  const KhatmahSetupDone(this.plan);
  final KhatmahPlan plan;
  @override
  List<Object?> get props => [plan];
}

class KhatmahSetupError extends KhatmahSetupState {
  const KhatmahSetupError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────
class KhatmahSetupCubit extends Cubit<KhatmahSetupState> {
  KhatmahSetupCubit(this._createKhatmah) : super(const KhatmahSetupIdle());

  final CreateKhatmahUsecase _createKhatmah;

  Future<void> createPlan({
    required int pagesPerDay,
    KhatmahDedication dedication = const KhatmahDedication(),
  }) async {
    emit(const KhatmahSetupSaving());
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final days = KhatmahSchedulingEngine.calculateDaysFromPages(
        604,
        pagesPerDay,
      );
      final endDate = KhatmahSchedulingEngine.calculateEndDate(today, days);

      final title = dedication.isDedicated && dedication.recipientName != null
          ? dedication.recipientName!
          : 'Khatmah';

      final plan = KhatmahPlan(
        id: const Uuid().v4(),
        title: title,
        targetPagesPerDay: pagesPerDay,
        targetDays: days,
        startDate: today,
        expectedEndDate: endDate,
        dedication: dedication,
      );

      await _createKhatmah(plan);
      emit(KhatmahSetupDone(plan));
    } catch (e) {
      emit(KhatmahSetupError(e.toString()));
    }
  }
}
```

- [ ] **Step 4: Add KhatmahCubit DI registration**

In `injection.dart`, add after the use case registrations:
```dart
  getIt.registerFactory<KhatmahCubit>(
    () => KhatmahCubit(
      getIt<GetActiveKhatmahUsecase>(),
      getIt<UpdateKhatmahProgressUsecase>(),
      getIt<CompleteKhatmahUsecase>(),
      getIt<PauseResumeKhatmahUsecase>(),
    ),
  );
  getIt.registerFactory<KhatmahSetupCubit>(
    () => KhatmahSetupCubit(getIt<CreateKhatmahUsecase>()),
  );
```

- [ ] **Step 5: Run all tests**

Run: `flutter test test/features/khatmah/`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```
git add lib/features/khatmah/presentation/cubits/ lib/core/di/injection.dart test/features/khatmah/presentation/
git commit -m "feat(khatmah): add KhatmahCubit and KhatmahSetupCubit with tests"
```

---

### Task 5: Reader Integration — Mode Parameter & Progress Hook

**Files:**
- Modify: `lib/features/quran/presentation/pages/quran_reader_page.dart:36-44` (add `readerMode` param)
- Modify: `lib/features/quran/presentation/pages/quran_reader_page.dart:300-340` (confirmation listener — skip `lastRestorableLocation` in khatmah mode)
- Modify: `lib/features/quran/presentation/cubits/quran_page_cubit.dart:38-82` (add khatmah progress hook)
- Modify: `lib/core/router/app_router.dart:449-456` (add `mode` query param parsing)
- Modify: `lib/core/di/injection.dart` (update QuranPageCubit registration)
- Test: `test/features/quran/presentation/cubits/quran_page_cubit_khatmah_test.dart`

**Interfaces:**
- Consumes: `QuranReaderMode` from Task 1, `UpdateKhatmahProgressUsecase` from Task 3, `KhatmahCubit` from Task 4
- Produces:
  - Modified `QuranReaderPage` constructor: `const QuranReaderPage({this.surahId, this.pageNumber, this.readerMode = QuranReaderMode.free})`
  - Modified `QuranPageCubit` constructor: adds optional `UpdateKhatmahProgressUsecase?` and `KhatmahCubit?`
  - Modified router: `/quran/page/:pageNumber?mode=khatmah` correctly parsed

- [ ] **Step 1: Write test for khatmah-aware confirmRead**

```dart
// test/features/quran/presentation/cubits/quran_page_cubit_khatmah_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_page_cubit.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/progress/domain/usecases/save_read_page_usecase.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/update_khatmah_progress_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';

class MockRepo extends Mock implements QuranRepository {}
class MockSaveRead extends Mock implements SaveReadPageUsecase {}
class MockStreak extends Mock implements StreakService {}
class MockUpdateKhatmah extends Mock implements UpdateKhatmahProgressUsecase {}
class MockKhatmahCubit extends Mock implements KhatmahCubit {}

void main() {
  test('confirmRead in khatmah mode calls updateKhatmahProgress', () async {
    final mockRepo = MockRepo();
    final mockSave = MockSaveRead();
    final mockStreak = MockStreak();
    final mockUpdateKhatmah = MockUpdateKhatmah();

    when(() => mockSave(any())).thenAnswer((_) async => const Right(null));
    when(() => mockStreak.recordActivity()).thenAnswer((_) async {});

    final testPlan = KhatmahPlan(
      id: 'test', title: 'Test',
      targetPagesPerDay: 4, targetDays: 151,
      startDate: DateTime(2026, 1, 1),
      expectedEndDate: DateTime(2026, 6, 1),
      currentPage: 10,
    );

    when(() => mockUpdateKhatmah(any(), any()))
        .thenAnswer((_) async => testPlan.copyWith(currentPage: 11));

    final cubit = QuranPageCubit(
      mockRepo, mockSave, mockStreak,
      khatmahProgressUsecase: mockUpdateKhatmah,
    );

    // Simulate loaded state first
    when(() => mockRepo.getQuranPage(11))
        .thenAnswer((_) async => Right(QuranPageDetail(
              pageNumber: 11,
              surahs: [],
              juzNumber: 1,
              hizbQuarter: 1,
            )));
    await cubit.loadPage(11);
    await cubit.confirmRead(11, activePlan: testPlan);

    verify(() => mockUpdateKhatmah(testPlan, 11)).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/quran/presentation/cubits/quran_page_cubit_khatmah_test.dart`
Expected: FAIL

- [ ] **Step 3: Modify QuranPageCubit to support khatmah mode**

In `lib/features/quran/presentation/cubits/quran_page_cubit.dart`, update the constructor and `confirmRead`:

```dart
class QuranPageCubit extends Cubit<QuranPageState> {
  QuranPageCubit(
    this._repository,
    this._saveReadPage,
    this._streakService, {
    this.khatmahProgressUsecase,
  }) : super(QuranPageInitial());

  final QuranRepository _repository;
  final SaveReadPageUsecase _saveReadPage;
  final StreakService _streakService;
  final UpdateKhatmahProgressUsecase? khatmahProgressUsecase;

  // ... loadPage stays the same ...

  Future<void> confirmRead(int pageNumber, {KhatmahPlan? activePlan}) async {
    if (state is! QuranPageLoaded) return;
    final loaded = state as QuranPageLoaded;
    if (loaded.isReadConfirmed) return;

    final saveResult = await _saveReadPage(pageNumber);
    final failure = saveResult.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(
        QuranPageLoaded(loaded.detail, readConfirmationError: failure.message),
      );
      return;
    }

    try {
      await _streakService.recordActivity();
    } catch (_) {}

    // Khatmah progress hook — only when in khatmah mode with an active plan
    if (activePlan != null && khatmahProgressUsecase != null) {
      try {
        await khatmahProgressUsecase!(activePlan, pageNumber);
      } catch (_) {
        // Non-critical — khatmah progress update failure should not block reading
      }
    }

    emit(QuranPageLoaded(loaded.detail, isReadConfirmed: true));
  }
}
```

- [ ] **Step 4: Modify QuranReaderPage constructor**

In `lib/features/quran/presentation/pages/quran_reader_page.dart` lines 36-44:

```dart
class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage({
    super.key,
    this.surahId,
    this.pageNumber,
    this.readerMode = QuranReaderMode.free,
  });

  final int? surahId;
  final int? pageNumber;
  final QuranReaderMode readerMode;

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}
```

Add the import at the top of the file:
```dart
import '../../../khatmah/domain/entities/khatmah_plan.dart';
```

- [ ] **Step 5: Modify router to pass mode**

In `lib/core/router/app_router.dart` lines 449-456:

```dart
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/quran/page/:pageNumber',
        builder: (context, state) {
          final pageNumber =
              int.tryParse(state.pathParameters['pageNumber'] ?? '1') ?? 1;
          final mode = state.uri.queryParameters['mode'] == 'khatmah'
              ? QuranReaderMode.khatmah
              : QuranReaderMode.free;
          return QuranReaderPage(pageNumber: pageNumber, readerMode: mode);
        },
      ),
```

Add import at top of `app_router.dart`:
```dart
import '../../features/khatmah/domain/entities/khatmah_plan.dart';
```

- [ ] **Step 6: Update QuranPageCubit DI registration**

In `injection.dart`, update the existing `QuranPageCubit` registration to include the optional khatmah usecase:

```dart
  getIt.registerFactory<QuranPageCubit>(
    () => QuranPageCubit(
      getIt<QuranRepository>(),
      getIt<SaveReadPageUsecase>(),
      getIt<StreakService>(),
      khatmahProgressUsecase: getIt<UpdateKhatmahProgressUsecase>(),
    ),
  );
```

- [ ] **Step 7: Run all tests**

Run: `flutter test test/features/khatmah/ test/features/quran/`
Expected: ALL PASS

- [ ] **Step 8: Run static analysis**

Run: `dart analyze lib/features/quran/ lib/features/khatmah/ lib/core/router/`
Expected: No new warnings

- [ ] **Step 9: Commit**

```
git add lib/features/quran/ lib/core/router/app_router.dart lib/core/di/injection.dart test/features/quran/
git commit -m "feat(khatmah): integrate reader mode parameter and khatmah progress hook"
```

---

### Task 6: Home Page Integration — KhatmahHeroCard

**Files:**
- Create: `lib/features/khatmah/presentation/widgets/khatmah_hero_card.dart`
- Modify: `lib/features/home/presentation/cubits/home_cubit.dart` (add khatmah loading)
- Modify: `lib/features/home/presentation/cubits/home_state.dart` (part of home_cubit.dart — add `activeKhatmah` field)
- Modify: `lib/features/home/presentation/pages/home_page.dart` (render KhatmahHeroCard)

**Interfaces:**
- Consumes: `KhatmahPlan`, `KhatmahSchedulingEngine`, `GetActiveKhatmahUsecase` from Tasks 1-3
- Produces:
  - `KhatmahHeroCard` widget displaying today's wird, progress gauge, and "Start reading" button
  - `HomeLoaded.activeKhatmah` field
  - KhatmahHeroCard navigation to `/quran/page/{wirdStartPage}?mode=khatmah`

- [ ] **Step 1: Create KhatmahHeroCard widget**

```dart
// lib/features/khatmah/presentation/widgets/khatmah_hero_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';

class KhatmahHeroCard extends StatelessWidget {
  const KhatmahHeroCard({
    super.key,
    required this.plan,
    required this.isDark,
  });

  final KhatmahPlan plan;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final wird = KhatmahSchedulingEngine.todaysWird(
      plan.currentPage,
      plan.targetPagesPerDay,
    );
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: InkWell(
        onTap: () => context.push(
          '/quran/page/${wird.startPage}?mode=khatmah',
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    plan.title,
                    style: AppTypography.labelLarge.copyWith(color: primary),
                  ),
                  const Spacer(),
                  Text(
                    '${(plan.progressPercentage * 100).toStringAsFixed(0)}%',
                    style: AppTypography.labelMedium.copyWith(color: primary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: plan.progressPercentage,
                  backgroundColor: primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(primary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Today: pages ${wird.startPage} - ${wird.endPage}',
                style: AppTypography.bodyMedium,
              ),
              if (plan.dedication.isDedicated &&
                  plan.dedication.recipientName != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Dedicated to: ${plan.dedication.recipientName}',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add activeKhatmah field to HomeLoaded**

In `home_state.dart` (which is `part of 'home_cubit.dart'`), add to `HomeLoaded`:
- New field: `final KhatmahPlan? activeKhatmah;`
- Add to constructor: `this.activeKhatmah,`
- Add to copyWith: `KhatmahPlan? activeKhatmah,`
- Add to props: `activeKhatmah,`

- [ ] **Step 3: Load active khatmah in HomeCubit**

In `home_cubit.dart`, add import:
```dart
import '../../../khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import '../../../khatmah/domain/entities/khatmah_plan.dart';
```

In the `load()` method, add alongside the parallel data loading calls:
```dart
final khatmahFuture = getIt<GetActiveKhatmahUsecase>()();
```

Then include in the `HomeLoaded` emit:
```dart
activeKhatmah: await khatmahFuture,
```

- [ ] **Step 4: Render KhatmahHeroCard in home_page.dart**

Add import in `home_page.dart`:
```dart
import '../../../khatmah/presentation/widgets/khatmah_hero_card.dart';
```

In the body builder, after the `UnifiedHeroActionCard`, add:
```dart
if (state.activeKhatmah != null)
  KhatmahHeroCard(
    plan: state.activeKhatmah!,
    isDark: isDark,
  ),
```

- [ ] **Step 5: Run static analysis**

Run: `dart analyze lib/features/khatmah/presentation/widgets/ lib/features/home/`
Expected: No new warnings

- [ ] **Step 6: Commit**

```
git add lib/features/khatmah/presentation/widgets/khatmah_hero_card.dart lib/features/home/
git commit -m "feat(khatmah): add KhatmahHeroCard and home page integration"
```

---

### Task 7: Khatmah Setup Page & Dashboard Page

**Files:**
- Create: `lib/features/khatmah/presentation/pages/khatmah_setup_page.dart`
- Create: `lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart`
- Create: `lib/features/khatmah/presentation/widgets/khatmah_dedication_form.dart`
- Create: `lib/features/khatmah/presentation/widgets/khatmah_progress_gauge.dart`
- Modify: `lib/core/router/app_router.dart` (add khatmah routes)

**Interfaces:**
- Consumes: `KhatmahSetupCubit`, `KhatmahCubit`, `KhatmahPlan`, `KhatmahDedication`, `KhatmahSchedulingEngine` from Tasks 1-4
- Produces:
  - `KhatmahSetupPage` — multi-step wizard: pages/day selection → dedication toggle → confirm
  - `KhatmahDashboardPage` — active plan overview, today's wird, progress, physical mushaf logger, pause/abandon
  - Routes: `/khatmah/setup`, `/khatmah/dashboard`

This is the largest UI task. Steps:

- [ ] **Step 1: Create KhatmahDedicationForm widget**

Full form with name field, relationship dropdown, condition selector (alive/deceased/sick), optional note. Uses standard Flutter form widgets with Arabic label support.

- [ ] **Step 2: Create KhatmahProgressGauge widget**

Circular progress indicator showing `progressPercentage`, completed/remaining pages counts, and estimated completion date.

- [ ] **Step 3: Create KhatmahSetupPage**

A multi-section page with:
1. Pages-per-day preset chips (2, 4, 10, 20) + custom input
2. Computed expected duration/end date display
3. Optional dedication toggle → expands `KhatmahDedicationForm`
4. "Start Khatmah" button → calls `KhatmahSetupCubit.createPlan()`
5. On `KhatmahSetupDone` → navigate to dashboard

- [ ] **Step 4: Create KhatmahDashboardPage**

Dashboard showing:
1. `KhatmahProgressGauge`
2. Today's wird card with "Start reading" button
3. Dedication info (if dedicated)
4. Physical mushaf logger (page number input + save)
5. Action buttons: Pause, Calm Adjustment, Mild Compensation, Abandon

- [ ] **Step 5: Add routes to AppRouter**

In `app_router.dart` `AppRoutes` class:
```dart
static const String khatmahSetup = '/khatmah/setup';
static const String khatmahDashboard = '/khatmah/dashboard';
static const String khatmDua = '/quran/khatm-dua';
```

Add GoRoute entries for each.

- [ ] **Step 6: Run static analysis**

Run: `dart analyze lib/features/khatmah/ lib/core/router/`
Expected: No new warnings

- [ ] **Step 7: Commit**

```
git add lib/features/khatmah/presentation/ lib/core/router/app_router.dart
git commit -m "feat(khatmah): add setup page, dashboard page, and routes"
```

---

### Task 8: Du'a Khatm al-Quran & Completion Flow

**Files:**
- Create: `assets/data/khatm_dua.json`
- Create: `lib/features/khatmah/data/datasources/khatm_dua_datasource.dart`
- Create: `lib/features/khatmah/domain/usecases/get_khatm_dua_usecase.dart`
- Create: `lib/features/khatmah/presentation/cubits/khatm_dua_cubit.dart`
- Create: `lib/features/khatmah/presentation/pages/khatm_dua_page.dart`
- Create: `lib/features/khatmah/presentation/pages/khatmah_completion_page.dart`
- Modify: `pubspec.yaml` (add `assets/data/khatm_dua.json` to assets)
- Test: `test/features/khatmah/data/datasources/khatm_dua_datasource_test.dart`

**Interfaces:**
- Consumes: `KhatmahPlan`, `KhatmahDedication`, `DedicationCondition` from Task 1
- Produces:
  - `assets/data/khatm_dua.json` — full du'a text with source metadata
  - `KhatmDuaDatasource` with `Future<KhatmDuaData> loadDua()`
  - `KhatmDuaPage` — standalone du'a viewer with font scaler and copy
  - `KhatmahCompletionPage` — celebratory screen with summary + du'a + share

- [ ] **Step 1: Create khatm_dua.json asset**

Create `assets/data/khatm_dua.json` with the du'a text, source info, tier classification, and dedication insert templates.

- [ ] **Step 2: Register asset in pubspec.yaml**

Add `- assets/data/khatm_dua.json` under the `assets` section.

- [ ] **Step 3: Create KhatmDuaDatasource**

```dart
// lib/features/khatmah/data/datasources/khatm_dua_datasource.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class KhatmDuaData {
  const KhatmDuaData({
    required this.arabicText,
    required this.source,
    required this.sourceNote,
    required this.tier,
    required this.dedicationInserts,
  });

  final String arabicText;
  final String source;
  final String sourceNote;
  final String tier;
  final Map<String, String> dedicationInserts;

  factory KhatmDuaData.fromJson(Map<String, dynamic> json) {
    return KhatmDuaData(
      arabicText: json['arabicText'] as String,
      source: json['source'] as String,
      sourceNote: json['sourceNote'] as String,
      tier: json['tier'] as String,
      dedicationInserts:
          Map<String, String>.from(json['dedicationInserts'] as Map),
    );
  }
}

class KhatmDuaDatasource {
  KhatmDuaData? _cached;

  Future<KhatmDuaData> loadDua() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/data/khatm_dua.json');
    _cached = KhatmDuaData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cached!;
  }
}
```

- [ ] **Step 4: Create GetKhatmDuaUsecase**

```dart
// lib/features/khatmah/domain/usecases/get_khatm_dua_usecase.dart
import '../../data/datasources/khatm_dua_datasource.dart';

class GetKhatmDuaUsecase {
  const GetKhatmDuaUsecase(this._datasource);
  final KhatmDuaDatasource _datasource;

  Future<KhatmDuaData> call() => _datasource.loadDua();
}
```

- [ ] **Step 5: Create KhatmDuaCubit, KhatmDuaPage, and KhatmahCompletionPage**

The du'a page shows the full du'a text with font size controls and copy button. The completion page shows the celebration, summary, du'a, and share options.

- [ ] **Step 6: Write du'a datasource test**

```dart
// test/features/khatmah/data/datasources/khatm_dua_datasource_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatm_dua_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('KhatmDuaData.fromJson parses all fields', () {
    final json = {
      'arabicText': 'test du\'a text',
      'source': 'King Fahd Complex',
      'sourceNote': 'Printed at end of Mushaf',
      'tier': 'guidance',
      'dedicationInserts': {
        'deceased': 'mercy text',
        'sick': 'healing text',
        'alive': 'blessing text',
      },
    };
    final data = KhatmDuaData.fromJson(json);
    expect(data.tier, 'guidance');
    expect(data.dedicationInserts['deceased'], 'mercy text');
  });
}
```

- [ ] **Step 7: Register DI and add route**

Add to `injection.dart`:
```dart
getIt.registerLazySingleton<KhatmDuaDatasource>(KhatmDuaDatasource.new);
getIt.registerLazySingleton<GetKhatmDuaUsecase>(
  () => GetKhatmDuaUsecase(getIt<KhatmDuaDatasource>()),
);
```

Add to `app_router.dart`:
```dart
GoRoute(
  path: '/quran/khatm-dua',
  builder: (context, state) => const KhatmDuaPage(),
),
```

- [ ] **Step 8: Run all tests**

Run: `flutter test test/features/khatmah/`
Expected: ALL PASS

- [ ] **Step 9: Commit**

```
git add assets/data/ lib/features/khatmah/ lib/core/di/injection.dart lib/core/router/app_router.dart pubspec.yaml test/features/khatmah/
git commit -m "feat(khatmah): add Du'a Khatm al-Quran and completion flow"
```

---

### Task 9: Social Share & Certificate Integration

**Files:**
- Modify: `lib/core/widgets/social_share/social_share_model.dart:10-18` (add `khatmah` to `SocialShareCategory`)
- Modify: `lib/features/certificate/domain/entities/certificate_award.dart:10` (add `khatmahReading` to `CertificateType`)

**Interfaces:**
- Consumes: `KhatmahPlan`, `KhatmahDedication` from Task 1
- Produces:
  - `SocialShareCategory.khatmah` enum value
  - `SocialShareData.khatmah()` factory or convenience constructor
  - `CertificateType.khatmahReading` enum value

- [ ] **Step 1: Add `khatmah` to SocialShareCategory**

In `social_share_model.dart` line 10-18, add `khatmah` to the enum and its icon.

- [ ] **Step 2: Add `khatmahReading` to CertificateType**

In `certificate_award.dart` line 10, add `khatmahReading` to the enum.

- [ ] **Step 3: Update verification code in CertificateAward**

Add `CertificateType.khatmahReading => 'KR'` to the `verificationCode` getter switch expression.

- [ ] **Step 4: Run static analysis**

Run: `dart analyze lib/core/widgets/social_share/ lib/features/certificate/`
Expected: No new warnings (check that existing switch expressions handle the new enum values)

- [ ] **Step 5: Commit**

```
git add lib/core/widgets/social_share/social_share_model.dart lib/features/certificate/domain/entities/certificate_award.dart
git commit -m "feat(khatmah): add khatmah social share category and certificate type"
```

---

### Task 10: Final Integration Testing & Cleanup

**Files:**
- Modify: `lib/core/identity/account_data_reset.dart` (add khatmah SharedPreferences keys to reset list)
- Run: Full test suite
- Run: Static analysis on entire project

**Interfaces:**
- Consumes: All previous tasks
- Produces: Clean, passing build

- [ ] **Step 1: Add khatmah keys to account data reset**

In `account_data_reset.dart`, add to the SharedPreferences keys list:
```dart
'khatmah_active_plan',
'khatmah_history',
'khatmah_cloud_dirty',
```

- [ ] **Step 2: Run full test suite**

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 3: Run static analysis**

Run: `dart analyze lib/`
Expected: No new warnings

- [ ] **Step 4: Verify reader isolation manually**

Describe: open free reader to a surah, confirm reading a page. Then open khatmah reader. Verify khatmah `currentPage` did not change from the free reading confirmation.

- [ ] **Step 5: Final commit**

```
git add .
git commit -m "feat(khatmah): final integration - account reset keys and cleanup"
```
