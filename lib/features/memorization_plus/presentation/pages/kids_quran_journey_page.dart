import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../../domain/services/kids_surah_house_summary_builder.dart';
import '../cubits/kids_quran_journey_cubit.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_loading_widget.dart';
import '../widgets/kids_quran_journey_map.dart';
import '../widgets/kids_ui.dart';

/// The whole-Quran journey map: one house per surah.
class KidsQuranJourneyPage extends StatelessWidget {
  const KidsQuranJourneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<KidsQuranJourneyCubit>()..load(),
      child: const _KidsQuranJourneyView(),
    );
  }
}

class _KidsQuranJourneyView extends StatelessWidget {
  const _KidsQuranJourneyView();

  @override
  Widget build(BuildContext context) {
    void back() => context.canPop()
        ? context.pop()
        : context.go(
            MemorizationNavigationResolver.kidsHomeFallbackLocation(1),
          );
    return Scaffold(
      backgroundColor: KidsTheme.nightSkyDark,
      body: BlocBuilder<KidsQuranJourneyCubit, KidsQuranJourneyState>(
        builder: (context, state) => switch (state) {
          KidsQuranJourneyLoading() => const Center(child: KidsLoadingWidget()),
          KidsQuranJourneyError() => KidsErrorWidget(
            onRetry: () => context.read<KidsQuranJourneyCubit>().load(),
          ),
          final KidsQuranJourneyLoaded loaded => KidsQuranJourneyContent(
            state: loaded,
            onBack: back,
            onOpenSurah: (surahId) async {
              await context.push(
                '${AppRoutes.memorizationPlusKidsJourney}?surahId=$surahId',
              );
              if (context.mounted) {
                await context.read<KidsQuranJourneyCubit>().load();
              }
            },
          ),
        },
      ),
    );
  }
}

@visibleForTesting
class KidsQuranJourneyContent extends StatelessWidget {
  const KidsQuranJourneyContent({
    super.key,
    required this.state,
    required this.onBack,
    required this.onOpenSurah,
  });

  final KidsQuranJourneyLoaded state;
  final VoidCallback onBack;
  final ValueChanged<int> onOpenSurah;

  String _nameOf(BuildContext context, int surahId) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (isArabic) {
      return state.surahNames[surahId] ?? context.localizedSurahName(surahId);
    }
    return context.localizedSurahName(surahId);
  }

  bool get _allCompleted =>
      state.houses.isNotEmpty &&
      state.houses.every((h) => h.status == KidsSurahHouseStatus.completed);

  Future<void> _onHouseTap(BuildContext context, KidsSurahHouse house) async {
    final needsConfirm =
        house.surahId != state.currentSurahId &&
        house.status == KidsSurahHouseStatus.notStarted;
    if (!needsConfirm) {
      onOpenSurah(house.surahId);
      return;
    }
    final l10n = context.l10n;
    final message = l10n.kidsQuranJourneyJumpConfirm(
      _nameOf(context, house.surahId),
      _nameOf(context, state.currentSurahId),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.kidsQuranJourneyJumpNo),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.kidsQuranJourneyJumpYes),
          ),
        ],
      ),
    );
    if (confirmed == true) onOpenSurah(house.surahId);
  }

  @override
  Widget build(BuildContext context) {
    return KidsBackground(
      child: SafeArea(
        child: Column(
          children: [
            KidsTopBar(
              title: context.l10n.kidsQuranJourneyTitle,
              onBack: onBack,
            ),
            if (_allCompleted)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: KidsTheme.parchmentGradient,
                    borderRadius: KidsTheme.cardRadius,
                    border: Border.all(color: KidsTheme.goldStar, width: 2),
                  ),
                  child: Text(
                    context.l10n.kidsQuranJourneyComplete,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium.copyWith(
                      color: KidsTheme.inkOnParchment,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: KidsQuranJourneyMap(
                houses: state.houses,
                currentSurahId: state.currentSurahId,
                celebratedSurahIds: state.celebratedSurahIds,
                nameOf: (id) => _nameOf(context, id),
                onHouseTap: (house) => _onHouseTap(context, house),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
