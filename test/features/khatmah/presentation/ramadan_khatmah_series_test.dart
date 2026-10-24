import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_plan_model.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/presentation/khatmah_setup_prefill.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_completion_page.dart';

void main() {
  final lastDay = DateTime(2027, 3, 9);
  KhatmahSeasonLink link(int round) =>
      KhatmahSeasonLink(round: round, rounds: 2, lastDay: lastDay);

  KhatmahPlan plan({KhatmahSeasonLink? seasonLink, int portions = 1}) =>
      KhatmahPlan(
        id: 'p',
        title: KhatmahPlan.defaultTitle,
        targetPagesPerDay: 41,
        targetDays: 15,
        startDate: DateTime(2027, 2, 8),
        expectedEndDate: DateTime(2027, 2, 22),
        portionsPerDay: portions,
        seasonLink: seasonLink,
      );

  group('model', () {
    test('portions and the season link survive a round trip', () {
      final original = plan(seasonLink: link(1), portions: 5);
      final json = KhatmahPlanModel.fromEntity(original).toJson();
      expect(json['seasonLink'], {
        'round': 1,
        'rounds': 2,
        'lastDay': '2027-03-09',
      });
      final restored = KhatmahPlanModel.fromJson(json).toEntity();
      expect(restored.portionsPerDay, 5);
      expect(restored.seasonLink, link(1));
    });

    test('older plans read as unsplit and unlinked; nothing extra is '
        'written for them', () {
      final json = KhatmahPlanModel.fromEntity(plan()).toJson();
      expect(json.containsKey('portionsPerDay'), isFalse);
      expect(json.containsKey('seasonLink'), isFalse);
      final restored = KhatmahPlanModel.fromJson(json).toEntity();
      expect(restored.portionsPerDay, 1);
      expect(restored.seasonLink, isNull);
    });

    test('malformed values fall back instead of failing the plan', () {
      final json = KhatmahPlanModel.fromEntity(plan()).toJson()
        ..['portionsPerDay'] = 9
        ..['seasonLink'] = {'round': 3, 'rounds': 2, 'lastDay': 'x'};
      final restored = KhatmahPlanModel.fromJson(json).toEntity();
      expect(restored.portionsPerDay, 1);
      expect(restored.seasonLink, isNull);
      final numericDay = KhatmahPlanModel.fromEntity(plan()).toJson()
        ..['seasonLink'] = {'round': 1, 'rounds': 2, 'lastDay': 123};
      expect(KhatmahPlanModel.fromJson(numericDay).toEntity().seasonLink, isNull);
    });
  });

  group('next round', () {
    test('offers the second khatmah over the days left', () {
      final next = KhatmahSetupPrefill.nextRound(
        plan(seasonLink: link(1)),
        DateTime(2027, 2, 22, 21),
      )!;
      expect(next.targetDays, 16); // 22 Feb through 9 Mar
      expect(next.pagesPerDay, (604 / 16).ceil());
      expect(next.seasonLink, link(2));
    });

    test('one day on the last day, then nothing; never for the last round '
        'or an unlinked plan', () {
      expect(
        KhatmahSetupPrefill.nextRound(
          plan(seasonLink: link(1)),
          DateTime(2027, 3, 9, 23),
        )?.targetDays,
        1,
      );
      expect(
        KhatmahSetupPrefill.nextRound(
          plan(seasonLink: link(1)),
          DateTime(2027, 3, 10),
        ),
        isNull,
      );
      expect(
        KhatmahSetupPrefill.nextRound(
          plan(seasonLink: link(2)),
          DateTime(2027, 2, 22),
        ),
        isNull,
      );
      expect(
        KhatmahSetupPrefill.nextRound(plan(), DateTime(2027, 2, 22)),
        isNull,
      );
    });
  });

  group('completion page', () {
    Object? setupExtra;

    Future<void> pump(WidgetTester tester, KhatmahPlan base) async {
      setupExtra = null;
      final completed = base.copyWith(
        status: KhatmahStatus.completed,
        completedPages: {for (var p = 1; p <= 604; p++) p},
      );
      final result = KhatmahReadingResult(
        plan: completed,
        newlyCompletedPages: const {604},
        historyEntry: KhatmahHistoryEntry(
          id: base.id,
          khatmahNumber: 1,
          title: base.title,
          startDate: base.startDate,
          completedDate: DateTime(2027, 2, 22),
          totalDays: 15,
        ),
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => KhatmahCompletionPage(
              completion: result,
              enableConfetti: false,
              now: () => DateTime(2027, 2, 22, 21),
            ),
          ),
          GoRoute(
            path: '/khatmah/setup',
            builder: (_, state) {
              setupExtra = state.extra;
              return const Scaffold(body: Text('setup'));
            },
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
    }

    const button = Key('khatmah_completion_next_round_button');

    testWidgets('the first of two offers the second with the days left', (
      tester,
    ) async {
      await pump(tester, plan(seasonLink: link(1)));
      expect(find.text('Start the second khatmah in 16 days'), findsOneWidget);
      await tester.ensureVisible(find.byKey(button));
      await tester.tap(find.byKey(button));
      await tester.pumpAndSettle();
      expect(find.text('setup'), findsOneWidget);
      final extra = setupExtra! as KhatmahSetupPrefill;
      expect(extra.targetDays, 16);
      expect(extra.seasonLink, link(2));
    });

    testWidgets('the second, or an ordinary khatmah, offers nothing more', (
      tester,
    ) async {
      await pump(tester, plan(seasonLink: link(2)));
      expect(find.byKey(button), findsNothing);
      await pump(tester, plan());
      expect(find.byKey(button), findsNothing);
    });
  });
}
