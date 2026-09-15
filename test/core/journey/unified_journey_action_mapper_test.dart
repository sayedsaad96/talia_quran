import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/core/journey/unified_journey_action_mapper.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/smart_coach_recommendation.dart';

void main() {
  testWidgets('maps daily reading and review backlog actions', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    const mapper = UnifiedJourneyActionMapper();
    final reading = mapper.map(
      captured,
      const UnifiedJourneyAction(
        route: '/quran/page/3',
        priority: UnifiedJourneyPriority.p5DailyGoal,
        source: 'DailyWird',
        actionType: UnifiedJourneyActionType.dailyReading,
        intent: JourneyIntent.reading,
      ),
    );
    expect(reading.title, captured.l10n.dailyWirdTitle);
    expect(reading.icon, Icons.menu_book_rounded);

    final backlog = mapper.map(
      captured,
      const UnifiedJourneyAction(
        route: '/memorization',
        priority: UnifiedJourneyPriority.p3ReviewBacklog,
        source: 'AdaptiveRecommendations',
        actionType: UnifiedJourneyActionType.reviewBacklog,
        intent: JourneyIntent.review,
        metadata: {'overdueAyahs': '4'},
      ),
    );
    expect(backlog.title, captured.l10n.reviewBacklogTitle);
    expect(backlog.icon, Icons.history_rounded);

    final coach = mapper.map(
      captured,
      const UnifiedJourneyAction(
        route:
            '/memorization-v2/session?surahId=2&ayahNumber=4&intent=memorize&origin=smartCoach',
        priority: UnifiedJourneyPriority.p2CriticalAlert,
        source: 'SmartCoach',
        actionType: UnifiedJourneyActionType.criticalAlert,
        intent: JourneyIntent.memorize,
        coachRecommendation: SmartCoachRecommendation(
          kind: SmartCoachRecommendationKind.memorizeNewAyahs,
          explanationCode: SmartCoachExplanationCode.newAyahsAvailable,
          route:
              '/memorization-v2/session?surahId=2&ayahNumber=4&intent=memorize&origin=smartCoach',
          surahId: 2,
          startAyah: 4,
        ),
      ),
    );
    expect(coach.title, captured.l10n.journeyMemorizeNewAyahsTitle);
    expect(coach.icon, Icons.auto_awesome_rounded);
  });
}

extension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
