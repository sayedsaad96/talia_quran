import 'package:flutter/widgets.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../cubits/kids_journey_cubit.dart';
import 'kids_talia_companion.dart';

/// Moments outside the session where Talia appears (home, journey, stage,
/// completion).
enum KidsTaliaMoment {
  guide,
  welcomeBack,
  farewell,
  journeyDone,
  mapGuide,
  stageReady,
  celebrate,
}

/// Which moment the kids home shows. Mirrors the precedence of the home body:
/// a spent daily quota first, then a finished journey, then a return after a
/// break, otherwise the mission guide.
KidsTaliaMoment kidsHomeTaliaMoment(KidsJourneyLoaded state) {
  if (state.dailyGoalCap != null) return KidsTaliaMoment.farewell;
  if (state.currentStage == null &&
      state.nextMission == null &&
      state.progress.ayahsCompleted > 0) {
    return KidsTaliaMoment.journeyDone;
  }
  if (state.isReturningAfterBreak) return KidsTaliaMoment.welcomeBack;
  return KidsTaliaMoment.guide;
}

KidsTaliaPose kidsTaliaPoseForMoment(
  KidsTaliaMoment moment,
) => switch (moment) {
  KidsTaliaMoment.guide || KidsTaliaMoment.mapGuide => KidsTaliaPose.pointRight,
  KidsTaliaMoment.welcomeBack || KidsTaliaMoment.farewell => KidsTaliaPose.wave,
  KidsTaliaMoment.journeyDone ||
  KidsTaliaMoment.celebrate => KidsTaliaPose.celebrate,
  KidsTaliaMoment.stageReady => KidsTaliaPose.idle,
};

String kidsTaliaMomentBubble(BuildContext context, KidsTaliaMoment moment) {
  final l10n = context.l10n;
  return switch (moment) {
    KidsTaliaMoment.guide => l10n.kidsTaliaGuideBubble,
    KidsTaliaMoment.welcomeBack => l10n.kidsTaliaWelcomeBackBubble,
    KidsTaliaMoment.farewell => l10n.kidsTaliaFarewellBubble,
    KidsTaliaMoment.journeyDone => l10n.kidsTaliaJourneyDoneBubble,
    KidsTaliaMoment.mapGuide => l10n.kidsTaliaMapBubble,
    KidsTaliaMoment.stageReady => l10n.kidsTaliaStageReadyBubble,
    KidsTaliaMoment.celebrate => l10n.kidsTaliaCelebrateBubble,
  };
}

/// Talia for a [moment]: still (these screens settle in tests and never play
/// recitation audio), pose and line chosen from the moment.
class KidsTaliaMomentCompanion extends StatelessWidget {
  const KidsTaliaMomentCompanion({
    super.key,
    required this.moment,
    this.height = 96,
  });

  final KidsTaliaMoment moment;
  final double height;

  @override
  Widget build(BuildContext context) {
    return KidsTaliaCompanion(
      pose: kidsTaliaPoseForMoment(moment),
      message: kidsTaliaMomentBubble(context, moment),
      animate: false,
      height: height,
    );
  }
}
