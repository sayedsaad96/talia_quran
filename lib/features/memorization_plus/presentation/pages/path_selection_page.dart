import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_info_banner.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../cubits/memorization_identity_cubit.dart';
import '../widgets/memorization_path_choice_card.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../../../../core/extensions/context_extensions.dart';

class PathSelectionPage extends StatelessWidget {
  const PathSelectionPage({super.key, this.preferredPath});

  final MemorizationPath? preferredPath;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MemorizationIdentityCubit>(),
      child: _PathSelectionView(preferredPath: preferredPath),
    );
  }
}

class _PathSelectionView extends StatelessWidget {
  const _PathSelectionView({this.preferredPath});

  final MemorizationPath? preferredPath;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.memorizationPathTitle,
      body: BlocConsumer<MemorizationIdentityCubit, MemorizationIdentityState>(
        listener: (context, state) {
          if (state is MemorizationIdentitySuccess) {
            final profile = state.profile;
            if (profile.isAdult) {
              unawaited(_goToAdultEntry(context));
            } else if (profile.isChild) {
              final authState = context.read<AuthCubit>().state;
              context.go(
                authState is AuthAuthenticated
                    ? AppRoutes.memorizationPlusGuardianLinking
                    : AppRoutes.memorizationPlusKidsHome,
              );
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is MemorizationIdentityLoading;
          final isDark = context.isDark;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.memorizationPathQuestion,
                      style: AppTypography.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.memorizationPathDescription,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (state is MemorizationIdentityError) ...[
                      const SizedBox(height: 20),
                      ErrorInfoBanner(
                        type: ErrorInfoBannerType.error,
                        title:
                            context.l10n.memorizationPathSelectionFailedTitle,
                        message: state.message,
                      ),
                    ],
                    const SizedBox(height: 48),
                    ..._pathCards(context, isLoading),
                    if (isLoading) ...[
                      const SizedBox(height: 32),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _goToAdultEntry(BuildContext context) async {
    final location = await MemorizationNavigationResolver(
      getIt<MemorizationPlusRepository>(),
    ).adultEntryLocation();
    if (context.mounted) context.go(location);
  }

  List<Widget> _pathCards(BuildContext context, bool isLoading) {
    final adultsCard = MemorizationPathChoiceCard(
      title: context.l10n.memorizationPathAdultsTitle,
      description: context.l10n.memorizationPathAdultsDesc,
      icon: Icons.person_outline,
      accentColor: AppColors.primary,
      isLoading: isLoading,
      onTap: () {
        _confirmPathSelection(
          context,
          path: MemorizationPath.adult,
          title: context.l10n.memorizationPathAdultsTitle,
          description: context.l10n.memorizationPathAdultsDesc,
        );
      },
    );
    final kidsCard = MemorizationPathChoiceCard(
      title: context.l10n.memorizationPathKidsTitle,
      description: context.l10n.memorizationPathKidsDesc,
      icon: Icons.child_care,
      accentColor: AppColors.primaryLight,
      isLoading: isLoading,
      onTap: () {
        _confirmPathSelection(
          context,
          path: MemorizationPath.child,
          title: context.l10n.memorizationPathKidsTitle,
          description: context.l10n.memorizationPathKidsDesc,
        );
      },
    );
    const spacer = SizedBox(height: 24);

    if (preferredPath == MemorizationPath.child) {
      return [kidsCard, spacer, adultsCard];
    }
    return [adultsCard, spacer, kidsCard];
  }

  Future<void> _confirmPathSelection(
    BuildContext context, {
    required MemorizationPath path,
    required String title,
    required String description,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.memorizationPathConfirmTitle,
                style: AppTypography.headlineSmall.copyWith(
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '$title\n$description',
                style: AppTypography.bodyMedium.copyWith(height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.memorizationPathCanChangeLater,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: Text(context.l10n.confirm),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: Text(context.l10n.goBack),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      unawaited(context.read<MemorizationIdentityCubit>().selectPath(path));
    }
  }
}
