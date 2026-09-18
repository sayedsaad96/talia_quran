import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/prayer_companion/data/datasources/prayer_companion_local_datasource.dart';
import 'package:talia_quran/features/prayer_companion/data/models/prayer_companion_record_isar.dart';
import 'package:talia_quran/features/prayer_companion/data/repositories/prayer_companion_repository_impl.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_companion/domain/repositories/prayer_companion_repository.dart';

bool _isarReady = false;

Future<void> _prepareIsar() async {
  if (_isarReady) return;
  if (Platform.isWindows) {
    final appData = Platform.environment['LOCALAPPDATA'];
    final path = appData == null
        ? null
        : '$appData\\Pub\\Cache\\hosted\\pub.dev\\'
              'isar_flutter_libs-3.1.0+1\\windows\\isar.dll';
    if (path != null && File(path).existsSync()) {
      await Isar.initializeIsarCore(libraries: {Abi.current(): path});
      _isarReady = true;
      return;
    }
  }
  await Isar.initializeIsarCore();
  _isarReady = true;
}

void main() {
  group('PrayerCompanionLocalDatasource', () {
    late Isar isar;
    late Directory dir;
    late PrayerCompanionRepository repository;

    setUp(() async {
      await _prepareIsar();
      dir = await Directory.systemTemp.createTemp('talia_companion_');
      isar = await Isar.open(
        [PrayerCompanionRecordIsarSchema],
        directory: dir.path,
        name: 'companion_${DateTime.now().microsecondsSinceEpoch}',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      repository = PrayerCompanionRepositoryImpl(
        PrayerCompanionLocalDatasource(isar),
        owner: const FixedRecordOwnerProvider('owner-a'),
      );
    });

    test('same owner/date/prayer is replaced rather than duplicated', () async {
      final asr = occurrenceFor('owner-a', PrayerKey.asr);
      await repository.save(recordFor(asr, PrayerCompanionStatus.prayNow));
      await repository.save(recordFor(asr, PrayerCompanionStatus.confirmed));

      final day = await repository.readDay(
        ownerId: 'owner-a',
        localDate: asr.localDate,
      );
      expect(day, hasLength(1));
      expect(day[PrayerKey.asr]!.status, PrayerCompanionStatus.confirmed);
      expect(await isar.prayerCompanionRecordIsars.where().count(), 1);
    });

    test('readDay returns a map keyed by PrayerKey', () async {
      await repository.save(
        recordFor(
          occurrenceFor('owner-a', PrayerKey.fajr),
          PrayerCompanionStatus.confirmed,
        ),
      );
      await repository.save(
        recordFor(
          occurrenceFor('owner-a', PrayerKey.isha),
          PrayerCompanionStatus.notYet,
        ),
      );

      final day = await repository.readDay(
        ownerId: 'owner-a',
        localDate: DateTime(2026, 9, 16),
      );
      expect(day.keys, containsAll([PrayerKey.fajr, PrayerKey.isha]));
      expect(day[PrayerKey.fajr]!.status, PrayerCompanionStatus.confirmed);
      expect(day[PrayerKey.isha]!.status, PrayerCompanionStatus.notYet);
    });

    test('another owner cannot read a record', () async {
      final ownerBRepository = PrayerCompanionRepositoryImpl(
        PrayerCompanionLocalDatasource(isar),
        owner: const FixedRecordOwnerProvider('owner-b'),
      );
      await repository.save(
        recordFor(
          occurrenceFor('owner-a', PrayerKey.asr),
          PrayerCompanionStatus.confirmed,
        ),
      );

      expect(
        await ownerBRepository.readDay(
          ownerId: 'owner-b',
          localDate: DateTime(2026, 9, 16),
        ),
        isEmpty,
      );
      expect(
        await ownerBRepository.read(occurrenceFor('owner-b', PrayerKey.asr)),
        isNull,
      );
      // Owner A still sees the record.
      expect(
        await repository.read(occurrenceFor('owner-a', PrayerKey.asr)),
        isNotNull,
      );
    });

    test(
      'read returns null for an occurrence without a stored record',
      () async {
        expect(
          await repository.read(occurrenceFor('owner-a', PrayerKey.maghrib)),
          isNull,
        );
      },
    );

    test('records on other days are not returned by readDay', () async {
      await repository.save(
        recordFor(
          occurrenceFor(
            'owner-a',
            PrayerKey.fajr,
            localDate: DateTime(2026, 9, 15),
          ),
          PrayerCompanionStatus.confirmed,
        ),
      );
      expect(
        await repository.readDay(
          ownerId: 'owner-a',
          localDate: DateTime(2026, 9, 16),
        ),
        isEmpty,
      );
    });

    test('changes stream emits on save and clearOwner', () async {
      final firstEmission = repository.changes.first;
      await repository.save(
        recordFor(
          occurrenceFor('owner-a', PrayerKey.asr),
          PrayerCompanionStatus.confirmed,
        ),
      );
      await firstEmission.timeout(const Duration(seconds: 5));

      final secondEmission = repository.changes.first;
      await repository.clearOwner('owner-a');
      await secondEmission.timeout(const Duration(seconds: 5));
    });

    test('clearOwner removes only that owner\'s rows', () async {
      final ownerBRepository = PrayerCompanionRepositoryImpl(
        PrayerCompanionLocalDatasource(isar),
        owner: const FixedRecordOwnerProvider('owner-b'),
      );
      await repository.save(
        recordFor(
          occurrenceFor('owner-a', PrayerKey.fajr),
          PrayerCompanionStatus.confirmed,
        ),
      );
      await ownerBRepository.save(
        recordFor(
          occurrenceFor('owner-b', PrayerKey.fajr),
          PrayerCompanionStatus.prayNow,
        ),
      );

      await repository.clearOwner('owner-a');

      expect(
        await repository.readDay(
          ownerId: 'owner-a',
          localDate: DateTime(2026, 9, 16),
        ),
        isEmpty,
      );
      expect(
        await ownerBRepository.readDay(
          ownerId: 'owner-b',
          localDate: DateTime(2026, 9, 16),
        ),
        hasLength(1),
      );
    });
  });
}

PrayerOccurrence occurrenceFor(
  String ownerId,
  PrayerKey key, {
  DateTime? localDate,
}) {
  final date = localDate ?? DateTime(2026, 9, 16);
  return PrayerOccurrence(
    ownerId: ownerId,
    localDate: date,
    prayerKey: key,
    scheduledAt: DateTime(date.year, date.month, date.day, 15, 30),
  );
}

PrayerCompanionRecord recordFor(
  PrayerOccurrence occurrence,
  PrayerCompanionStatus status, {
  DateTime? at,
}) {
  final now = at ?? DateTime(2026, 9, 16, 16);
  return PrayerCompanionRecord(
    occurrence: occurrence,
    status: status,
    statusUpdatedAt: now,
    followUpCount: 0,
    createdAt: now,
    updatedAt: now,
  );
}
