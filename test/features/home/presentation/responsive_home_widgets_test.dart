// Ensures the Home page's building blocks lay out cleanly across the range
// of mobile sizes and text-scale factors we support: from small phones
// (~320dp wide, e.g. iPhone SE) to large phones/phablets, in both LTR and
// RTL, and from default to large accessibility font scaling. Any Flutter
// layout ("RenderFlex overflowed") error thrown during a pump is reported by
// the test framework and captured below via `tester.takeException()`.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/journey/journey_presentation_data.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/audio_resume_store.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/streak_risk_evaluator.dart';
import 'package:talia_quran/core/theme/app_theme.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/home/domain/entities/activity_event.dart';
import 'package:talia_quran/features/home/domain/entities/ayah_of_day.dart';
import 'package:talia_quran/features/home/domain/entities/continue_recitation.dart';
import 'package:talia_quran/features/home/domain/entities/home_contextual_slot.dart';
import 'package:talia_quran/features/home/domain/entities/today_checklist.dart';
import 'package:talia_quran/features/home/domain/services/home_occasion_service.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/home/presentation/pages/home_page.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/daily_wird_card.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_activity_feed.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_action_tiles.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_ayah_of_day.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_background.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_context_bar.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_contextual_slot.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_continue_card.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_daily_challenge_card.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_first_run.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_momentum_strip.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_night_header.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_parent_children.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_quick_access.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_resume_chips.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_today_checklist.dart';
import 'package:talia_quran/features/home/presentation/widgets/next_best_action_card.dart';
import 'package:talia_quran/features/home/presentation/widgets/resume_session_card.dart';
import 'package:talia_quran/features/home/presentation/widgets/unified_hero_action_card.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/family_dashboard.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/settings/data/user_profile.dart';
import 'package:talia_quran/features/settings/presentation/cubits/profile_cubit.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';
import 'package:talia_quran/features/streak/presentation/cubits/streak_cubit.dart';

/// Narrow-to-wide phone widths we must not overflow at.
const _kWidths = <double>[320, 360, 414, 600];

/// Default plus large accessibility text-scale factors.
const _kTextScales = <double>[1.0, 1.3, 2.0];

const _kLocales = <Locale>[Locale('ar'), Locale('en')];

const _kThemes = <Brightness>[Brightness.dark, Brightness.light];

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required double width,
  required double textScale,
  required Locale locale,
  Brightness brightness = Brightness.light,
  List<BlocProvider<dynamic>> providers = const [],
}) async {
  await tester.binding.setSurfaceSize(Size(width, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  Widget app = MaterialApp(
    locale: locale,
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        );
      },
    ),
  );

  if (providers.isNotEmpty) {
    app = MultiBlocProvider(providers: providers, child: app);
  }

  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Future<void> _pumpPage(
  WidgetTester tester,
  Widget child, {
  required double width,
  required double textScale,
  required Locale locale,
  required Brightness brightness,
  List<BlocProvider<dynamic>> providers = const [],
}) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  Widget app = MaterialApp(
    locale: locale,
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(body: child),
        );
      },
    ),
  );

  if (providers.isNotEmpty) {
    app = MultiBlocProvider(providers: providers, child: app);
  }

  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// Runs [build] across the full matrix of widths, text scales and locales,
/// failing with a descriptive message if any combination throws.
void _forEachViewportAndTheme(
  String description,
  Future<void> Function(
    WidgetTester tester,
    double width,
    double textScale,
    Locale locale,
    Brightness brightness,
  )
      run,
) {
  for (final locale in _kLocales) {
    for (final width in _kWidths) {
      for (final textScale in _kTextScales) {
        for (final brightness in _kThemes) {
          testWidgets(
            '$description (locale=${locale.languageCode}, width=$width, '
            'textScale=$textScale, brightness=$brightness)',
            (tester) async {
              await run(tester, width, textScale, locale, brightness);
              expect(
                tester.takeException(),
                isNull,
                reason: '$description overflowed at width=$width, '
                    'textScale=$textScale, locale=${locale.languageCode}, '
                    'brightness=$brightness',
              );
            },
          );
        }
      }
    }
  }
}

/// Runs [build] across the full matrix of widths, text scales and locales,
/// failing with a descriptive message if any combination throws.
void _forEachViewport(
  String description,
  Future<void> Function(
    WidgetTester tester,
    double width,
    double textScale,
    Locale locale,
  )
      run,
) {
  for (final locale in _kLocales) {
    for (final width in _kWidths) {
      for (final textScale in _kTextScales) {
        testWidgets(
          '$description (locale=${locale.languageCode}, width=$width, '
          'textScale=$textScale)',
          (tester) async {
            await run(tester, width, textScale, locale);
            expect(
              tester.takeException(),
              isNull,
              reason: '$description overflowed at width=$width, '
                  'textScale=$textScale, locale=${locale.languageCode}',
            );
          },
        );
      }
    }
  }
}

