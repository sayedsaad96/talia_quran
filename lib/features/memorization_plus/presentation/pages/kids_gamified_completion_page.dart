import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_reward_dialog.dart';

class KidsGamifiedCompletionPage extends StatefulWidget {
  const KidsGamifiedCompletionPage({
    super.key,
    required this.surahId,
    required this.completedAyahNumber,
    this.starsEarned = 1,
    this.onNext,
    this.onReturnToMap,
  });

  final int surahId;
  final int completedAyahNumber;
  final int starsEarned;
  final VoidCallback? onNext;
  final VoidCallback? onReturnToMap;

  @override
  State<KidsGamifiedCompletionPage> createState() =>
      _KidsGamifiedCompletionPageState();
}

class _KidsGamifiedCompletionPageState
    extends State<KidsGamifiedCompletionPage> {
  KidsJourneyMission? _nextMission;

  @override
  void initState() {
    super.initState();
    _loadNextMission();
  }

  Future<void> _loadNextMission() async {
    final result = await getIt<MemorizationPlusRepository>().getKidsJourney(
      surahId: widget.surahId,
    );
    if (!mounted) return;
    final mission = result.fold(
      (_) => null,
      KidsJourneyMissionResolver.nextMission,
    );
    setState(() {
      _nextMission = mission;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KidsGamifiedCompletionContent(
      starsEarned: widget.starsEarned,
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
      '&ayahNumber=${mission.ayahNumber}',
    );
  }

  void _returnToMap(BuildContext context) {
    context.go(
      '${AppRoutes.memorizationPlusKidsJourney}?surahId=${widget.surahId}',
    );
  }
}

@visibleForTesting
class KidsJourneyMission {
  const KidsJourneyMission({required this.surahId, required this.ayahNumber});

  final int surahId;
  final int ayahNumber;
}

@visibleForTesting
abstract final class KidsJourneyMissionResolver {
  static KidsJourneyMission? nextMission(List<KidsJourneyStage> stages) {
    KidsJourneyStage? stage;
    for (final candidate in stages) {
      if (candidate.status == KidsJourneyStageStatus.current) {
        stage = candidate;
        break;
      }
    }
    for (final candidate in stages) {
      if (stage == null &&
          candidate.status == KidsJourneyStageStatus.needsReview) {
        stage = candidate;
      }
    }
    if (stage == null || !stage.isUnlocked) return null;
    return KidsJourneyMission(
      surahId: stage.surahId,
      ayahNumber: stage.nextAyahToStart,
    );
  }
}

@visibleForTesting
class KidsGamifiedCompletionContent extends StatelessWidget {
  const KidsGamifiedCompletionContent({
    super.key,
    required this.starsEarned,
    this.showNextButton = true,
    required this.onNext,
    required this.onReturnToMap,
  });

  final int starsEarned;
  final bool showNextButton;
  final VoidCallback onNext;
  final VoidCallback onReturnToMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: KidsTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: KidsRewardDialog(
                starsEarned: starsEarned,
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
