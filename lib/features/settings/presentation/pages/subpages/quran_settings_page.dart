import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../quran/presentation/cubits/quran_audio_player_cubit.dart';
import '../../cubits/settings_cubit.dart';
import '../../cubits/settings_state.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/settings_memorization_tiles.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/settings_subpage_scaffold.dart';

/// Dedicated subpage for Quran and memorization preferences.
class QuranSettingsPage extends StatelessWidget {
  const QuranSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return SettingsSubpageScaffold(
      title: context.l10n.settingsSectionQuranMemorization,
      children: [
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return SettingsGroup(
              children: [
                _BackgroundPlaybackSettingTile(isDark: isDark),
                SettingsDivider(isDark: isDark, indent: 0),
                AccuracySettingTile(isDark: isDark),
                SettingsDivider(isDark: isDark, indent: 0),
                MemorizationPathSummaryTile(
                  isDark: isDark,
                  profile: state.memorizationProfile,
                ),
                if (state.memorizationProfile?.hasSelectedPath == true) ...[
                  SettingsDivider(isDark: isDark, indent: 0),
                  ResetMemorizationPathTile(
                    isDark: isDark,
                    onReset: context.read<SettingsCubit>().resetMemorizationIdentity,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BackgroundPlaybackSettingTile extends StatefulWidget {
  const _BackgroundPlaybackSettingTile({required this.isDark});

  final bool isDark;

  @override
  State<_BackgroundPlaybackSettingTile> createState() =>
      _BackgroundPlaybackSettingTileState();
}

class _BackgroundPlaybackSettingTileState
    extends State<_BackgroundPlaybackSettingTile> {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuranAudioPlayerCubit>();
    final isDark = widget.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final isEnabled = cubit.isBackgroundPlaybackEnabled;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _leadingIcon(primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _copy(context, textColor, subtextColor)),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(
            value: isEnabled,
            activeTrackColor: primary,
            onChanged: (value) => _toggle(cubit, value),
          ),
        ],
      ),
    );
  }

  Widget _leadingIcon(Color primary) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.headphones_rounded, color: primary, size: 22),
    );
  }

  Widget _copy(BuildContext context, Color textColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.settingsBackgroundPlaybackTitle,
          style: AppTypography.titleSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          context.l10n.settingsBackgroundPlaybackSubtitle,
          style: AppTypography.bodySmall.copyWith(
            color: subtextColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Future<void> _toggle(QuranAudioPlayerCubit cubit, bool value) async {
    await cubit.setBackgroundPlaybackEnabled(value);
    if (mounted) setState(() {});
  }
}
