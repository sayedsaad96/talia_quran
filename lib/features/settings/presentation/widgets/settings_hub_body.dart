import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';
import '../pages/subpages/about_settings_page.dart';
import '../pages/subpages/kids_settings_page.dart';
import '../pages/subpages/notification_settings_page.dart';
import '../pages/subpages/prayer_settings_page.dart';
import '../pages/subpages/quran_settings_page.dart';
import 'settings_account_tiles.dart';
import 'settings_appearance_tiles.dart';
import 'settings_group.dart';
import 'settings_nav_tile.dart';
import 'settings_section.dart';

class SettingsHubBody extends StatelessWidget {
  const SettingsHubBody({super.key, required this.state, required this.isDark});

  final SettingsState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final showKids = state.isAdultPath || state.shouldShowParentSection;

    return Column(
      children: [
        _accountGroup(context),
        const SizedBox(height: AppSpacing.xl),
        _appearanceGroup(context),
        const SizedBox(height: AppSpacing.xl),
        _practiceGroup(context),
        const SizedBox(height: AppSpacing.xl),
        _remindersGroup(context),
        if (showKids) ...[
          const SizedBox(height: AppSpacing.xl),
          _kidsGroup(context),
        ],
        const SizedBox(height: AppSpacing.xl),
        _supportGroup(context),
      ],
    );
  }

  Widget _accountGroup(BuildContext context) {
    final l10n = context.l10n;
    return SettingsGroup(
      title: l10n.settingsSectionAccount,
      children: [
        AccountSection(isDark: isDark),
        SettingsDivider(isDark: isDark),
        ProfileSettingTile(isDark: isDark),
      ],
    );
  }

  Widget _appearanceGroup(BuildContext context) {
    final l10n = context.l10n;
    return SettingsGroup(
      title: l10n.settingsQuickPreferences,
      subtitle: l10n.settingsSectionAppearance,
      children: [
        SettingsInlineHeader(
          isDark: isDark,
          icon: Icons.translate_rounded,
          title: l10n.language,
        ),
        LocaleSettingTile(isDark: isDark),
        SettingsDivider(isDark: isDark),
        SettingsInlineHeader(
          isDark: isDark,
          icon: Icons.palette_rounded,
          title: l10n.theme,
        ),
        ThemeSettingTile(isDark: isDark),
      ],
    );
  }

  Widget _practiceGroup(BuildContext context) {
    final l10n = context.l10n;
    return SettingsGroup(
      title: l10n.settingsHubPractice,
      children: [
        _destination(
          context,
          icon: Icons.auto_stories_rounded,
          title: l10n.settingsSectionQuranMemorization,
          subtitle: _pathSubtitle(context),
          page: BlocProvider.value(
            value: context.read<SettingsCubit>(),
            child: const QuranSettingsPage(),
          ),
        ),
        SettingsDivider(isDark: isDark),
        _destination(
          context,
          icon: Icons.schedule_rounded,
          title: l10n.homePrayerTimes,
          subtitle: l10n.prayerCompanionSettingsTitle,
          page: const PrayerSettingsPage(),
        ),
      ],
    );
  }

  Widget _remindersGroup(BuildContext context) {
    final l10n = context.l10n;
    return SettingsGroup(
      title: l10n.settingsHubReminders,
      children: [
        _destination(
          context,
          icon: Icons.notifications_active_rounded,
          title: l10n.settingsSectionProgressAchievements,
          page: const NotificationSettingsPage(),
        ),
      ],
    );
  }

  Widget _kidsGroup(BuildContext context) {
    return SettingsGroup(
      children: [
        _destination(
          context,
          icon: Icons.family_restroom_rounded,
          title: context.l10n.settingsSectionKidsGuardian,
          page: BlocProvider.value(
            value: context.read<SettingsCubit>(),
            child: const KidsSettingsPage(),
          ),
        ),
      ],
    );
  }

  Widget _supportGroup(BuildContext context) {
    final l10n = context.l10n;
    return SettingsGroup(
      title: l10n.settingsHubSupport,
      children: [
        _destination(
          context,
          icon: Icons.info_outline_rounded,
          title: l10n.settingsSectionAboutTalia,
          subtitle:
              '${l10n.settingsSectionHelpTutorial} · ${l10n.settingsSectionPrivacySecurity}',
          page: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<AuthCubit>()),
              BlocProvider.value(value: context.read<ProfileCubit>()),
              BlocProvider.value(value: context.read<SettingsCubit>()),
            ],
            child: const AboutSettingsPage(),
          ),
        ),
      ],
    );
  }

  String? _pathSubtitle(BuildContext context) {
    final profile = state.memorizationProfile;
    if (profile?.hasSelectedPath != true) return null;
    final l10n = context.l10n;
    return profile?.isAdult == true
        ? l10n.memorizationPathAdultsTitle
        : l10n.memorizationPathKidsTitle;
  }

  Widget _destination(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
    String? subtitle,
  }) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return SettingsNavTile(
      icon: icon,
      iconColor: accent,
      title: title,
      subtitle: subtitle,
      isDark: isDark,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => page),
        );
      },
    );
  }
}
