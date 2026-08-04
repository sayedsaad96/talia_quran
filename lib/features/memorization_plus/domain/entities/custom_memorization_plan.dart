import 'package:equatable/equatable.dart';

enum PlanTargetUser { adult, child }

// ─── CustomMemorizationPlan ───────────────────────────────────────────────────

/// Difficulty level affects the spaced repetition multiplier.
enum MemorizationDifficulty { easy, moderate, challenging }

/// A user-defined memorization plan with all scheduling parameters.
class CustomMemorizationPlan extends Equatable {
  const CustomMemorizationPlan({
    required this.name,
    required this.startSurahId,
    required this.endSurahId,
    required this.newAyahsPerDay,
    required this.availableDaysPerWeek,
    required this.sessionMinutes,
    required this.difficulty,
    required this.enableNearRevision,
    required this.enableFarRevision,
    required this.nearRevisionCount,
    required this.farRevisionCount,
    required this.startAyah,
    required this.createdAt,
    this.isActive = true,
    this.targetUser = PlanTargetUser.adult,
  });

  /// User-given plan name, e.g. "خطتي لحفظ جزء عمّ"
  final String name;

  /// Surah range (inclusive)
  final int startSurahId;
  final int endSurahId;

  /// Starting ayah inside [startSurahId] (1-based)
  final int startAyah;

  /// How many new ayahs to introduce each session
  final int newAyahsPerDay;

  /// How many days per week the user can dedicate
  final int availableDaysPerWeek;

  /// Ideal session duration in minutes
  final int sessionMinutes;

  /// Affects review interval multiplier
  final MemorizationDifficulty difficulty;

  /// Whether to include near-revision and far-revision sections
  final bool enableNearRevision;
  final bool enableFarRevision;

  /// Max ayahs to include in each revision section
  final int nearRevisionCount;
  final int farRevisionCount;

  final DateTime createdAt;
  final bool isActive;
  final PlanTargetUser targetUser;

  bool get isForChild => targetUser == PlanTargetUser.child;

  /// Estimated days to finish based on **actual** surah ayah counts.
  /// Works for both ascending (startSurahId < endSurahId) and descending plans.
  int get estimatedDays {
    int totalAyahs = 0;
    final lo = startSurahId <= endSurahId ? startSurahId : endSurahId;
    final hi = startSurahId <= endSurahId ? endSurahId : startSurahId;
    for (int s = lo; s <= hi; s++) {
      totalAyahs += _surahAyahCounts[s] ?? 20;
    }
    // Subtract ayahs before startAyah in the first memorized surah (startSurahId)
    if (startAyah > 1) {
      totalAyahs -= (startAyah - 1);
    }
    if (newAyahsPerDay == 0) return 0;
    final sessionsNeeded = (totalAyahs / newAyahsPerDay).ceil();
    return (sessionsNeeded / (availableDaysPerWeek / 7.0)).ceil();
  }

  // RISK-4 FIX: actual ayah counts for all 114 surahs
  static const Map<int, int> _surahAyahCounts = {
    1: 7,
    2: 286,
    3: 200,
    4: 176,
    5: 120,
    6: 165,
    7: 206,
    8: 75,
    9: 129,
    10: 109,
    11: 123,
    12: 111,
    13: 43,
    14: 52,
    15: 99,
    16: 128,
    17: 111,
    18: 110,
    19: 98,
    20: 135,
    21: 112,
    22: 78,
    23: 118,
    24: 64,
    25: 77,
    26: 227,
    27: 93,
    28: 88,
    29: 69,
    30: 60,
    31: 34,
    32: 30,
    33: 73,
    34: 54,
    35: 45,
    36: 83,
    37: 182,
    38: 88,
    39: 75,
    40: 85,
    41: 54,
    42: 53,
    43: 89,
    44: 59,
    45: 37,
    46: 35,
    47: 38,
    48: 29,
    49: 18,
    50: 45,
    51: 60,
    52: 49,
    53: 62,
    54: 55,
    55: 78,
    56: 96,
    57: 29,
    58: 22,
    59: 24,
    60: 13,
    61: 14,
    62: 11,
    63: 11,
    64: 18,
    65: 12,
    66: 12,
    67: 30,
    68: 52,
    69: 52,
    70: 44,
    71: 28,
    72: 28,
    73: 20,
    74: 56,
    75: 40,
    76: 31,
    77: 50,
    78: 40,
    79: 46,
    80: 42,
    81: 29,
    82: 19,
    83: 36,
    84: 25,
    85: 22,
    86: 17,
    87: 19,
    88: 26,
    89: 30,
    90: 20,
    91: 15,
    92: 21,
    93: 11,
    94: 8,
    95: 8,
    96: 19,
    97: 5,
    98: 8,
    99: 8,
    100: 11,
    101: 11,
    102: 8,
    103: 3,
    104: 9,
    105: 5,
    106: 4,
    107: 7,
    108: 3,
    109: 6,
    110: 3,
    111: 5,
    112: 4,
    113: 5,
    114: 6,
  };

  CustomMemorizationPlan copyWith({
    String? name,
    int? startSurahId,
    int? endSurahId,
    int? newAyahsPerDay,
    int? availableDaysPerWeek,
    int? sessionMinutes,
    MemorizationDifficulty? difficulty,
    bool? enableNearRevision,
    bool? enableFarRevision,
    int? nearRevisionCount,
    int? farRevisionCount,
    int? startAyah,
    DateTime? createdAt,
    bool? isActive,
    PlanTargetUser? targetUser,
  }) => CustomMemorizationPlan(
    name: name ?? this.name,
    startSurahId: startSurahId ?? this.startSurahId,
    endSurahId: endSurahId ?? this.endSurahId,
    newAyahsPerDay: newAyahsPerDay ?? this.newAyahsPerDay,
    availableDaysPerWeek: availableDaysPerWeek ?? this.availableDaysPerWeek,
    sessionMinutes: sessionMinutes ?? this.sessionMinutes,
    difficulty: difficulty ?? this.difficulty,
    enableNearRevision: enableNearRevision ?? this.enableNearRevision,
    enableFarRevision: enableFarRevision ?? this.enableFarRevision,
    nearRevisionCount: nearRevisionCount ?? this.nearRevisionCount,
    farRevisionCount: farRevisionCount ?? this.farRevisionCount,
    startAyah: startAyah ?? this.startAyah,
    createdAt: createdAt ?? this.createdAt,
    isActive: isActive ?? this.isActive,
    targetUser: targetUser ?? this.targetUser,
  );

  @override
  List<Object?> get props => [
    name,
    startSurahId,
    endSurahId,
    newAyahsPerDay,
    availableDaysPerWeek,
    sessionMinutes,
    difficulty,
    enableNearRevision,
    enableFarRevision,
    nearRevisionCount,
    farRevisionCount,
    startAyah,
    createdAt,
    isActive,
    targetUser,
  ];
}
