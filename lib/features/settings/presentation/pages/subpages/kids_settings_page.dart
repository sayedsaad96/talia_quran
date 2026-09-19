import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubits/settings_cubit.dart';
import '../../cubits/settings_state.dart';
import '../../widgets/settings_parent_tiles.dart';
import '../../widgets/settings_section.dart';

/// Dedicated subpage for Kids & Guardian settings.
class KidsSettingsPage extends StatelessWidget {
  const KidsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.settingsSectionKidsGuardian),
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
              SettingsSection(
                title: context.l10n.settingsSectionKidsGuardian,
                accentColor: accentColor,
                icon: Icons.family_restroom_rounded,
                collapsible: false,
                children: [
                  if (state.isAdultPath)
                    ParentModeToggle(
                      isDark: isDark,
                      isParentMode: state.isParentMode,
                      onChanged:
                          context.read<SettingsCubit>().toggleParentMode,
                    ),
                  if (state.isAdultPath && state.shouldShowParentSection)
                    SettingsDivider(isDark: isDark),
                  if (state.shouldShowParentSection)
                    ParentDashboardTile(isDark: isDark),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
