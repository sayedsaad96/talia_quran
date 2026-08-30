import 'package:equatable/equatable.dart';

enum AzkarCategory { morning, evening, general, duas }

/// Reviewer-controlled authenticity grades (V1-M3).
/// Values are assigned exclusively by the qualified Islamic reviewer.
enum AuthenticityGrade { sahih, hasan, daif, mawquf }

/// Product prominence tiers for retained duas (V1-M3).
enum DuaTier { essential, recommended, supplementary }

/// Content governance states (V1-M3).
enum ContentReviewStatus { pendingReview, approved, rejected }

extension ZikrGradePresentation on AuthenticityGrade? {
  String get displayName => switch (this) {
    AuthenticityGrade.sahih => 'صحيح',
    AuthenticityGrade.hasan => 'حسن',
    AuthenticityGrade.daif => 'ضعيف',
    AuthenticityGrade.mawquf => 'موقوف',
    null => '',
  };
}

class Zikr extends Equatable {
  const Zikr({
    required this.id,
    required this.text,
    required this.transliteration,
    required this.translation,
    required this.totalCount,
    required this.category,
    this.reference = '',
    this.subcategory = '',
    this.citation,
    this.sourceType,
    this.authenticityGrade,
    this.tier,
    this.reviewStatus = ContentReviewStatus.pendingReview,
    this.datasetVersion = 'unversioned',
  });

  final String id;
  final String text;
  final String transliteration;
  final String translation;
  final int totalCount;
  final AzkarCategory category;
  final String reference;
  final String subcategory;

  /// Resolvable numbered citation (e.g. "Muslim 2689", "Quran 2:201").
  /// Null until verified by the qualified reviewer.
  final String? citation;

  /// Coarse origin type: 'quran' | 'hadith' | 'dhikr' | 'dua'.
  /// Null until assigned during review.
  final String? sourceType;

  final AuthenticityGrade? authenticityGrade;

  final DuaTier? tier;

  final ContentReviewStatus reviewStatus;

  /// Frozen dataset version this record was reviewed under.
  final String datasetVersion;

  @override
  List<Object?> get props => [
    id,
    text,
    totalCount,
    category,
    subcategory,
    citation,
    authenticityGrade,
    tier,
    reviewStatus,
  ];
}

extension ZikrReviewPresentation on Zikr {
  bool get shouldShowAuthenticityGrade =>
      reviewStatus == ContentReviewStatus.approved && authenticityGrade != null;
}

class ZikrSession extends Equatable {
  const ZikrSession({
    required this.zikr,
    required this.currentCount,
    required this.isDone,
  });

  final Zikr zikr;
  final int currentCount;
  final bool isDone;

  double get progress =>
      zikr.totalCount == 0 ? 0 : currentCount / zikr.totalCount;

  ZikrSession increment() {
    final next = currentCount + 1;
    return ZikrSession(
      zikr: zikr,
      currentCount: next.clamp(0, zikr.totalCount),
      isDone: next >= zikr.totalCount,
    );
  }

  ZikrSession decrement() {
    final next = (currentCount - 1).clamp(0, zikr.totalCount);
    return ZikrSession(
      zikr: zikr,
      currentCount: next,
      isDone: next >= zikr.totalCount,
    );
  }

  ZikrSession reset() =>
      ZikrSession(zikr: zikr, currentCount: 0, isDone: false);

  @override
  List<Object?> get props => [zikr, currentCount, isDone];
}
