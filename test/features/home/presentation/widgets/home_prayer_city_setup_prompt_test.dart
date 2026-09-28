import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_night_header.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<PrayerTimesService>(PrayerTimesService(prefs));
  });

  tearDown(() => getIt.reset());

  testWidgets('home asks for a city when prayer times start enabled', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_homeHeader());

    expect(
      find.text('Choose your city to show accurate prayer times.'),
      findsOneWidget,
    );
    expect(find.text('Choose city'), findsOneWidget);

    await getIt<PrayerTimesService>().setCityId('cairo');
    final snapshot =
        await getIt<PrayerTimesService>().current(isArabic: false);
    await tester.pumpWidget(_homeHeader(prayerSnapshot: snapshot));
    expect(find.text('Choose city'), findsNothing);
  });
}

Widget _homeHeader({PrayerTimesSnapshot? prayerSnapshot}) {
  const progress = OverallProgress(
    memorizedAyahs: 0,
    totalAyahs: 6236,
    memorizedSurahs: 0,
    totalSurahs: 114,
    memorizedJuz: 0,
    totalJuz: 30,
    readAyahs: 0,
    readSurahs: 0,
    readJuz: 0,
    streakDays: 0,
    lastActiveDate: null,
    achievements: [],
    readPagesCount: 0,
    totalQuranPages: 604,
    learningAyahs: 0,
    reviewAyahs: 0,
  );
  final state = HomeLoaded(
    progress: progress,
    greeting: 'morning',
    activityStartDate: DateTime(2026, 1, 1),
    prayerSnapshot: prayerSnapshot,
  );
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: SingleChildScrollView(
        child: HomeNightHeader(
          state: state,
          skin: HomeSkin.forBrightness(Brightness.dark),
        ),
      ),
    ),
  );
}
