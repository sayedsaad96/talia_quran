import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/hijri_date_adjustment.dart';
import 'package:talia_quran/core/theme/app_theme.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/home/presentation/pages/home_page.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_background.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/settings/data/user_profile.dart';
import 'package:talia_quran/features/settings/presentation/cubits/profile_cubit.dart';
import 'package:talia_quran/features/streak/presentation/cubits/streak_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late HijriDateAdjustment adjustment;

  setUp(() async {
    HomeSkin.blurEnabled = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    adjustment = HijriDateAdjustment(prefs);
    getIt.registerSingleton<HijriDateAdjustment>(adjustment);
    getIt.registerSingleton<ExperienceFlags>(
      ExperienceFlags(
        (key) =>
            key == ExperienceFeature.seasonalRamadan.storageKey ? true : null,
      ),
    );
  });

  tearDown(() async {
    HomeSkin.blurEnabled = true;
    await getIt.reset();
  });

  final state = HomeLoaded(
    progress: const OverallProgress(
      memorizedAyahs: 120,
      totalAyahs: 6236,
      memorizedSurahs: 0,
      inProgressSurahs: 0,
      totalSurahs: 114,
      memorizedJuz: 0,
      totalJuz: 30,
      readAyahs: 400,
      readSurahs: 0,
      readJuz: 0,
      streakDays: 0,
      lastActiveDate: null,
      achievements: [],
      readPagesCount: 80,
      totalQuranPages: 604,
      learningAyahs: 0,
      reviewAyahs: 0,
    ),
    greeting: 'evening',
    activityStartDate: DateTime(2026, 1, 1),
    totalXp: 0,
    hijriLabel: '',
    gregorianLabel: '',
  );

  Widget app(DateTime Function() clock) {
    final skin = HomeSkin.forBrightness(Brightness.light);
    return MaterialApp(
      locale: const Locale('ar'),
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>(
            create: (_) =>
                _FakeProfile(const ProfileLoaded(UserProfile(name: 'x'))),
          ),
          BlocProvider<HomeCubit>.value(value: _FakeHome(state)),
          BlocProvider<StreakCubit>(create: (_) => _FakeStreak()),
          BlocProvider<QuranAudioPlayerCubit>(create: (_) => _FakeAudio()),
        ],
        child: Scaffold(
          body: HomeBackground(
            skin: skin,
            child: HomeLoadedView(state: state, skin: skin, clock: clock),
          ),
        ),
      ),
    );
  }

  Future<void> pumpAt(WidgetTester tester, DateTime at) async {
    await tester.pumpWidget(app(() => at));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('a new day remounts the Ramadan card with the new phase', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAt(tester, DateTime(2027, 2, 7, 12));
    expect(find.text('استعد لرمضان'), findsOneWidget);

    await pumpAt(tester, DateTime(2027, 2, 8, 12));
    expect(find.text('استعد لرمضان'), findsNothing);
    expect(find.textContaining('من رمضان'), findsOneWidget);
  });

  testWidgets('changing the Hijri adjustment remounts the Ramadan card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final day = DateTime(2027, 2, 7, 12);
    await pumpAt(tester, day);
    expect(find.text('استعد لرمضان'), findsOneWidget);

    await tester.runAsync(() => adjustment.setDays(1));
    await pumpAt(tester, day);
    expect(find.text('استعد لرمضان'), findsNothing);
    expect(find.textContaining('من رمضان'), findsOneWidget);
  });
}

class _FakeProfile extends Cubit<ProfileState> implements ProfileCubit {
  _FakeProfile(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHome extends Cubit<HomeState> implements HomeCubit {
  _FakeHome(super.initialState);
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStreak extends Cubit<StreakState> implements StreakCubit {
  _FakeStreak() : super(const StreakInitial());
  @override
  Future<void> loadStreak() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAudio extends Cubit<QuranAudioPlayerState>
    implements QuranAudioPlayerCubit {
  _FakeAudio() : super(const QuranAudioPlayerState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
