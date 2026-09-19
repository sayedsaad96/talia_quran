import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';
import '../widgets/settings_account_tiles.dart';
import '../widgets/settings_appearance_tiles.dart';
import '../widgets/settings_nav_tile.dart';
import '../widgets/settings_section.dart';
import 'subpages/about_settings_page.dart';
import 'subpages/kids_settings_page.dart';
import 'subpages/notification_settings_page.dart';
import 'subpages/prayer_settings_page.dart';
import 'subpages/quran_settings_page.dart';

void _showSettingsError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    ),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SettingsCubit>()..load(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (_, state) => state is ProfileError,
      listener: (context, state) {
        if (state is ProfileError) {
          _showSettingsError(context, state.message);
        }
      },
      child: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            _showSettingsError(context, state.errorMessage!);
            context.read<SettingsCubit>().clearTransientMessages();
          } else if (state.showMemorizationPathResetSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.memorizationPathReset),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<SettingsCubit>().clearTransientMessages();
          }
        },
        builder: (context, state) {
          final accentColor =
              isDark ? AppColors.primaryLight : AppColors.primary;
          final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
          final borderColor =
              isDark ? AppColors.darkDivider : AppColors.lightDivider;

          return Scaffold(
            backgroundColor:
                isDark ? AppColors.darkBackground : AppColors.lightBackground,
            body: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(context, isDark),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        AppSpacing.md,
                        AppSpacing.pagePadding,
                        100,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // ── 1. Account Section ──
                          SettingsSection(
                            title: context.l10n.settingsSectionAccount,
                            accentColor: accentColor,
                            icon: Icons.person_rounded,
                            children: [
                              AccountSection(isDark: isDark),
                              SettingsDivider(isDark: isDark),
                              ProfileSettingTile(isDark: isDark),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // ── 2. Quick Preferences (Theme & Language) ──
                          SettingsSection(
                            title: context.l10n.settingsQuickPreferences,
                            subtitle: context.l10n.settingsSectionAppearance,
                            accentColor: accentColor,
                            icon: Icons.palette_rounded,
                            children: [
                              SettingsInlineHeader(
                                isDark: isDark,
                                icon: Icons.translate_rounded,
                                title: context.l10n.language,
                              ),
                              SettingsDivider(isDark: isDark),
                              LocaleSettingTile(isDark: isDark),
                              SettingsDivider(isDark: isDark),
                              SettingsInlineHeader(
                                isDark: isDark,
                                icon: Icons.palette_rounded,
                                title: context.l10n.theme,
                              ),
                              SettingsDivider(isDark: isDark),
                              ThemeSettingTile(isDark: isDark),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // ── 3. Navigation Menu Hub ──
                          Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: [
                                // Quran & Memorization
                                SettingsNavTile(
                                  icon: Icons.auto_stories_rounded,
                                  iconColor: isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primary,
                                  title: context
                                      .l10n.settingsSectionQuranMemorization,
                                  subtitle: state.memorizationProfile
                                              ?.hasSelectedPath ==
                                          true
                                      ? (state.memorizationProfile?.isAdult ==
                                              true
                                          ? 'مسار الكبار'
                                          : 'مسار الأطفال')
                                      : null,
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider.value(
                                          value: context.read<SettingsCubit>(),
                                          child: const QuranSettingsPage(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                SettingsDivider(isDark: isDark),

                                // Prayer Times
                                SettingsNavTile(
                                  icon: Icons.schedule_rounded,
                                  iconColor: const Color(0xFF10B981),
                                  title: context.l10n.homePrayerTimes,
                                  subtitle: context
                                      .l10n.prayerCompanionSettingsTitle,
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PrayerSettingsPage(),
                                      ),
                                    );
                                  },
                                ),
                                SettingsDivider(isDark: isDark),

                                // Notifications & Reminders
                                SettingsNavTile(
                                  icon: Icons.notifications_active_rounded,
                                  iconColor: AppColors.gold,
                                  title: context.l10n
                                      .settingsSectionProgressAchievements,
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationSettingsPage(),
                                      ),
                                    );
                                  },
                                ),

                                // Kids & Guardian (conditional)
                                if (state.isAdultPath ||
                                    state.shouldShowParentSection) ...[
                                  SettingsDivider(isDark: isDark),
                                  SettingsNavTile(
                                    icon: Icons.family_restroom_rounded,
                                    iconColor: const Color(0xFF3B82F6),
                                    title: context
                                        .l10n.settingsSectionKidsGuardian,
                                    isDark: isDark,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => BlocProvider.value(
                                            value:
                                                context.read<SettingsCubit>(),
                                            child: const KidsSettingsPage(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                SettingsDivider(isDark: isDark),

                                // Help & About Talia
                                SettingsNavTile(
                                  icon: Icons.info_outline_rounded,
                                  iconColor: const Color(0xFF8B5CF6),
                                  title: context.l10n.settingsSectionAboutTalia,
                                  subtitle:
                                      '${context.l10n.settingsSectionHelpTutorial} • ${context.l10n.settingsSectionPrivacySecurity}',
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MultiBlocProvider(
                                          providers: [
                                            BlocProvider.value(
                                              value: context.read<AuthCubit>(),
                                            ),
                                            BlocProvider.value(
                                              value:
                                                  context.read<ProfileCubit>(),
                                            ),
                                            BlocProvider.value(
                                              value:
                                                  context.read<SettingsCubit>(),
                                            ),
                                          ],
                                          child: const AboutSettingsPage(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 100,
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.arrow_back_rounded
              : Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.md,
        ),
        title: Text(
          context.l10n.settings,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: context.isArabic ? 'Amiri' : null,
            fontSize: 20,
          ),
        ),
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.heroGradientDark
                : AppColors.heroGradientLight,
          ),
        ),
      ),
    );
  }
}
