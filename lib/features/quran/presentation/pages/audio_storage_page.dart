import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/services/quran_audio_download_manager.dart';
import '../../../../core/services/quran_reciter.dart';
import '../cubits/audio_downloads_cubit.dart';

class AudioStoragePage extends StatelessWidget {
  const AudioStoragePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        AudioDownloadsCubit(getIt<QuranAudioDownloadManager>())..loadStorage(),
    child: Scaffold(
      appBar: AppBar(title: Text(context.l10n.audioDownloadsStorage)),
      body: BlocBuilder<AudioDownloadsCubit, AudioDownloadsState>(
        builder: (context, state) => ListView(
          children: [
            if (state.busy) const LinearProgressIndicator(),
            if (state.failed)
              ListTile(
                title: Text(context.l10n.tryAgain),
                onTap: () => context.read<AudioDownloadsCubit>().loadStorage(),
              ),
            for (final reciter in QuranReciter.availableValues)
              ListTile(
                title: Text(context.isArabic ? reciter.nameAr : reciter.nameEn),
                subtitle: !state.bytes.containsKey(reciter)
                    ? null
                    : Text(
                        context.l10n.audioDownloadsBytes(
                          context.numText(state.bytes[reciter] ?? 0),
                        ),
                      ),
                trailing: IconButton(
                  tooltip: context.l10n.audioDownloadsDelete,
                  icon: const Icon(TaliaIcons.delete),
                  onPressed: state.busy
                      ? null
                      : () => _delete(context, reciter),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> _delete(BuildContext context, QuranReciter reciter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(context.l10n.audioDownloadsDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.audioDownloadsDelete),
          ),
        ],
      ),
    );
    if (context.mounted && confirmed == true) {
      await context.read<AudioDownloadsCubit>().deleteReciter(reciter);
    }
  }
}
