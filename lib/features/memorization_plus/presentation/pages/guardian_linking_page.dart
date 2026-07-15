import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/error_info_banner.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../cubits/guardian_linking_cubit.dart';
import '../cubits/guardian_linking_state.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';

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
    final authState = context.watch<AuthCubit>().state;
    final isGuest = authState is! AuthAuthenticated;

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
                unawaited(_goToKidsJourney(context));
              }
            },
            builder: (context, state) {
              if (!isGuest &&
                  (state is GuardianLinkingLoading ||
                      state is GuardianLinkingInitial)) {
                return const _GuardianLinkingLoading();
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
                    context.l10n.guardianLinkTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineSmall.copyWith(
                      color: textColor,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.guardianLinkDesc,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (isGuest)
                    _GuestGuardianLinkingCard(surface: surface)
                  else ...[
                    if (state is GuardianLinkingError ||
                        state is GuardianLinkingBlocked) ...[
                      ErrorInfoBanner(
                        type: state is GuardianLinkingBlocked
                            ? ErrorInfoBannerType.warning
                            : ErrorInfoBannerType.error,
                        title: state is GuardianLinkingBlocked
                            ? context.l10n.guardianLinkingTemporarilyBlocked
                            : context.l10n.guardianLinkingFailedTitle,
                        message: state is GuardianLinkingError
                            ? (state.kind == GuardianLinkingErrorKind.timeout
                                  ? context.l10n.guardianLinkingTimeoutMessage
                                  : state.message)
                            : (state as GuardianLinkingBlocked).message,
                      ),
                      if (state is GuardianLinkingError) ...[
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.read<GuardianLinkingCubit>().load(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(context.l10n.tryAgain),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                    ],
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
                        title: context.l10n.guardianCodeExpired,
                        message: context.l10n.guardianCreateCodeMessage,
                        actionLabel: context.l10n.guardianCreateNewCode,
                        onPressed: () => context
                            .read<GuardianLinkingCubit>()
                            .createPairingSession(),
                      )
                    else if (state is GuardianLinkingUsed)
                      _StatusCard(
                        surface: surface,
                        title: context.l10n.guardianCodeAlreadyUsed,
                        message: context.l10n.guardianCodeUsedMessage,
                        actionLabel: context.l10n.guardianCreateNewCode,
                        onPressed: () => context
                            .read<GuardianLinkingCubit>()
                            .createPairingSession(),
                      )
                    else
                      _ChoiceActions(surface: surface),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _goToKidsJourney(BuildContext context) async {
    final location = await MemorizationNavigationResolver(
      getIt<MemorizationPlusRepository>(),
    ).guardianLinkedLocation();
    if (context.mounted) context.go(location);
  }
}

/// Loading view for authenticated users. After a short delay it reveals an
/// escape hatch so the user is never trapped on an indefinite spinner with the
/// system back gesture disabled by the surrounding [PopScope].
class _GuardianLinkingLoading extends StatefulWidget {
  const _GuardianLinkingLoading();

  @override
  State<_GuardianLinkingLoading> createState() =>
      _GuardianLinkingLoadingState();
}

class _GuardianLinkingLoadingState extends State<_GuardianLinkingLoading> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (_slow) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              child: Text(
                context.l10n.guardianLinkingSlowHint,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<GuardianLinkingCubit>()
                  .continueWithoutGuardian(),
              icon: Icon(
                context.isArabic
                    ? Icons.arrow_back_rounded
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(context.l10n.continueWithoutGuardian),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuestGuardianLinkingCard extends StatelessWidget {
  const _GuestGuardianLinkingCard({required this.surface});

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
          ErrorInfoBanner(
            type: ErrorInfoBannerType.info,
            title: context.l10n.guardianLinkTitle,
            message: context.l10n.guardianSignInRequired,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.login),
            icon: const Icon(Icons.login_rounded),
            label: Text(context.l10n.guardianSignInAction),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.memorizationPlusKidsHome),
            icon: Icon(
              context.isArabic
                  ? Icons.arrow_back_rounded
                  : Icons.arrow_forward_rounded,
            ),
            label: Text(context.l10n.guardianGuestContinueKids),
          ),
        ],
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
            label: Text(context.l10n.linkGuardianNow),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () =>
                context.read<GuardianLinkingCubit>().continueWithoutGuardian(),
            icon: Icon(
              context.isArabic
                  ? Icons.arrow_back_rounded
                  : Icons.arrow_forward_rounded,
            ),
            label: Text(context.l10n.continueWithoutGuardian),
          ),
        ],
      ),
    );
  }
}

class _PairingCard extends StatefulWidget {
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
  State<_PairingCard> createState() => _PairingCardState();
}

class _PairingCardState extends State<_PairingCard> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _remaining = _calculateRemaining());
      context.read<GuardianLinkingCubit>().checkLinkStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _calculateRemaining() {
    final remaining = widget.expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remaining.inSeconds / 60).ceil().clamp(0, 999);
    final time = TimeOfDay.fromDateTime(widget.expiresAt).format(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: widget.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          QrImageView(
            data: widget.qrData,
            size: 180,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: AppSpacing.lg),
          SelectableText(
            widget.code,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.primary,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.guardianPairingValidUntil(time),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            minutes == 0
                ? context.l10n.guardianPairingExpired
                : context.l10n.guardianPairingExpiresIn(minutes),
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              color: minutes == 0 ? AppColors.error : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PairingSteps(),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () =>
                context.read<GuardianLinkingCubit>().createPairingSession(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.guardianRegenerateCode),
          ),
        ],
      ),
    );
  }
}

class _PairingSteps extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      context.l10n.guardianPairingStepOpenParentDevice,
      context.l10n.guardianPairingStepOpenDashboard,
      context.l10n.guardianPairingStepScanOrEnterCode,
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.guardianPairingStepsTitle,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == steps.length - 1 ? 0 : AppSpacing.xs,
              ),
              child: Text(
                '${i + 1}. ${steps[i]}',
                style: AppTypography.bodySmall,
                textDirection: Directionality.of(context),
              ),
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
