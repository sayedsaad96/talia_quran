import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/reader_repeat_plan.dart';
import '../../../../core/services/sleep_timer.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/quran_audio_player_cubit.dart';

/// Repeat, speed and sleep timer controls for the reader's audio player.
///
/// Session-only: nothing here is persisted. v1 repeats from the current ayah
/// to the end of the page or surah that started playback; there is no manual
/// "from ayah to ayah" range.
class ReaderRepeatSheet extends StatelessWidget {
  const ReaderRepeatSheet({super.key});

  static const List<int> _counts = [1, 2, 3, 5, 10];

  static Future<void> show(BuildContext context) {
    final cubit = context.read<QuranAudioPlayerCubit>();
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const ReaderRepeatSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: context.tokens.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: BlocBuilder<QuranAudioPlayerCubit, QuranAudioPlayerState>(
            builder: (context, state) {
              final cubit = context.read<QuranAudioPlayerCubit>();
              final repeat = state.repeat;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.readerRepeatTitle,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Section(
                    title: l10n.readerRepeatPerAyah,
                    children: [
                      for (final n in _counts)
                        _Choice(
                          key: ValueKey('repeat-per-ayah-$n'),
                          label: context.numText(n),
                          selected: repeat.perAyah == n,
                          onSelected: () => cubit.setRepeat(
                            ReaderRepeatSettings(
                              perAyah: n,
                              rangeTimes: repeat.rangeTimes,
                              speed: repeat.speed,
                            ),
                          ),
                        ),
                    ],
                  ),
                  _Section(
                    title: l10n.readerRepeatRange,
                    children: [
                      for (final n in _counts)
                        _Choice(
                          key: ValueKey('repeat-range-$n'),
                          label: context.numText(n),
                          selected: repeat.rangeTimes == n,
                          onSelected: () => cubit.setRepeat(
                            ReaderRepeatSettings(
                              perAyah: repeat.perAyah,
                              rangeTimes: n,
                              speed: repeat.speed,
                            ),
                          ),
                        ),
                      _Choice(
                        key: const ValueKey('repeat-range-infinite'),
                        label: l10n.readerRepeatInfinite,
                        selected: repeat.rangeTimes == 0,
                        onSelected: () => cubit.setRepeat(
                          ReaderRepeatSettings(
                            perAyah: repeat.perAyah,
                            rangeTimes: 0,
                            speed: repeat.speed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _Section(
                    title: l10n.readerRepeatSpeed,
                    children: [
                      for (final s in ReaderRepeatSettings.allowedSpeeds)
                        _Choice(
                          key: ValueKey('repeat-speed-$s'),
                          label: '${context.digitText(s.toString())}x',
                          selected: repeat.normalizedSpeed == s,
                          onSelected: () => cubit.setRepeat(
                            ReaderRepeatSettings(
                              perAyah: repeat.perAyah,
                              rangeTimes: repeat.rangeTimes,
                              speed: s,
                            ),
                          ),
                        ),
                    ],
                  ),
                  _Section(
                    title: l10n.readerSleepTimer,
                    children: [
                      _sleepChoice(
                        SleepTimerChoice.off,
                        l10n.readerSleepOff,
                        state,
                        cubit,
                      ),
                      _sleepChoice(
                        SleepTimerChoice.min15,
                        l10n.readerSleepMinutes(context.numText(15)),
                        state,
                        cubit,
                      ),
                      _sleepChoice(
                        SleepTimerChoice.min30,
                        l10n.readerSleepMinutes(context.numText(30)),
                        state,
                        cubit,
                      ),
                      _sleepChoice(
                        SleepTimerChoice.min60,
                        l10n.readerSleepMinutes(context.numText(60)),
                        state,
                        cubit,
                      ),
                      _sleepChoice(
                        SleepTimerChoice.endOfSurah,
                        l10n.readerSleepEndOfSurah,
                        state,
                        cubit,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sleepChoice(
    SleepTimerChoice choice,
    String label,
    QuranAudioPlayerState state,
    QuranAudioPlayerCubit cubit,
  ) {
    return _Choice(
      key: ValueKey('sleep-${choice.name}'),
      label: label,
      selected: state.sleepChoice == choice,
      onSelected: () => cubit.setSleepTimer(choice),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: children,
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
