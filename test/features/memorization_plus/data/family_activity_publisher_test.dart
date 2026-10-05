import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/home/domain/entities/activity_event.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/family_activity_publisher.dart';

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => true;
}

final _now = DateTime(2026, 10, 5, 9);

FamilyActivityInputs _inputs({
  Map<String, int> activityByDay = const {'2026-10-05': 2},
  Set<int> readPages = const {1, 2},
  Set<int> todayReadPages = const {2},
  List<ActivityEvent> events = const [],
  List<CertificateAward> certificates = const [],
  int totalXp = 40,
  int currentStreak = 3,
}) => FamilyActivityInputs(
  currentStreak: currentStreak,
  longestStreak: 5,
  totalXp: totalXp,
  activityByDay: activityByDay,
  readPages: readPages,
  todayReadPages: todayReadPages,
  events: events,
  certificates: certificates,
);

ActivityEvent _event(int minute) => ActivityEvent(
  occurredAt: _now.add(Duration(minutes: minute)),
  kind: ActivityEventKind.reading,
  idempotencyKey: 'e$minute',
  pageNumber: 3,
);

void main() {
  late SharedPreferences prefs;
  late _MutableOwner owner;
  late FamilyActivityInputs inputs;
  late DateTime clock;

  FamilyActivityPublisher publisher() => FamilyActivityPublisher(
    prefs,
    owner,
    () async => inputs,
    clock: () => clock,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = _MutableOwner('child-1');
    inputs = _inputs();
    clock = _now;
  });

  group('buildSnapshot', () {
    test('counts active days only within the last 30 local days', () {
      final snapshot = FamilyActivityPublisher.buildSnapshot(
        _inputs(
          activityByDay: {
            '2026-10-05': 1,
            '2026-09-06': 1,
            '2026-09-05': 4,
            '2026-10-01': 0,
            '2026-10-06': 2,
          },
        ),
        _now,
      );

      expect(snapshot['day_key'], '2026-10-05');
      expect(snapshot['active_days_last_30'], 2);
      expect(snapshot['today_activity_count'], 1);
    });

    test('counts only valid Mushaf pages', () {
      final snapshot = FamilyActivityPublisher.buildSnapshot(
        _inputs(readPages: {0, 1, 604, 605}, todayReadPages: {604, 700}),
        _now,
      );

      expect(snapshot['read_pages_count'], 2);
      expect(snapshot['today_read_pages_count'], 1);
    });

    test('keeps the 100 newest events, newest first', () {
      final snapshot = FamilyActivityPublisher.buildSnapshot(
        _inputs(events: [for (var i = 0; i < 120; i++) _event(i)]),
        _now,
      );
      final activities = snapshot['activities'] as List;

      expect(activities, hasLength(FamilyActivityPublisher.maxActivities));
      expect((activities.first as Map)['key'], 'e119');
      expect((activities.last as Map)['key'], 'e20');
      expect((activities.first as Map)['page'], 3);
      expect((activities.first as Map).containsKey('surah'), isFalse);
    });

    test('clamps counters to the server range', () {
      final snapshot = FamilyActivityPublisher.buildSnapshot(
        _inputs(totalXp: 99999999999, currentStreak: -4),
        _now,
      );

      expect(snapshot['total_xp'], 9999999999);
      expect(snapshot['current_streak'], 0);
    });

    test('serialises certificates with their type name', () {
      final snapshot = FamilyActivityPublisher.buildSnapshot(
        _inputs(
          certificates: [
            CertificateAward(
              id: 'c1',
              titleAr: CertificateType.juz.titleAr,
              type: CertificateType.juz,
              earnedAt: DateTime.utc(2026, 10, 1),
            ),
          ],
        ),
        _now,
      );

      expect(snapshot['certificates'], [
        {
          'cert_id': 'c1',
          'title_ar': CertificateType.juz.titleAr,
          'cert_type': 'juz',
          'earned_at': '2026-10-01T00:00:00.000Z',
        },
      ]);
    });
  });

  group('publish', () {
    test('sends once and skips an unchanged snapshot', () async {
      final calls = <Map<String, dynamic>>[];
      final sut = publisher();

      expect(await sut.publish((p) async => calls.add(p)), isFalse);
      expect(await sut.publish((p) async => calls.add(p)), isFalse);

      expect(calls, hasLength(1));
      expect(calls.single['p_revision'], _now.millisecondsSinceEpoch);
      expect(
        calls.single['p_device_id'],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('revision keeps growing even if the clock goes back', () async {
      final calls = <Map<String, dynamic>>[];
      final sut = publisher();
      await sut.publish((p) async => calls.add(p));

      clock = _now.subtract(const Duration(hours: 1));
      inputs = _inputs(totalXp: 50);
      await sut.publish((p) async => calls.add(p));

      expect(calls[1]['p_revision'], _now.millisecondsSinceEpoch + 1);
      expect(calls[1]['p_device_id'], calls[0]['p_device_id']);
    });

    test('transient failure asks for retry and resends later', () async {
      final sut = publisher();

      expect(
        await sut.publish((_) async => throw Exception('offline')),
        isTrue,
      );
      var sent = 0;
      expect(await sut.publish((_) async => sent++), isFalse);
      expect(sent, 1);
    });

    test('server rejection is terminal and does not retry', () async {
      final sut = publisher();

      final retry = await sut.publish(
        (_) async =>
            throw const PostgrestException(message: 'Child account required'),
      );

      expect(retry, isFalse);
    });

    test('does not record success if the owner changed mid-call', () async {
      final sut = publisher();
      await sut.publish((_) async => owner.currentOwnerId = 'other');

      owner.currentOwnerId = 'child-1';
      var sent = 0;
      await sut.publish((_) async => sent++);
      expect(sent, 1);
    });

    test('missing inputs skip publishing without retry', () async {
      final sut = FamilyActivityPublisher(
        prefs,
        owner,
        () async => throw StateError('no isar'),
        clock: () => clock,
      );
      var sent = 0;

      expect(await sut.publish((_) async => sent++), isFalse);
      expect(sent, 0);
    });
  });
}
