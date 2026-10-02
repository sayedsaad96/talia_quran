import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_kids_local_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_home_mission.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

class _UnusedQuranRepository implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStreakReader implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}

class _FakeProgressEventsBus implements ProgressEventsBus {
  @override
  void notify(ProgressChangedReason reason) {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  MemorizationKidsLocalService serviceFor(String owner) {
    final provider = FixedRecordOwnerProvider(owner);
    return MemorizationKidsLocalService(
      MemorizationPlusLocalDatasourceImpl(prefs, owner: provider),
      _UnusedQuranRepository(),
      _FakeStreakReader(),
      _FakeProgressEventsBus(),
      null,
      owner: provider,
    );
  }

  List<KidsHomeMission> right(dynamic either) =>
      either.fold((f) => fail('expected Right, got $f'), (v) => v)
          as List<KidsHomeMission>;

  test('adding a mission stores it assigned with a trimmed title', () async {
    final service = serviceFor('a');
    final missions = right(await service.addLocalHomeMission('  رتّب غرفتك  '));

    expect(missions, hasLength(1));
    expect(missions.single.title, 'رتّب غرفتك');
    expect(missions.single.status, KidsHomeMissionStatus.assigned);
    expect(missions.single.id, startsWith('local-'));
    expect(missions.single.reportedAt, isNull);
    expect(right(await service.getHomeMissions()), missions);
  });

  test('empty and over-long titles fail validation', () async {
    final service = serviceFor('a');
    for (final title in ['', '   ', 'ا' * 121]) {
      final result = await service.addLocalHomeMission(title);
      expect(
        result.fold((f) => f, (_) => null),
        const ValidationFailure(CubitMessageCodes.kidsHomeMissionInvalidTitle),
      );
    }
    expect(right(await service.addLocalHomeMission('ا' * 120)), hasLength(1));
  });

  test('reporting marks reported with reportedAt and is idempotent', () async {
    final service = serviceFor('a');
    final id = right(await service.addLocalHomeMission('مهمة')).single.id;

    final first = right(await service.reportHomeMission(id)).single;
    expect(first.status, KidsHomeMissionStatus.reported);
    expect(first.reportedAt, isNotNull);

    final second = right(await service.reportHomeMission(id)).single;
    expect(second, first);
  });

  test('reporting an unknown id is a NotFoundFailure', () async {
    final result = await serviceFor('a').reportHomeMission('nope');
    expect(result.fold((f) => f, (_) => null), isA<NotFoundFailure>());
  });

  test('acknowledging an assigned mission fails; reported succeeds', () async {
    final service = serviceFor('a');
    final id = right(await service.addLocalHomeMission('مهمة')).single.id;

    final early = await service.acknowledgeLocalHomeMission(id);
    expect(early.fold((f) => f, (_) => null), isA<ValidationFailure>());

    await service.reportHomeMission(id);
    final done = right(await service.acknowledgeLocalHomeMission(id)).single;
    expect(done.status, KidsHomeMissionStatus.acknowledged);
    expect(done.acknowledgedAt, isNotNull);
    expect(done.reportedAt, isNotNull);

    // Reporting an acknowledged mission leaves it untouched.
    expect(right(await service.reportHomeMission(id)).single, done);
  });

  test('owner B does not see owner A missions', () async {
    await serviceFor('a').addLocalHomeMission('مهمة أ');

    expect(right(await serviceFor('b').getHomeMissions()), isEmpty);
    expect(right(await serviceFor('a').getHomeMissions()), hasLength(1));
  });

  test('a corrupt stored payload is quarantined and reads as empty', () async {
    final service = serviceFor('a');
    await service.addLocalHomeMission('مهمة');
    final key = prefs.getKeys().firstWhere(
      (k) => k.startsWith('mem_plus_home_missions'),
    );
    await prefs.setString(
      key,
      jsonEncode([
        {
          'id': 'x',
          'title': 't',
          'status': 'bogus',
          'createdAt': DateTime(2026).toIso8601String(),
        },
      ]),
    );

    expect(right(await service.getHomeMissions()), isEmpty);
  });

  test('JSON round-trip keeps every field including pendingReportSync', () {
    final mission = KidsHomeMission(
      id: 'm1',
      title: 'مهمة',
      status: KidsHomeMissionStatus.reported,
      createdAt: DateTime.utc(2026, 10, 2, 8),
      reportedAt: DateTime.utc(2026, 10, 2, 9),
      pendingReportSync: true,
    );
    final restored = KidsHomeMission.fromJson(
      jsonDecode(jsonEncode(mission.toJson())) as Map<String, dynamic>,
    );
    expect(restored, mission);
    expect(restored.pendingReportSync, isTrue);

    final json = mission.toJson()..remove('pendingReportSync');
    expect(KidsHomeMission.fromJson(json).pendingReportSync, isFalse);
  });

  test('fromJson rejects an unknown status', () {
    expect(
      () => KidsHomeMission.fromJson({
        'id': 'm',
        'title': 't',
        'status': 'bogus',
        'createdAt': DateTime(2026).toIso8601String(),
      }),
      throwsFormatException,
    );
  });
}