OverallProgress _progress() => const OverallProgress(
      memorizedAyahs: 9999,
      totalAyahs: 6236,
      memorizedSurahs: 60,
      totalSurahs: 114,
      memorizedJuz: 12,
      totalJuz: 30,
      readAyahs: 6236,
      readSurahs: 114,
      readJuz: 30,
      streakDays: 365,
      lastActiveDate: null,
      achievements: [
        Achievement(
          id: 'full_quran_read',
          titleKey: 'k',
          descriptionKey: 'd',
          icon: 'star',
          isUnlocked: true,
          category: AchievementCategory.reading,
          currentValue: 604,
          targetValue: 604,
        ),
      ],
      readPagesCount: 604,
      totalQuranPages: 604,
      learningAyahs: 42,
      reviewAyahs: 87,
      overdueReviews: 9999,
      inProgressSurahs: 8,
    );

HomeLoaded _homeLoaded({
  TodayChecklist? todayChecklist,
  AyahOfDay? ayahOfDay,
  AudioResumePosition? audioResume,
  HomeSlotCandidate? activeSlot,
  List<FamilyChildEntry> familyChildren = const [],
  StreakRisk? streakRisk,
  HomeOccasion occasion = HomeOccasion.none,
  ContinueRecitation? continueRecitation,
  List<ActivityEvent> recentActivity = const [],
  PrayerTimesSnapshot? prayerSnapshot,
}) {
  return HomeLoaded(
    progress: _progress(),
    greeting: 'morning',
    activityStartDate: DateTime(2024, 1, 1),
    totalXp: 987654,
    todayChecklist: todayChecklist,
    ayahOfDay: ayahOfDay,
    audioResume: audioResume,
    activeSlot: activeSlot,
    familyChildren: familyChildren,
    streakRisk: streakRisk,
    occasion: occasion,
    hijriLabel: 'الخميس ١٧ ربيع الآخر ١٤٤٨ هـ',
    gregorianLabel: '8 / 9 / 2026',
    weeklyActiveDays: 7,
    weeklyActivityCount: 9999,
    activityCountsByDay: const {},
    heroMinutes: 45,
    continueRecitation: continueRecitation,
    recentActivity: recentActivity,
    prayerSnapshot: prayerSnapshot,
  );
}

ContinueRecitation _continueRecitation() => const ContinueRecitation(
      surahName: 'البقرة',
      surahId: 2,
      startAyah: 1,
      endAyah: 5,
      current: 5,
      total: 286,
      percent: 5 / 286,
      route: '/quran/page/2',
      unit: ContinueRecitationUnit.ayahs,
    );

TodayChecklist _checklist() => const TodayChecklist(
      tasks: [
        TodayTask(
          kind: TodayTaskKind.reading,
          route: '/quran/page/1',
          isComplete: false,
          current: 0,
          total: 1,
        ),
        TodayTask(
          kind: TodayTaskKind.memorize,
          route: '/memorization-hub',
          isComplete: false,
          current: 2,
          total: 10,
        ),
        TodayTask(
          kind: TodayTaskKind.review,
          route: '/memorization-hub',
          isComplete: false,
          current: 0,
          total: 5,
        ),
        TodayTask(
          kind: TodayTaskKind.azkar,
          route: '/azkar/morning',
          isComplete: true,
          current: 1,
          total: 1,
        ),
      ],
    );

List<ActivityEvent> _activity() => [
      ActivityEvent(
        occurredAt: DateTime(2026, 9, 9, 12),
        kind: ActivityEventKind.reading,
        idempotencyKey: 'reading|20260909|2',
        surahId: 2,
        startAyah: 1,
        endAyah: 5,
        pageNumber: 2,
      ),
      ActivityEvent(
        occurredAt: DateTime(2026, 9, 8, 18),
        kind: ActivityEventKind.review,
        idempotencyKey: 'review|s1|block',
        surahId: 1,
        startAyah: 1,
        endAyah: 7,
      ),
    ];

PrayerTimesSnapshot _prayer() => PrayerTimesSnapshot(
      city: const PrayerCity(
        id: 'cairo',
        nameAr: 'القاهرة',
        nameEn: 'Cairo',
        latitude: 30,
        longitude: 31,
      ),
      nextName: 'maghrib',
      nextTime: DateTime(2026, 9, 9, 18, 12),
      minutesUntil: 42,
    );

