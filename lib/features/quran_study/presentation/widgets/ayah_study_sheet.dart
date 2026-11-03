import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/study_entry.dart';
import '../../domain/usecases/get_ayah_study.dart';
import '../cubits/ayah_study_cubit.dart';
import '../cubits/ayah_study_state.dart';
import 'study_source_footer.dart';
import 'study_text.dart';

class AyahStudySheet extends StatelessWidget {
  const AyahStudySheet({
    super.key,
    required this.surahId,
    required this.ayahNumber,
    required this.getAyahStudy,
  });
  final int surahId, ayahNumber;
  final GetAyahStudy getAyahStudy;
  static Future<void> show(
    BuildContext context, {
    required int surahId,
    required int ayahNumber,
    required GetAyahStudy getAyahStudy,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => AyahStudySheet(
      surahId: surahId,
      ayahNumber: ayahNumber,
      getAyahStudy: getAyahStudy,
    ),
  );
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AyahStudyCubit(getAyahStudy)
      ..load(surahId: surahId, ayahNumber: ayahNumber, kind: StudyKind.tafsir),
    child: _StudyBody(surahId: surahId, ayahNumber: ayahNumber),
  );
}

class _StudyBody extends StatelessWidget {
  const _StudyBody({required this.surahId, required this.ayahNumber});
  final int surahId, ayahNumber;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: Column(
        children: [
          Text(
            '${context.l10n.ayahStudyAction} $surahId:$ayahNumber',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          BlocBuilder<AyahStudyCubit, AyahStudyState>(
            builder: (context, state) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<StudyKind>(
                segments: [
                  ButtonSegment(
                    value: StudyKind.tafsir,
                    label: Text(context.l10n.ayahStudyTafsir),
                  ),
                  ButtonSegment(
                    value: StudyKind.meaningTranslation,
                    label: Text(context.l10n.ayahStudyTranslation),
                  ),
                ],
                selected: {state.kind},
                onSelectionChanged: (selection) => unawaited(
                  context.read<AyahStudyCubit>().load(
                    surahId: surahId,
                    ayahNumber: ayahNumber,
                    kind: selection.first,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<AyahStudyCubit, AyahStudyState>(
              builder: (context, state) {
                if (state.loading) {
                  return Center(
                    child: Semantics(
                      label: context.l10n.ayahStudyLoading,
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }
                final result = state.result;
                if (result == null ||
                    result.status == StudyLoadStatus.unavailable) {
                  return Center(child: Text(context.l10n.ayahStudyUnavailable));
                }
                if (result.status != StudyLoadStatus.ready ||
                    result.source == null) {
                  return Center(child: Text(context.l10n.ayahStudyInvalid));
                }
                if (result.entries.isEmpty) {
                  return Center(child: Text(context.l10n.ayahStudyUnavailable));
                }
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final block in result.entries) ...[
                      Text(
                        '${block.surahId}:${block.fromAyah}${block.toAyah == block.fromAyah ? '' : '–${block.toAyah}'}',
                      ),
                      Directionality(
                        textDirection: block.language.startsWith('ar')
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: StudyText(
                          text: block.text,
                          isTafsir: block.kind == StudyKind.tafsir,
                        ),
                      ),
                      if (block.footnotes.isNotEmpty) ...[
                        Text(
                          context.l10n.ayahStudyFootnotes,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        for (final note in block.footnotes)
                          Directionality(
                            textDirection: block.language.startsWith('ar')
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            child: SelectableText(note),
                          ),
                      ],
                      const SizedBox(height: 16),
                    ],
                    StudySourceFooter(
                      source: result.source!,
                      surahId: surahId,
                      ayahNumber: ayahNumber,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
