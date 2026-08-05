import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';
import '../widgets/settings_account_tiles.dart';
import '../widgets/settings_appearance_tiles.dart';
import '../widgets/settings_info_tiles.dart';
import '../widgets/settings_memorization_tiles.dart';
import '../widgets/settings_notification_tiles.dart';
import '../widgets/settings_parent_tiles.dart';
import '../widgets/settings_section.dart';

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
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            body: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: CustomScrollView(
                  slivers: [
                _buildAppBar(context, isDark),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                    AppSpacing.pagePadding,
                    120,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      SettingsSection(
                        title: context.l10n.settingsSectionAccount,
                        accentColor: isDark ? AppColors.primaryLight : AppColors.primary,
                        icon: Icons.person_rounded,
                        children: [
                          AccountSection(isDark: isDark),
                          SettingsDivider(isDark: isDark),
                          ProfileSettingTile(isDark: isDark),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SettingsSection(
                        title: context.l10n.settingsSectionAppearance,
                        accentColor: AppColors.amber,
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
                      SettingsSection(
                        title: context.l10n.settingsSectionQuranMemorization,
                        accentColor: AppColors.gold,
                        icon: Icons.auto_stories_rounded,
                        children: [
                          AccuracySettingTile(isDark: isDark),
                          SettingsDivider(isDark: isDark),
                          MemorizationPathSummaryTile(
                            isDark: isDark,
                            profile: state.memorizationProfile,
                          ),
                          if (state.memorizationProfile?.hasSelectedPath ==
                              true) ...[
                            SettingsDivider(isDark: isDark),
                            ResetMemorizationPathTile(
                              isDark: isDark,
                              onReset: context
                                  .read<SettingsCubit>()
                                  .resetMemorizationIdentity,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (state.isAdultPath ||
                          state.shouldShowParentSection) ...[
                        SettingsSection(
                          title: context.l10n.settingsSectionKidsGuardian,
                          accentColor: AppColors.kidsGreen,
                          icon: Icons.family_restroom_rounded,
                          children: [
                            if (state.isAdultPath)
                              ParentModeToggle(
                                isDark: isDark,
                                isParentMode: state.isParentMode,
                                onChanged: context
                                    .read<SettingsCubit>()
                                    .toggleParentMode,
                              ),
                            if (state.isAdultPath &&
                                state.shouldShowParentSection)
                              SettingsDivider(isDark: isDark),
                            if (state.shouldShowParentSection)
                              ParentDashboardTile(isDark: isDark),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      SettingsSection(
                        title: context.l10n.settingsSectionProgressAchievements,
                        accentColor: AppColors.success,
                        icon: Icons.notifications_active_rounded,
                        children: [NotificationSettingTile(isDark: isDark)],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SettingsSection(
                        title: context.l10n.settingsSectionHelpTutorial,
                        accentColor: AppColors.info,
                        icon: Icons.help_outline_rounded,
                        children: [TutorialGuideTile(isDark: isDark)],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SettingsSection(
                        title: context.l10n.settingsSectionPrivacySecurity,
                        accentColor: AppColors.warning,
                        icon: Icons.security_rounded,
                        children: [
                          PrivacyPolicyTile(isDark: isDark),
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, authState) {
                              if (authState is! AuthAuthenticated) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                children: [
                                  SettingsDivider(isDark: isDark),
                                  DeleteAccountTile(
                                    isDark: isDark,
                                    email: authState.user.email,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SettingsSection(
                        title: context.l10n.settingsSectionAboutTalia,
                        accentColor: isDark ? AppColors.primaryLight : AppColors.primary,
                        icon: Icons.info_outline_rounded,
                        children: [AboutTile(isDark: isDark)],
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
      expandedHeight: 160,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        icon: Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.arrow_forward_rounded
              : Icons.arrow_back_rounded,
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
        background: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.heroGradientDark
                      : AppColors.heroGradientLight,
                ),
              ),
            ),
            Positioned(
              left: Directionality.of(context) == TextDirection.rtl ? null : -20,
              right: Directionality.of(context) == TextDirection.rtl ? -20 : null,
              top: -10,
              child: Icon(
                Icons.settings_rounded,
                size: 170,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            PositionedDirectional(
              start: AppSpacing.pagePadding,
              top: 74,
              child: Text(
                'مركز التحكم والتفضيلات الشخصية',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
