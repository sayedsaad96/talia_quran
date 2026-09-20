import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/features/prayer_companion/application/prayer_companion_controller.dart';
import 'package:talia_quran/features/prayer_companion/application/prayer_companion_usecases.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_companion/domain/repositories/prayer_companion_repository.dart';
import 'package:talia_quran/features/prayer_companion/domain/services/prayer_companion_policy.dart';
import 'package:talia_quran/features/prayer_companion/presentation/cubits/prayer_companion_cubit.dart';

class _MockPrayerCompanionRepository extends Mock
    implements PrayerCompanionRepository {}

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

class _FakeAppLocalizations extends Fake implements AppLocalizations {}

/// Records every emitted state so transitions can be asserted
/// deterministically without depending on stream timing.
class _RecordingCubit extends PrayerCompanionCubit {
  _RecordingCubit({required super.controller, required super.occurrence});

  final List<PrayerCompanionState> emitted = [];

  @override
  void emit(PrayerCompanionState state) {
    emitted.add(state);
    super.emit(state);
  }
}

void main() {
  final asr = PrayerOccurrence(
    ownerId: 'owner-a',
    localDate: DateTime(2026, 9, 16),
    prayerKey: PrayerKey.asr,
    scheduledAt: DateTime(2026, 9, 16, 15, 0),
  );

  setUpAll(() {
    registerFallbackValue(asr);
    registerFallbackValue(PrayerCompanionCommand.confirm);
    registerFallbackValue(_FakeAppLocalizations());
    registerFallbackValue(
      PrayerCompanionRecord(
        occurrence: asr,
        status: PrayerCompanionStatus.unconfirmed,
        statusUpdatedAt: asr.scheduledAt,
        followUpCount: 0,
        createdAt: asr.scheduledAt,
        updatedAt: asr.scheduledAt,
      ),
    );
  });

  PrayerCompanionController makeController({
    required PrayerCompanionRepository repository,
    required NotificationScheduler scheduler,
  }) {
    return PrayerCompanionController(
      applyCommand: ApplyPrayerCompanionCommand(
        repository,
        const PrayerCompanionPolicy(),
        const FixedRecordOwnerProvider('owner-a'),
      ),
      scheduler: scheduler,
      locale: () => const Locale('ar'),
      nextPrayerAt: () async => DateTime(2026, 9, 16, 18, 0),
    );
  }

  test('submit confirm persists then reports success', () async {
    final repository = _MockPrayerCompanionRepository();
    final scheduler = _MockNotificationScheduler();
    when(() => repository.read(any())).thenAnswer((_) async => null);
    when(() => repository.save(any())).thenAnswer(
      (invocation) async =>
          invocation.positionalArguments.first as PrayerCompanionRecord,
    );
    when(
      () => scheduler.refreshNotifications(any(), force: true),
    ).thenAnswer((_) async {});
    final cubit = _RecordingCubit(
      controller: makeController(repository: repository, scheduler: scheduler),
      occurrence: asr,
    );

    await cubit.submit(PrayerCompanionCommand.confirm);

    expect(cubit.emitted[0], isA<PrayerCompanionSubmitting>());
    expect(cubit.emitted[1], isA<PrayerCompanionSuccess>());
    expect(
      (cubit.emitted[1] as PrayerCompanionSuccess).record.status,
      PrayerCompanionStatus.confirmed,
    );
    await cubit.close();
  });

  test('does not report success when persistence fails', () async {
    final repository = _MockPrayerCompanionRepository();
    final scheduler = _MockNotificationScheduler();
    when(
      () => repository.read(any()),
    ).thenThrow(StateError('isar write failed'));
    final cubit = _RecordingCubit(
      controller: makeController(repository: repository, scheduler: scheduler),
      occurrence: asr,
    );

    await cubit.submit(PrayerCompanionCommand.confirm);

    expect(cubit.emitted[0], isA<PrayerCompanionSubmitting>());
    expect(cubit.emitted[1], isA<PrayerCompanionFailure>());
    await cubit.close();
  });
}
