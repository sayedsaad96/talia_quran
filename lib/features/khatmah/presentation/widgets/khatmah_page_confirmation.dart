import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/khatmah_read_confirmation_policy.dart';
import '../cubits/khatmah_cubit.dart';

class KhatmahPageConfirmation extends StatefulWidget {
  const KhatmahPageConfirmation({
    super.key,
    required this.cubit,
    required this.pageNumber,
    required this.enabled,
    required this.onConfirm,
  });

  final KhatmahCubit cubit;
  final int pageNumber;
  final bool enabled;
  final Future<void> Function() onConfirm;

  @override
  State<KhatmahPageConfirmation> createState() =>
      _KhatmahPageConfirmationState();
}

class _KhatmahPageConfirmationState extends State<KhatmahPageConfirmation> {
  bool _saving = false;

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onConfirm();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<KhatmahCubit, KhatmahState>(
    bloc: widget.cubit,
    builder: (context, state) {
      final plan = switch (state) {
        KhatmahActive(:final plan) => plan,
        KhatmahWirdCompleted(:final plan) => plan,
        _ => null,
      };
      if (plan == null ||
          !requiresKhatmahReadConfirmation(
            plan,
            widget.pageNumber,
            widget.cubit.displayDate,
          )) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('khatmah_confirm_page_button'),
            onPressed: widget.enabled && !_saving ? _confirm : null,
            child: Text(
              _saving
                  ? context.l10n.khatmahSaving
                  : context.l10n.khatmahFinishedReadingPage,
            ),
          ),
        ),
      );
    },
  );
}
