import '../../domain/entities/memorization_entities.dart';

// ─── AyahReviewRecordModel ────────────────────────────────────────────────────

class AyahReviewRecordModel extends AyahReviewRecord {
  const AyahReviewRecordModel({
    required super.surahId,
    required super.ayahNumber,
    required super.strengthLevel,
    required super.intervalDays,
    required super.lastReviewedAt,
    required super.nextReviewDate,
    required super.totalReviews,
    required super.lastRating,
  });

  factory AyahReviewRecordModel.initial(int surahId, int ayahNumber) {
    final now = DateTime.now();
    return AyahReviewRecordModel(
      surahId: surahId,
      ayahNumber: ayahNumber,
      strengthLevel: 0,
      intervalDays: 0,
      lastReviewedAt: now,
      nextReviewDate: now,
      totalReviews: 0,
      lastRating: null,
    );
  }

  factory AyahReviewRecordModel.fromJson(Map<String, dynamic> json) {
    final ratingIndex = json['lastRating'] as int?;
    return AyahReviewRecordModel(
      surahId: json['surahId'] as int,
      ayahNumber: json['ayahNumber'] as int,
      strengthLevel: json['strengthLevel'] as int,
      intervalDays: json['intervalDays'] as int,
      lastReviewedAt: DateTime.parse(json['lastReviewedAt'] as String),
      nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
      totalReviews: json['totalReviews'] as int,
      lastRating: ratingIndex != null
          ? PerformanceRating.values[ratingIndex]
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'surahId': surahId,
    'ayahNumber': ayahNumber,
    'strengthLevel': strengthLevel,
    'intervalDays': intervalDays,
    'lastReviewedAt': lastReviewedAt.toIso8601String(),
    'nextReviewDate': nextReviewDate.toIso8601String(),
    'totalReviews': totalReviews,
    'lastRating': lastRating?.index,
  };

  /// Promote from domain entity
  factory AyahReviewRecordModel.fromEntity(AyahReviewRecord r) =>
      AyahReviewRecordModel(
        surahId: r.surahId,
        ayahNumber: r.ayahNumber,
        strengthLevel: r.strengthLevel,
        intervalDays: r.intervalDays,
        lastReviewedAt: r.lastReviewedAt,
        nextReviewDate: r.nextReviewDate,
        totalReviews: r.totalReviews,
        lastRating: r.lastRating,
      );
}

// ─── KidsProgressModel ────────────────────────────────────────────────────────

class KidsProgressModel extends KidsProgress {
  const KidsProgressModel({
    required super.totalPoints,
    required super.currentLevel,
    required super.currentStreak,
    required super.starsEarned,
    required super.ayahsCompleted,
    required super.lastSessionAt,
  });

  const KidsProgressModel.empty()
    : super(
        totalPoints: 0,
        currentLevel: 1,
        currentStreak: 0,
        starsEarned: 0,
        ayahsCompleted: 0,
        lastSessionAt: null,
      );

  factory KidsProgressModel.fromJson(Map<String, dynamic> json) {
    final lastSession = json['lastSessionAt'] as String?;
    return KidsProgressModel(
      totalPoints: json['totalPoints'] as int,
      currentLevel: json['currentLevel'] as int,
      currentStreak: json['currentStreak'] as int,
      starsEarned: json['starsEarned'] as int,
      ayahsCompleted: json['ayahsCompleted'] as int,
      lastSessionAt: lastSession != null ? DateTime.parse(lastSession) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalPoints': totalPoints,
    'currentLevel': currentLevel,
    'currentStreak': currentStreak,
    'starsEarned': starsEarned,
    'ayahsCompleted': ayahsCompleted,
    'lastSessionAt': lastSessionAt?.toIso8601String(),
  };

  factory KidsProgressModel.fromEntity(KidsProgress p) => KidsProgressModel(
    totalPoints: p.totalPoints,
    currentLevel: p.currentLevel,
    currentStreak: p.currentStreak,
    starsEarned: p.starsEarned,
    ayahsCompleted: p.ayahsCompleted,
    lastSessionAt: p.lastSessionAt,
  );
}

class KidsSessionLogModel extends KidsSessionLog {
  const KidsSessionLogModel({
    required super.id,
    required super.surahId,
    required super.ayahNumber,
    required super.repeatsCompleted,
    required super.pointsEarned,
    required super.completedAt,
    super.syncedAt,
  });

