import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';
import '../widgets/settings_hub_body.dart';

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
          final background = isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground;

          return Scaffold(
            backgroundColor: background,
            body: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(context, isDark, background),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        AppSpacing.md,
                        AppSpacing.pagePadding,
                        AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: SettingsHubBody(state: state, isDark: isDark),
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

  SliverAppBar _buildAppBar(
    BuildContext context,
    bool isDark,
    Color background,
  ) {
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return SliverAppBar(
      pinned: true,
      backgroundColor: background,
      foregroundColor: titleColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: BackButton(
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
        style: AppTypography.titleLarge.copyWith(
          color: titleColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
