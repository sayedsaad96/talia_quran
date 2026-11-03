import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../quran/domain/repositories/reading_checkpoint_repository.dart';
import '../../../quran/presentation/cubits/reading_checkpoint_cubit.dart';

class ReadingCheckpointPanel extends StatelessWidget {
  const ReadingCheckpointPanel({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ReadingCheckpointCubit, ReadingCheckpointState>(
        builder: (context, state) {
          final result = state.result;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: state.busy
                    ? null
                    : context.read<ReadingCheckpointCubit>().sync,
                child: Text(context.l10n.checkpointSync),
              ),
              if (state.busy) const LinearProgressIndicator(),
              if (state.failed) Text(context.l10n.protectionUnknown),
              if (result?.status == CheckpointSyncStatus.synced)
                Text(context.l10n.protectionSynced),
              if (result?.status == CheckpointSyncStatus.pending)
                Text(context.l10n.protectionPending),
              if (result?.status == CheckpointSyncStatus.conflict &&
                  result?.remote != null) ...[
                Text(
                  context.l10n.checkpointChoose(
                    result!.local?.pageNumber ?? 0,
                    result.remote!.pageNumber,
                  ),
                ),
                TextButton(
                  onPressed: state.busy
                      ? null
                      : () =>
                            context.read<ReadingCheckpointCubit>().choose(true),
                  child: Text(context.l10n.checkpointKeepLocal),
                ),
                TextButton(
                  onPressed: state.busy
                      ? null
                      : () => context.read<ReadingCheckpointCubit>().choose(
                          false,
                        ),
                  child: Text(context.l10n.checkpointUseCloud),
                ),
              ],
            ],
          );
        },
      );
}
