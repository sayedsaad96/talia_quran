@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/theme/app_theme.dart';
import 'package:talia_quran/features/home/domain/entities/activity_event.dart';
import 'package:talia_quran/features/home/domain/entities/ayah_of_day.dart';
import 'package:talia_quran/features/home/domain/entities/continue_recitation.dart';
import 'package:talia_quran/features/home/domain/entities/today_checklist.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/home/presentation/pages/home_page.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_background.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/settings/data/user_profile.dart';
import 'package:talia_quran/features/settings/presentation/cubits/profile_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HomeSkin.blurEnabled = false;
  });

  tearDown(() {
    HomeSkin.blurEnabled = true;
  });

  for (final brightness in [Brightness.dark, Brightness.light]) {
    testWidgets('home loaded golden ($brightness)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final skin = HomeSkin.forBrightness(brightness);
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
        todayChecklist: const TodayChecklist(
          tasks: [
            TodayTask(
              kind: TodayTaskKind.reading,
              route: '/quran/page/1',
              isComplete: true,
              current: 1,
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
        ),
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
        ayahOfDay: const AyahOfDay(
          surahId: 1,
          ayahNumber: 1,
          text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          surahNameAr: 'الفاتحة',
          surahNameEn: 'Al-Fatihah',
          pageNumber: 1,
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
          theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
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

      await expectLater(
        find.byType(HomeBackground),
        matchesGoldenFile(
          'goldens/home_loaded_${brightness.name}.png',
        ),
      );
    });
  }
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
