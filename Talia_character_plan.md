# Talia Character System — Step-by-Step Implementation Plan

> **هذا الملف هو المرجع الكامل لتنفيذ نظام شخصية تالية خطوة بخطوة.**
> كل خطوة تتبع الأنماط البرمجية الموجودة فعلاً في المشروع.
> لا يوجد تخمين — كل كلاس، كل ملف، كل تسجيل في DI مبني على الكود الحالي.

---

## المبادئ المُلزِمة (يجب الالتزام بها في كل سطر كود)

| المبدأ | التطبيق في هذا المشروع |
|---|---|
| **Clean Architecture** | domain → data → application → presentation. لا يوجد import عكسي أبداً. |
| **Equatable** | كل entity و كل state يرث من `Equatable` مع `props`. |
| **dartz Either** | كل repository method يرجع `Future<Either<Failure, T>>`. |
| **Isar Schema** | `@collection` + `toModel()` + `fromModel()` + `compositeKey` pattern. |
| **GetIt DI** | 7 blocks مرتبة: External → Core → Datasources → CoreServices → Repositories → Usecases → Cubits. |
| **Event Bus** | `StreamController<T>.broadcast()` — نفس pattern `ProgressEventsBus`. |
| **Cubits not Blocs** | `Cubit<State>` فقط. States sealed + Equatable. Factories في DI. |
| **Relative Imports** | داخل المشروع `../../` — الحزم الخارجية `package:`. |
| **Error Handling** | `try/catch` في Repository impl → `Left(CacheFailure(e.toString()))`. |
| **ARB Localization** | Keys تبدأ بـ `char_`. ملفات `app_ar.arb` + `app_en.arb`. |
| **UTC Timestamps** | `DateTime.now().toUtc()` دائماً. |

---

## هيكل الملفات الكامل

```
lib/features/character/
├── domain/
│   ├── entities/
│   │   ├── character_profile.dart
│   │   ├── character_level.dart
│   │   ├── character_cosmetic.dart
│   │   └── dialogue_line.dart
│   ├── value_objects/
│   │   ├── character_emotion.dart
│   │   ├── character_animation_state.dart
│   │   ├── character_context.dart
│   │   └── character_event.dart
│   ├── repositories/
│   │   └── character_repository.dart
│   └── usecases/
│       ├── get_character_profile_usecase.dart
│       ├── save_character_profile_usecase.dart
│       ├── add_character_xp_usecase.dart
│       ├── get_dialogue_line_usecase.dart
│       └── resolve_character_state_usecase.dart
│
├── data/
│   ├── models/
│   │   ├── isar_character_profile.dart
│   │   ├── isar_character_profile.g.dart          ← generated
│   │   └── character_profile_model.dart
│   ├── datasources/
│   │   ├── character_local_datasource.dart
│   │   └── isar_character_local_datasource_impl.dart
│   └── repositories/
│       └── character_repository_impl.dart
│
├── application/
│   ├── character_event_bus.dart
│   ├── character_scheduler.dart
│   ├── character_controller.dart
│   ├── character_emotion_resolver.dart
│   ├── character_dialogue_engine.dart
│   └── character_progression_engine.dart
│
└── presentation/
    ├── cubits/
    │   ├── character_cubit.dart
    │   └── character_state.dart
    ├── widgets/
    │   ├── character_widget.dart
    │   ├── character_png_view.dart
    │   ├── character_dialogue_bubble.dart
    │   ├── character_particle_layer.dart
    │   └── character_progression_badge.dart
    └── controllers/
        └── character_png_controller.dart
```

---

---

# المرحلة 1 — Foundation (الأساسات)

> **الهدف:** إنشاء كل ملفات Domain + Data + EventBus + تسجيل DI + Isar Migration.
> **المدة:** أسبوعان.
> **لا يوجد UI في هذه المرحلة.**

---

## الخطوة 1.1 — إنشاء مجلد الـ Feature

إنشاء هيكل المجلدات الكامل:

```
lib/features/character/domain/entities/
lib/features/character/domain/value_objects/
lib/features/character/domain/repositories/
lib/features/character/domain/usecases/
lib/features/character/data/models/
lib/features/character/data/datasources/
lib/features/character/data/repositories/
lib/features/character/application/
lib/features/character/presentation/cubits/
lib/features/character/presentation/widgets/
lib/features/character/presentation/controllers/
```

---

## الخطوة 1.2 — Domain Entities

### ملف: `domain/entities/character_profile.dart`

```dart
import 'package:equatable/equatable.dart';

class CharacterProfile extends Equatable {
  const CharacterProfile({
    required this.userId,
    required this.characterXp,
    required this.characterLevel,
    required this.unlockedCosmeticIds,
    required this.lastSeenAt,
    required this.totalDialoguesShown,
    required this.characterEnabled,
    required this.dialogueEnabled,
  });

  final String userId;
  final int characterXp;
  final int characterLevel;           // 1–6
  final List<String> unlockedCosmeticIds;
  final DateTime lastSeenAt;
  final int totalDialoguesShown;
  final bool characterEnabled;
  final bool dialogueEnabled;

  CharacterProfile copyWith({
    String? userId,
    int? characterXp,
    int? characterLevel,
    List<String>? unlockedCosmeticIds,
    DateTime? lastSeenAt,
    int? totalDialoguesShown,
    bool? characterEnabled,
    bool? dialogueEnabled,
  }) {
    return CharacterProfile(
      userId: userId ?? this.userId,
      characterXp: characterXp ?? this.characterXp,
      characterLevel: characterLevel ?? this.characterLevel,
      unlockedCosmeticIds: unlockedCosmeticIds ?? this.unlockedCosmeticIds,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      totalDialoguesShown: totalDialoguesShown ?? this.totalDialoguesShown,
      characterEnabled: characterEnabled ?? this.characterEnabled,
      dialogueEnabled: dialogueEnabled ?? this.dialogueEnabled,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        characterXp,
        characterLevel,
        unlockedCosmeticIds,
        lastSeenAt,
        totalDialoguesShown,
        characterEnabled,
        dialogueEnabled,
      ];
}
```

### ملف: `domain/entities/character_level.dart`

```dart
import 'package:equatable/equatable.dart';

class CharacterLevel extends Equatable {
  const CharacterLevel({
    required this.level,
    required this.labelAr,
    required this.labelEn,
    required this.xpThreshold,
    required this.cosmeticIds,
  });

  final int level;
  final String labelAr;
  final String labelEn;
  final int xpThreshold;
  final List<String> cosmeticIds;

  @override
  List<Object?> get props => [level, xpThreshold];

  /// All levels defined as constants — tunable without rebuild.
  static const List<CharacterLevel> all = [
    CharacterLevel(
      level: 1,
      labelAr: 'الصفحة الأولى',
      labelEn: 'First Page',
      xpThreshold: 0,
      cosmeticIds: [],
    ),
    CharacterLevel(
      level: 2,
      labelAr: 'نور المصحف',
      labelEn: 'Light of the Mushaf',
      xpThreshold: 200,
      cosmeticIds: ['mushaf_l2'],
    ),
    CharacterLevel(
      level: 3,
      labelAr: 'درب الحفظ',
      labelEn: 'Path of Memorization',
      xpThreshold: 600,
      cosmeticIds: ['mushaf_l2', 'outfit_l3'],
    ),
    CharacterLevel(
      level: 4,
      labelAr: 'ضياء القمر',
      labelEn: 'Moonlight',
      xpThreshold: 1400,
      cosmeticIds: ['mushaf_l2', 'outfit_l3', 'aura_l4'],
    ),
    CharacterLevel(
      level: 5,
      labelAr: 'مقام النجوم',
      labelEn: 'Station of Stars',
      xpThreshold: 3000,
      cosmeticIds: ['mushaf_l2', 'outfit_l3', 'aura_l4', 'particles_l5'],
    ),
    CharacterLevel(
      level: 6,
      labelAr: 'حارسة الكلمة',
      labelEn: 'Guardian of the Word',
      xpThreshold: 6000,
      cosmeticIds: ['mushaf_l2', 'outfit_l3', 'aura_l4', 'particles_l5', 'shimmer_l6'],
    ),
  ];

  /// Resolve level from XP amount.
  static CharacterLevel fromXp(int xp) {
    for (int i = all.length - 1; i >= 0; i--) {
      if (xp >= all[i].xpThreshold) return all[i];
    }
    return all.first;
  }
}
```

### ملف: `domain/entities/character_cosmetic.dart`

```dart
import 'package:equatable/equatable.dart';

enum CosmeticType { outfit, mushafSkin, aura, accessory, effect }

class CharacterCosmetic extends Equatable {
  const CharacterCosmetic({
    required this.id,
    required this.type,
    required this.assetPath,
    required this.isDefault,
  });

  final String id;
  final CosmeticType type;
  final String assetPath;   // PNG path (v1)
  final bool isDefault;

  @override
  List<Object?> get props => [id, type];
}
```

### ملف: `domain/entities/dialogue_line.dart`

```dart
import 'package:equatable/equatable.dart';

enum DialogueCategory {
  greetingMorning, greetingAfternoon, greetingEvening, greetingNight,
  returnShort, returnLong,
  readingStart, memorizationStart,
  reviewShort, reviewLong,
  planCompleted, achievement, streakMilestone, surahCompleted,
  loading, syncDone, offline, levelUp,
  kidsMission, encouragement,
}

enum DialogueTone { calm, excited, warm, encouraging }

class DialogueLine extends Equatable {
  const DialogueLine({
    required this.key,
    required this.category,
    required this.tone,
  });

  final String key;             // ARB key: "char_greeting_morning_0"
  final DialogueCategory category;
  final DialogueTone tone;

  @override
  List<Object?> get props => [key, category];
}
```

