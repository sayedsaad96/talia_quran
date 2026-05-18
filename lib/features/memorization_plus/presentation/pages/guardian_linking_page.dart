import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/guardian_linking_cubit.dart';
import '../cubits/guardian_linking_state.dart';

class GuardianLinkingPage extends StatelessWidget {
  const GuardianLinkingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GuardianLinkingCubit>()..load(),
      child: const _GuardianLinkingView(),
    );
  }
}

class _GuardianLinkingView extends StatelessWidget {
  const _GuardianLinkingView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: SafeArea(
          child: BlocConsumer<GuardianLinkingCubit, GuardianLinkingState>(
            listener: (context, state) {
              if (state is GuardianLinkingSkipped ||
                  state is GuardianLinkingLinked) {
                context.go('/memorization-plus/kids-journey?surahId=1');
              } else if (state is GuardianLinkingError ||
                  state is GuardianLinkingBlocked) {
                final message = state is GuardianLinkingError
                    ? state.message
                    : (state as GuardianLinkingBlocked).message;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            },
            builder: (context, state) {
              if (state is GuardianLinkingLoading ||
                  state is GuardianLinkingInitial) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const Icon(
                    Icons.family_restroom_rounded,
                    color: AppColors.primary,
                    size: 64,
                    semanticLabel: 'Guardian linking',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'ربط حساب ولي الأمر',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineSmall.copyWith(
                      color: textColor,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'اختر ما إذا كنت تريد ربط ولي أمر بهذا المسار لمتابعة حفظ الطفل.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (state is GuardianLinkingPending)
                    _PairingCard(
                      surface: surface,
                      code: state.session.pairingCode,
                      qrData: state.session.qrData,
                      expiresAt: state.session.expiresAt,
                    )
                  else if (state is GuardianLinkingExpired)
                    _StatusCard(
                      surface: surface,
                      title: 'انتهت صلاحية الرمز',
                      message: 'قم بإنشاء رمز جديد صالح لمدة 15 دقيقة.',
                      actionLabel: 'إنشاء رمز جديد',
                      onPressed: () => context
                          .read<GuardianLinkingCubit>()
                          .createPairingSession(),
                    )
                  else if (state is GuardianLinkingUsed)
                    _StatusCard(
                      surface: surface,
                      title: 'الرمز مستخدم مسبقاً',
                      message: 'لا يمكن استخدام هذا الرمز مرة أخرى.',
                      actionLabel: 'إنشاء رمز جديد',
                      onPressed: () => context
                          .read<GuardianLinkingCubit>()
                          .createPairingSession(),
                    )
                  else
                    _ChoiceActions(surface: surface),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChoiceActions extends StatelessWidget {
  const _ChoiceActions({required this.surface});
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () =>
                context.read<GuardianLinkingCubit>().createPairingSession(),
            icon: const Icon(Icons.qr_code_rounded),
            label: const Text('ربط ولي الأمر الآن'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () =>
                context.read<GuardianLinkingCubit>().continueWithoutGuardian(),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('المتابعة بدون ربط'),
          ),
        ],
      ),
    );
  }
}

class _PairingCard extends StatelessWidget {
  const _PairingCard({
    required this.surface,
    required this.code,
    required this.qrData,
    required this.expiresAt,
  });

  final Color surface;
  final String code;
  final String qrData;
  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          QrImageView(data: qrData, size: 180, backgroundColor: Colors.white),
          const SizedBox(height: AppSpacing.lg),
          SelectableText(
            code,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.primary,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Valid until ${TimeOfDay.fromDateTime(expiresAt).format(context)}',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () =>
                context.read<GuardianLinkingCubit>().createPairingSession(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Regenerate code'),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.surface,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final Color surface;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Text(title, style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
