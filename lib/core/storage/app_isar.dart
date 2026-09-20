import 'package:isar/isar.dart';

import '../../features/hifz/data/models/isar_ayah_progress.dart';
import '../../features/home/data/models/activity_event_isar.dart';
import '../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import '../../features/memorization_plus/data/models/isar_review_evidence_event.dart';
import '../../features/memorization_plus/data/models/isar_v2_session.dart';
import '../../features/prayer_companion/data/models/prayer_companion_record_isar.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/xp/data/models/xp_isar.dart';
import '../sync/cloud_sync_queue_item.dart';

/// The complete schema of Talia's default local database.
///
/// Every isolate that opens the default database must use this list. Opening
/// it with a subset is a destructive schema migration in Isar and can remove
/// user-owned collections.
final List<CollectionSchema<dynamic>> appIsarSchemas = [
  IsarAyahProgressSchema,
  IsarAyahReviewRecordSchema,
  IsarV2SessionSchema,
  IsarReviewEvidenceEventSchema,
  IsarReviewEffectOutboxSchema,
  StreakIsarSchema,
  XpIsarSchema,
  DailyActivityIsarSchema,
  ActivityEventIsarSchema,
  CloudSyncQueueItemSchema,
  PrayerCompanionRecordIsarSchema,
];

Future<Isar> openAppIsar({
  required String directory,
  String name = Isar.defaultName,
}) async {
  return Isar.getInstance(name) ??
      Isar.open(appIsarSchemas, directory: directory, name: name);
}
