import 'package:equatable/equatable.dart';

/// Guardian hints. Null preserves the device's existing behavior.
/// This value never defines a saved house range or grants learning access.
final class KidsRemotePlan extends Equatable {
  const KidsRemotePlan({
    this.nextSurahId,
    this.ayahsPerSession,
    this.practiceDays,
  });

  final int? nextSurahId;
  final int? ayahsPerSession;

  /// Bits 0..6 represent Monday..Sunday; zero disables practice reminders.
  final int? practiceDays;

  factory KidsRemotePlan.fromJson(Object? raw) {
    if (raw is! Map) return const KidsRemotePlan();
    return KidsRemotePlan(
      nextSurahId: _bounded(raw['nextSurahId'], 1, 114),
      ayahsPerSession: _bounded(raw['ayahsPerSession'], 1, 10),
      practiceDays: _bounded(raw['practiceDays'], 0, 127),
    );
  }

  factory KidsRemotePlan.fromRow(Map row) => KidsRemotePlan(
    nextSurahId: _bounded(row['next_surah_id'], 1, 114),
    ayahsPerSession: _bounded(row['ayahs_per_session'], 1, 10),
    practiceDays: _bounded(row['practice_days'], 0, 127),
  );

  KidsRemotePlan sanitized() => KidsRemotePlan(
    nextSurahId: _bounded(nextSurahId, 1, 114),
    ayahsPerSession: _bounded(ayahsPerSession, 1, 10),
    practiceDays: _bounded(practiceDays, 0, 127),
  );

  Map<String, int?> toJson() {
    final clean = sanitized();
    return {
      'nextSurahId': clean.nextSurahId,
      'ayahsPerSession': clean.ayahsPerSession,
      'practiceDays': clean.practiceDays,
    };
  }

  Map<String, int?> toRpcParameters() {
    final clean = sanitized();
    return {
      'p_next_surah_id': clean.nextSurahId,
      'p_ayahs_per_session': clean.ayahsPerSession,
      'p_practice_days': clean.practiceDays,
    };
  }

  bool shouldRemindOn(DateTime localDate) {
    final mask = sanitized().practiceDays;
    return mask == null || (mask & (1 << (localDate.weekday - 1))) != 0;
  }

  static int? _bounded(Object? raw, int min, int max) =>
      raw is int && raw >= min && raw <= max ? raw : null;

  @override
  List<Object?> get props => [nextSurahId, ayahsPerSession, practiceDays];
}
