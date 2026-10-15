import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../cubits/app_update_cubit.dart';
import '../cubits/app_update_state.dart';

/// Displays the final install choice after Google Play has downloaded an update.
class AppUpdatePromptListener extends StatelessWidget {
  const AppUpdatePromptListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppUpdateCubit, AppUpdateState>(
      listenWhen: (previous, current) =>
          current.status == AppUpdateUiStatus.installReady ||
          current.status == AppUpdateUiStatus.completionFailed,
      listener: (context, state) {
        final l10n = AppLocalizations.of(context);
        final failed = state.status == AppUpdateUiStatus.completionFailed;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    failed ? l10n.appUpdateInstallFailed : l10n.appUpdateReady,
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: SnackBarAction(
                      label: l10n.appUpdateInstallAction,
                      onPressed: context
                          .read<AppUpdateCubit>()
                          .completeDownloadedUpdate,
                    ),
                  ),
                ],
              ),
              duration: const Duration(days: 1),
              showCloseIcon: true,
            ),
          );
      },
      child: child,
    );
  }
}
