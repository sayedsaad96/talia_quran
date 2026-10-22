import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/ayah_note.dart';
import '../cubits/ayah_notes_cubit.dart';
import '../../domain/services/ayah_note_policy.dart';

/// Separate private-note editor. It never renders note text in the Mushaf.
class AyahNoteEditorSheet extends StatelessWidget {
  const AyahNoteEditorSheet({
    super.key,
    required this.surahId,
    required this.ayahNumber,
  });

  final int surahId;
  final int ayahNumber;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<AyahNotesCubit>()..openEditor(surahId, ayahNumber),
    child: _AyahNoteEditorBody(surahId: surahId, ayahNumber: ayahNumber),
  );
}

class _AyahNoteEditorBody extends StatefulWidget {
  const _AyahNoteEditorBody({required this.surahId, required this.ayahNumber});
  final int surahId;
  final int ayahNumber;
  @override
  State<_AyahNoteEditorBody> createState() => _AyahNoteEditorBodyState();
}

class _AyahNoteEditorBodyState extends State<_AyahNoteEditorBody> {
  final _controller = TextEditingController();
  var _saving = false;
  AyahNote? _loadedNote;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = await context.read<AyahNotesCubit>().saveEditor(
        widget.surahId,
        widget.ayahNumber,
        _controller.text,
      );
      if (mounted && saved) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<AyahNotesCubit, AyahNotesState>(
    listenWhen: (before, after) =>
        before.available != after.available ||
        before.loading != after.loading ||
        before.editorNote != after.editorNote ||
        before.saveFailed != after.saveFailed ||
        before.editorLoadFailed != after.editorLoadFailed,
    listener: (context, state) {
      final note = state.editorNote;
      if (!state.available || state.loading) {
        _controller.clear();
        _loadedNote = null;
      } else if (note != null && note != _loadedNote) {
        _controller.text = note.body;
        _loadedNote = note;
      } else if (note == null) {
        _loadedNote = null;
      }
      if (state.saveFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.ayahNoteSaveFailed)),
        );
      }
      if (state.editorLoadFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.ayahNotesLoadFailed)),
        );
      }
    },
    builder: (context, state) {
      final canEdit =
          state.available && !state.loading && !state.editorLoadFailed;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            AppSpacing.pagePadding + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.ayahNoteLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _controller,
                  autofocus: canEdit,
                  enabled: canEdit,
                  maxLines: 6,
                  // Same grapheme limit the save enforces, shown as a counter.
                  maxLength: AyahNotePolicy.maxBodyLength,
                  decoration: InputDecoration(
                    hintText: context.l10n.ayahNoteHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _saving || !canEdit ? null : _save,
                  child: Text(context.l10n.save),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
