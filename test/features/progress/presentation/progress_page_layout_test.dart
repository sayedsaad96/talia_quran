import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/features/progress/domain/usecases/get_progress_usecase.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/core/theme/app_theme.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/progress/presentation/cubits/progress_cubit.dart';
import 'package:talia_quran/features/progress/presentation/pages/progress_page.dart';

/// Renders the full progress page at a small phone width with every
/// optional chip populated, to catch overflows in both locales.
void main() {
  late ProgressEventsBus bus;

  setUp(() {
    bus = ProgressEventsBus();
    getIt
      ..registerSingleton<ProgressEventsBus>(bus)
      ..registerSingleton<AchievementService>(_FakeAchievementService())
      ..registerFactory<ProgressCubit>(() => _SeededProgressCubit(bus));
  });

  tearDown(() async {
    await getIt.reset();
    bus.dispose();
  });

  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      testWidgets('renders without overflow (${locale.languageCode}, '
          '${theme.brightness.name})', (tester) async {
        tester.view.physicalSize = const Size(360, 3200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            theme: theme,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ProgressPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final l10n = lookupAppLocalizations(locale);
        expect(find.text(l10n.progressNextMilestoneTitle), findsOneWidget);
        expect(find.text(l10n.progressStartReview), findsOneWidget);
        expect(find.text(l10n.progressDueReviewsNudge(12)), findsOneWidget);
      });
    }
  }

  testWidgets('survives a large text scale', (tester) async {
    tester.view.physicalSize = const Size(360, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        theme: AppTheme.light,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: const ProgressPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

class _SeededProgressCubit extends ProgressCubit {
  _SeededProgressCubit(ProgressEventsBus bus)
    : super(_NeverCalledUsecase(), _NeverCalledResolver(), bus);

  @override
  Future<void> load() async {
    emit(
      ProgressLoaded(
        progress: OverallProgress(
          memorizedAyahs: 412,
          startedAyahs: 530,
          reviewedAyahsTotal: 12840,
          overdueReviews: 5,
          lastReviewedAt: DateTime(2026, 9, 28),
          lastMemorizedSurahId: 2,
          lastMemorizedAyahNumber: 286,
          totalAyahs: 6236,
          memorizedSurahs: 37,
          totalSurahs: 114,
          memorizedJuz: 1,
          totalJuz: 30,
          readAyahs: 3120,
          readSurahs: 60,
          readJuz: 14,
          streakDays: 128,
          lastActiveDate: DateTime(2026, 9, 28),
          achievements: [
            for (final (id, current, target, category) in const [
              ('first_page', 1, 1, AchievementCategory.reading),
              ('half_quran_read', 280, 302, AchievementCategory.reading),
              ('juz_amma', 540, 564, AchievementCategory.memorization),
              ('year_streak', 128, 365, AchievementCategory.streak),
            ])
              Achievement(
                id: id,
                titleKey: id,
                descriptionKey: id,
                icon: '',
                isUnlocked: current >= target,
                category: category,
                currentValue: current,
                targetValue: target,
              ),
          ],
          readPagesCount: 280,
          totalQuranPages: 604,
          learningAyahs: 118,
          reviewAyahs: 12,
          kidsPoints: 340,
          kidsStars: 21,
        ),
        activityCountsByDay: const {'2026-09-28': 12},
        activityStartDate: DateTime(2025, 1, 1),
        totalXp: 125430,
        xpLevelProgress: 0.4,
      ),
    );
  }
}

class _FakeAchievementService implements AchievementService {
  @override
  List<CertificateAward> getEarnedCertificates({required bool isKids}) => [
    CertificateAward(
      id: 'surah-67',
      titleAr: 'سورة الملك',
      type: CertificateType.surah,
      earnedAt: DateTime.utc(2026, 7, 9),
      surahId: 67,
    ),
  ];

  @override
  bool hasNewCertificate({required bool isKids}) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NeverCalledUsecase implements GetProgressUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NeverCalledResolver implements MemorizationPathResolver {
  @override
  Stream<void> get changes => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