  factory KidsSessionLogModel.fromJson(Map<String, dynamic> json) =>
      KidsSessionLogModel(
        id: json['id'] as String,
        surahId: json['surahId'] as int,
        ayahNumber: json['ayahNumber'] as int,
        repeatsCompleted: json['repeatsCompleted'] as int,
        pointsEarned: json['pointsEarned'] as int,
        completedAt: DateTime.parse(json['completedAt'] as String),
        syncedAt: json['syncedAt'] == null
            ? null
            : DateTime.parse(json['syncedAt'] as String),
      );

  factory KidsSessionLogModel.fromEntity(KidsSessionLog log) =>
      KidsSessionLogModel(
        id: log.id,
        surahId: log.surahId,
        ayahNumber: log.ayahNumber,
        repeatsCompleted: log.repeatsCompleted,
        pointsEarned: log.pointsEarned,
        completedAt: log.completedAt,
        syncedAt: log.syncedAt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'surahId': surahId,
    'ayahNumber': ayahNumber,
    'repeatsCompleted': repeatsCompleted,
    'pointsEarned': pointsEarned,
    'completedAt': completedAt.toIso8601String(),
    'syncedAt': syncedAt?.toIso8601String(),
  };
}

class ParentSettingsModel extends ParentSettings {
  const ParentSettingsModel({
    super.pinHash,
    super.reminderEnabled,
    super.reminderHour,
    super.reminderMinute,
    super.weeklyGoalSessions,
    super.remoteLinkEnabled,
  });

  const ParentSettingsModel.defaults() : super();

  factory ParentSettingsModel.fromJson(Map<String, dynamic> json) =>
      ParentSettingsModel(
        pinHash: json['pinHash'] as String?,
        reminderEnabled: json['reminderEnabled'] as bool? ?? true,
        reminderHour: json['reminderHour'] as int? ?? 18,
        reminderMinute: json['reminderMinute'] as int? ?? 30,
        weeklyGoalSessions: json['weeklyGoalSessions'] as int? ?? 5,
        remoteLinkEnabled: json['remoteLinkEnabled'] as bool? ?? false,
      );

  factory ParentSettingsModel.fromEntity(ParentSettings settings) =>
      ParentSettingsModel(
        pinHash: settings.pinHash,
        reminderEnabled: settings.reminderEnabled,
        reminderHour: settings.reminderHour,
        reminderMinute: settings.reminderMinute,
        weeklyGoalSessions: settings.weeklyGoalSessions,
        remoteLinkEnabled: settings.remoteLinkEnabled,
      );

  Map<String, dynamic> toJson() => {
    'pinHash': pinHash,
    'reminderEnabled': reminderEnabled,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'weeklyGoalSessions': weeklyGoalSessions,
    'remoteLinkEnabled': remoteLinkEnabled,
  };
}

class ParentRewardModel extends ParentReward {
  const ParentRewardModel({
    required super.id,
    required super.title,
    required super.status,
    required super.createdAt,
    super.unlockedAt,
    super.claimedAt,
  });

  factory ParentRewardModel.fromJson(Map<String, dynamic> json) =>
      ParentRewardModel(
        id: json['id'] as String,
        title: json['title'] as String,
        status: ParentRewardStatus.values[json['status'] as int],
        createdAt: DateTime.parse(json['createdAt'] as String),
        unlockedAt: json['unlockedAt'] == null
            ? null
            : DateTime.parse(json['unlockedAt'] as String),
        claimedAt: json['claimedAt'] == null
            ? null
            : DateTime.parse(json['claimedAt'] as String),
      );

  factory ParentRewardModel.fromEntity(ParentReward reward) =>
      ParentRewardModel(
        id: reward.id,
        title: reward.title,
        status: reward.status,
        createdAt: reward.createdAt,
        unlockedAt: reward.unlockedAt,
        claimedAt: reward.claimedAt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status.index,
    'createdAt': createdAt.toIso8601String(),
    'unlockedAt': unlockedAt?.toIso8601String(),
    'claimedAt': claimedAt?.toIso8601String(),
  };
}

// ─── DailyPlanModel (cached) ──────────────────────────────────────────────────

class DailyPlanModel extends DailyPlan {
  const DailyPlanModel({
    required super.generatedAt,
    required super.surahId,
    required super.newAyahs,
    required super.nearRevision,
    required super.farRevision,
    required super.completedAyahNums,
  });

