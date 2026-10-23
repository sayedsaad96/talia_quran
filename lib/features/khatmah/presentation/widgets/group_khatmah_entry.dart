import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/sync/group_khatmah_environment.dart';
import '../../../group_khatmah/data/group_khatmah_remote.dart';

class GroupKhatmahEntry extends StatelessWidget {
  const GroupKhatmahEntry({
    super.key,
    this.environment,
    this.owner,
    this.onOpen,
  });
  final GroupKhatmahEnvironment? environment;
  final RecordOwnerProvider? owner;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final audience =
        environment ??
        (getIt.isRegistered<GroupKhatmahAppEnvironment>()
            ? getIt<GroupKhatmahAppEnvironment>()
            : null);
    final account =
        owner ??
        (getIt.isRegistered<RecordOwnerProvider>()
            ? getIt<RecordOwnerProvider>()
            : null);
    if (audience == null || account == null) return const SizedBox.shrink();
    return StreamBuilder<void>(
      stream: audience.changes,
      builder: (context, _) {
        if (groupKhatmahRedirect(audience, account) != null) {
          return const SizedBox.shrink();
        }
        return IconButton(
          key: const Key('group-khatmah-entry'),
          tooltip: AppLocalizations.of(context).groupKhatmahTitle,
          icon: const Icon(TaliaIcons.family),
          onPressed: onOpen ?? () => context.push(AppRoutes.groupKhatmah),
        );
      },
    );
  }
}
