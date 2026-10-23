import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../khatmah/data/datasources/khatm_dua_datasource.dart';
import '../../domain/entities/group_khatmah.dart';
import '../cubits/group_khatmah_cubit.dart';
import '../group_khatmah_messages.dart';
import '../widgets/group_khatmah_part_card.dart';

class GroupKhatmahDetailPage extends StatefulWidget {
  const GroupKhatmahDetailPage({
    super.key,
    required this.cubit,
    required this.groupId,
    this.duaDatasource,
    this.onShareCode,
  });

  final GroupKhatmahCubit cubit;
  final String groupId;
  final KhatmDuaDatasource? duaDatasource;
  final Future<void> Function(String code)? onShareCode;

  @override
  State<GroupKhatmahDetailPage> createState() => _GroupKhatmahDetailPageState();
}

class _GroupKhatmahDetailPageState extends State<GroupKhatmahDetailPage> {
  late final Future<KhatmDuaData?> _dua;

  @override
  void initState() {
    super.initState();
    _dua = _approvedDua();
  }

  Future<KhatmDuaData?> _approvedDua() async {
    try {
      final data = await (widget.duaDatasource ?? KhatmDuaDatasource())
          .loadDua();
      return data.isApproved ? data : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _share(String code) async {
    if (widget.onShareCode != null) {
      await widget.onShareCode!(code);
    } else {
      await SharePlus.instance.share(ShareParams(text: code));
    }
  }

  Future<void> _leave(GroupKhatmah group) async {
    final l10n = AppLocalizations.of(context);
    final owner = group.ownerId == widget.cubit.currentOwnerId;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
        title: Text(owner ? l10n.groupKhatmahDelete : l10n.groupKhatmahLeave),
        content: Text(
          owner
              ? l10n.groupKhatmahDeleteConfirm
              : l10n.groupKhatmahLeaveConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.groupKhatmahCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.groupKhatmahConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final left = await widget.cubit.leave(group.id);
    if (left && mounted) Navigator.pop(context);
  }

  Future<void> _showDua(KhatmDuaData data) async {
    if (!data.isApproved || !mounted) return;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.groupKhatmahDuaOpen),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.arabicText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(data.sourceNote),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).closeButtonTooltip),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<GroupKhatmahCubit, GroupKhatmahState>(
        bloc: widget.cubit,
        builder: (context, state) {
          final group = state.validated ? state.group(widget.groupId) : null;
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            appBar: AppBar(title: Text(group?.title ?? l10n.groupKhatmahTitle)),
            body: !state.validated
                ? const Center(child: CircularProgressIndicator())
                : group == null
                ? Center(child: Text(l10n.groupKhatmahNotMember))
                : _body(context, group, state, l10n),
          );
        },
      );

  Widget _body(
    BuildContext context,
    GroupKhatmah group,
    GroupKhatmahState state,
    AppLocalizations l10n,
  ) {
    return RefreshIndicator(
      onRefresh: widget.cubit.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._summary(context, group, state, l10n),
            const SizedBox(height: 8),
            _inviteCard(group, l10n),
            if (group.status == GroupKhatmahStatus.completed)
              _completionCard(l10n),
            _partsGrid(group, state),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: state.busy ? null : () => _leave(group),
              icon: const Icon(TaliaIcons.logout),
              label: Text(
                group.ownerId == widget.cubit.currentOwnerId
                    ? l10n.groupKhatmahDelete
                    : l10n.groupKhatmahLeave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _summary(
    BuildContext context,
    GroupKhatmah group,
    GroupKhatmahState state,
    AppLocalizations l10n,
  ) {
    final completed = group.parts
        .where((part) => part.status == GroupPartStatus.completed)
        .length;
    return [
      Text(l10n.groupKhatmahCompletedCount(completed)),
      Text(l10n.groupKhatmahMembersCount(group.members.length)),
      if (state.errorCode != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            localizedGroupKhatmahError(l10n, state.errorCode!),
            key: const Key('group-khatmah-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      if (state.isStale) Text(l10n.groupKhatmahStale),
    ];
  }

  Widget _inviteCard(GroupKhatmah group, AppLocalizations l10n) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(group.code),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('group-khatmah-share'),
              onPressed: () => _share(group.code),
              icon: const Icon(TaliaIcons.share),
              label: Text(l10n.groupKhatmahShare),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _partsGrid(GroupKhatmah group, GroupKhatmahState state) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final columns = constraints.maxWidth >= 340 && scale <= 1.4 ? 2 : 1;
          final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final part in [
                ...group.parts,
              ]..sort((a, b) => a.juz.compareTo(b.juz)))
                SizedBox(
                  width: width,
                  child: GroupKhatmahPartCard(
                    part: part,
                    group: group,
                    ownerId: widget.cubit.currentOwnerId,
                    busy: state.busy,
                    cubit: widget.cubit,
                  ),
                ),
            ],
          );
        },
      );

  Widget _completionCard(AppLocalizations l10n) => FutureBuilder<KhatmDuaData?>(
    future: _dua,
    builder: (context, snapshot) {
      final data = snapshot.data;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: data == null
              ? Text(l10n.groupKhatmahDuaUnavailable)
              : TextButton.icon(
                  key: const Key('group-khatmah-dua-open'),
                  onPressed: () => _showDua(data),
                  icon: const Icon(TaliaIcons.dua),
                  label: Text(l10n.groupKhatmahDuaOpen),
                ),
        ),
      );
    },
  );
}
