import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/navigation/kids_next_mission_resolver.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../widgets/kids_reward_dialog.dart';
import '../widgets/kids_ui.dart';

class KidsGamifiedCompletionPage extends StatefulWidget {
  const KidsGamifiedCompletionPage({
    super.key,
    required this.surahId,
    required this.completedAyahNumber,
    this.starsEarned = 1,
    this.pointsEarned = 0,
    this.leveledUpTo,
    this.onNext,
    this.onReturnToMap,
  });

  final int surahId;
  final int completedAyahNumber;
  final int starsEarned;

  /// K11: points earned by the finished session, shown next to the stars.
  final int pointsEarned;

  /// K11: new level when this session triggered a level-up; null otherwise.
  final int? leveledUpTo;
  final VoidCallback? onNext;
  final VoidCallback? onReturnToMap;

  @override
  State<KidsGamifiedCompletionPage> createState() =>
      _KidsGamifiedCompletionPageState();
}

class _KidsGamifiedCompletionPageState
    extends State<KidsGamifiedCompletionPage> {
  KidsNextMission? _nextMission;

  @override
  void initState() {
    super.initState();
    _loadNextMission();
  }

  /// Resolves the next mission with the exact same SRS-first priority as the
  /// kids home screen (due review → resume → linked review → new ayah), so
  /// "Next" never contradicts the mission the child was shown on home. The
  /// just-completed ayah is presumed completed before resolving (K5), which
  /// both skips reopening it and keeps due reviews ahead of new memorization.
  Future<void> _loadNextMission() async {
    final journeyResult = await getIt<MemorizationPlusRepository>().getKidsJourney(
      surahId: widget.surahId,
    );
    final reviewResult = await getIt<MemorizationPlusRepository>()
        .getAllReviewRecords(scope: ReviewRecordReadScope.kids);
    if (!mounted) return;

    final stages = journeyResult.getOrElse(() => const <KidsJourneyStage>[]);
    final reviewRecords = reviewResult.getOrElse(() => const []);
    final mission = const KidsNextMissionResolver().resolveSkippingAyah(
      activeSurahId: widget.surahId,
      stages: stages,
      reviewRecords: reviewRecords,
      now: DateTime.now().toUtc(),
      justCompletedSurahId: widget.surahId,
      justCompletedAyah: widget.completedAyahNumber,
    );
    if (!mounted) return;
    setState(() => _nextMission = mission);
  }

  @override
  Widget build(BuildContext context) {
    return KidsGamifiedCompletionContent(
      starsEarned: widget.starsEarned,
      pointsEarned: widget.pointsEarned,
      leveledUpTo: widget.leveledUpTo,
      showNextButton: _nextMission != null,
      onNext: widget.onNext ?? () => _openNextMission(context),
      onReturnToMap: widget.onReturnToMap ?? () => _returnToMap(context),
    );
  }

  void _openNextMission(BuildContext context) {
    final mission = _nextMission;
    if (mission == null) {
      _returnToMap(context);
      return;
    }

    context.pushReplacement(
      '${AppRoutes.memorizationPlusKids}?surahId=${mission.surahId}'
      '&ayahNumber=${mission.startAyah}'
      '&missionType=${mission.type.name}',
    );
  }

  void _returnToMap(BuildContext context) {
    context.go(
      '${AppRoutes.memorizationPlusKidsJourney}?surahId=${widget.surahId}',
    );
  }
}

@visibleForTesting
class KidsGamifiedCompletionContent extends StatelessWidget {
  const KidsGamifiedCompletionContent({
    super.key,
    required this.starsEarned,
    this.pointsEarned = 0,
    this.leveledUpTo,
    this.showNextButton = true,
    required this.onNext,
    required this.onReturnToMap,
  });

  final int starsEarned;
  final int pointsEarned;
  final int? leveledUpTo;
  final bool showNextButton;
  final VoidCallback onNext;
  final VoidCallback onReturnToMap;

  @override
  Widget build(BuildContext context) {
    return KidsBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: KidsRewardDialog(
                starsEarned: starsEarned,
                pointsEarned: pointsEarned,
                leveledUpTo: leveledUpTo,
                showNextButton: showNextButton,
                onNext: onNext,
                onReturnToMap: onReturnToMap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
