import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../cubits/ayah_notes_cubit.dart';

class AyahNotesPage extends StatelessWidget {
  const AyahNotesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<AyahNotesCubit>()..loadList(),
    child: Scaffold(
      appBar: AppBar(title: Text(context.l10n.ayahNotesTitle)),
      body: BlocConsumer<AyahNotesCubit, AyahNotesState>(
        listenWhen: (before, after) =>
            !before.navigationFailed && after.navigationFailed,
        listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.ayahNoteNavigationFailed)),
        ),
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!state.available || state.listFailed) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.ayahNotesLoadFailed),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<AyahNotesCubit>().loadList(),
                    child: Text(context.l10n.tryAgain),
                  ),
                ],
              ),
            );
          }
          if (state.notes.isEmpty) {
            return Center(child: Text(context.l10n.ayahNotesEmpty));
          }
          return ListView.separated(
            itemCount: state.notes.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final note = state.notes[index];
              return ListTile(
                title: Text(
                  context.l10n.surahAyahFormat(
                    context.localizedSurahName(note.surahId),
                    context.numText(note.ayahNumber),
                  ),
                ),
                subtitle: Text(
                  note.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  final page = await context.read<AyahNotesCubit>().pageFor(
                    note,
                  );
                  if (context.mounted && page != null) {
                    unawaited(
                      context.push(
                        Uri(
                          path: '/quran/page/$page',
                          queryParameters: {
                            'targetSurah': '${note.surahId}',
                            'targetAyah': '${note.ayahNumber}',
                          },
                        ).toString(),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    ),
  );
}
