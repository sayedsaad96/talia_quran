import 'khatmah_dedication_model.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_reading_result.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';

class KhatmahPlanModel {
  KhatmahPlanModel({
    required this.id,
    required this.title,
    this.startPage = 1,
    Iterable<int>? completedPages,
    required this.targetPagesPerDay,
    required this.targetDays,
    required this.startDate,
    required this.expectedEndDate,
    this.status = 'active',
    required this.dedication,
    this.lastReadDate,
    this.dailyTargetDate,
    this.dailyTargetStartPage,
    this.dailyTargetEndPage,
    this.pausedAt,
    this.wirdUnit = 'pages',
    this.portionsPerDay = 1,
    this.seasonLink,
  }) : completedPages = Set.unmodifiable(
         _normalizeCompletedPages(completedPages ?? const <int>{}),
       ),
       currentPage = _highestContiguousPage(
         _normalizeCompletedPages(completedPages ?? const <int>{}),
       );

  final String id;
  final String title;
  final int startPage;
  final int currentPage;
  final Set<int> completedPages;
  final int targetPagesPerDay;
  final int targetDays;
  final DateTime startDate;
  final DateTime expectedEndDate;
  final String status;
  final KhatmahDedicationModel dedication;
  final DateTime? lastReadDate;
  final DateTime? dailyTargetDate;
  final int? dailyTargetStartPage;
  final int? dailyTargetEndPage;
  final DateTime? pausedAt;
  final String wirdUnit;
  final int portionsPerDay;
  final KhatmahSeasonLink? seasonLink;

  factory KhatmahPlanModel.fromJson(Map<String, dynamic> json) {
    final rawCompletedPages = json['completedPages'];
    final currentPage = json['currentPage'] as int? ?? 0;
    final startPage = json['startPage'] as int? ?? 1;
    return KhatmahPlanModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startPage: startPage,
      completedPages: json.containsKey('completedPages')
          ? _parseCompletedPages(rawCompletedPages)
          : _legacyCompletedPages(startPage, currentPage),
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
      dailyTargetDate: json['dailyTargetDate'] != null
          ? DateTime.parse(json['dailyTargetDate'] as String)
          : null,
      dailyTargetStartPage: json['dailyTargetStartPage'] as int?,
      dailyTargetEndPage: json['dailyTargetEndPage'] as int?,
      wirdUnit: json['wirdUnit'] as String? ?? 'pages',
      portionsPerDay: _parsePortions(json['portionsPerDay']),
      seasonLink: _parseSeasonLink(json['seasonLink']),
    );
  }

  /// Older plans have no value; anything but 1–5 reads as 1.
  static int _parsePortions(Object? raw) =>
      raw is int && raw >= 1 && raw <= 5 ? raw : 1;

  /// Malformed links are dropped: they only gate an optional offer.
  static KhatmahSeasonLink? _parseSeasonLink(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final round = raw['round'];
    final rounds = raw['rounds'];
    final rawDay = raw['lastDay'];
    final lastDay = rawDay is String ? DateTime.tryParse(rawDay) : null;
    if (round is! int ||
        rounds is! int ||
        lastDay == null ||
        round < 1 ||
        rounds < round ||
        rounds > 5) {
      return null;
    }
    return KhatmahSeasonLink(round: round, rounds: rounds, lastDay: lastDay);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startPage': startPage,
    'currentPage': currentPage,
    'completedPages': completedPages.toList()..sort(),
    'targetPagesPerDay': targetPagesPerDay,
    'targetDays': targetDays,
    'startDate': startDate.toIso8601String(),
    'expectedEndDate': expectedEndDate.toIso8601String(),
    'status': status,
    'dedication': dedication.toJson(),
    'lastReadDate': lastReadDate?.toIso8601String(),
    'dailyTargetDate': dailyTargetDate?.toIso8601String(),
    'dailyTargetStartPage': dailyTargetStartPage,
    'dailyTargetEndPage': dailyTargetEndPage,
    'pausedAt': pausedAt?.toIso8601String(),
    'wirdUnit': wirdUnit,
    if (portionsPerDay != 1) 'portionsPerDay': portionsPerDay,
    if (seasonLink case final link?)
      'seasonLink': {
        'round': link.round,
        'rounds': link.rounds,
        'lastDay':
            '${link.lastDay.year.toString().padLeft(4, '0')}-'
            '${link.lastDay.month.toString().padLeft(2, '0')}-'
            '${link.lastDay.day.toString().padLeft(2, '0')}',
      },
  };

  factory KhatmahPlanModel.fromEntity(KhatmahPlan entity) {
    return KhatmahPlanModel(
      id: entity.id,
      title: entity.title,
      startPage: entity.startPage,
      completedPages: entity.completedPages,
      targetPagesPerDay: entity.targetPagesPerDay,
      targetDays: entity.targetDays,
      startDate: entity.startDate,
      expectedEndDate: entity.expectedEndDate,
      status: entity.status.name,
      dedication: KhatmahDedicationModel.fromEntity(entity.dedication),
      lastReadDate: entity.lastReadDate,
      dailyTargetDate: entity.dailyTargetDate,
      dailyTargetStartPage: entity.dailyTargetStartPage,
      dailyTargetEndPage: entity.dailyTargetEndPage,
      pausedAt: entity.pausedAt,
      wirdUnit: entity.wirdUnit.name,
      portionsPerDay: entity.portionsPerDay,
      seasonLink: entity.seasonLink,
    );
  }

  KhatmahPlan toEntity() => KhatmahPlan(
    id: id,
    title: title,
    startPage: startPage,
    completedPages: completedPages,
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
    dailyTargetDate: dailyTargetDate,
    dailyTargetStartPage: dailyTargetStartPage,
    dailyTargetEndPage: dailyTargetEndPage,
    pausedAt: pausedAt,
    wirdUnit:
        KhatmahWirdUnit.values.where((u) => u.name == wirdUnit).firstOrNull ??
        KhatmahWirdUnit.pages,
    portionsPerDay: portionsPerDay,
    seasonLink: seasonLink,
  );

  static Set<int> _legacyCompletedPages(int startPage, int currentPage) {
    return {
      for (
        var page = startPage;
        page <= currentPage && page <= KhatmahSchedulingEngine.totalPages;
        page++
      )
        page,
    };
  }

  static Iterable<int> _parseCompletedPages(Object? value) {
    if (value is! List) {
      throw const KhatmahStorageException(
        'completedPages must be a JSON array of page numbers.',
      );
    }
    if (value.any((page) => page is! int)) {
      throw const KhatmahStorageException(
        'completedPages must contain only integer page numbers.',
      );
    }
    return value.cast<int>();
  }

  static Set<int> _normalizeCompletedPages(Iterable<int> pages) {
    return {
      for (final page in pages)
        if (page >= 1 && page <= KhatmahSchedulingEngine.totalPages) page,
    };
  }

  static int _highestContiguousPage(Set<int> pages) {
    var current = 0;
    while (pages.contains(current + 1)) {
      current++;
    }
    return current;
  }
}
