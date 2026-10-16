import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/accessibility/clarity_mode.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/theme/app_theme.dart';
import 'package:talia_quran/features/home/domain/entities/activity_event.dart';
import 'package:talia_quran/features/home/domain/entities/continue_recitation.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/home/presentation/pages/home_page.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_activity_feed.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_background.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_continue_card.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_unified_progress.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/settings/data/user_profile.dart';
import 'package:talia_quran/features/settings/presentation/cubits/profile_cubit.dart';
import 'package:talia_quran/features/streak/presentation/cubits/streak_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HomeUnifiedProgress.clock = () => DateTime(2026, 9, 30, 12);
    HomeSkin.blurEnabled = false;
  });

  tearDown(() async {
    HomeSkin.blurEnabled = true;
    if (getIt.isRegistered<ClarityModeController>()) {
      await getIt.unregister<ClarityModeController>();
    }
  });

  Future<void> pumpHome(WidgetTester tester, {required bool clarity}) async {
    SharedPreferences.setMockInitialValues({'clarity_mode_on': clarity});
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<ClarityModeController>(
      ClarityModeController(prefs, flagEnabled: () => true),
    );
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final skin = HomeSkin.forBrightness(Brightness.light);
    final state = HomeLoaded(
      progress: const OverallProgress(
        memorizedAyahs: 120,
        totalAyahs: 6236,
        memorizedSurahs: 4,
        inProgressSurahs: 3,
        totalSurahs: 114,
        memorizedJuz: 1,
        totalJuz: 30,
        readAyahs: 400,
        readSurahs: 8,
        readJuz: 2,
        streakDays: 12,
        lastActiveDate: null,
        achievements: [],
        readPagesCount: 80,
        totalQuranPages: 604,
        learningAyahs: 20,
        reviewAyahs: 15,
      ),
      greeting: 'evening',
      activityStartDate: DateTime(2026, 1, 1),
      totalXp: 420,
      hijriLabel: '١٧ ربيع الآخر ١٤٤٨ هـ',
      gregorianLabel: '9 / 9 / 2026',
      continueRecitation: const ContinueRecitation(
        surahName: 'البقرة',
        surahId: 2,
        startAyah: 1,
        endAyah: 5,
        current: 5,
        total: 286,
        percent: 5 / 286,
        route: '/quran/page/2',
        unit: ContinueRecitationUnit.ayahs,
      ),
      recentActivity: [
        ActivityEvent(
          occurredAt: DateTime(2026, 9, 9, 12),
          kind: ActivityEventKind.reading,
          idempotencyKey: 'reading|20260909|2',
          surahId: 2,
          startAyah: 1,
          endAyah: 5,
          pageNumber: 2,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ProfileCubit>(
              create: (_) => _FakeProfileCubit(
                const ProfileLoaded(UserProfile(name: 'سارة')),
              ),
            ),
            BlocProvider<HomeCubit>.value(value: _FakeHomeCubit(state)),
            BlocProvider<StreakCubit>(
              create: (_) => _FakeStreakCubit(const StreakInitial()),
            ),
            BlocProvider<QuranAudioPlayerCubit>(
              create: (_) => _FakeQuranAudioPlayerCubit(),
            ),
          ],
          child: Scaffold(
            body: HomeBackground(
              skin: skin,
              child: HomeLoadedView(state: state, skin: skin),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('home hides progress and activity feed when clarity is on', (
    tester,
  ) async {
    await pumpHome(tester, clarity: true);
    expect(find.byType(HomeUnifiedProgress), findsNothing);
    expect(find.byType(HomeActivityFeed), findsNothing);
    expect(find.byType(HomeContinueCard), findsOneWidget);
  });

  testWidgets('home is unchanged when clarity is off', (tester) async {
    await pumpHome(tester, clarity: false);
    expect(find.byType(HomeUnifiedProgress), findsOneWidget);
    expect(find.byType(HomeActivityFeed), findsOneWidget);
    expect(find.byType(HomeContinueCard), findsOneWidget);
  });
}

class _FakeProfileCubit extends Cubit<ProfileState> implements ProfileCubit {
  _FakeProfileCubit(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHomeCubit extends Cubit<HomeState> implements HomeCubit {
  _FakeHomeCubit(super.initialState);
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStreakCubit extends Cubit<StreakState> implements StreakCubit {
  _FakeStreakCubit(super.initialState);
  @override
  Future<void> loadStreak() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuranAudioPlayerCubit extends Cubit<QuranAudioPlayerState>
    implements QuranAudioPlayerCubit {
  _FakeQuranAudioPlayerCubit() : super(const QuranAudioPlayerState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
