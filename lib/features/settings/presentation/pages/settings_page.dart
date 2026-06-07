import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/notification_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/locale_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../memorization_plus/presentation/navigation/memorization_navigation_resolver.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';
import '../../data/user_profile.dart';
import '../../../../core/router/app_router.dart';

part 'settings_page_tiles.dart';

void _showSettingsError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
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

    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          _showSettingsError(context, state.errorMessage!);
          context.read<SettingsCubit>().clearTransientMessages();
        } else if (state.showMemorizationPathResetSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.memorizationPathReset)),
          );
          context.read<SettingsCubit>().clearTransientMessages();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, isDark),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.lg,
                  AppSpacing.pagePadding,
                  120,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ─── Account (Google Sign-In) ───────────────────────
                    _SettingsSection(
                      title: context.l10n.account,
                      children: [_AccountSection(isDark: isDark)],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsSection(
                      title: context.l10n.profile,
                      children: [_ProfileSettingTile(isDark: isDark)],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ─── Parent Mode Toggle (for adults track) ──────────
                    if (state.selectedTrack == 'adults') ...[
                      _SettingsSection(
                        title: context.l10n.parentGuardianMode,
                        children: [
                          _ParentModeToggle(
                            isDark: isDark,
                            isParentMode: state.isParentMode,
                            onChanged: context
                                .read<SettingsCubit>()
                                .toggleParentMode,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    if (state.memorizationProfile?.hasSelectedPath == true) ...[
                      _SettingsSection(
                        title: context.l10n.memorizationPath,
                        children: [
                          _ResetMemorizationPathTile(
                            isDark: isDark,
                            onReset: context
                                .read<SettingsCubit>()
                                .resetMemorizationIdentity,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // ─── Parent Dashboard (conditional) ─────────────────
                    if (state.shouldShowParentSection) ...[
                      _SettingsSection(
                        title: context.l10n.kidsAndGuardian,
                        children: [_ParentDashboardTile(isDark: isDark)],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    _SettingsSection(
                      title: context.l10n.theme,
                      children: [_ThemeSettingTile(isDark: isDark)],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsSection(
                      title: context.l10n.language,
                      children: [_LocaleSettingTile(isDark: isDark)],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsSection(
                      title: context.l10n.recitationAccuracy,
                      children: [_AccuracySettingTile(isDark: isDark)],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsSection(
                      title: context.l10n.notifications,
                      children: [_NotificationSettingTile(isDark: isDark)],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsSection(
                      title: context.isArabic ? 'المساعدة' : 'Help',
                      children: [_TutorialGuideTile(isDark: isDark)],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsSection(
                      title: context.l10n.about,
                      children: [
                        _PrivacyPolicyTile(isDark: isDark),
                        Divider(
                          height: 0.5,
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                          indent: 56,
                        ),
                        _AboutTile(isDark: isDark),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
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
      title: Text(
        context.l10n.settings,
        style: AppTypography.headlineSmall.copyWith(
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
      ),
      centerTitle: true,
    );
  }
}
