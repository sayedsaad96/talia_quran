import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// IS-6 source-level production verification checklist.
///
/// These assertions encode the Sprint 6 exit questions that can be proven
/// statically from the repo. Remote Supabase apply remains a manual gate.
void main() {
  final root = Directory.current.path;

  String read(String rel) => File('$root/$rel').readAsStringSync();

  bool exists(String rel) => File('$root/$rel').existsSync();

  test('one Memorization Plus practice path — Hifz presentation is gone', () {
    expect(exists('lib/features/hifz/presentation/pages/hifz_page.dart'), isFalse);
    expect(exists('lib/features/hifz/presentation/cubits/hifz_cubit.dart'), isFalse);
    expect(exists('lib/features/memorization_plus/presentation/pages/practice_surah_page.dart'), isTrue);

    final router = read('lib/core/router/app_router.dart');
    expect(router.contains('PracticeSurahPage'), isTrue);
    expect(router.contains('HifzPage'), isFalse);

    final di = read('lib/core/di/injection.dart');
    expect(di.contains('PracticeSurahCubit'), isTrue);
    expect(di.contains('HifzCubit'), isFalse);
  });

  test('identity isolation contract is present locally and in SQL', () {
    expect(exists('lib/core/memorization/review_record_identity.dart'), isTrue);
    expect(exists('supabase/migrations/0007_review_record_audience_identity.sql'), isTrue);

    final migration = read('supabase/migrations/0007_review_record_audience_identity.sql');
    expect(migration.contains('unique_user_audience_ayah_review'), isTrue);
    expect(migration.contains('user_id, audience, surah_id, ayah_number'), isTrue);

    final baseline = read('supabase/migrations/0001_baseline.sql');
    expect(baseline.contains('public.ayah_review_records_cloud'), isTrue);
  });

  test('account safety + sync integrity artifacts exist', () {
    expect(exists('lib/core/identity/account_data_reset.dart'), isTrue);
    expect(exists('lib/core/memorization/daily_plan_cloud_merge.dart'), isTrue);
    expect(exists('lib/core/memorization/kids_progress_cloud_merge.dart'), isTrue);
    expect(exists('supabase/migrations/0008_custom_plans_cloud.sql'), isTrue);
    expect(exists('supabase/migrations/0010_kids_session_log_ayah_dedup.sql'), isTrue);

    final coordinator = read(
      'lib/features/auth/application/cloud_sync_coordinator.dart',
    );
    expect(coordinator.contains('pullCertificatesFromCloud'), isTrue);
    expect(coordinator.contains('pullKidsProgressFromCloud'), isTrue);
    expect(coordinator.contains('mergeEarnedFromCloud'), isTrue);
    expect(coordinator.contains('CloudSyncQueueKind.certificatePull'), isTrue);
    expect(
      coordinator.contains('enqueue(CloudSyncQueueKind.certificatePull)'),
      isTrue,
    );
  });

  test('legacy Hifz writes are retired while migration scaffolding remains', () {
    final repo = read('lib/features/hifz/data/repositories/hifz_repository_impl.dart');
    expect(repo.contains('Hifz write API retired'), isTrue);

    final di = read('lib/core/di/injection.dart');
    expect(di.contains('HifzMigrationService'), isTrue);
    expect(di.contains('HifzRepository'), isTrue);
  });

  test('IS-6 evidence document records applied cloud migrations', () {
    expect(
      exists('docs/superpowers/specs/2026-08-08-is6-production-verification.md'),
      isTrue,
    );
    final evidence =
        read('docs/superpowers/specs/2026-08-08-is6-production-verification.md');
    expect(evidence.contains('CONDITIONAL GO'), isTrue);
    expect(evidence.contains('review_record_audience_identity'), isTrue);
    expect(evidence.contains('custom_plans_cloud'), isTrue);
    expect(evidence.contains('unique_user_audience_ayah_review'), isTrue);
  });
}
