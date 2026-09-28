import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../cubits/listening_review_cubit.dart';
import '../cubits/listening_review_state.dart';
import '../widgets/listening_review_views.dart';

/// Adult Listening Review ("مراجعة بالسماع"). Practice only — never changes SRS.
class ListeningReviewPage extends StatelessWidget {
  const ListeningReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ListeningReviewCubit>()..load(),
      child: const ListeningReviewView(),
    );
  }
}

class ListeningReviewView extends StatelessWidget {
  const ListeningReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.listeningReviewTitle)),
      body: SafeArea(
        child: BlocBuilder<ListeningReviewCubit, ListeningReviewState>(
          builder: (context, state) => switch (state) {
            ListeningReviewLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ListeningReviewError() => const ListeningErrorView(),
            ListeningReviewNotEnough() => const ListeningNotEnoughView(),
            ListeningReviewIdle(:final stats) => ListeningStartView(
              stats: stats,
            ),
            final ListeningReviewInRound round => ListeningQuestionView(
              round: round,
            ),
            ListeningReviewFinished(:final result) => ListeningResultView(
              result: result,
            ),
          },
        ),
      ),
    );
  }
}
