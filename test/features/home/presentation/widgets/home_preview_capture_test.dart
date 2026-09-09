/// Renders the Home surface with the real Arabic fonts, icon font and bundled
/// images so the resulting PNGs can be reviewed as actual design references.
/// The regular goldens run without fonts and are only useful for regressions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(rootBundle.load(path));
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont('Amiri', [
      'assets/fonts/Amiri/Amiri-Regular.ttf',
      'assets/fonts/Amiri/Amiri-Bold.ttf',
    ]);
    await _loadFont('Noto_Naskh_Arabic', [
      'assets/fonts/Noto_Naskh_Arabic/NotoNaskhArabic-Regular.ttf',
      'assets/fonts/Noto_Naskh_Arabic/NotoNaskhArabic-Bold.ttf',
    ]);
    try {
      await _loadFont('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']);
    } catch (_) {
      // Icon font is unavailable in some SDK layouts; previews still render.
    }
  });

  for (final brightness in [Brightness.dark, Brightness.light]) {
    testWidgets('capture ${brightness.name}', (tester) async {
      HomeSkin.blurEnabled = false;
      await tester.binding.setSurfaceSize(const Size(412, 1800));
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        return tester.binding.setSurfaceSize(null);
      });

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
        hijriLabel: 'الأربعاء ١٧ ربيع الآخر ١٤٤٨ هـ',
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
          text: 'وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ وَرَحْمَةٌ لِلْمُؤْمِنِينَ',
          surahNameAr: 'الإسراء',
          surahNameEn: 'Al-Isra',
          pageNumber: 291,
        ),
        recentActivity: [
          ActivityEvent(
            occurredAt: DateTime.now().subtract(const Duration(hours: 2)),
            kind: ActivityEventKind.reading,
            idempotencyKey: 'reading|1',
            surahId: 2,
            startAyah: 1,
            endAyah: 5,
            pageNumber: 2,
          ),
          ActivityEvent(
            occurredAt: DateTime.now().subtract(const Duration(days: 1)),
            kind: ActivityEventKind.review,
            idempotencyKey: 'review|1',
            surahId: 36,
            startAyah: 1,
            endAyah: 12,
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
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() async {
        for (final asset in [HomeSkin.backgroundAsset, HomeSkin.logoAsset]) {
          await precacheImage(
            AssetImage(asset),
            tester.element(find.byType(HomeBackground)),
          );
        }
      });
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(HomeBackground),
        matchesGoldenFile('preview/home_preview_${brightness.name}.png'),
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
