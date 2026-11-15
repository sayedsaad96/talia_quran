import '../entities/good_impact.dart';

class GoodImpactMilestonePolicy {
  const GoodImpactMilestonePolicy();
  Set<GoodImpactMilestone> derive(GoodImpact impact) => {
    if (impact.downstreamReach >= 1) GoodImpactMilestone.firstChainStarted,
    if (impact.responses + impact.downstreamReach >= 5)
      GoodImpactMilestone.fiveReach,
    if (impact.responses >= 10) GoodImpactMilestone.tenResponses,
    if (impact.responses + impact.downstreamReach >= 25)
      GoodImpactMilestone.twentyFiveReach,
  };
}
