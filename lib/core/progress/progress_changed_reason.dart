/// Identifies which progress domain changed so listeners can refresh selectively.
enum ProgressChangedReason {
  /// An [AyahReviewRecord] was written or updated (SRS / memorization).
  reviewRecord,

  /// A Quran page was confirmed as read.
  readPage,

  /// Streak counter or daily activity heatmap changed.
  streak,

  /// XP total or level changed.
  xp,

  /// A certificate was newly earned.
  certificate,

  /// Kids points, stars, or session log changed (SharedPreferences path).
  kidsProgress,

  /// Today's daily plan completion list changed.
  dailyPlan,

  /// Cloud pull merged remote SRS / streak / XP into local storage (B7).
  cloudPull,
}
