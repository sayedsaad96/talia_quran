import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../khatmah/data/datasources/khatm_dua_datasource.dart';
import '../../domain/entities/group_khatmah.dart';
import '../cubits/group_khatmah_cubit.dart';
import '../group_khatmah_messages.dart';
import '../widgets/group_khatmah_recovery_panel.dart';
import 'group_khatmah_detail_page.dart';
import 'group_khatmah_join_sheet.dart';

class GroupKhatmahListPage extends StatefulWidget {
  const GroupKhatmahListPage({
    super.key,
    required this.cubit,
    this.duaDatasource,
    this.onShareCode,
    this.onBack,
  });

  final GroupKhatmahCubit cubit;
  final KhatmDuaDatasource? duaDatasource;
  final Future<void> Function(String code)? onShareCode;
  final VoidCallback? onBack;

  @override
  State<GroupKhatmahListPage> createState() => _GroupKhatmahListPageState();
}

class _GroupKhatmahListPageState extends State<GroupKhatmahListPage> {
  @override
  void initState() {
    super.initState();
    widget.cubit.start();
  }

  Future<void> _showSheet(bool isCreate) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: false,
      builder: (context) =>
          GroupKhatmahJoinSheet(cubit: widget.cubit, isCreate: isCreate),
    );
  }

  void _open(GroupKhatmah group) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupKhatmahDetailPage(
          cubit: widget.cubit,
          groupId: group.id,
          duaDatasource: widget.duaDatasource,
          onShareCode: widget.onShareCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : BackButton(onPressed: widget.onBack),
        title: Text(l10n.groupKhatmahTitle),
        actions: [
          IconButton(
            tooltip: l10n.groupKhatmahRefresh,
            onPressed: widget.cubit.refresh,
            icon: const Icon(TaliaIcons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<GroupKhatmahCubit, GroupKhatmahState>(
        bloc: widget.cubit,
        builder: (_, state) => _body(state, l10n),
      ),
      bottomNavigationBar: _bottomActions(l10n),
    );
  }

  Widget _body(GroupKhatmahState state, AppLocalizations l10n) {
    if (state.validated) return _groups(state, l10n);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GroupKhatmahRecoveryPanel(cubit: widget.cubit, state: state),
            if (state.loading)
              const CircularProgressIndicator()
            else
              Text(
                localizedGroupKhatmahError(l10n, state.errorCode ?? 'network'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _groups(GroupKhatmahState state, AppLocalizations l10n) =>
      RefreshIndicator(
        onRefresh: widget.cubit.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            GroupKhatmahRecoveryPanel(cubit: widget.cubit, state: state),
            if (state.errorCode != null)
              Text(
                localizedGroupKhatmahError(l10n, state.errorCode!),
                key: const Key('group-khatmah-list-error'),
              ),
            if (state.isStale && state.groups.isNotEmpty)
              Text(l10n.groupKhatmahStale),
            if (state.groups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(child: Text(l10n.groupKhatmahEmpty)),
              ),
            for (final group in state.groups) _groupTile(group, l10n),
          ],
        ),
      );

  Widget _groupTile(GroupKhatmah group, AppLocalizations l10n) => Card(
    child: ListTile(
      title: Text(group.title),
      subtitle: Text(
        l10n.groupKhatmahCompletedCount(
          group.parts
              .where((part) => part.status == GroupPartStatus.completed)
              .length,
          group.parts.length,
        ),
      ),
      trailing: const Icon(TaliaIcons.chevronForward),
      onTap: () => _open(group),
    ),
  );

  Widget _bottomActions(AppLocalizations l10n) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            key: const Key('group-khatmah-create'),
            onPressed: () => _showSheet(true),
            icon: const Icon(TaliaIcons.add),
            label: Text(l10n.groupKhatmahCreate),
          ),
          OutlinedButton.icon(
            key: const Key('group-khatmah-join'),
            onPressed: () => _showSheet(false),
            icon: const Icon(TaliaIcons.family),
            label: Text(l10n.groupKhatmahJoin),
          ),
        ],
      ),
    ),
  );
}