---

## الخطوة 1.3 — Domain Value Objects

### ملف: `domain/value_objects/character_emotion.dart`

```dart
enum CharacterEmotion {
  happy,
  calm,
  focused,
  proud,
  excited,
  sleepy,
  thinking,
  sad,
  neutral,
}
```

### ملف: `domain/value_objects/character_animation_state.dart`

```dart
enum CharacterAnimationState {
  idle,
  greeting,
  reading,
  memorizing,
  reviewing,
  celebrating,
  achievement,
  thinking,
  loading,
  waiting,
  sleeping,
  sad,
  offline,
  syncing,
  kidsDancing,
  kidsClapping,
}
```

### ملف: `domain/value_objects/character_context.dart`

```dart
import 'package:equatable/equatable.dart';
import 'character_emotion.dart';
import 'character_event.dart';

class CharacterContext extends Equatable {
  const CharacterContext({
    required this.now,
    required this.streakDays,
    required this.appXp,
    required this.characterXp,
    required this.characterLevel,
    required this.isKidsMode,
    required this.isOnline,
    required this.isBatteryLow,
    required this.isReducedMotion,
    required this.locale,
    required this.sourceEvent,
    this.sinceLastSession,
    this.completedAyahsToday,
  });

  final DateTime now;
  final int streakDays;
  final int appXp;
  final int characterXp;
  final int characterLevel;
  final bool isKidsMode;
  final bool isOnline;
  final bool isBatteryLow;
  final bool isReducedMotion;
  final String locale;               // 'ar' | 'en'
  final CharacterEvent sourceEvent;
  final Duration? sinceLastSession;
  final int? completedAyahsToday;

  @override
  List<Object?> get props => [now, sourceEvent, locale, isKidsMode];
}
```

### ملف: `domain/value_objects/character_event.dart`

```dart
/// Sealed event hierarchy — features fire these into CharacterEventBus.
/// No character module internals are needed to construct these.
sealed class CharacterEvent {
  const CharacterEvent();
}

class AppOpenedEvent extends CharacterEvent {
  const AppOpenedEvent();
}

class ReadingStartedEvent extends CharacterEvent {
  const ReadingStartedEvent({required this.surahId});
  final int surahId;
}

class ReadingFinishedEvent extends CharacterEvent {
  const ReadingFinishedEvent({required this.surahId, required this.pagesRead});
  final int surahId;
  final int pagesRead;
}

class MemorizationStartedEvent extends CharacterEvent {
  const MemorizationStartedEvent();
}

class MemorizationCompletedEvent extends CharacterEvent {
  const MemorizationCompletedEvent({required this.ayahsMemorized});
  final int ayahsMemorized;
}

class ReviewStartedEvent extends CharacterEvent {
  const ReviewStartedEvent();
}

class ReviewCompletedEvent extends CharacterEvent {
  const ReviewCompletedEvent({required this.score, required this.total});
  final int score;
  final int total;
}

class AchievementUnlockedEvent extends CharacterEvent {
  const AchievementUnlockedEvent({required this.achievementId, required this.title});
  final String achievementId;
  final String title;
}

class StreakUpdatedEvent extends CharacterEvent {
  const StreakUpdatedEvent({required this.newStreak});
  final int newStreak;
}

class PlanCompletedEvent extends CharacterEvent {
  const PlanCompletedEvent();
}

class SurahCompletedEvent extends CharacterEvent {
  const SurahCompletedEvent({required this.surahId});
  final int surahId;
}

class SyncCompletedEvent extends CharacterEvent {
  const SyncCompletedEvent();
}

class WentOfflineEvent extends CharacterEvent {
  const WentOfflineEvent();
}

class WentOnlineEvent extends CharacterEvent {
  const WentOnlineEvent();
}

class LoadingStartedEvent extends CharacterEvent {
  const LoadingStartedEvent();
}

class LoadingFinishedEvent extends CharacterEvent {
  const LoadingFinishedEvent();
}

class LongAbsenceDetectedEvent extends CharacterEvent {
  const LongAbsenceDetectedEvent({required this.daysMissed});
  final int daysMissed;
}

class KidsMissionCompletedEvent extends CharacterEvent {
  const KidsMissionCompletedEvent({required this.missionId});
  final String missionId;
}

class KidsModeChangedEvent extends CharacterEvent {
  const KidsModeChangedEvent({required this.enabled});
  final bool enabled;
}

class CharacterLevelUpEvent extends CharacterEvent {
  const CharacterLevelUpEvent({required this.newLevel});
  final int newLevel;
}

class OnboardingStepEvent extends CharacterEvent {
  const OnboardingStepEvent({required this.stepIndex});
  final int stepIndex;
}
```

---

## الخطوة 1.4 — Repository Interface

### ملف: `domain/repositories/character_repository.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../entities/character_profile.dart';

/// Abstract repository — matches existing HifzRepository pattern exactly.
abstract class CharacterRepository {
  Future<Either<Failure, CharacterProfile?>> getProfile(String userId);
  Future<Either<Failure, void>> saveProfile(CharacterProfile profile);
  Future<Either<Failure, CharacterProfile>> addXp(String userId, int amount);
  Future<Either<Failure, void>> markSeen(String userId, DateTime at);
  Stream<CharacterProfile?> watchProfile(String userId);
}
```

---

## الخطوة 1.5 — Use Cases

> كل usecase يتبع نفس pattern `GetSurahsUsecase` — يرث `UseCase` أو `UseCaseNoParams`.

### ملف: `domain/usecases/get_character_profile_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/character_profile.dart';
import '../repositories/character_repository.dart';

class GetCharacterProfileUsecase implements UseCase<CharacterProfile?, String> {
  GetCharacterProfileUsecase(this._repository);
  final CharacterRepository _repository;

  @override
  Future<Either<Failure, CharacterProfile?>> call(String userId) =>
      _repository.getProfile(userId);
}
```

### ملف: `domain/usecases/save_character_profile_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/character_profile.dart';
import '../repositories/character_repository.dart';

class SaveCharacterProfileUsecase implements UseCase<void, CharacterProfile> {
  SaveCharacterProfileUsecase(this._repository);
  final CharacterRepository _repository;

  @override
  Future<Either<Failure, void>> call(CharacterProfile profile) =>
      _repository.saveProfile(profile);
}
```

### ملف: `domain/usecases/add_character_xp_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/character_profile.dart';
import '../repositories/character_repository.dart';

class AddCharacterXpParams {
  const AddCharacterXpParams({required this.userId, required this.amount});
  final String userId;
  final int amount;
}

class AddCharacterXpUsecase implements UseCase<CharacterProfile, AddCharacterXpParams> {
  AddCharacterXpUsecase(this._repository);
  final CharacterRepository _repository;

  @override
  Future<Either<Failure, CharacterProfile>> call(AddCharacterXpParams params) =>
      _repository.addXp(params.userId, params.amount);
}
```

### ملف: `domain/usecases/get_dialogue_line_usecase.dart`

```dart
import '../../application/character_dialogue_engine.dart';
import '../entities/dialogue_line.dart';
import '../value_objects/character_context.dart';

/// Not Either-based — dialogue resolution is pure, cannot fail.
class GetDialogueLineUsecase {
  GetDialogueLineUsecase(this._engine);
  final CharacterDialogueEngine _engine;

  DialogueLine? call(CharacterContext context) =>
      _engine.resolve(context);
}
```

### ملف: `domain/usecases/resolve_character_state_usecase.dart`

```dart
import '../../application/character_emotion_resolver.dart';
import '../value_objects/character_animation_state.dart';
import '../value_objects/character_context.dart';
import '../value_objects/character_emotion.dart';

/// Pure state resolution — no IO, cannot fail.
class ResolveCharacterStateUsecase {
  const ResolveCharacterStateUsecase();

  (CharacterAnimationState, CharacterEmotion) call(CharacterContext context) {
    final state = _resolveAnimation(context);
    final emotion = const CharacterEmotionResolver().resolve(context);
    return (state, emotion);
  }

  CharacterAnimationState _resolveAnimation(CharacterContext context) {
    return switch (context.sourceEvent) {
      AppOpenedEvent()              => CharacterAnimationState.greeting,
      ReadingStartedEvent()         => CharacterAnimationState.reading,
      ReadingFinishedEvent()        => CharacterAnimationState.idle,
      MemorizationStartedEvent()    => CharacterAnimationState.memorizing,
      MemorizationCompletedEvent()  => CharacterAnimationState.celebrating,
      ReviewStartedEvent()          => CharacterAnimationState.reviewing,
      ReviewCompletedEvent(score: var s, total: var t) =>
        (s / t >= 0.6) ? CharacterAnimationState.celebrating : CharacterAnimationState.thinking,
      AchievementUnlockedEvent()    => CharacterAnimationState.achievement,
      StreakUpdatedEvent(newStreak: var n) =>
        (n % 7 == 0) ? CharacterAnimationState.celebrating : CharacterAnimationState.idle,
      PlanCompletedEvent()          => CharacterAnimationState.celebrating,
      SurahCompletedEvent()         => CharacterAnimationState.celebrating,
      SyncCompletedEvent()          => CharacterAnimationState.syncing,
      WentOfflineEvent()            => CharacterAnimationState.offline,
      WentOnlineEvent()             => CharacterAnimationState.syncing,
      LoadingStartedEvent()         => CharacterAnimationState.loading,
      LoadingFinishedEvent()        => CharacterAnimationState.idle,
      LongAbsenceDetectedEvent()    => CharacterAnimationState.sad,
      KidsMissionCompletedEvent()   => CharacterAnimationState.kidsDancing,
      KidsModeChangedEvent()        => CharacterAnimationState.greeting,
      CharacterLevelUpEvent()       => CharacterAnimationState.achievement,
      OnboardingStepEvent()         => CharacterAnimationState.greeting,
    };
  }
}
```

---

## الخطوة 1.6 — Data Layer: Isar Model

### ملف: `data/models/isar_character_profile.dart`

> يتبع نفس pattern `IsarAyahProgress` — `@collection` + `compositeKey` + `toModel()` + `fromModel()`.

```dart
import 'package:isar/isar.dart';
import 'character_profile_model.dart';

