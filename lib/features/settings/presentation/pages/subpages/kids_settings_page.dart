import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../cubits/settings_cubit.dart';
import '../../cubits/settings_state.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/settings_parent_tiles.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/settings_subpage_scaffold.dart';

/// Kids path and guardian tools, shown only when the profile allows them.
class KidsSettingsPage extends StatelessWidget {
  const KidsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return SettingsSubpageScaffold(
      title: context.l10n.settingsSectionKidsGuardian,
      children: [
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return SettingsGroup(
              children: [
                if (state.isAdultPath)
                  ParentModeToggle(
                    isDark: isDark,
                    isParentMode: state.isParentMode,
                    onChanged: context.read<SettingsCubit>().toggleParentMode,
                  ),
                if (state.isAdultPath && state.shouldShowParentSection)
                  SettingsDivider(isDark: isDark),
                if (state.shouldShowParentSection)
                  ParentDashboardTile(isDark: isDark),
              ],
            );
          },
        ),
      ],
    );
  }
}
