import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../settings/presentation/cubits/profile_cubit.dart';

Future<void> showCertificateCelebrationDialog(
  BuildContext context,
  List<CertificateAward> awards,
) {
  if (awards.isEmpty) return Future.value();

  final userName = _resolveUserName(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => CertificateCelebrationDialog(
      awards: awards,
      onViewAward: (award) {
        Navigator.of(dialogContext).pop();
        unawaited(
          context.push(
            '/certificate',
            extra: {'award': award, 'userName': userName},
          ),
        );
      },
    ),
  );
}

String _resolveUserName(BuildContext context) {
  try {
    final state = context.read<ProfileCubit>().state;
    if (state is ProfileLoaded) return state.profile.displayName;
  } catch (_) {
    // Some full-screen routes are built outside the profile provider tree.
  }

  try {
    final cubit = getIt<ProfileCubit>();
    if (cubit.state is ProfileInitial) cubit.loadProfile();
    final state = cubit.state;
    if (state is ProfileLoaded) return state.profile.displayName;
  } catch (_) {
    // Dependency injection may not be ready in widget tests.
  }

  return context.l10n.taliaUser;
}

class CertificateCelebrationDialog extends StatefulWidget {
  const CertificateCelebrationDialog({
    super.key,
    required this.awards,
    required this.onViewAward,
  });

  final List<CertificateAward> awards;
  final ValueChanged<CertificateAward> onViewAward;

  @override
  State<CertificateCelebrationDialog> createState() =>
      _CertificateCelebrationDialogState();
}

class _CertificateCelebrationDialogState
    extends State<CertificateCelebrationDialog> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    )..play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final multiple = widget.awards.length > 1;
    final title = context.l10n.congratulations;
    final subtitle = multiple
        ? (context.isArabic
              ? 'لقد حصلت على ${widget.awards.length} شهادات جديدة'
              : 'You earned ${widget.awards.length} new certificates!')
        : (context.isArabic
              ? 'لقد حصلت على ${widget.awards.first.titleAr}'
              : 'You earned a new certificate!');

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.gold,
                  size: 64,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final award in widget.awards) ...[
                          _AwardTile(
                            award: award,
                            isDark: isDark,
                            onView: () => widget.onViewAward(award),
                          ),
                          if (award != widget.awards.last)
                            const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    context.l10n.continueMemorizing,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ],
      ),
    );
  }
}

class _AwardTile extends StatelessWidget {
  const _AwardTile({
    required this.award,
    required this.isDark,
    required this.onView,
  });

  final CertificateAward award;
  final bool isDark;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final icon = switch (award.type) {
      CertificateType.juz => Icons.menu_book_rounded,
      CertificateType.surah => Icons.verified_rounded,
      CertificateType.halfQuran => Icons.auto_stories_rounded,
      CertificateType.fullQuran => Icons.workspace_premium_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              award.titleAr,
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontFamily: 'Amiri',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: onView,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(context.l10n.view),
          ),
        ],
      ),
    );
  }
}