part 'isar_character_profile.g.dart';

@collection
class IsarCharacterProfile {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String compositeKey;       // userId

  late String userId;
  late int characterXp;
  late int characterLevel;
  late List<String> unlockedCosmeticIds;
  late DateTime lastSeenAt;
  late int totalDialoguesShown;
  late bool characterEnabled;
  late bool dialogueEnabled;

  CharacterProfileModel toModel() {
    return CharacterProfileModel(
      userId: userId,
      characterXp: characterXp,
      characterLevel: characterLevel,
      unlockedCosmeticIds: unlockedCosmeticIds,
      lastSeenAt: lastSeenAt,
      totalDialoguesShown: totalDialoguesShown,
      characterEnabled: characterEnabled,
      dialogueEnabled: dialogueEnabled,
    );
  }

  static IsarCharacterProfile fromModel(CharacterProfileModel model) {
    return IsarCharacterProfile()
      ..compositeKey = model.userId
      ..userId = model.userId
      ..characterXp = model.characterXp
      ..characterLevel = model.characterLevel
      ..unlockedCosmeticIds = model.unlockedCosmeticIds
      ..lastSeenAt = model.lastSeenAt
      ..totalDialoguesShown = model.totalDialoguesShown
      ..characterEnabled = model.characterEnabled
      ..dialogueEnabled = model.dialogueEnabled;
  }
}
```

### ملف: `data/models/character_profile_model.dart`

```dart
import '../../domain/entities/character_profile.dart';

class CharacterProfileModel extends CharacterProfile {
  const CharacterProfileModel({
    required super.userId,
    required super.characterXp,
    required super.characterLevel,
    required super.unlockedCosmeticIds,
    required super.lastSeenAt,
    required super.totalDialoguesShown,
    required super.characterEnabled,
    required super.dialogueEnabled,
  });

  /// Default profile for new users.
  factory CharacterProfileModel.initial(String userId) {
    return CharacterProfileModel(
      userId: userId,
      characterXp: 0,
      characterLevel: 1,
      unlockedCosmeticIds: const [],
      lastSeenAt: DateTime.now().toUtc(),
      totalDialoguesShown: 0,
      characterEnabled: true,
      dialogueEnabled: true,
    );
  }

