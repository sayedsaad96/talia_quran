// lib/features/memorization_plus/presentation/pages/v2/kids_v2_session_page.dart
//
// Kids V2 session entry point + phase router.
// Flow: Listen → Try to Remember → Complete

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/memorization/v2/session_phase.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/state_widgets.dart';
import '../../cubits/kids_memorization_session_cubit.dart';
import 'kids_listen_page.dart';
import 'kids_try_remember_page.dart';
import 'kids_completion_page.dart';

/// Entry point for the Kids V2 memorization session.
class KidsV2SessionPage extends StatelessWidget {
  const KidsV2SessionPage({
    super.key,
    required this.surahId,
    required this.ayahNumber,
  });

  final int surahId;
  final int ayahNumber;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<KidsMemorizationSessionCubit>()
        ..startSession(surahId: surahId, startAyah: ayahNumber),
      child: const _KidsV2SessionView(),
    );
  }
}

class _KidsV2SessionView extends StatelessWidget {
  const _KidsV2SessionView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.isArabic ? 'حفظ الآية' : 'Memorize Ayah'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.kidsGreen,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<KidsMemorizationSessionCubit,
          KidsMemorizationSessionState>(
        listener: (context, state) {
          if (state is KMSError) {
            context.showSnackBar(state.message, isError: true);
          }
        },
        builder: (context, state) {
          if (state is KMSLoading || state is KMSInitial) {
            return const Center(child: LoadingWidget());
          }
          if (state is KMSError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.go(AppRoutes.memorizationPlusKidsHome),
            );
          }
          if (state is KMSCompleted) {
            return KidsCompletionV2Page(completed: state);
          }
          if (state is! KMSActive) return const SizedBox.shrink();

          // Phase router: Learning → Listen, Memorizing → Try to Remember.
          return switch (state.sessionState.phase) {
            V2SessionPhase.created ||
            V2SessionPhase.learning =>
              KidsListenPage(state: state),
            V2SessionPhase.memorizing ||
            V2SessionPhase.reciting ||
            V2SessionPhase.remediation =>
              KidsTryRememberPage(state: state),
            // Kids never reach blockReview phases (blockReviewRequired=false).
            V2SessionPhase.blockReviewPending ||
            V2SessionPhase.blockReview ||
            V2SessionPhase.completed =>
              KidsCompletionV2Page(
                completed: KMSCompleted(
                  finalState: state.sessionState,
                  awards: const [],
                  starsEarned: 0,
                ),
              ),
          };
        },
      ),
    );
  }
}
