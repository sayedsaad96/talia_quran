// lib/features/memorization_plus/presentation/pages/v2_session_page.dart
//
// V2 session orchestrator — owns the BlocProvider and the phase router.
// All phase UI widgets live in the v2/ subdirectory.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/memorization/v2/session_phase.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../certificate/presentation/widgets/certificate_celebration_dialog.dart';
import '../cubits/memorization_session_cubit.dart';
import 'v2/v2_block_review_page.dart';
import 'v2/v2_completion_page.dart';
import 'v2/v2_learning_page.dart';
import 'v2/v2_memorizing_page.dart';
import 'v2/v2_recitation_page.dart';
import 'v2/v2_remediation_page.dart';

export 'v2/v2_block_review_page.dart'
    show V2BlockReviewPendingPage, V2BlockReviewPage;
export 'v2/v2_completion_page.dart' show V2CompletionPage;
export 'v2/v2_learning_page.dart' show V2LearningPage;
export 'v2/v2_memorizing_page.dart' show V2MemorizingPage;
export 'v2/v2_recitation_page.dart' show V2RecitationPage;
export 'v2/v2_remediation_page.dart' show V2RemediationPage;

/// Entry-point widget for the V2 memorization session.
///
/// Creates the [MemorizationSessionCubit] and starts the session.
/// Delegates phase rendering to the dedicated page widgets in `v2/`.
class V2SessionPage extends StatelessWidget {
  const V2SessionPage({
    super.key,
    required this.surahId,
    required this.startAyah,
    this.blockSize = 5,
  });

  final int surahId;
  final int startAyah;
  final int blockSize;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MemorizationSessionCubit>()
        ..startSession(
          surahId: surahId,
          startAyah: startAyah,
          blockSize: blockSize,
        ),
      child: const _V2SessionView(),
    );
  }
}

class _V2SessionView extends StatefulWidget {
  const _V2SessionView();

  @override
  State<_V2SessionView> createState() => _V2SessionViewState();
}

class _V2SessionViewState extends State<_V2SessionView> {
  /// Set after the user confirms leave so [PopScope] allows the route pop.
  var _forceAllowPop = false;

  Future<void> _onPopInvoked({
    required bool didPop,
    required bool sessionAllowsPop,
  }) async {
    if (didPop || sessionAllowsPop || _forceAllowPop) return;
    final l10n = context.l10n;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.hifzLeaveSessionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (shouldLeave != true || !mounted) return;
    setState(() => _forceAllowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.memorizationPlus);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return BlocConsumer<MemorizationSessionCubit, MemorizationSessionState>(
      listenWhen: (previous, current) {
        if (current is MSError) return true;
        return current is MSCompleted && previous is! MSCompleted;
      },
      listener: (context, state) {
        if (state is MSError) {
          context.showSnackBar(state.message, isError: true);
          return;
        }
        if (state is MSCompleted && state.awards.isNotEmpty) {
          unawaited(
            showCertificateCelebrationDialog(context, state.awards),
          );
        }
      },
      builder: (context, state) {
        final sessionAllowsPop = state is! MSActive;
        final allowPop = sessionAllowsPop || _forceAllowPop;
        return PopScope(
          canPop: allowPop,
          onPopInvokedWithResult: (didPop, _) {
            unawaited(
              _onPopInvoked(
                didPop: didPop,
                sessionAllowsPop: sessionAllowsPop,
              ),
            );
          },
          child: Scaffold(
            backgroundColor:
                isDark ? AppColors.darkBackground : AppColors.lightBackground,
            appBar: AppBar(
              title: Text(context.l10n.memorizationSessionTitle),
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MemorizationSessionState state) {
    if (state is MSLoading || state is MSInitial) {
      return const Center(child: LoadingWidget());
    }
    if (state is MSError) {
      return ErrorStateWidget(
        message: state.message,
        onRetry: () => context.go(AppRoutes.memorizationPlus),
      );
    }
    if (state is MSCompleted) {
      return V2CompletionPage(finalState: state.finalState);
    }
    if (state is! MSActive) return const SizedBox.shrink();

    return switch (state.sessionState.phase) {
      V2SessionPhase.created ||
      V2SessionPhase.learning =>
        V2LearningPage(state: state),
      V2SessionPhase.memorizing => V2MemorizingPage(state: state),
      V2SessionPhase.reciting => V2RecitationPage(state: state),
      V2SessionPhase.remediation => V2RemediationPage(state: state),
      V2SessionPhase.blockReviewPending => V2BlockReviewPendingPage(
        state: state,
      ),
      V2SessionPhase.blockReview => V2BlockReviewPage(state: state),
      V2SessionPhase.completed => const Center(child: LoadingWidget()),
    };
  }
}
