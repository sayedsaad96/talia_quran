import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../quran/presentation/cubits/quran_audio_player_cubit.dart';
import '../../cubits/settings_cubit.dart';
import '../../cubits/settings_state.dart';
import '../../widgets/settings_memorization_tiles.dart';
import '../../widgets/settings_section.dart';

/// Dedicated subpage for Quran & Memorization preferences.
class QuranSettingsPage extends StatelessWidget {
  const QuranSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.settingsSectionQuranMemorization),
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
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
                        onReset: context
                            .read<SettingsCubit>()
                            .resetMemorizationIdentity,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
    final primary = isDark ? AppColors.goldLight : AppColors.primary;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isEnabled = cubit.isBackgroundPlaybackEnabled;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.headphones_rounded,
              color: primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التشغيل في الخلفية',
                  style: AppTypography.titleSmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'استمرار تلاوة السور عند مغادرة التطبيق مع شريط التحكم في الإشعارات',
                  style: AppTypography.bodySmall.copyWith(
                    color: subtextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(
            value: isEnabled,
            activeThumbColor: isDark ? AppColors.goldLight : Colors.white,
            activeTrackColor: primary,
            onChanged: (value) async {
              await cubit.setBackgroundPlaybackEnabled(value);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
