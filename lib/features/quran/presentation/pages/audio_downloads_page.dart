import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/services/quran_audio_download_manager.dart';
import '../../../../core/services/quran_reciter.dart';
import '../../../../core/services/quran_reciter_service.dart';
import '../cubits/audio_downloads_cubit.dart';

class AudioDownloadsPage extends StatelessWidget {
  const AudioDownloadsPage({super.key, this.initialSurah});
  final int? initialSurah;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AudioDownloadsCubit(getIt<QuranAudioDownloadManager>()),
    child: _DownloadView(initialSurah: initialSurah),
  );
}

class _DownloadView extends StatefulWidget {
  const _DownloadView({this.initialSurah});
  final int? initialSurah;

  @override
  State<_DownloadView> createState() => _DownloadViewState();
}

class _DownloadViewState extends State<_DownloadView> {
  QuranReciter _reciter = getIt.isRegistered<QuranReciterService>()
      ? getIt<QuranReciterService>().currentReciter.value
      : QuranReciter.alafasy;
  late int _surah = widget.initialSurah ?? 1;
  int _juz = 30;
  bool _wholeJuz = false;
  bool _wifiOnly = true;

  Future<void> _start() async {
    final cubit = context.read<AudioDownloadsCubit>();
    final unmetered = _wifiOnly ? await cubit.probeUnmeteredNetwork() : null;
    if (!mounted) return;
    // A known network needs no confirmation: Wi-Fi proceeds, and a metered
    // network is refused by the manager with a "connect to Wi-Fi" status.
    if (_wifiOnly && unmetered != null) {
      await cubit.start(
        reciter: _reciter,
        wifiOnly: true,
        allowUnverifiedNetwork: false,
        surah: _wholeJuz ? null : _surah,
        juz: _wholeJuz ? _juz : null,
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.audioDownloadsTitle),
        content: Text(context.l10n.audioDownloadsNetworkWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.audioDownloadsProceed),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await cubit.start(
      reciter: _reciter,
      wifiOnly: _wifiOnly,
      allowUnverifiedNetwork: true,
      surah: _wholeJuz ? null : _surah,
      juz: _wholeJuz ? _juz : null,
    );
  }

  /// Leaving the page cancels the running download, so ask first.
  Future<void> _confirmLeave() async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.audioDownloadsLeaveTitle),
        content: Text(context.l10n.audioDownloadsLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.audioDownloadsLeaveStay),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.audioDownloadsLeaveStop),
          ),
        ],
      ),
    );
    if (!mounted || stop != true) return;
    await context.read<AudioDownloadsCubit>().cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AudioDownloadsCubit, AudioDownloadsState>(
        buildWhen: (a, b) => a.busy != b.busy,
        builder: (context, gate) => PopScope(
          canPop: !gate.busy,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_confirmLeave());
          },
          child: _scaffold(),
        ),
      );

  Widget _scaffold() => Scaffold(
    appBar: AppBar(title: Text(context.l10n.audioDownloadsTitle)),
    body: BlocBuilder<AudioDownloadsCubit, AudioDownloadsState>(
      builder: (context, state) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _reciterField(state.busy),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(context.l10n.audioDownloadsWholeJuz),
            value: _wholeJuz,
            onChanged: state.busy
                ? null
                : (value) => setState(() => _wholeJuz = value),
          ),
          if (_wholeJuz) _juzField(state.busy) else _surahField(state.busy),
          SwitchListTile(
            title: Text(context.l10n.audioDownloadsWifiOnly),
            value: _wifiOnly,
            onChanged: state.busy
                ? null
                : (value) => setState(() => _wifiOnly = value),
          ),
          const SizedBox(height: 12),
          if (state.progress?.spaceUnknown ?? false) ...[
            Text(context.l10n.audioDownloadsSpaceUnknown),
            const SizedBox(height: 16),
          ],
          if (state.progress case final progress?) ...[
            Text(_status(context, progress.phase)),
            if (progress.totalAyahs > 0)
              Text(
                '${context.numText(progress.completedAyahs)} / ${context.numText(progress.totalAyahs)}',
              ),
            if (state.busy) const LinearProgressIndicator(),
            const SizedBox(height: 16),
          ],
          if (state.failed) Text(context.l10n.audioDownloadsFailed),
          FilledButton(
            onPressed: state.busy ? null : _start,
            child: Text(context.l10n.audioDownloadsStart),
          ),
          if (state.busy)
            TextButton(
              onPressed: () => context.read<AudioDownloadsCubit>().cancel(),
              child: Text(context.l10n.cancel),
            ),
        ],
      ),
    ),
  );

  Widget _reciterField(bool busy) => DropdownButtonFormField<QuranReciter>(
    initialValue: _reciter,
    isExpanded: true,
    decoration: InputDecoration(labelText: context.l10n.selectReciter),
    items: QuranReciter.availableValues
        .map(
          (reciter) => DropdownMenuItem(
            value: reciter,
            child: Text(context.isArabic ? reciter.nameAr : reciter.nameEn),
          ),
        )
        .toList(),
    onChanged: busy ? null : (value) => setState(() => _reciter = value!),
  );

  Widget _surahField(bool busy) => DropdownButtonFormField<int>(
    initialValue: _surah,
    decoration: InputDecoration(labelText: context.l10n.surah),
    isExpanded: true,
    items: List.generate(
      114,
      (index) => DropdownMenuItem(
        value: index + 1,
        child: Text(context.localizedSurahName(index + 1)),
      ),
    ),
    onChanged: busy ? null : (value) => setState(() => _surah = value!),
  );

  Widget _juzField(bool busy) => DropdownButtonFormField<int>(
    initialValue: _juz,
    decoration: InputDecoration(labelText: context.l10n.juz),
    items: List.generate(
      30,
      (index) => DropdownMenuItem(
        value: index + 1,
        child: Text(context.l10n.audioDownloadsJuz(context.numText(index + 1))),
      ),
    ),
    onChanged: busy ? null : (value) => setState(() => _juz = value!),
  );

  String _status(BuildContext context, DownloadPhase phase) => switch (phase) {
    DownloadPhase.completed => context.l10n.audioDownloadsCompleted,
    DownloadPhase.cancelled => context.l10n.audioDownloadsCancelled,
    DownloadPhase.insufficientSpace =>
      context.l10n.audioDownloadsInsufficientSpace,
    DownloadPhase.failed => context.l10n.audioDownloadsFailed,
    DownloadPhase.waitingForNetworkConfirmation =>
      context.l10n.audioDownloadsWifiUnavailable,
    DownloadPhase.waitingForWifi => context.l10n.audioDownloadsWaitingForWifi,
    _ => context.l10n.audioDownloadsInProgress,
  };
}