  factory DailyPlanModel.fromJson(Map<String, dynamic> json) {
    List<DailyPlanAyah> parseList(List<dynamic> raw) => raw
        .map(
          (e) => DailyPlanAyah(
            surahId: e['surahId'] as int,
            ayahNumber: e['ayahNumber'] as int,
            ayahText: e['ayahText'] as String? ?? '...',
            record: null, // Records fetched live; not stored in cache
          ),
        )
        .toList();

    return DailyPlanModel(
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      surahId: json['surahId'] as int,
      newAyahs: parseList(json['newAyahs'] as List<dynamic>),
      nearRevision: parseList(json['nearRevision'] as List<dynamic>),
      farRevision: parseList(json['farRevision'] as List<dynamic>),
      completedAyahNums: (json['completedAyahNums'] as List<dynamic>)
          .cast<int>(),
    );
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> toList(List<DailyPlanAyah> list) => list
        .map(
          (a) => {
            'surahId': a.surahId,
            'ayahNumber': a.ayahNumber,
            'ayahText': a.ayahText,
          },
        )
        .toList();

    return {
      'generatedAt': generatedAt.toIso8601String(),
      'surahId': surahId,
      'newAyahs': toList(newAyahs),
      'nearRevision': toList(nearRevision),
      'farRevision': toList(farRevision),
      'completedAyahNums': completedAyahNums,
    };
  }

  factory DailyPlanModel.fromEntity(DailyPlan p) => DailyPlanModel(
    generatedAt: p.generatedAt,
    surahId: p.surahId,
    newAyahs: p.newAyahs,
    nearRevision: p.nearRevision,
    farRevision: p.farRevision,
    completedAyahNums: p.completedAyahNums,
  );
}

// ─── CustomMemorizationPlanModel ──────────────────────────────────────────────

class CustomMemorizationPlanModel extends CustomMemorizationPlan {
  const CustomMemorizationPlanModel({
    required super.name,
    required super.startSurahId,
    required super.endSurahId,
    required super.newAyahsPerDay,
    required super.availableDaysPerWeek,
    required super.sessionMinutes,
    required super.difficulty,
    required super.enableNearRevision,
    required super.enableFarRevision,
    required super.nearRevisionCount,
    required super.farRevisionCount,
    required super.startAyah,
    required super.createdAt,
    super.isActive = true,
  });

  factory CustomMemorizationPlanModel.fromJson(Map<String, dynamic> json) =>
      CustomMemorizationPlanModel(
        name: json['name'] as String,
        startSurahId: json['startSurahId'] as int,
        endSurahId: json['endSurahId'] as int,
        newAyahsPerDay: json['newAyahsPerDay'] as int,
        availableDaysPerWeek: json['availableDaysPerWeek'] as int,
        sessionMinutes: json['sessionMinutes'] as int,
        difficulty: MemorizationDifficulty.values[json['difficulty'] as int],
        enableNearRevision: json['enableNearRevision'] as bool,
        enableFarRevision: json['enableFarRevision'] as bool,
        nearRevisionCount: json['nearRevisionCount'] as int,
        farRevisionCount: json['farRevisionCount'] as int,
        startAyah: json['startAyah'] as int? ?? 1,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isActive: json['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'startSurahId': startSurahId,
    'endSurahId': endSurahId,
    'newAyahsPerDay': newAyahsPerDay,
    'availableDaysPerWeek': availableDaysPerWeek,
    'sessionMinutes': sessionMinutes,
    'difficulty': difficulty.index,
    'enableNearRevision': enableNearRevision,
    'enableFarRevision': enableFarRevision,
    'nearRevisionCount': nearRevisionCount,
    'farRevisionCount': farRevisionCount,
    'startAyah': startAyah,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
  };

  factory CustomMemorizationPlanModel.fromEntity(CustomMemorizationPlan p) =>
      CustomMemorizationPlanModel(
        name: p.name,
        startSurahId: p.startSurahId,
        endSurahId: p.endSurahId,
        newAyahsPerDay: p.newAyahsPerDay,
        availableDaysPerWeek: p.availableDaysPerWeek,
        sessionMinutes: p.sessionMinutes,
        difficulty: p.difficulty,
        enableNearRevision: p.enableNearRevision,
        enableFarRevision: p.enableFarRevision,
        nearRevisionCount: p.nearRevisionCount,
        farRevisionCount: p.farRevisionCount,
        startAyah: p.startAyah,
        createdAt: p.createdAt,
        isActive: p.isActive,
      );
}
