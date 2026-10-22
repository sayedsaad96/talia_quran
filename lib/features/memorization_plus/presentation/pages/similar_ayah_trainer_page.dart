import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/memorization/similar_ayah/ayah_comparison_aligner.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../domain/entities/confusion_pair.dart';
import '../../domain/entities/similar_ayah_reference_pair.dart';
import '../cubits/similar_ayah_trainer_cubit.dart';
import '../widgets/similar_ayah_label.dart';

/// Presentation-only historical practice; construction is supplied by routing.
final class SimilarAyahTrainerPage extends StatelessWidget {
  const SimilarAyahTrainerPage({super.key, required this.cubit});

  final SimilarAyahTrainerCubit cubit;

  @override
  Widget build(BuildContext context) =>
      BlocProvider.value(value: cubit, child: const _TrainerView());
}

final class _TrainerView extends StatelessWidget {
  const _TrainerView();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SimilarAyahTrainerCubit, SimilarAyahTrainerState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.similarAyahTrainerTitle),
            leading: state.selected == null
                ? null
                : BackButton(
                    onPressed: context
                        .read<SimilarAyahTrainerCubit>()
                        .showPairs,
                  ),
          ),
          body: SafeArea(child: _body(context, state)),
        ),
      );

  Widget _body(BuildContext context, SimilarAyahTrainerState state) {
    if (!state.available || state.gated) {
      return _Message(context.l10n.similarAyahTrainerUnavailable);
    }
    if (state.indexUnavailable) {
      return _Message(context.l10n.similarAyahIndexUnavailable);
    }
    if (state.loading && state.selected == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.failed) return _Retry(pair: state.selected);
    if (state.selected != null) return _Practice(state: state);
    if (state.related.isNotEmpty) return _RelatedList(pairs: state.related);
    if (state.pairs.isEmpty) {
      return _Message(context.l10n.similarAyahTrainerEmpty);
    }
    return _PairList(pairs: state.pairs);
  }
}

final class _PairList extends StatelessWidget {
  const _PairList({required this.pairs});
  final List<ConfusionPair> pairs;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(context.l10n.similarAyahTrainerMachineNote),
      const SizedBox(height: 12),
      for (final pair in pairs)
        Card(
          child: ListTile(
            leading: const Icon(TaliaIcons.swapHorizontal),
            title: Text(
              '${similarAyahLabel(context, pair.targetSurahId, pair.targetAyahNumber)}'
              '  ↔  '
              '${similarAyahLabel(context, pair.otherSurahId, pair.otherAyahNumber)}',
            ),
            subtitle: Text(context.l10n.similarAyahTrainerCount(pair.count)),
            onTap: () => context.read<SimilarAyahTrainerCubit>().choose(pair),
          ),
        ),
    ],
  );
}

final class _RelatedList extends StatelessWidget {
  const _RelatedList({required this.pairs});
  final List<SimilarAyahReferencePair> pairs;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(context.l10n.similarAyahTrainerMachineNote),
      for (final pair in pairs)
        ListTile(
          title: Text(
            similarAyahLabel(context, pair.otherSurahId, pair.otherAyahNumber),
          ),
          onTap: () =>
              context.read<SimilarAyahTrainerCubit>().chooseReference(pair),
        ),
    ],
  );
}

final class _Practice extends StatelessWidget {
  const _Practice({required this.state});
  final SimilarAyahTrainerState state;

  @override
  Widget build(BuildContext context) {
    final target = state.target;
    final other = state.other;
    if (state.loading || target == null || other == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final comparison = const AyahComparisonAligner().align(
      leftText: target.ayah.text,
      rightText: other.ayah.text,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.l10n.similarAyahTrainerMachineNote),
        const SizedBox(height: 12),
        if (state.practiceMode && !state.revealTarget)
          ..._practiceChildren(context, target)
        else
          ..._comparisonChildren(context, target, other, comparison),
      ],
    );
  }

  List<Widget> _practiceChildren(
    BuildContext context,
    SimilarAyahTrainerPassage target,
  ) => [
    Text(context.l10n.similarAyahTrainerPractice),
    if (target.previous != null)
      _PassageCard(
        label: context.l10n.similarAyahTrainerPrevious,
        passage: target.previous!,
      )
    else
      Text(context.l10n.similarAyahTrainerNoPrevious),
    FilledButton.icon(
      onPressed: context.read<SimilarAyahTrainerCubit>().revealTarget,
      icon: const Icon(TaliaIcons.show),
      label: Text(context.l10n.similarAyahTrainerReveal),
    ),
  ];

  List<Widget> _comparisonChildren(
    BuildContext context,
    SimilarAyahTrainerPassage target,
    SimilarAyahTrainerPassage other,
    AyahComparisonAlignment comparison,
  ) => [
    if (target.previous != null)
      _PassageCard(
        label: context.l10n.similarAyahTrainerPrevious,
        passage: target.previous!,
      ),
    if (target.previous == null)
      Text(context.l10n.similarAyahTrainerNoPrevious),
    _PassageCard(
      label: context.l10n.similarAyahTrainerTarget,
      passage: target.ayah,
      spans: comparison.left,
    ),
    _PassageCard(
      label: context.l10n.similarAyahTrainerOther,
      passage: other.ayah,
      spans: comparison.right,
    ),
    if (other.previous != null)
      _PassageCard(
        label: context.l10n.similarAyahTrainerPrevious,
        passage: other.previous!,
      ),
    if (other.previous == null) Text(context.l10n.similarAyahTrainerNoPrevious),
    FilledButton.icon(
      onPressed: () => context.read<SimilarAyahTrainerCubit>().startPractice(),
      icon: const Icon(TaliaIcons.hifz),
      label: Text(context.l10n.similarAyahTrainerPractice),
    ),
  ];
}

final class _PassageCard extends StatelessWidget {
  const _PassageCard({required this.label, required this.passage, this.spans});
  final String label;
  final Ayah passage;
  final List<AyahComparisonSpan>? spans;

  @override
  Widget build(BuildContext context) {
    final displaySpans =
        spans ??
        const AyahComparisonAligner()
            .align(leftText: passage.text, rightText: passage.text)
            .left;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label · ${similarAyahLabel(context, passage.surahId, passage.numberInSurah)}',
            ),
            const SizedBox(height: 8),
            Semantics(
              label: passage.text,
              child: ExcludeSemantics(
                child: RichText(
                  textDirection: TextDirection.rtl,
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    style: AppTypography.quranVerse.copyWith(
                      color: DefaultTextStyle.of(context).style.color,
                    ),
                    children: _textSpans(context, displaySpans),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _textSpans(
    BuildContext context,
    List<AyahComparisonSpan> spans,
  ) => [
    for (final span in spans)
      TextSpan(
        text: passage.text.substring(span.start, span.end),
        style: span.status == AyahComparisonSpanStatus.different
            ? TextStyle(color: Theme.of(context).colorScheme.error)
            : null,
      ),
  ];
}

final class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}

final class _Retry extends StatelessWidget {
  const _Retry({this.pair});
  final SimilarAyahReferencePair? pair;
  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(
      onPressed: () async {
        final cubit = context.read<SimilarAyahTrainerCubit>();
        final selected = pair;
        if (selected == null) {
          await cubit.retry();
        } else {
          await cubit.chooseReference(selected);
        }
      },
      child: Text(context.l10n.similarAyahTrainerTryAgain),
    ),
  );
}
