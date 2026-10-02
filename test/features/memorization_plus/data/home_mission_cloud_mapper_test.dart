import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_cloud_gateway.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_cloud_mappers.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_kids_cloud_sync_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_home_mission.dart';

class _UnavailableGateway extends MemorizationCloudGateway {
  _UnavailableGateway(super.prefs);

  @override
  Either<Failure, SupabaseClient> supabaseOrFailure() =>
      const Left(NetworkFailure('unavailable'));
}

class _NoStreak implements StreakReader {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoDatasource implements MemorizationPlusLocalDatasource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedOwner implements RecordOwnerProvider {
  const _FixedOwner();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final mappers = MemorizationCloudMappers(const ProgressMetricsService());

  test('homeMissionFromCloud maps a server row', () {
    final mission = mappers.homeMissionFromCloud({
      'id': 12,
      'parent_user_id': 'p',
      'child_user_id': 'c',
      'title': 'رتّب غرفتك',
      'status': 'reported',
      'created_at': '2026-10-01T08:00:00Z',
      'reported_at': '2026-10-01T09:00:00Z',
      'acknowledged_at': null,
    });

    expect(mission.id, '12');
    expect(mission.title, 'رتّب غرفتك');
    expect(mission.status, KidsHomeMissionStatus.reported);
    expect(mission.createdAt, DateTime.utc(2026, 10, 1, 8));
    expect(mission.reportedAt, DateTime.utc(2026, 10, 1, 9));
    expect(mission.acknowledgedAt, isNull);
    expect(mission.pendingReportSync, isFalse);
  });

  test('homeMissionFromCloud falls back to assigned on unknown status', () {
    final mission = mappers.homeMissionFromCloud({
      'id': 1,
      'title': 't',
      'status': 'weird',
      'created_at': '2026-10-01T08:00:00Z',
    });
    expect(mission.status, KidsHomeMissionStatus.assigned);
  });

  group('remote home mission service calls', () {
    late MemorizationKidsCloudSyncService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = MemorizationKidsCloudSyncService(
        _NoDatasource(),
        _NoStreak(),
        _UnavailableGateway(prefs),
        mappers,
        owner: const _FixedOwner(),
      );
    });

    test('rejects an empty or over-long title before any network', () async {
      for (final title in ['   ', 'a' * 121]) {
        final result = await service.createRemoteHomeMission(
          childUserId: 'c1',
          title: title,
        );
        expect(
          result.fold((f) => f.message, (_) => null),
          CubitMessageCodes.kidsHomeMissionInvalidTitle,
        );
      }
    });

    test('rejects a non-numeric mission id', () async {
      final result = await service.acknowledgeRemoteHomeMission('abc');
      expect(result.isLeft(), isTrue);
    });

    test('reports cloud unavailable when Supabase is not ready', () async {
      final created = await service.createRemoteHomeMission(
        childUserId: 'c1',
        title: 'رتّب غرفتك',
      );
      final acked = await service.acknowledgeRemoteHomeMission('5');
      final read = await service.getRemoteHomeMissions('c1');

      for (final result in [created, acked, read]) {
        expect(
          result.fold((f) => f.message, (_) => null),
          CubitMessageCodes.guardianCloudUnavailable,
        );
      }
    });
  });
}
