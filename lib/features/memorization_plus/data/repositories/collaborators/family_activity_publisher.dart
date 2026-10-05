import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/identity/record_owner_provider.dart';
import '../../../../../core/utils/talia_logger.dart';
import '../../../../certificate/domain/entities/certificate_award.dart';
import '../../../../home/domain/entities/activity_event.dart';
import '../../../domain/services/kids_daily_missions.dart';
import '../../datasources/install_device_id.dart';

/// Local sources the child device summarises for its guardian.
class FamilyActivityInputs {
  const FamilyActivityInputs({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalXp,
    required this.activityByDay,
    required this.readPages,
    required this.todayReadPages,
    required this.events,
    required this.certificates,
  });

  final int currentStreak;
  final int longestStreak;
  final int totalXp;

  /// Activity count per local day, keyed `yyyy-MM-dd`.
  final Map<String, int> activityByDay;

  /// Distinct Mushaf pages confirmed within the retained reading history.
  final Set<int> readPages;
  final Set<int> todayReadPages;
  final List<ActivityEvent> events;
  final List<CertificateAward> certificates;
}

typedef FamilyActivityInputsLoader = Future<FamilyActivityInputs> Function();
typedef FamilyActivityRpc = Future<void> Function(Map<String, dynamic> params);

/// Publishes the child's activity snapshot through
/// `publish_child_family_activity`. Unchanged snapshots are not re-sent; the
/// revision only grows so the server never keeps an older snapshot.
class FamilyActivityPublisher {
  FamilyActivityPublisher(
    this._prefs,
    this._owner,
    this._loadInputs, {
    DateTime Function()? clock,
    Random? random,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure();

  static const deviceIdKey = InstallDeviceId.key;
  static const maxActivities = 100;
  static const maxCertificates = 100;
  static const _maxCount = 9999999999;
  static const _lastPage = 604;

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;
  final FamilyActivityInputsLoader _loadInputs;
  final DateTime Function() _clock;
  final Random _random;

  String get _revisionKey =>
      'family_activity_revision_${_owner.currentOwnerId}';
  String get _lastSentKey => 'family_activity_last_${_owner.currentOwnerId}';

  /// Returns true when publishing failed transiently and should be retried.
  Future<bool> publish(FamilyActivityRpc rpc) async {
    final ownerId = _owner.currentOwnerId;
    final Map<String, dynamic> snapshot;
    try {
      snapshot = buildSnapshot(await _loadInputs(), _clock());
    } catch (error, stack) {
      TaliaLogger.w('Family activity snapshot unavailable', error, stack);
      return false;
    }
    final encoded = jsonEncode(snapshot);
    if (_prefs.getString(_lastSentKey) == encoded) return false;

    final revision = _nextRevision();
    final device = await deviceId();
    try {
      await rpc({
        'p_device_id': device,
        'p_revision': revision,
        'p_snapshot': snapshot,
      });
    } on PostgrestException catch (error) {
      if (_isTerminal(error.message)) {
        TaliaLogger.w('Family activity rejected', error.message);
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
    if (_owner.currentOwnerId != ownerId) return false;
    await _prefs.setInt(_revisionKey, revision);
    await _prefs.setString(_lastSentKey, encoded);
    return false;
  }

  /// Stable per-install identifier (UUID v4).
  Future<String> deviceId() => InstallDeviceId.read(_prefs, random: _random);

  int _nextRevision() {
    final last = _prefs.getInt(_revisionKey) ?? 0;
    final now = _clock().millisecondsSinceEpoch;
    return now > last ? now : last + 1;
  }

  static bool _isTerminal(String message) =>
      message.contains('Child account required') ||
      message.contains('Invalid family activity');

  /// Builds a payload within the server's validation limits.
  static Map<String, dynamic> buildSnapshot(
    FamilyActivityInputs inputs,
    DateTime now,
  ) {
    final today = kidsDayKey(now);
    final cutoff = kidsDayKey(now.subtract(const Duration(days: 29)));
    final activeDays = inputs.activityByDay.entries
        .where((e) => e.value > 0 && e.key.compareTo(cutoff) >= 0)
        .where((e) => e.key.compareTo(today) <= 0)
        .length;
    final events = [...inputs.events]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final certificates = [...inputs.certificates]
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    return {
      'day_key': today,
      'read_pages_count': _pages(inputs.readPages),
      'today_read_pages_count': _pages(inputs.todayReadPages),
      'total_xp': _count(inputs.totalXp),
      'current_streak': _count(inputs.currentStreak),
      'longest_streak': _count(inputs.longestStreak),
      'active_days_last_30': activeDays.clamp(0, 30),
      'today_activity_count': _count(inputs.activityByDay[today] ?? 0),
      'activities': [
        for (final event in events.take(maxActivities)) _event(event),
      ],
      'certificates': [
        for (final cert in certificates.take(maxCertificates))
          {
            'cert_id': cert.id,
            'title_ar': cert.titleAr,
            'cert_type': cert.type.name,
            'earned_at': cert.earnedAt.toUtc().toIso8601String(),
          },
      ],
    };
  }

  static Map<String, dynamic> _event(ActivityEvent event) => {
    'at': event.occurredAt.toUtc().toIso8601String(),
    'kind': event.kind.name,
    'key': event.idempotencyKey,
    if (event.surahId != null) 'surah': _count(event.surahId!),
    if (event.startAyah != null) 'start': _count(event.startAyah!),
    if (event.endAyah != null) 'end': _count(event.endAyah!),
    if (event.pageNumber != null) 'page': _count(event.pageNumber!),
  };

  static int _pages(Set<int> pages) =>
      pages.where((p) => p >= 1 && p <= _lastPage).length;

  static int _count(int value) => value.clamp(0, _maxCount);
}