List<BlocProvider<dynamic>> _profileProviders() => [
      BlocProvider<ProfileCubit>(
        create: (_) => _FakeProfileCubit(
          const ProfileLoaded(
            UserProfile(
              name: 'محمد عبدالرحمن الأنصاري الطويل جداً جداً لاختبار التمرير',
            ),
          ),
        ),
      ),
      BlocProvider<HomeCubit>(
        create: (_) => _FakeHomeCubit(_homeLoaded()),
      ),
    ];

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileCubit extends Cubit<ProfileState> implements ProfileCubit {
  _FakeProfileCubit(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    HomeSkin.blurEnabled = false;
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    getIt.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('HomeMomentumStrip', () {
    _forEachViewport('renders without overflow', (tester, width, scale, locale) async {
      await _pump(
        tester,
        HomeMomentumStrip(
          state: _homeLoaded(
            streakRisk: const StreakRisk(
              isAtRisk: true,
              freezesAvailable: 3,
              hasActivityToday: false,
              currentStreak: 365,
            ),
          ),
          isDark: false,
        ),
        width: width,
        textScale: scale,
        locale: locale,
        providers: [
          BlocProvider<StreakCubit>(
            create: (_) => _FakeStreakCubit(
              const StreakLoaded(
                streak: StreakEntity(currentStreak: 365, longestStreak: 400),
              ),
            ),
          ),
        ],
      );
    });
  });

  group('HomeContextBar', () {
    _forEachViewport('renders without overflow', (tester, width, scale, locale) async {
      await _pump(
        tester,
        HomeContextBar(
          state: _homeLoaded(occasion: HomeOccasion.ramadan),
          isDark: false,
        ),
        width: width,
        textScale: scale,
        locale: locale,
        providers: [
          BlocProvider<ProfileCubit>(
            create: (_) => _FakeProfileCubit(
              const ProfileLoaded(
                UserProfile(
                  name:
                      'محمد عبدالرحمن الأنصاري الطويل جداً جداً لاختبار التمرير',
                ),
              ),
            ),
          ),
        ],
      );
    });
  });

  group('HomeTodayChecklist', () {
    _forEachViewport('renders without overflow', (tester, width, scale, locale) async {
      await _pump(
        tester,
        const HomeTodayChecklist(
          checklist: TodayChecklist(
            tasks: [
              TodayTask(
                kind: TodayTaskKind.reading,
                route: '/quran/page/1',
                isComplete: false,
                current: 0,
                total: 1,
              ),
              TodayTask(
                kind: TodayTaskKind.memorize,
                route: '/memorization-hub',
                isComplete: false,
                current: 2,
                total: 10,
              ),
              TodayTask(
                kind: TodayTaskKind.review,
                route: '/memorization-hub',
                isComplete: false,
                current: 0,
                total: 9999,
              ),
              TodayTask(
                kind: TodayTaskKind.azkar,
                route: '/azkar/morning',
                isComplete: true,
                current: 1,
                total: 1,
              ),
            ],
          ),
          isDark: false,
        ),
        width: width,
        textScale: scale,
        locale: locale,
      );
    });
  });

  group('HomeAyahOfDayCard', () {
    _forEachViewportAndTheme('renders without overflow', (
      tester,
      width,
      scale,
      locale,
      brightness,
    ) async {
      await _pump(
        tester,
        HomeAyahOfDayCard(
          skin: HomeSkin.forBrightness(brightness),
          ayah: const AyahOfDay(
            surahId: 2,
            ayahNumber: 255,
            text:
                'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا '
                'تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ '
                'وَمَا فِي الْأَرْضِ وَلَا يَئُودُهُ حِفْظُهُمَا وَهُوَ '
                'الْعَلِيُّ الْعَظِيمُ',
            surahNameAr: 'البقرة',
            surahNameEn: 'Al-Baqarah',
            pageNumber: 42,
          ),
        ),
        width: width,
        textScale: scale,
        locale: locale,
        brightness: brightness,
      );
    });

    testWidgets('shows the seasonal context for a Ramadan ayah', (tester) async {
      await _pump(
        tester,
        HomeAyahOfDayCard(
          skin: HomeSkin.forBrightness(Brightness.light),
          ayah: const AyahOfDay(
            surahId: 2,
            ayahNumber: 185,
            text: 'شَهْرُ رَمَضَانَ الَّذِي أُنزِلَ فِيهِ الْقُرْآنُ',
            surahNameAr: 'البقرة',
            surahNameEn: 'Al-Baqarah',
            pageNumber: 28,
            context: DailyAyahContext.ramadanStart,
          ),
        ),
        width: 360,
        textScale: 1,
        locale: const Locale('ar'),
      );

      expect(find.text('آية لبداية رمضان'), findsOneWidget);
    });
  });

  group('HomeResumeChips', () {
    _forEachViewport('renders without overflow', (tester, width, scale, locale) async {
      await _pump(
        tester,
        HomeResumeChips(
          state: _homeLoaded(
            audioResume: const AudioResumePosition(
              surahId: 2,
              ayahNumber: 123,
              reciterId: null,
              scope: PlayScope.surah,
            ),
          ),
          isDark: false,
        ),
        width: width,
        textScale: scale,
        locale: locale,
      );
    });
  });

  group('HomeContextualSlot (streak risk)', () {
    _forEachViewportAndTheme('renders without overflow', (
      tester,
      width,
      scale,
      locale,
      brightness,
    ) async {
      await _pump(
        tester,
        HomeContextualSlot(
          state: _homeLoaded(
            activeSlot: const HomeSlotCandidate(
              kind: HomeSlotKind.streakRisk,
              route: '/progress',
            ),
          ),
          skin: HomeSkin.forBrightness(brightness),
        ),
        width: width,
        textScale: scale,
        locale: locale,
        brightness: brightness,
      );
    });
  });

  group('HomeContextualSlot (sign in)', () {
    _forEachViewportAndTheme('renders without overflow', (
      tester,
      width,
      scale,
      locale,
      brightness,
    ) async {
      await _pump(
        tester,
        HomeContextualSlot(
          state: _homeLoaded(
            activeSlot: const HomeSlotCandidate(
              kind: HomeSlotKind.signIn,
              route: '/settings',
            ),
          ),
          skin: HomeSkin.forBrightness(brightness),
        ),
        width: width,
        textScale: scale,
        locale: locale,
        brightness: brightness,
        providers: [
          BlocProvider<AuthCubit>(
            create: (_) => _FakeAuthCubit(const AuthUnauthenticated()),
          ),
        ],
      );
    });
  });

  group('HomeQuickAccess', () {
    _forEachViewportAndTheme('renders without overflow', (
      tester,
      width,
      scale,
      locale,
      brightness,
    ) async {
      await _pump(
        tester,
        HomeQuickAccess(
          state: _homeLoaded(),
          skin: HomeSkin.forBrightness(brightness),
        ),
        width: width,
        textScale: scale,
        locale: locale,
        brightness: brightness,
      );
    });
  });

  group('HomeParentChildren', () {
    _forEachViewportAndTheme('renders without overflow', (
      tester,
      width,
      scale,
      locale,
      brightness,
    ) async {
      await _pump(
        tester,
        HomeParentChildren(
          skin: HomeSkin.forBrightness(brightness),
          children: const [
            FamilyChildEntry(
              childUserId: 'c1',
              displayName:
                  'محمد عبدالرحمن الأنصاري الطويل جداً جداً لاختبار التمرير',
              isLocal: true,
            ),
            FamilyChildEntry(
              childUserId: 'c2',
              displayName: 'Sarah',
              isLocal: true,
            ),
          ],
        ),
        width: width,
        textScale: scale,
        locale: locale,
        brightness: brightness,
      );
    });
  });

  group('HomeFirstRun', () {
    _forEachViewport('renders without overflow', (tester, width, scale, locale) async {
      await _pump(
        tester,
        const HomeFirstRun(isDark: false),
        width: width,
        textScale: scale,
        locale: locale,
      );
    });
  });

  group('UnifiedHeroActionCard', () {
    _forEachViewport('renders without overflow', (tester, width, scale, locale) async {
      await _pump(
        tester,
        UnifiedHeroActionCard(
          data: const JourneyPresentationData(
            title: 'استكمال حفظ سورة البقرة من حيث توقفت في آخر مرة',
            subtitle:
                'راجع الآيات القديمة قبل الانتقال إلى الآيات الجديدة لتثبيت الحفظ · 45 دقيقة',
            icon: Icons.menu_book_rounded,
            route: '/memorization-hub',
          ),
          isDark: false,
          onTap: () {},
        ),
        width: width,
        textScale: scale,
        locale: locale,
      );
    });
  });

  group('NextBestActionCard', () {
    _forEachViewport('renders without overflow', (tester, width, scale, locale) async {
      await _pump(
        tester,
        NextBestActionCard(state: _homeLoaded(), isDark: false),
        width: width,
        textScale: scale,
        locale: locale,
      );
    });
  });

  group('ResumeSessionCard', () {
    _forEachViewport('renders without overflow', (tester, width, scale, locale) async {
      await _pump(
        tester,
        const ResumeSessionCard(
          location: '/memorization-plus/v2-session?surahId=2',
          isDark: false,
          isKids: false,
        ),
        width: width,
        textScale: scale,
        locale: locale,
      );
    });
  });

  group('DailyWirdCard', () {
    _forEachViewport('renders without overflow', (tester, width, scale, locale) async {
      await _pump(
        tester,
        DailyWirdCard(state: _homeLoaded(), isDark: false),
        width: width,
        textScale: scale,
        locale: locale,
      );
    });
  });

  group('HomeNightHeader', () {
    _forEachViewportAndTheme('renders without overflow', (
      tester,
      width,
      scale,
      locale,
      brightness,
    ) async {
      await _pump(
        tester,
        HomeNightHeader(
          state: _homeLoaded(
            occasion: HomeOccasion.ramadan,
            prayerSnapshot: _prayer(),
          ),
          skin: HomeSkin.forBrightness(brightness),
        ),
        width: width,
        textScale: scale,
        locale: locale,
        brightness: brightness,
        providers: _profileProviders(),
      );
    });
  });

  group('HomeContinueCard', () {
    _forEachViewportAndTheme('renders without overflow', (
      tester,
      width,
      scale,
      locale,
      brightness,
    ) async {
      await _pump(
        tester,
        HomeContinueCard(
          recitation: _continueRecitation(),
          skin: HomeSkin.forBrightness(brightness),
        ),
        width: width,
        textScale: scale,
        locale: locale,
        brightness: brightness,
      );
    });
  });

  group('HomeActionTiles', () {
    _forEachViewportAndTheme('renders without overflow', (
      tester,
      width,
      scale,
      locale,
      brightness,
    ) async {
      await _pump(
        tester,
        HomeActionTiles(
          state: _homeLoaded(todayChecklist: _checklist()),
          skin: HomeSkin.forBrightness(brightness),
        ),
        width: width,
        textScale: scale,
        locale: locale,
        brightness: brightness,
      );
    });
  });

  group('HomeDailyChallengeCard', () {
    _forEachViewportAndTheme('renders without overflow', (
      tester,
      width,
      scale,
      locale,
      brightness,
    ) async {
      await _pump(
        tester,
        HomeDailyChallengeCard(
          state: _homeLoaded(todayChecklist: _checklist()),
          skin: HomeSkin.forBrightness(brightness),
        ),
        width: width,
        textScale: scale,
        locale: locale,
        brightness: brightness,
      );
    });
  });

  group('HomeJourneyRingCard', () {
    _forEachViewportAndTheme('renders without overflow', (
      tester,
      width,
      scale,
      locale,
      brightness,
    ) async {
      await _pump(
        tester,
        HomeJourneyRingCard(
          state: _homeLoaded(),
          skin: HomeSkin.forBrightness(brightness),
        ),
        width: width,
        textScale: scale,
        locale: locale,
        brightness: brightness,
      );
    });
  });

  group('HomeActivityFeed', () {
    _forEachViewportAndTheme('renders without overflow', (
      tester,
      width,
      scale,
      locale,
      brightness,
    ) async {
      await _pump(
        tester,
        HomeActivityFeed(
          state: _homeLoaded(recentActivity: _activity()),
          skin: HomeSkin.forBrightness(brightness),
        ),
        width: width,
        textScale: scale,
        locale: locale,
        brightness: brightness,
      );
    });
  });

  group('HomeLoadedView', () {
    _forEachViewportAndTheme('renders without overflow', (
      tester,
      width,
      scale,
      locale,
      brightness,
    ) async {
      final skin = HomeSkin.forBrightness(brightness);
      final state = _homeLoaded(
        todayChecklist: _checklist(),
        continueRecitation: _continueRecitation(),
        recentActivity: _activity(),
        prayerSnapshot: _prayer(),
        ayahOfDay: const AyahOfDay(
          surahId: 2,
          ayahNumber: 255,
          text: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
          surahNameAr: 'البقرة',
          surahNameEn: 'Al-Baqarah',
          pageNumber: 42,
        ),
        activeSlot: const HomeSlotCandidate(
          kind: HomeSlotKind.streakRisk,
          route: '/progress',
        ),
        familyChildren: const [
          FamilyChildEntry(
            childUserId: 'c1',
            displayName: 'محمد',
            isLocal: true,
          ),
        ],
      );
      await _pumpPage(
        tester,
        HomeBackground(
          skin: skin,
          child: HomeLoadedView(state: state, skin: skin),
        ),
        width: width,
        textScale: scale,
        locale: locale,
        brightness: brightness,
        providers: _profileProviders(),
      );
    });
  });
}