  factory CharacterProfileModel.fromJson(Map<String, dynamic> json) {
    return CharacterProfileModel(
      userId: json['user_id'] as String,
      characterXp: json['character_xp'] as int? ?? 0,
      characterLevel: json['character_level'] as int? ?? 1,
      unlockedCosmeticIds: List<String>.from(json['unlocked_cosmetic_ids'] ?? []),
      lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
      totalDialoguesShown: json['total_dialogues_shown'] as int? ?? 0,
      characterEnabled: json['character_enabled'] as bool? ?? true,
      dialogueEnabled: json['dialogue_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'character_xp': characterXp,
        'character_level': characterLevel,
        'unlocked_cosmetic_ids': unlockedCosmeticIds,
        'last_seen_at': lastSeenAt.toIso8601String(),
        'total_dialogues_shown': totalDialoguesShown,
        'character_enabled': characterEnabled,
        'dialogue_enabled': dialogueEnabled,
      };

  CharacterProfileModel withAddedXp(int amount) {
    return CharacterProfileModel(
      userId: userId,
      characterXp: characterXp + amount,
      characterLevel: characterLevel,
      unlockedCosmeticIds: unlockedCosmeticIds,
      lastSeenAt: lastSeenAt,
      totalDialoguesShown: totalDialoguesShown,
      characterEnabled: characterEnabled,
      dialogueEnabled: dialogueEnabled,
    );
  }
}
```

---

## الخطوة 1.7 — Data Layer: Datasource

### ملف: `data/datasources/character_local_datasource.dart`

```dart
import '../models/character_profile_model.dart';

/// Abstract datasource — same pattern as HifzLocalDatasource.
abstract class CharacterLocalDatasource {
  Future<CharacterProfileModel?> getProfile(String userId);
  Future<void> saveProfile(CharacterProfileModel profile);
  Future<void> updateXp(String userId, int amount);
  Future<void> markSeen(String userId, DateTime at);
  Stream<CharacterProfileModel?> watchProfile(String userId);
}
```

### ملف: `data/datasources/isar_character_local_datasource_impl.dart`

```dart
import 'package:isar/isar.dart';
import '../models/character_profile_model.dart';
import '../models/isar_character_profile.dart';

class IsarCharacterLocalDatasourceImpl implements CharacterLocalDatasource {
  IsarCharacterLocalDatasourceImpl(this._isar);
  final Isar _isar;

  @override
  Future<CharacterProfileModel?> getProfile(String userId) async {
    final record = await _isar.isarCharacterProfiles
        .where()
        .compositeKeyEqualTo(userId)
        .findFirst();
    return record?.toModel();
  }

  @override
  Future<void> saveProfile(CharacterProfileModel profile) async {
    await _isar.writeTxn(() async {
      await _isar.isarCharacterProfiles
          .put(IsarCharacterProfile.fromModel(profile));
    });
  }

  @override
  Future<void> updateXp(String userId, int amount) async {
    await _isar.writeTxn(() async {
      final record = await _isar.isarCharacterProfiles
          .where()
          .compositeKeyEqualTo(userId)
          .findFirst();
      if (record != null) {
        record.characterXp += amount;
        await _isar.isarCharacterProfiles.put(record);
      }
    });
  }

  @override
  Future<void> markSeen(String userId, DateTime at) async {
    await _isar.writeTxn(() async {
      final record = await _isar.isarCharacterProfiles
          .where()
          .compositeKeyEqualTo(userId)
          .findFirst();
      if (record != null) {
        record.lastSeenAt = at;
        await _isar.isarCharacterProfiles.put(record);
      }
    });
  }

  @override
  Stream<CharacterProfileModel?> watchProfile(String userId) {
    return _isar.isarCharacterProfiles
        .where()
        .compositeKeyEqualTo(userId)
        .watch(fireImmediately: true)
        .map((list) => list.isEmpty ? null : list.first.toModel());
  }
}
```

---

## الخطوة 1.8 — Data Layer: Repository Implementation

### ملف: `data/repositories/character_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../domain/entities/character_profile.dart';
import '../../domain/repositories/character_repository.dart';
import '../datasources/character_local_datasource.dart';
import '../models/character_profile_model.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  CharacterRepositoryImpl(this._datasource);
  final CharacterLocalDatasource _datasource;

  @override
  Future<Either<Failure, CharacterProfile?>> getProfile(String userId) async {
    try {
      final profile = await _datasource.getProfile(userId);
      return Right(profile);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveProfile(CharacterProfile profile) async {
    try {
      final model = profile is CharacterProfileModel
          ? profile
          : CharacterProfileModel(
              userId: profile.userId,
              characterXp: profile.characterXp,
              characterLevel: profile.characterLevel,
              unlockedCosmeticIds: profile.unlockedCosmeticIds,
              lastSeenAt: profile.lastSeenAt,
              totalDialoguesShown: profile.totalDialoguesShown,
              characterEnabled: profile.characterEnabled,
              dialogueEnabled: profile.dialogueEnabled,
            );
      await _datasource.saveProfile(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CharacterProfile>> addXp(String userId, int amount) async {
    try {
      await _datasource.updateXp(userId, amount);
      final updated = await _datasource.getProfile(userId);
      return Right(updated!);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markSeen(String userId, DateTime at) async {
    try {
      await _datasource.markSeen(userId, at);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<CharacterProfile?> watchProfile(String userId) =>
      _datasource.watchProfile(userId);
}
```

---

## الخطوة 1.9 — Character Event Bus

### ملف: `application/character_event_bus.dart`

> يتبع نفس pattern `ProgressEventsBus` بالضبط.

```dart
import 'dart:async';

import '../domain/value_objects/character_event.dart';

/// Broadcasts character-domain events so the character module reacts
/// without any feature needing to import character internals.
///
/// Features call [fire] after state transitions.
/// CharacterScheduler listens to [events].
class CharacterEventBus {
  CharacterEventBus();

  final _controller = StreamController<CharacterEvent>.broadcast();

  Stream<CharacterEvent> get events => _controller.stream;

  void fire(CharacterEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}
```

---

## الخطوة 1.10 — Isar Schema Registration

### تعديل: `lib/core/di/injection.dart`

> إضافة `IsarCharacterProfileSchema` في قائمة schemas عند فتح Isar.

```dart
// ─── 1. External ─────────────────────────────────────────────────────────────
final isar = await Isar.open([
  IsarAyahProgressSchema,
  IsarAyahReviewRecordSchema,
  IsarV2SessionSchema,
  StreakIsarSchema,
  XpIsarSchema,
  DailyActivityIsarSchema,
  CloudSyncQueueItemSchema,
  IsarCharacterProfileSchema,       // ← إضافة جديدة
], directory: dir.path);
```

---

## الخطوة 1.11 — DI Registration

### تعديل: `lib/core/di/injection.dart`

> إضافة تسجيلات Character في الأماكن الصحيحة بحسب الترتيب المُعتمد.

```dart
// ─── 2. Core ─────────────────────────────────────────────────────────────────
getIt.registerSingleton<CharacterEventBus>(CharacterEventBus());

// ─── 3. Datasources ──────────────────────────────────────────────────────────
getIt.registerLazySingleton<CharacterLocalDatasource>(
  () => IsarCharacterLocalDatasourceImpl(getIt<Isar>()),
);

// ─── 5. Repositories & Domain Adapters ───────────────────────────────────────
getIt.registerLazySingleton<CharacterRepository>(
  () => CharacterRepositoryImpl(getIt<CharacterLocalDatasource>()),
);

// ─── 6. Usecases ─────────────────────────────────────────────────────────────
getIt.registerLazySingleton(() => GetCharacterProfileUsecase(getIt()));
getIt.registerLazySingleton(() => SaveCharacterProfileUsecase(getIt()));
getIt.registerLazySingleton(() => AddCharacterXpUsecase(getIt()));

// ─── 7. Cubits ───────────────────────────────────────────────────────────────
// (سيتم إضافته في المرحلة 4)
```

---

## الخطوة 1.12 — Code Generation

```bash
# Generate Isar schema code
dart run build_runner build --delete-conflicting-outputs
```

---

## الخطوة 1.13 — Verification

```bash
# 1. Static analysis — must pass with zero errors
dart analyze

# 2. Run existing tests — must all pass
flutter test

# 3. Build — must succeed
flutter build apk --debug
```

> **قاعدة:** لا ننتقل للمرحلة 2 حتى تمر كل الاختبارات والبناء بدون أخطاء.

---

---

# المرحلة 2 — Logic Layer (طبقة المنطق)

> **الهدف:** بناء كل الـ engines والـ resolvers والـ scheduler.
> **المدة:** أسبوعان.
> **لا يوجد UI — فقط pure logic + unit tests.**

---

## الخطوة 2.1 — Character Emotion Resolver

### ملف: `application/character_emotion_resolver.dart`

```dart
import '../domain/value_objects/character_context.dart';
import '../domain/value_objects/character_emotion.dart';
import '../domain/value_objects/character_event.dart';

/// Pure, side-effect-free resolver — same pattern as SmartCoachEngine.
class CharacterEmotionResolver {
  const CharacterEmotionResolver();

  CharacterEmotion resolve(CharacterContext ctx) {
    // Night + no active session → sleepy
    if (_isNightTime(ctx.now) && ctx.sourceEvent is! ReadingStartedEvent) {
      return CharacterEmotion.sleepy;
    }

    return switch (ctx.sourceEvent) {
      AchievementUnlockedEvent()   => CharacterEmotion.excited,
      LongAbsenceDetectedEvent()   => CharacterEmotion.sad,
      PlanCompletedEvent()         => CharacterEmotion.proud,
      ReviewCompletedEvent(score: var s, total: var t)
        when (s / t >= 0.7)        => CharacterEmotion.happy,
      ReviewCompletedEvent()       => CharacterEmotion.thinking,
      MemorizationStartedEvent()   => CharacterEmotion.focused,
      AppOpenedEvent()             => CharacterEmotion.happy,
      LoadingStartedEvent()        => CharacterEmotion.calm,
      _                            => CharacterEmotion.neutral,
    };
  }

  bool _isNightTime(DateTime now) {
    final hour = now.hour;
    return hour >= 21 || hour < 5;
  }
}
```

---

## الخطوة 2.2 — Character Dialogue Engine

### ملف: `application/character_dialogue_engine.dart`

```dart
import 'dart:math';

import '../domain/entities/dialogue_line.dart';
import '../domain/value_objects/character_context.dart';
import '../domain/value_objects/character_event.dart';

/// Rule-based dialogue resolver with anti-repetition.
/// All text is in ARB files — this engine resolves KEYS only.
class CharacterDialogueEngine {
  CharacterDialogueEngine();

  final _random = Random();

  /// Tracks recently used variant indices per category to prevent repetition.
  final Map<DialogueCategory, Set<int>> _recentlyUsed = {};

  /// Number of variants per category (minimum 3 per spec).
  static const int _variantsPerCategory = 3;

  /// Resolve a dialogue line for the given context, or null if silent.
  DialogueLine? resolve(CharacterContext context) {
    final category = _resolveCategory(context);
    if (category == null) return null;

    final index = _pickNonRepeating(category);
    final key = 'char_${category.name}_$index';

    return DialogueLine(
      key: key,
      category: category,
      tone: _resolveTone(category),
    );
  }

  DialogueCategory? _resolveCategory(CharacterContext context) {
    return switch (context.sourceEvent) {
      AppOpenedEvent()             => _greetingByTime(context.now),
      LongAbsenceDetectedEvent(daysMissed: var d) =>
          d >= 3 ? DialogueCategory.returnLong : DialogueCategory.returnShort,
      ReadingStartedEvent()        => DialogueCategory.readingStart,
      MemorizationStartedEvent()   => DialogueCategory.memorizationStart,
      ReviewStartedEvent()         => _reviewCategory(context),
      PlanCompletedEvent()         => DialogueCategory.planCompleted,
      AchievementUnlockedEvent()   => DialogueCategory.achievement,
      StreakUpdatedEvent(newStreak: var n) =>
          (n % 7 == 0 || n % 30 == 0) ? DialogueCategory.streakMilestone : null,
      SurahCompletedEvent()        => DialogueCategory.surahCompleted,
      LoadingStartedEvent()        => DialogueCategory.loading,
      SyncCompletedEvent()         => DialogueCategory.syncDone,
      WentOfflineEvent()           => DialogueCategory.offline,
      CharacterLevelUpEvent()      => DialogueCategory.levelUp,
      KidsMissionCompletedEvent()  => DialogueCategory.kidsMission,
      _                            => null,  // silent events
    };
  }

  DialogueCategory _greetingByTime(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return DialogueCategory.greetingMorning;
    if (hour >= 12 && hour < 18) return DialogueCategory.greetingAfternoon;
    if (hour >= 18 && hour < 21) return DialogueCategory.greetingEvening;
    return DialogueCategory.greetingNight;
  }

  DialogueCategory _reviewCategory(CharacterContext context) {
    // Default: short. Could be extended with review item count.
    return DialogueCategory.reviewShort;
  }

  int _pickNonRepeating(DialogueCategory category) {
    _recentlyUsed.putIfAbsent(category, () => {});
    final used = _recentlyUsed[category]!;

    final pool = List.generate(_variantsPerCategory, (i) => i)
        .where((i) => !used.contains(i))
        .toList();

    if (pool.isEmpty) {
      used.clear();
      return _random.nextInt(_variantsPerCategory);
    }

    final selected = pool[_random.nextInt(pool.length)];
    used.add(selected);
    return selected;
  }

  DialogueTone _resolveTone(DialogueCategory category) {
    return switch (category) {
      DialogueCategory.achievement ||
      DialogueCategory.planCompleted ||
      DialogueCategory.surahCompleted ||
      DialogueCategory.streakMilestone ||
      DialogueCategory.kidsMission     => DialogueTone.excited,
      DialogueCategory.returnLong ||
      DialogueCategory.returnShort     => DialogueTone.warm,
      DialogueCategory.readingStart ||
      DialogueCategory.memorizationStart => DialogueTone.encouraging,
      _                                => DialogueTone.calm,
    };
  }
}
```

---

## الخطوة 2.3 — Character Progression Engine

### ملف: `application/character_progression_engine.dart`

```dart
import '../domain/entities/character_level.dart';
import '../domain/entities/character_profile.dart';
import '../domain/value_objects/character_event.dart';

/// Pure progression calculator — no side effects, no IO.
class CharacterProgressionEngine {
  const CharacterProgressionEngine();

  /// XP reward table — matches §13.1 spec.
  static const Map<Type, int> _xpTable = {
    AppOpenedEvent:              5,
    ReadingFinishedEvent:       10,
    MemorizationCompletedEvent: 20,
    ReviewCompletedEvent:       15,
    PlanCompletedEvent:         25,
    AchievementUnlockedEvent:   30,
    SurahCompletedEvent:        50,
    KidsMissionCompletedEvent:  15,
  };

  /// Returns XP to award for a given event, or 0 if the event has no XP.
  int xpForEvent(CharacterEvent event) {
    // Streak milestone: only every 7 days
    if (event is StreakUpdatedEvent && event.newStreak % 7 == 0) return 40;
    return _xpTable[event.runtimeType] ?? 0;
  }

  /// Check if adding `xpGain` crosses a level threshold.
  /// Returns the new CharacterLevel if a level-up occurred, null otherwise.
  CharacterLevel? checkLevelUp({
    required int currentXp,
    required int xpGain,
    required int currentLevel,
  }) {
    final newXp = currentXp + xpGain;
    final newLevel = CharacterLevel.fromXp(newXp);
    if (newLevel.level > currentLevel) return newLevel;
    return null;
  }
}
```

---

## الخطوة 2.4 — Character Scheduler

### ملف: `application/character_scheduler.dart`

```dart
import 'dart:async';
import '../domain/value_objects/character_event.dart';

/// Enforces business rules BEFORE events reach the controller:
/// - 60-second dialogue cooldown
/// - Priority ordering (Achievement > Plan > Greeting)
/// - Context lock during active sessions
/// - Deduplication within a time window
class CharacterScheduler {
  CharacterScheduler();

  DateTime? _lastDialogueTime;
  bool _isSessionActive = false;

  static const _dialogueCooldown = Duration(seconds: 60);
  static const _debounceWindow = Duration(milliseconds: 300);

  DateTime? _lastEventTime;

  /// Returns true if the event should be processed.
  bool shouldProcess(CharacterEvent event) {
    final now = DateTime.now().toUtc();

    // Debounce: ignore events within 300ms of each other
    if (_lastEventTime != null &&
        now.difference(_lastEventTime!) < _debounceWindow) {
      return false;
    }
    _lastEventTime = now;

    // Session lock: suppress non-critical events during active sessions
    if (_isSessionActive && !_isCriticalEvent(event)) {
      return false;
    }

    return true;
  }

  /// Returns true if dialogue should be shown (separate from animation).
  bool shouldShowDialogue(CharacterEvent event) {
    final now = DateTime.now().toUtc();

    // Cooldown check
    if (_lastDialogueTime != null &&
        now.difference(_lastDialogueTime!) < _dialogueCooldown) {
      // Allow high-priority events to bypass cooldown
      if (!_isHighPriority(event)) return false;
    }

    _lastDialogueTime = now;
    return true;
  }

  /// Called when a reading/memorization/review session starts.
  void lockSession() => _isSessionActive = true;

  /// Called when a session ends.
  void unlockSession() => _isSessionActive = false;

  bool _isCriticalEvent(CharacterEvent event) {
    return event is AchievementUnlockedEvent ||
        event is CharacterLevelUpEvent ||
        event is ReadingFinishedEvent ||
        event is MemorizationCompletedEvent ||
        event is ReviewCompletedEvent;
  }

  bool _isHighPriority(CharacterEvent event) {
    return event is AchievementUnlockedEvent ||
        event is CharacterLevelUpEvent ||
        event is PlanCompletedEvent ||
        event is SurahCompletedEvent;
  }

  /// Priority score for ordering (higher = processed first).
  int priority(CharacterEvent event) {
    return switch (event) {
      AchievementUnlockedEvent() => 100,
      CharacterLevelUpEvent()    => 95,
      SurahCompletedEvent()      => 90,
      PlanCompletedEvent()       => 85,
      StreakUpdatedEvent()       => 80,
      _ => 50,
    };
  }
}
```

---

## الخطوة 2.5 — Character Controller

### ملف: `application/character_controller.dart`

```dart
import 'dart:async';
import '../domain/entities/character_level.dart';
import '../domain/entities/character_profile.dart';
import '../domain/entities/dialogue_line.dart';
import '../domain/repositories/character_repository.dart';
import '../domain/value_objects/character_animation_state.dart';
import '../domain/value_objects/character_context.dart';
import '../domain/value_objects/character_emotion.dart';
import '../domain/value_objects/character_event.dart';
import 'character_dialogue_engine.dart';
import 'character_emotion_resolver.dart';
import 'character_event_bus.dart';
import 'character_progression_engine.dart';
import 'character_scheduler.dart';

/// Orchestrates the entire character state machine.
/// Receives events from CharacterEventBus → applies scheduling →
/// resolves animation + emotion + dialogue → persists XP → emits state.
class CharacterController {
  CharacterController({
    required CharacterEventBus eventBus,
    required CharacterScheduler scheduler,
    required CharacterEmotionResolver emotionResolver,
    required CharacterDialogueEngine dialogueEngine,
    required CharacterProgressionEngine progressionEngine,
    required CharacterRepository repository,
  })  : _eventBus = eventBus,
        _scheduler = scheduler,
        _emotionResolver = emotionResolver,
        _dialogueEngine = dialogueEngine,
        _progressionEngine = progressionEngine,
        _repository = repository;

  final CharacterEventBus _eventBus;
  final CharacterScheduler _scheduler;
  final CharacterEmotionResolver _emotionResolver;
  final CharacterDialogueEngine _dialogueEngine;
  final CharacterProgressionEngine _progressionEngine;
  final CharacterRepository _repository;

  StreamSubscription<CharacterEvent>? _subscription;

  /// Callback for state changes — CharacterCubit listens to this.
  void Function(CharacterStateUpdate)? onStateUpdate;

  void start() {
    _subscription = _eventBus.events.listen(_handleEvent);
  }

  Future<void> _handleEvent(CharacterEvent event) async {
    // 1. Scheduler gate
    if (!_scheduler.shouldProcess(event)) return;

    // 2. Session lock management
    if (event is ReadingStartedEvent ||
        event is MemorizationStartedEvent ||
        event is ReviewStartedEvent) {
      _scheduler.lockSession();
    }
    if (event is ReadingFinishedEvent ||
        event is MemorizationCompletedEvent ||
        event is ReviewCompletedEvent) {
      _scheduler.unlockSession();
    }

    // 3. Build context (simplified — full version reads from services)
    final context = CharacterContext(
      now: DateTime.now().toUtc(),
      streakDays: 0,       // pulled from StreakReader in full wiring
      appXp: 0,            // pulled from XpService in full wiring
      characterXp: 0,
      characterLevel: 1,
      isKidsMode: false,
      isOnline: true,
      isBatteryLow: false,
      isReducedMotion: false,
      locale: 'ar',
      sourceEvent: event,
    );

    // 4. Resolve animation state + emotion
    final animState = _resolveAnimation(event);
    final emotion = _emotionResolver.resolve(context);

    // 5. Resolve dialogue (if allowed)
    DialogueLine? dialogue;
    if (_scheduler.shouldShowDialogue(event)) {
      dialogue = _dialogueEngine.resolve(context);
    }

    // 6. XP + level-up
    final xp = _progressionEngine.xpForEvent(event);
    CharacterLevel? levelUp;
    if (xp > 0) {
      final result = await _repository.addXp(context.sourceEvent is AppOpenedEvent
          ? 'current_user' : 'current_user', xp);
      result.fold(
        (failure) {},
        (profile) {
          levelUp = _progressionEngine.checkLevelUp(
            currentXp: profile.characterXp - xp,
            xpGain: xp,
            currentLevel: profile.characterLevel,
          );
        },
      );
    }

    // 7. Emit state update
    onStateUpdate?.call(CharacterStateUpdate(
      animationState: animState,
      emotion: emotion,
      dialogue: dialogue,
      levelUp: levelUp,
    ));

    // 8. If level-up occurred, fire internal event
    if (levelUp != null) {
      _eventBus.fire(CharacterLevelUpEvent(newLevel: levelUp!.level));
    }
  }

  CharacterAnimationState _resolveAnimation(CharacterEvent event) {
    return switch (event) {
      AppOpenedEvent()              => CharacterAnimationState.greeting,
      ReadingStartedEvent()         => CharacterAnimationState.reading,
      ReadingFinishedEvent()        => CharacterAnimationState.idle,
      MemorizationStartedEvent()    => CharacterAnimationState.memorizing,
      MemorizationCompletedEvent()  => CharacterAnimationState.celebrating,
      ReviewStartedEvent()          => CharacterAnimationState.reviewing,
      ReviewCompletedEvent(score: var s, total: var t) =>
        (s / t >= 0.6) ? CharacterAnimationState.celebrating
                       : CharacterAnimationState.thinking,
      AchievementUnlockedEvent()    => CharacterAnimationState.achievement,
      StreakUpdatedEvent(newStreak: var n) =>
        (n % 7 == 0) ? CharacterAnimationState.celebrating
                     : CharacterAnimationState.idle,
      PlanCompletedEvent()          => CharacterAnimationState.celebrating,
      SurahCompletedEvent()         => CharacterAnimationState.celebrating,
      SyncCompletedEvent()          => CharacterAnimationState.syncing,
      WentOfflineEvent()            => CharacterAnimationState.offline,
      WentOnlineEvent()             => CharacterAnimationState.syncing,
      LoadingStartedEvent()         => CharacterAnimationState.loading,
      LoadingFinishedEvent()        => CharacterAnimationState.idle,
      LongAbsenceDetectedEvent()    => CharacterAnimationState.sad,
      KidsMissionCompletedEvent()   => CharacterAnimationState.kidsDancing,
      KidsModeChangedEvent()        => CharacterAnimationState.greeting,
      CharacterLevelUpEvent()       => CharacterAnimationState.achievement,
      OnboardingStepEvent()         => CharacterAnimationState.greeting,
    };
  }

  void dispose() {
    _subscription?.cancel();
  }
}

/// Immutable state update emitted by CharacterController.
class CharacterStateUpdate {
  const CharacterStateUpdate({
    required this.animationState,
    required this.emotion,
    this.dialogue,
    this.levelUp,
  });

  final CharacterAnimationState animationState;
  final CharacterEmotion emotion;
  final DialogueLine? dialogue;
  final CharacterLevel? levelUp;
}
```

---

## الخطوة 2.6 — ARB Dialogue Strings

### تعديل: `lib/core/l10n/app_ar.arb`

```json
"char_greetingMorning_0": "صباح الخير! هل أنتِ مستعدة لتلاوة اليوم؟",
"char_greetingMorning_1": "صباح النور! آمل أن يكون يومك مباركاً.",
"char_greetingMorning_2": "أهلاً بكِ في الصباح الباكر! القرآن ينتظر.",
"char_greetingAfternoon_0": "أهلاً! كيف كان يومك حتى الآن؟",
"char_greetingAfternoon_1": "مرحباً! وقت رائع للمراجعة.",
"char_greetingAfternoon_2": "أهلاً بعودتك! هيا نكمل.",
"char_greetingEvening_0": "مساء النور! وقت المراجعة المسائية.",
"char_greetingEvening_1": "مساء الخير! جاهزة لختام اليوم مع القرآن؟",
"char_greetingEvening_2": "يا مساء الورد! هيا نراجع معاً.",
"char_greetingNight_0": "السهرة مع القرآن — ما أجملها.",
"char_greetingNight_1": "هدوء الليل مع المصحف — وقت مميز.",
"char_greetingNight_2": "أهلاً! ليلة مباركة للقراءة.",
"char_returnShort_0": "اشتقت لكِ! هيا نكمل معاً.",
"char_returnShort_1": "أهلاً بعودتكِ! فاتنا وقت جميل.",
"char_returnShort_2": "رجعتِ! يلا نبدأ من حيث توقفنا.",
"char_returnLong_0": "أهلاً بعودتكِ. كل يوم جديد فرصة.",
"char_returnLong_1": "اشتقت لكِ كثيراً! لا بأس، هيا نبدأ من جديد.",
"char_returnLong_2": "مرحباً بعودتكِ! الخطوة الأولى هي الأهم.",
"char_readingStart_0": "خذي وقتكِ، أنا هنا معكِ.",
"char_readingStart_1": "قراءة ممتعة! أنا بجانبك.",
"char_readingStart_2": "بسم الله، هيا نبدأ.",
"char_memorizationStart_0": "ركّزي، كل آية خطوة إلى الأمام.",
"char_memorizationStart_1": "حفظ جديد! أنتِ قادرة.",
"char_memorizationStart_2": "بإذن الله، كل آية ستبقى في قلبكِ.",
"char_reviewShort_0": "مراجعة اليوم قصيرة، هيا ننهيها!",
"char_reviewShort_1": "مراجعة سريعة! يلا نبدأ.",
"char_reviewShort_2": "بضع آيات فقط، هيا بنا!",
"char_reviewLong_0": "مراجعة كبيرة اليوم، ثقي بنفسك!",
"char_reviewLong_1": "مراجعة طويلة! خذيها آية بآية.",
"char_reviewLong_2": "يوم مراجعة مهم — أنتِ جاهزة!",
"char_planCompleted_0": "أتممتِ خطة اليوم! ما شاء الله!",
"char_planCompleted_1": "خطة اليوم مكتملة! عمل رائع!",
"char_planCompleted_2": "أنهيتِ كل شيء اليوم! مبروك!",
"char_achievement_0": "ماشاء الله! لقد فتحتِ إنجازاً جديداً!",
"char_achievement_1": "إنجاز جديد! أنتِ رائعة!",
"char_achievement_2": "مبروك الإنجاز! استمري هكذا!",
"char_streakMilestone_0": "سبعة أيام متواصلة! استمري هكذا!",
"char_streakMilestone_1": "سلسلة رائعة! ما شاء الله عليكِ!",
"char_streakMilestone_2": "استمرار مذهل! كل يوم يقربكِ أكثر.",
"char_surahCompleted_0": "أكملتِ سورة كاملة! هذا إنجاز عظيم.",
"char_surahCompleted_1": "سورة كاملة! ما شاء الله!",
"char_surahCompleted_2": "أتممتِ سورة! فخورة بكِ!",
"char_loading_0": "جاري التحميل...",
"char_loading_1": "لحظة واحدة...",
"char_loading_2": "جاري التجهيز...",
"char_syncDone_0": "تمت المزامنة بنجاح!",
"char_syncDone_1": "كل شيء محدّث!",
"char_syncDone_2": "المزامنة اكتملت!",
"char_offline_0": "لا اتصال الآن، لكننا نعمل بلا إنترنت.",
"char_offline_1": "بدون اتصال — لا تقلقي، كل شيء محفوظ.",
"char_offline_2": "أوفلاين الآن، لكن كل شيء يعمل!",
"char_levelUp_0": "مبروك! وصلتِ لمستوى جديد!",
"char_levelUp_1": "ارتقيتِ! مستوى جديد!",
"char_levelUp_2": "ما شاء الله! مستوى أعلى!",
"char_kidsMission_0": "رائعة! أتممتِ المهمة!",
"char_kidsMission_1": "أحسنتِ! مهمة ناجحة!",
"char_kidsMission_2": "ممتازة! أكملتِ المهمة!",
"char_encouragement_0": "استمري، كل خطوة تُقرّبكِ.",
"char_encouragement_1": "أنتِ على الطريق الصحيح!",
"char_encouragement_2": "كل يوم أفضل من الذي قبله!"
```

### تعديل: `lib/core/l10n/app_en.arb`

> نفس المفاتيح بالإنجليزية — يتم إضافتها بنفس البنية.

---

## الخطوة 2.7 — Unit Tests

### الملفات المطلوبة:

```
test/features/character/
├── application/
│   ├── character_emotion_resolver_test.dart
│   ├── character_dialogue_engine_test.dart
│   ├── character_progression_engine_test.dart
│   └── character_scheduler_test.dart
└── domain/
    └── entities/
        └── character_level_test.dart
```

> كل engine يجب أن يكون له tests تغطي:
> - كل حالة في `switch`
> - Kids Mode amplification
> - Night time logic
> - Anti-repetition في Dialogue
> - XP thresholds و level-up detection
> - Scheduler cooldown و session lock

---

## الخطوة 2.8 — Verification

```bash
dart analyze
flutter test
flutter test test/features/character/
```

---

---

# المرحلة 3 — PNG Animation Layer (طبقة الرسوم)

> **الهدف:** توليد 9 صور PNG + بناء CharacterPngController + CharacterPngView.
> **المدة:** أسبوعان (بالتوازي مع المرحلة 2).
> **هذه المرحلة تعتمد على `Talia_Master_Character.png` كمرجع أساسي.**

---

## الخطوة 3.1 — توليد الصور بالذكاء الاصطناعي

### المرجع الأساسي: `assets/images/character/Talia_Master_Character.png`

### Prompt الأساسي لكل صورة:

```
"Same cartoon girl as reference image.
 Royal teal hijab with gold trim, Royal teal abaya
 with gold arabesque embroidery, warm brown eyes,
 holding a small teal-and-gold Mushaf.
 Transparent background. 3D cartoon style.
 [POSE-SPECIFIC INSTRUCTION]"
```

### الصور المطلوبة:

| # | الملف | التعليمات الخاصة بالوضعية |
|---|---|---|
| 1 | `talia_idle.png` | Standing relaxed, soft smile, Mushaf held with both hands in front |
| 2 | `talia_greeting.png` | Right arm raised in a warm friendly wave, bright gentle smile |
| 3 | `talia_reading.png` | Seated cross-legged on ground, Mushaf open in lap, gaze gently downward |
| 4 | `talia_memorizing.png` | Standing upright, eyes focused forward, attentive calm expression |
| 5 | `talia_thinking.png` | Standing, right hand lightly raised near chin, curious soft look |
| 6 | `talia_celebrating.png` | Both arms raised joyfully upward, big warm bright smile |
| 7 | `talia_sad.png` | Standing, soft downward gaze, slight gentle droop, calm but subdued |
| 8 | `talia_sleeping.png` | Standing, eyes peacefully closed, relaxed posture |
| 9 | `talia_night.png` | Same as idle but with a small decorative star-pin on left hijab side |

### المواصفات الثابتة:

- **الحجم:** 1200 × 1800 px
- **الخلفية:** شفافة تماماً
- **الهامش:** 40px safe zone
- **التحقق:** كل صورة يجب أن تطابق الصورة الرئيسية في: الوجه، لون الحجاب، التطريز الذهبي، المصحف

### الحفظ:

```
assets/images/character/talia_idle.png
assets/images/character/talia_greeting.png
assets/images/character/talia_reading.png
assets/images/character/talia_memorizing.png
assets/images/character/talia_thinking.png
assets/images/character/talia_celebrating.png
assets/images/character/talia_sad.png
assets/images/character/talia_sleeping.png
assets/images/character/talia_night.png
```

### تعديل `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/character/
```

---

## الخطوة 3.2 — Character PNG Controller

### ملف: `presentation/controllers/character_png_controller.dart`

```dart
import '../../domain/value_objects/character_animation_state.dart';
import '../../domain/value_objects/character_emotion.dart';

/// Maps CharacterAnimationState → PNG asset path + animation spec.
/// Pure controller — no Flutter widgets. flutter_animate is applied in the View.
class CharacterPngController {
  CharacterAnimationState _currentState = CharacterAnimationState.idle;
  CharacterEmotion _currentEmotion = CharacterEmotion.neutral;
  bool _isKidsMode = false;
  int _level = 1;
  bool enableReducedMotion = false;

  /// Resolve which PNG to display.
  String get poseAssetPath => resolvePoseAsset(_currentState, _level);

  /// Current animation spec for flutter_animate.
  AnimationSpec get animationSpec =>
      enableReducedMotion ? AnimationSpec.none : _resolveAnimationSpec();

  void applyState({
    required CharacterAnimationState state,
    CharacterEmotion emotion = CharacterEmotion.neutral,
    bool kidsMode = false,
    int level = 1,
  }) {
    _currentState = state;
    _currentEmotion = emotion;
    _isKidsMode = kidsMode;
    _level = level;
  }

  String resolvePoseAsset(CharacterAnimationState state, int level) {
    return switch (state) {
      CharacterAnimationState.idle        => _leveledAsset('talia_idle', level),
      CharacterAnimationState.greeting    => 'assets/images/character/talia_greeting.png',
      CharacterAnimationState.reading     => 'assets/images/character/talia_reading.png',
      CharacterAnimationState.memorizing  => 'assets/images/character/talia_memorizing.png',
      CharacterAnimationState.reviewing   => 'assets/images/character/talia_thinking.png',
      CharacterAnimationState.celebrating => 'assets/images/character/talia_celebrating.png',
      CharacterAnimationState.achievement => 'assets/images/character/talia_celebrating.png',
      CharacterAnimationState.thinking    => 'assets/images/character/talia_thinking.png',
      CharacterAnimationState.loading     => 'assets/images/character/talia_reading.png',
      CharacterAnimationState.waiting     => 'assets/images/character/talia_idle.png',
      CharacterAnimationState.sleeping    => 'assets/images/character/talia_sleeping.png',
      CharacterAnimationState.sad         => 'assets/images/character/talia_sad.png',
      CharacterAnimationState.offline     => 'assets/images/character/talia_idle.png',
      CharacterAnimationState.syncing     => 'assets/images/character/talia_greeting.png',
      CharacterAnimationState.kidsDancing => 'assets/images/character/talia_celebrating.png',
      CharacterAnimationState.kidsClapping => 'assets/images/character/talia_celebrating.png',
    };
  }

  String _leveledAsset(String base, int level) {
    if (level >= 2) return 'assets/images/character/${base}_l$level.png';
    return 'assets/images/character/$base.png';
  }

  AnimationSpec _resolveAnimationSpec() {
    final kidsFactor = _isKidsMode ? 1.5 : 1.0;
    final kidsDuration = _isKidsMode ? 0.7 : 1.0;

    return switch (_currentState) {
      CharacterAnimationState.idle =>
        _currentEmotion == CharacterEmotion.sleepy
            ? AnimationSpec(type: AnimationType.float, amplitude: 2 * kidsFactor, durationMs: (5000 * kidsDuration).toInt(), loops: -1)
            : AnimationSpec(type: AnimationType.float, amplitude: 4 * kidsFactor, durationMs: (3000 * kidsDuration).toInt(), loops: -1),
      CharacterAnimationState.greeting =>
        AnimationSpec(type: AnimationType.scaleBounce, amplitude: 1.05 * kidsFactor, durationMs: 600, loops: 1),
      CharacterAnimationState.reading =>
        AnimationSpec(type: AnimationType.float, amplitude: 2, durationMs: 4000, loops: -1),
      CharacterAnimationState.memorizing =>
        AnimationSpec(type: AnimationType.breathe, amplitude: 1.01, durationMs: 2000, loops: -1),
      CharacterAnimationState.reviewing ||
      CharacterAnimationState.thinking =>
        AnimationSpec(type: AnimationType.sway, amplitude: 2 * kidsFactor, durationMs: 3000, loops: -1),
      CharacterAnimationState.celebrating =>
        AnimationSpec(type: AnimationType.bounce, amplitude: 20 * kidsFactor, durationMs: (500 * kidsDuration).toInt(), loops: 3),
      CharacterAnimationState.achievement =>
        AnimationSpec(type: AnimationType.scalePulse, amplitude: 1.15 * kidsFactor, durationMs: 700, loops: 3),
      CharacterAnimationState.kidsDancing =>
        AnimationSpec(type: AnimationType.bounce, amplitude: 30, durationMs: 400, loops: 4),
      CharacterAnimationState.kidsClapping =>
        AnimationSpec(type: AnimationType.scalePulse, amplitude: 1.1, durationMs: 250, loops: 6),
      _ => AnimationSpec(type: AnimationType.float, amplitude: 4, durationMs: 3000, loops: -1),
    };
  }
}

/// Declarative animation spec — the View translates this to flutter_animate.
enum AnimationType { float, bounce, scaleBounce, scalePulse, breathe, sway, none }

class AnimationSpec {
  const AnimationSpec({
    required this.type,
    required this.amplitude,
    required this.durationMs,
    required this.loops,
  });

  static const none = AnimationSpec(type: AnimationType.none, amplitude: 0, durationMs: 0, loops: 0);

  final AnimationType type;
  final double amplitude;
  final int durationMs;          // -1 = infinite loop
  final int loops;
}
```

---

## الخطوة 3.3 — Verification

```bash
dart analyze
flutter test
```

---

---

# المرحلة 4 — Presentation (طبقة العرض)

> **الهدف:** بناء CharacterCubit + CharacterWidget + كل الـ sub-widgets.
> **المدة:** أسبوعان.

---

## الخطوة 4.1 — Character State

### ملف: `presentation/cubits/character_state.dart`

```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/character_level.dart';
import '../../domain/entities/dialogue_line.dart';
import '../../domain/value_objects/character_animation_state.dart';
import '../../domain/value_objects/character_emotion.dart';

sealed class CharacterState extends Equatable {
  const CharacterState();
}

class CharacterInitial extends CharacterState {
  const CharacterInitial();
  @override
  List<Object?> get props => [];
}

class CharacterVisible extends CharacterState {
  const CharacterVisible({
    required this.animationState,
    required this.emotion,
    required this.level,
    required this.isKidsMode,
    this.activeLine,
    this.showLevelBadge = false,
  });

  final CharacterAnimationState animationState;
  final CharacterEmotion emotion;
  final CharacterLevel level;
  final bool isKidsMode;
  final DialogueLine? activeLine;
  final bool showLevelBadge;

  @override
  List<Object?> get props => [animationState, emotion, level, activeLine, showLevelBadge, isKidsMode];
}

class CharacterHidden extends CharacterState {
  const CharacterHidden();
  @override
  List<Object?> get props => [];
}

class CharacterReducedMotion extends CharacterState {
  const CharacterReducedMotion({required this.emotion});
  final CharacterEmotion emotion;
  @override
  List<Object?> get props => [emotion];
}
```

---

## الخطوة 4.2 — Character Cubit

### ملف: `presentation/cubits/character_cubit.dart`

> يتبع نفس pattern `KidsModeCubit` — Factory في DI.

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/character_controller.dart';
import '../../domain/entities/character_level.dart';
import '../../domain/value_objects/character_animation_state.dart';
import '../../domain/value_objects/character_emotion.dart';
import 'character_state.dart';

class CharacterCubit extends Cubit<CharacterState> {
  CharacterCubit({
    required CharacterController controller,
  })  : _controller = controller,
        super(const CharacterInitial()) {
    _controller.onStateUpdate = _onUpdate;
    _controller.start();
  }

  final CharacterController _controller;

  void _onUpdate(CharacterStateUpdate update) {
    emit(CharacterVisible(
      animationState: update.animationState,
      emotion: update.emotion,
      level: update.levelUp ?? CharacterLevel.all.first,
      isKidsMode: false,   // pulled from KidsModeCubit in full wiring
      activeLine: update.dialogue,
      showLevelBadge: update.levelUp != null,
    ));
  }

  /// Pre-warm critical images after scaffold is mounted.
  void prewarmImages(BuildContext context) {
    precacheImage(const AssetImage('assets/images/character/talia_idle.png'), context);
    precacheImage(const AssetImage('assets/images/character/talia_greeting.png'), context);
  }

  void dismissDialogue() {
    final current = state;
    if (current is CharacterVisible && current.activeLine != null) {
      emit(CharacterVisible(
        animationState: current.animationState,
        emotion: current.emotion,
        level: current.level,
        isKidsMode: current.isKidsMode,
        activeLine: null,
        showLevelBadge: false,
      ));
    }
  }

  void setEnabled(bool enabled) {
    if (!enabled) emit(const CharacterHidden());
  }

  @override
  Future<void> close() {
    _controller.dispose();
    return super.close();
  }
}
```

---

## الخطوة 4.3 — Character Widget

### ملف: `presentation/widgets/character_widget.dart`

> The top-level composable. Wraps everything in `RepaintBoundary` + `BlocBuilder`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/character_cubit.dart';
import '../cubits/character_state.dart';
import 'character_dialogue_bubble.dart';
import 'character_particle_layer.dart';
import 'character_png_view.dart';
import 'character_progression_badge.dart';

class CharacterWidget extends StatelessWidget {
  const CharacterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BlocBuilder<CharacterCubit, CharacterState>(
        builder: (context, state) => switch (state) {
          CharacterInitial()      => const SizedBox.shrink(),
          CharacterHidden()       => const SizedBox.shrink(),
          CharacterReducedMotion(emotion: var e) =>
            _buildStatic(context, e),
          CharacterVisible()      => _buildAnimated(context, state),
        },
      ),
    );
  }

  Widget _buildAnimated(BuildContext context, CharacterVisible state) {
    return GestureDetector(
      onTap: () => context.read<CharacterCubit>().dismissDialogue(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CharacterPngView(
            animationState: state.animationState,
            emotion: state.emotion,
            isKidsMode: state.isKidsMode,
            level: state.level.level,
          ),
          CharacterParticleLayer(animationState: state.animationState),
          if (state.activeLine != null)
            CharacterDialogueBubble(
              dialogueLine: state.activeLine!,
              isKidsMode: state.isKidsMode,
            ),
          if (state.showLevelBadge)
            CharacterProgressionBadge(level: state.level),
        ],
      ),
    );
  }

  Widget _buildStatic(BuildContext context, CharacterEmotion emotion) {
    return Semantics(
      label: 'تالية — رفيقتك في الحفظ',
      excludeSemantics: true,
      child: Image.asset('assets/images/character/talia_idle.png'),
    );
  }
}
```

---

## الخطوة 4.4 — Character PNG View

### ملف: `presentation/widgets/character_png_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/value_objects/character_animation_state.dart';
import '../../domain/value_objects/character_emotion.dart';
import '../controllers/character_png_controller.dart';

class CharacterPngView extends StatefulWidget {
  const CharacterPngView({
    super.key,
    required this.animationState,
    required this.emotion,
    required this.isKidsMode,
    required this.level,
  });

  final CharacterAnimationState animationState;
  final CharacterEmotion emotion;
  final bool isKidsMode;
  final int level;

  @override
  State<CharacterPngView> createState() => _CharacterPngViewState();
}

class _CharacterPngViewState extends State<CharacterPngView> {
  final _controller = CharacterPngController();

  @override
  void didUpdateWidget(CharacterPngView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.applyState(
      state: widget.animationState,
      emotion: widget.emotion,
      kidsMode: widget.isKidsMode,
      level: widget.level,
    );
  }

  @override
  Widget build(BuildContext context) {
    _controller.applyState(
      state: widget.animationState,
      emotion: widget.emotion,
      kidsMode: widget.isKidsMode,
      level: widget.level,
    );

    final assetPath = _controller.poseAssetPath;
    final spec = _controller.animationSpec;

    return Semantics(
      label: 'تالية — رفيقتك في الحفظ',
      excludeSemantics: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        ),
        child: _buildAnimatedPose(assetPath, spec),
      ),
    );
  }

  Widget _buildAnimatedPose(String assetPath, AnimationSpec spec) {
    Widget image = Image.asset(
      assetPath,
      key: ValueKey(assetPath),
      filterQuality: FilterQuality.medium,
    );

    if (spec.type == AnimationType.none) return image;

    // Apply flutter_animate chain based on spec type
    return switch (spec.type) {
      AnimationType.float => image
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -spec.amplitude, end: spec.amplitude,
                 duration: Duration(milliseconds: spec.durationMs),
                 curve: Curves.easeInOut),
      AnimationType.bounce => image
          .animate(onPlay: (c) => c.repeat(count: spec.loops))
          .moveY(begin: 0, end: -spec.amplitude,
                 duration: Duration(milliseconds: spec.durationMs),
                 curve: Curves.easeOut)
          .then()
          .moveY(begin: -spec.amplitude, end: 0,
                 duration: Duration(milliseconds: spec.durationMs),
                 curve: Curves.bounceOut),
      AnimationType.scaleBounce => image
          .animate()
          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.05, 1.05),
                 duration: Duration(milliseconds: spec.durationMs ~/ 2),
                 curve: Curves.easeOut)
          .then()
          .scale(begin: const Offset(1.05, 1.05), end: const Offset(1.0, 1.0),
                 duration: Duration(milliseconds: spec.durationMs ~/ 2),
                 curve: Curves.easeIn),
      AnimationType.scalePulse => image
          .animate(onPlay: (c) => c.repeat(count: spec.loops, reverse: true))
          .scale(begin: const Offset(1.0, 1.0), end: Offset(spec.amplitude, spec.amplitude),
                 duration: Duration(milliseconds: spec.durationMs),
                 curve: Curves.easeInOut),
      AnimationType.breathe => image
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: Offset(0.99, 0.99), end: Offset(spec.amplitude, spec.amplitude),
                 duration: Duration(milliseconds: spec.durationMs),
                 curve: Curves.easeInOut),
      AnimationType.sway => image
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .rotate(begin: -spec.amplitude / 100, end: spec.amplitude / 100,
                  duration: Duration(milliseconds: spec.durationMs),
                  curve: Curves.easeInOut),
      _ => image,
    };
  }
}
```

---

## الخطوات 4.5–4.7 — باقي Widgets

> يتم بناء `CharacterDialogueBubble`, `CharacterParticleLayer`, `CharacterProgressionBadge` بنفس الأنماط. التفاصيل في Blueprint §6.3.

---

## الخطوة 4.8 — DI Registration (Cubits)

### تعديل: `lib/core/di/injection.dart`

```dart
// ─── 4. Core Services ────────────────────────────────────────────────────────
getIt.registerLazySingleton(() => CharacterScheduler());
getIt.registerLazySingleton(() => const CharacterEmotionResolver());
getIt.registerLazySingleton(() => CharacterDialogueEngine());
getIt.registerLazySingleton(() => const CharacterProgressionEngine());
getIt.registerLazySingleton(() => CharacterController(
  eventBus: getIt(),
  scheduler: getIt(),
  emotionResolver: getIt(),
  dialogueEngine: getIt(),
  progressionEngine: getIt(),
  repository: getIt(),
));

// ─── 7. Cubits ───────────────────────────────────────────────────────────────
getIt.registerFactory(() => CharacterCubit(controller: getIt()));
```

---

## الخطوة 4.9 — Verification

```bash
dart analyze
flutter test
flutter run  # تأكد يدوياً أن الشخصية تظهر بدون أخطاء
```

---

---

# المرحلة 5 — Integration (الربط)

> **الهدف:** ربط كل feature بالـ CharacterEventBus.
> **المدة:** أسبوع واحد.

---

## الخطوة 5.1 — Fire Events from Features

> كل feature يضيف سطرين فقط: import + fire.

```dart
// أي feature — import هذين الملفين فقط:
import 'package:talia_quran/features/character/application/character_event_bus.dart';
import 'package:talia_quran/features/character/domain/value_objects/character_event.dart';

// ثم:
sl<CharacterEventBus>().fire(AppOpenedEvent());
```

### أماكن الربط:

| Feature | الملف | الحدث |
|---|---|---|
| Home | `HomeCubit.init()` | `AppOpenedEvent()` |
| Quran | `QuranPageCubit` | `ReadingStartedEvent`, `ReadingFinishedEvent` |
| Memorization | `MemorizationSessionCubit` | `MemorizationStartedEvent`, `MemorizationCompletedEvent` |
| Review | `MemorizationSessionCubit` | `ReviewStartedEvent`, `ReviewCompletedEvent` |
| Achievements | `AchievementService` | `AchievementUnlockedEvent` |
| Streaks | `StreakService` | `StreakUpdatedEvent` |
| Smart Coach | `SmartCoachEngine` | `PlanCompletedEvent` |
| Onboarding | `OnboardingCubit` | `OnboardingStepEvent` |
| Router | Loading overlay | `LoadingStartedEvent`, `LoadingFinishedEvent` |
| Kids | `KidsJourneyCubit` | `KidsMissionCompletedEvent` |
| App Session | `AppLifecycleObserver` | `LongAbsenceDetectedEvent` |

---

## الخطوة 5.2 — Home Screen: Place CharacterWidget

```dart
// في HomeScreen build — داخل Stack:
BlocProvider(
  create: (_) => sl<CharacterCubit>()..prewarmImages(context),
  child: const Positioned(
    bottom: 0,
    right: 0,           // adult
    // bottom: 0, center for kids
    child: SizedBox(
      height: MediaQuery.of(context).size.height * 0.22,
      child: CharacterWidget(),
    ),
  ),
),
```

---

## الخطوة 5.3 — Settings Toggles

```dart
// في Settings screen:
SwitchListTile(
  title: Text('إظهار تالية'),
  value: characterEnabled,
  onChanged: (v) => context.read<CharacterCubit>().setEnabled(v),
),
SwitchListTile(
  title: Text('حوارات تالية'),
  value: dialogueEnabled,
  onChanged: (v) => context.read<CharacterCubit>().setDialogueEnabled(v),
),
```

---

## الخطوة 5.4 — Verification

```bash
dart analyze
flutter test
flutter run  # اختبار يدوي شامل لكل سيناريو
```

---

---

# المرحلة 6 — Polish & QA (التلميع والاختبار)

> **المدة:** أسبوع واحد.

---

## قائمة الفحص:

- [ ] `disableAnimations = true` → تظهر صورة ثابتة فقط (لا animations)
- [ ] `Semantics` wrapper على كل widget
- [ ] البطارية < 20% → الـ animation يتوقف
- [ ] App backgrounded → ticker يتوقف
- [ ] App foregrounded → ticker يستأنف
- [ ] Adult mode: animation هادئ، dialogue بالعربي
- [ ] Kids mode: animation مُكثّف، bounce أقوى، confetti
- [ ] Night mode (21:00-05:00): `talia_night.png` + `SLEEPY` emotion
- [ ] Offline mode: `talia_idle.png` + رسالة offline
- [ ] Level-up flow: ACHIEVEMENT state → badge → dialogue → idle
- [ ] 60-second cooldown يعمل
- [ ] Session lock يعمل (لا dialogue أثناء القراءة/الحفظ/المراجعة)
- [ ] Anti-repetition: نفس الرسالة لا تتكرر مباشرة

---

---

# المرحلة 7 — Rive Upgrade (v2 — مستقبلي)

> **هذه المرحلة مستقلة تماماً. تبدأ فقط عند جاهزية ملف Rive.**

## الخطوات:

1. Commission `assets/rive/talia_main.riv`
2. إنشاء `CharacterRiveView` — نفس interface `CharacterPngView`
3. إنشاء `CharacterRiveController` — نفس `applyState()` signature
4. إضافة `rive: ^0.13.x` في `pubspec.yaml`
5. إضافة feature flag في `character_config.dart`:
   ```dart
   const kUseRiveAnimation = true;  // toggle
   ```
6. QA validation
7. إزالة PNG fallback بعد التأكد

> **صفر تغييرات في:** domain, application, cubits, dialogue engine, scheduler, أي feature integration code.

---

---

# ملخص التبعيات

| المرحلة | تعتمد على |
|---|---|
| Phase 1 (Foundation) | لا شيء — مستقلة |
| Phase 2 (Logic) | Phase 1 |
| Phase 3 (PNG) | مستقلة — بالتوازي مع Phase 2 |
| Phase 4 (Presentation) | Phase 1 + 2 + 3 |
| Phase 5 (Integration) | Phase 4 |
| Phase 6 (QA) | Phase 5 |
| Phase 7 (Rive v2) | Phase 6 + Rive assets |

---

# الجدول الزمني

```
Week 1-2  ███████████████  Phase 1: Foundation
Week 3-4  ███████████████  Phase 2: Logic Layer
Week 3-4  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  Phase 3: PNG (parallel)
Week 5-6  ███████████████  Phase 4: Presentation
Week 7    ████████         Phase 5: Integration
Week 8    ████████         Phase 6: QA
Future    ░░░░░░░░░░░░░░░  Phase 7: Rive v2
```

**v1 Total: ~9 أسابيع**
