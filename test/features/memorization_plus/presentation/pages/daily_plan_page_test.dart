import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/daily_plan_page.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

void main() {
  testWidgets('DailyPlanPage shows buckets and completion checkmarks', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final datasource = MemorizationPlusLocalDatasourceImpl(prefs);
    final plan = DailyPlan(
      generatedAt: DateTime.now().toUtc(),
      surahId: 67,
      newAyahs: const [
        DailyPlanAyah(
          surahId: 67,
          ayahNumber: 1,
          ayahText: 'text',
          record: null,
        ),
        DailyPlanAyah(
          surahId: 67,
          ayahNumber: 2,
          ayahText: 'text',
          record: null,
        ),
      ],
      nearRevision: const [],
      farRevision: const [],
      completedAyahNums: const [1],
    );
    await datasource.saveDailyPlan(DailyPlanModel.fromEntity(plan));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: DailyPlanPage(
          repositoryOverride: MemorizationPlusRepositoryImpl(
            datasource,
            _UnusedQuranRepository(),
            _FakeStreakReader(),
            ProgressEventsBus(),
            prefs,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's Plan"), findsOneWidget);
    expect(find.textContaining('1 completed'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });
}

class _FakeStreakReader implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}

class _UnusedQuranRepository implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
