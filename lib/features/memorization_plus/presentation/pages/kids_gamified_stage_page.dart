import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_stage_details.dart';
import '../widgets/kids_ui.dart';

class KidsGamifiedStagePage extends StatefulWidget {
  const KidsGamifiedStagePage({
    super.key,
    required this.stage,
    this.surahName,
    this.onStartMission,
  });

  final KidsJourneyStage stage;
  final String? surahName;
  final VoidCallback? onStartMission;

  @override
  State<KidsGamifiedStagePage> createState() => _KidsGamifiedStagePageState();
}/// Route the stage page navigates to when the child starts this stage's
/// mission. Carries the resolved mission type (resume for in-progress stages,
/// otherwise new memorization) so the V2 session restores its correct phase.
@visibleForTesting
String kidsNextMissionLocation(KidsJourneyStage stage) {
  final missionType = stage.completedAyahs.isEmpty
      ? KidsMissionType.newMemorization
      : KidsMissionType.resume;
  return '${AppRoutes.memorizationPlusKids}?surahId=${stage.surahId}'
      '&ayahNumber=${stage.nextAyahToStart}'
      '&missionType=${missionType.name}';
}

class _KidsGamifiedStagePageState
    extends State<KidsGamifiedStagePage> {
  late KidsJourneyStage _stage;

  @override
  void initState() {
    super.initState();
    _stage = widget.stage;
    _loadAuthoritativeStage();
  }

  Future<void> _loadAuthoritativeStage() async {
    final result = await getIt<MemorizationPlusRepository>().getKidsJourney(
      surahId: widget.stage.surahId,
    );
    if (!mounted) return;
    final stage = result.fold((_) => null, (stages) {
      for (final candidate in stages) {
        if (candidate.stageNumber == widget.stage.stageNumber &&
            candidate.startAyah == widget.stage.startAyah &&
            candidate.endAyah == widget.stage.endAyah) {
          return candidate;
        }
      }
      return null;
    });
    if (stage != null) {
      setState(() => _stage = stage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSurahName =
        widget.surahName ?? '${context.l10n.surah} ${_stage.surahId}';
    return KidsGamifiedStageContent(
      stage: _stage,
      surahName: resolvedSurahName,
      onBack: () => context.canPop()
          ? context.pop()
          : context.go(
              MemorizationNavigationResolver.kidsHomeFallbackLocation(
                _stage.surahId,
              ),
            ),
      onStartMission: _stage.isUnlocked
          ? (widget.onStartMission ?? () => _startMission(context, _stage))
          : null,
    );
  }

  void _showLockedStageMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.kidsGamifiedLockedStage)),
    );
  }

  void _startMission(BuildContext context, KidsJourneyStage stage) {
    if (!stage.isUnlocked) {
      _showLockedStageMessage(context);
      return;
    }
    // Match the home and completion routes by carrying the mission type,
    // so resume/review sessions restore their phase instead of resetting.
    context.push(kidsNextMissionLocation(stage));
  }
}

@visibleForTesting
class KidsGamifiedStageContent extends StatelessWidget {
  const KidsGamifiedStageContent({
    super.key,
    required this.stage,
    required this.surahName,
    required this.onBack,
    required this.onStartMission,
  });

  final KidsJourneyStage stage;
  final String surahName;
  final VoidCallback onBack;
  final VoidCallback? onStartMission;

  @override
  Widget build(BuildContext context) {
    return KidsBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              KidsTopBar(
                title: context.l10n.kidsGamifiedMissions,
                onBack: onBack,
              ),
              Expanded(
                child: CustomScrollView(
                  key: const PageStorageKey<String>('kids-gamified-stage'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      sliver: SliverList.list(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: KidsTheme.creamParchment,
                              borderRadius: KidsTheme.cardRadius,
                              border: Border.all(
                                color: KidsTheme.parchmentEdge,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: KidsStageDetails(
                                stage: stage,
                                surahName: surahName,
                                onStartMission: onStartMission,
                              ),
                            ),
                          ),
                          const SizedBox(height: 96),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
