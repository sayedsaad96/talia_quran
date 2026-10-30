import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';
import '../cubits/kids_journey_switch_cubit.dart';
import 'guardian_pin_dialog.dart';
import 'kids_journey_path_selector.dart';

Future<bool> showKidsJourneySwitchDialog(BuildContext context) async {
  final cubit = KidsJourneySwitchCubit(
    getIt<MemorizationPlusRepository>(),
    getIt<ParentAccessUsecase>(),
    getIt<RecordOwnerProvider>(),
    AccountDataBarrier.forPreferences(getIt<SharedPreferences>()),
  );
  unawaited(cubit.load());
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _JourneyDialog()),
  );
  await cubit.close();
  return result == true;
}

class _JourneyDialog extends StatelessWidget {
  const _JourneyDialog();

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<KidsJourneySwitchCubit, JourneySwitchState>(
        listener: (context, state) {
          if (state.status == JourneySwitchStatus.success) {
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          final cubit = context.read<KidsJourneySwitchCubit>();
          final busy = state.status == JourneySwitchStatus.saving;
          return PopScope(
            canPop: !busy,
            child: AlertDialog(
              title: Text(context.l10n.kidsChangeJourneyTitle),
              content: SingleChildScrollView(
                child: _content(context, state, cubit),
              ),
              actions: _actions(context, state, cubit),
            ),
          );
        },
      );

  Widget _content(
    BuildContext context,
    JourneySwitchState state,
    KidsJourneySwitchCubit cubit,
  ) {
    switch (state.status) {
      case JourneySwitchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case JourneySwitchStatus.error:
      case JourneySwitchStatus.stale:
        return Text(context.l10n.errorCacheMessage);
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.kidsChangeJourneyDescription),
            KidsJourneyPathSelector(
              value: state.selected!,
              onChanged: state.status == JourneySwitchStatus.saving
                  ? (_) {}
                  : cubit.select,
            ),
          ],
        );
    }
  }

  List<Widget> _actions(
    BuildContext context,
    JourneySwitchState state,
    KidsJourneySwitchCubit cubit,
  ) {
    final busy = state.status == JourneySwitchStatus.saving;
    return [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context, false),
        child: Text(context.l10n.cancel),
      ),
      if (state.status == JourneySwitchStatus.error)
        TextButton(onPressed: cubit.load, child: Text(context.l10n.retryLabel)),
      if (state.status == JourneySwitchStatus.ready || busy)
        FilledButton(
          onPressed: state.canSave
              ? () => cubit.save(
                  (linked) async => (await optionalGuardianPin(
                    context,
                    allowCreate: !linked,
                    allowRecovery: linked,
                    isScopeValid: () => cubit.isScopeValid,
                    canCreatePin: cubit.canCreateGuardianPin,
                    confirmLabel: context.l10n.confirm,
                  )).proceeds,
                )
              : null,
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.save),
        ),
    ];
  }
}
