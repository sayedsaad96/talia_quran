import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_prayer_times_sheet.dart';
import 'package:talia_quran/features/prayer_companion/application/prayer_companion_controller.dart';
import 'package:talia_quran/features/prayer_companion/application/prayer_companion_usecases.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_companion/domain/repositories/prayer_companion_repository.dart';
import 'package:talia_quran/features/prayer_companion/domain/services/prayer_companion_policy.dart';

class _MockPrayerCompanionRepository extends Mock
    implements PrayerCompanionRepository {}

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

class _FakeAppLocalizations extends Fake implements AppLocalizations {}

void main() {
  const city = PrayerCity(
    id: 'cairo',
    nameAr: 'القاهرة',
    nameEn: 'Cairo',
    latitude: 30.0444,
    longitude: 31.2357,
    timeZone: 'Africa/Cairo',
    countryId: 'eg',
    countryAr: 'مصر',
    countryEn: 'Egypt',
    defaultMethod: 'egyptian',
  );

  final now = DateTime(2026, 9, 12, 16, 0);
  final snapshot = PrayerTimesSnapshot(
    city: city,
    nextName: 'maghrib',
    nextTime: DateTime(2026, 9, 12, 18, 5),
    minutesUntil: 125,
    fajr: DateTime(2026, 9, 12, 4, 15),
    sunrise: DateTime(2026, 9, 12, 5, 40),
    dhuhr: DateTime(2026, 9, 12, 11, 55),
    asr: DateTime(2026, 9, 12, 15, 25),
    maghrib: DateTime(2026, 9, 12, 18, 5),
    isha: DateTime(2026, 9, 12, 19, 25),
  );

  final asrOccurrence = PrayerOccurrence(
    ownerId: 'owner-a',
    localDate: DateTime(2026, 9, 12),
    prayerKey: PrayerKey.asr,
    scheduledAt: DateTime(2026, 9, 12, 15, 25),
  );

  setUpAll(() {
    registerFallbackValue(asrOccurrence);
    registerFallbackValue(PrayerCompanionCommand.confirm);
    registerFallbackValue(_FakeAppLocalizations());
    registerFallbackValue(
      PrayerCompanionRecord(
        occurrence: asrOccurrence,
        status: PrayerCompanionStatus.unconfirmed,
        statusUpdatedAt: asrOccurrence.scheduledAt,
        followUpCount: 0,
        createdAt: asrOccurrence.scheduledAt,
        updatedAt: asrOccurrence.scheduledAt,
      ),
    );
  });

  PrayerCompanionController makeController() {
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
    return PrayerCompanionController(
      applyCommand: ApplyPrayerCompanionCommand(
        repository,
        const PrayerCompanionPolicy(),
        const FixedRecordOwnerProvider('owner-a'),
      ),
      scheduler: scheduler,
      locale: () => const Locale('ar'),
    );
  }

  Widget sheetHarness({
    required PrayerCompanionDaySummary? summary,
    Locale locale = const Locale('ar'),
    PrayerCompanionController? controller,
    VoidCallback? onCompanionChanged,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: locale,
      home: Scaffold(
        body: HomePrayerTimesSheet(
          snapshot: snapshot,
          hijriLabel: '٢٤ ربيع الأول ١٤٤٨',
          skin: HomeSkin.forBrightness(Brightness.light),
          now: () => now,
          companionSummary: summary,
          companionController: controller ?? makeController(),
          onCompanionChanged: onCompanionChanged,
        ),
      ),
    );
  }

  testWidgets('past unconfirmed prayer is not displayed as completed', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      sheetHarness(
        summary: PrayerCompanionDaySummary(
          statusByPrayer: const {
            PrayerKey.fajr: PrayerCompanionStatus.unconfirmed,
            PrayerKey.dhuhr: PrayerCompanionStatus.unconfirmed,
            PrayerKey.asr: PrayerCompanionStatus.unconfirmed,
            PrayerKey.maghrib: PrayerCompanionStatus.unconfirmed,
            PrayerKey.isha: PrayerCompanionStatus.unconfirmed,
          },
          confirmedCount: 0,
          actionableOccurrence: asrOccurrence,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لم يتم التأكيد بعد'), findsNWidgets(3));
    expect(find.bySemanticsLabel('العصر: لم يتم التأكيد بعد'), findsOneWidget);
    expect(find.text('✓ العصر'), findsNothing);
    // Sunrise carries no Companion state at all.
    expect(find.bySemanticsLabel('الشروق: لم يتم التأكيد بعد'), findsNothing);
    expect(find.bySemanticsLabel('الشروق: قادمة'), findsNothing);
    semantics.dispose();
  });

  testWidgets('confirmed prayer has text and icon, not color only', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      sheetHarness(
        summary: const PrayerCompanionDaySummary(
          statusByPrayer: {
            PrayerKey.fajr: PrayerCompanionStatus.confirmed,
            PrayerKey.dhuhr: PrayerCompanionStatus.unconfirmed,
            PrayerKey.asr: PrayerCompanionStatus.unconfirmed,
            PrayerKey.maghrib: PrayerCompanionStatus.unconfirmed,
            PrayerKey.isha: PrayerCompanionStatus.unconfirmed,
          },
          confirmedCount: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تم التأكيد'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('الفجر: تم التأكيد'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('renders all statuses in English LTR with semantic labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      sheetHarness(
        locale: const Locale('en'),
        summary: const PrayerCompanionDaySummary(
          statusByPrayer: {
            PrayerKey.fajr: PrayerCompanionStatus.confirmed,
            PrayerKey.dhuhr: PrayerCompanionStatus.prayNow,
            PrayerKey.asr: PrayerCompanionStatus.remindLater,
            PrayerKey.maghrib: PrayerCompanionStatus.unconfirmed,
            PrayerKey.isha: PrayerCompanionStatus.notYet,
          },
          confirmedCount: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Will pray now'), findsOneWidget);
    expect(find.text('Reminder set'), findsOneWidget);
    expect(find.text('Not yet'), findsOneWidget);
    expect(find.text('1 of 5 confirmed'), findsOneWidget);
  });

  testWidgets(
    'actionable occurrence renders the action group and triggers reload',
    (tester) async {
      var reloaded = false;
      await tester.pumpWidget(
        sheetHarness(
          summary: PrayerCompanionDaySummary(
            statusByPrayer: const {
              PrayerKey.asr: PrayerCompanionStatus.unconfirmed,
            },
            confirmedCount: 0,
            actionableOccurrence: asrOccurrence,
          ),
          onCompanionChanged: () => reloaded = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('صليت'), findsOneWidget);
      expect(find.text('سأصلي الآن'), findsOneWidget);
      expect(find.text('ذكرني لاحقاً'), findsOneWidget);
      expect(find.text('ليس بعد'), findsOneWidget);

      await tester.tap(find.text('صليت'));
      await tester.pumpAndSettle();
      expect(reloaded, isTrue);
    },
  );
}
