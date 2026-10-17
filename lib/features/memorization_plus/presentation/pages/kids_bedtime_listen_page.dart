import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/memorization/kids_enrichment_feature_flags.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/sleep_timer.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../domain/services/kids_world_phase.dart';
import '../cubits/kids_bedtime_cubit.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_chunky_button.dart';
import '../widgets/kids_loading_widget.dart';
import '../widgets/kids_ui.dart';
import '../world/kids_world_palette.dart';

/// Bedtime listening exists only while its rollout flag is on.
bool kidsBedtimeListeningEnabled() =>
    getIt.isRegistered<KidsEnrichmentFlags>() &&
    getIt<KidsEnrichmentFlags>().isEnabled(
      KidsEnrichmentFeature.bedtimeListening,
    );

/// «استماع قبل النوم»: the child's memorized surahs played back to back with
/// a sleep timer. Listening only: no points, rewards or logs.
class KidsBedtimeListenPage extends StatelessWidget {
  const KidsBedtimeListenPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<KidsBedtimeCubit>()..load(),
    child: const KidsBedtimeView(),
  );
}

@visibleForTesting
class KidsBedtimeView extends StatelessWidget {
  const KidsBedtimeView({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.memorizationPlusKidsHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const palette = KidsWorldPalette.night;
    return KidsWorldPhaseScope(
      phase: KidsWorldPhase.night,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: palette.skyStops,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                KidsTopBar(
                  title: l10n.kidsBedtimeTitle,
                  onBack: () => _back(context),
                  backLabel: l10n.goBack,
                ),
                Expanded(
                  child: BlocBuilder<KidsBedtimeCubit, KidsBedtimeState>(
                    builder: (context, state) => switch (state.status) {
                      KidsBedtimeStatus.loading => const Center(
                        child: KidsLoadingWidget(),
                      ),
                      KidsBedtimeStatus.error => KidsErrorWidget(
                        onRetry: () => context.read<KidsBedtimeCubit>().load(),
                      ),
                      KidsBedtimeStatus.empty => _EmptyMessage(
                        text: l10n.kidsBedtimeEmpty,
                      ),
                      KidsBedtimeStatus.ready => _BedtimeList(state: state),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TaliaIcon(
              TaliaKidsIcons.moon,
              color: KidsWorldPalette.moon,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: KidsWorldPalette.night.onScene,
                fontFamily: 'Amiri',
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BedtimeList extends StatelessWidget {
  const _BedtimeList({required this.state});

  final KidsBedtimeState state;

  String _surahName(BuildContext context, Surah surah) =>
      context.l10n.localeName.startsWith('ar') ? surah.nameAr : surah.nameEn;

  String _timerLabel(BuildContext context, SleepTimerChoice choice) =>
      switch (choice) {
        SleepTimerChoice.min15 => context.l10n.readerSleepMinutes(
          context.numText(15),
        ),
        SleepTimerChoice.min30 => context.l10n.readerSleepMinutes(
          context.numText(30),
        ),
        _ => context.l10n.readerSleepOff,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<KidsBedtimeCubit>();
    const palette = KidsWorldPalette.night;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (final surah in state.surahs)
          CheckboxListTile(
            key: ValueKey('kids-bedtime-surah-${surah.id}'),
            value: state.selected.contains(surah.id),
            onChanged: state.playing
                ? null
                : (_) => cubit.toggleSurah(surah.id),
            activeColor: KidsTheme.goldStar,
            checkColor: KidsTheme.inkOnParchment,
            title: Text(
              _surahName(context, surah),
              style: AppTypography.titleMedium.copyWith(
                color: palette.onScene,
                fontFamily: 'Amiri',
                letterSpacing: 0,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.kidsBedtimeTimer,
          style: AppTypography.labelLarge.copyWith(
            color: palette.onSceneMuted,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final choice in kKidsBedtimeTimerChoices)
              ChoiceChip(
                key: ValueKey('kids-bedtime-timer-${choice.name}'),
                label: Text(_timerLabel(context, choice)),
                selected: state.timer == choice,
                onSelected: state.playing
                    ? null
                    : (_) => cubit.setTimer(choice),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        KidsChunkyButton(
          key: const ValueKey('kids-bedtime-toggle'),
          label: state.playing ? l10n.kidsBedtimeStop : l10n.kidsBedtimeStart,
          icon: state.playing ? TaliaKidsIcons.stop : TaliaKidsIcons.play,
          tone: state.playing ? KidsButtonTone.soft : KidsButtonTone.gold,
          onPressed: state.playing
              ? () => cubit.stop()
              : state.queue.isEmpty
              ? null
              : () => cubit.start(),
        ),
      ],
    );
  }
}

/// The home's quiet-time invitation; shown only in the night phase of the
/// kids world.
class KidsBedtimeCard extends StatelessWidget {
  const KidsBedtimeCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (KidsWorldPhaseScope.phaseOf(context) != KidsWorldPhase.night) {
      return const SizedBox.shrink();
    }
    const palette = KidsWorldPalette.night;
    final radius = BorderRadius.circular(AppSpacing.radiusLg);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        key: const ValueKey('kids-bedtime-card'),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: palette.skyStops),
              borderRadius: radius,
              border: Border.all(
                color: KidsWorldPalette.moon.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const TaliaIcon(
                  TaliaKidsIcons.moon,
                  color: KidsWorldPalette.moon,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.kidsBedtimeCard,
                    style: AppTypography.titleSmall.copyWith(
                      color: palette.onScene,
                      fontFamily: 'Amiri',
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
