import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/datasources/share_good_local_store.dart';
import '../../domain/entities/invite_activity_target.dart';
import '../../domain/entities/share_prompt_state.dart';
import '../../share_good_config.dart';
import '../cubits/share_prompt_cubit.dart';
import 'invite_mode_sheet.dart';
import '../../domain/entities/invite_types.dart';

class ShareGoodPromptHint extends StatefulWidget {
  const ShareGoodPromptHint({super.key, required this.target});
  final InviteActivityTarget target;
  @override
  State<ShareGoodPromptHint> createState() => _ShareGoodPromptHintState();
}

class _ShareGoodPromptHintState extends State<ShareGoodPromptHint> {
  SharePromptCubit? _cubit;
  StreamSubscription<AuthState>? _authChanges;
  StreamSubscription<void>? _audienceChanges;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    if (!getIt.isRegistered<ShareGoodAvailability>() ||
        !getIt<ShareGoodAvailability>().isAvailable) {
      return;
    }
    _authChanges = getIt<AuthCubit>().stream.listen((_) => _hide());
    _audienceChanges = getIt<MemorizationPathResolver>().changes.listen(
      (_) => _hide(),
    );
    unawaited(_prepare());
  }

  void _hide() {
    _generation++;
    final cubit = _cubit;
    if (mounted) setState(() => _cubit = null);
    unawaited(cubit?.close());
  }

  Future<void> _prepare() async {
    final generation = _generation;
    try {
      final auth = getIt<AuthCubit>();
      final current = auth.state;
      if (current is! AuthAuthenticated) return;
      final lease = AccountDataBarrier.forPreferences(
        getIt<SharedPreferences>(),
      ).capture();
      final profile = await getIt<MemorizationPathResolver>().currentProfile();
      lease.checkOwner(current.user.id);
      if (!mounted ||
          generation != _generation ||
          profile?.isAdult != true ||
          auth.state != current) {
        return;
      }
      final cubit = SharePromptCubit(
        store: getIt<ShareGoodLocalStore>(),
        owner: current.user.id,
        barrier: AccountDataBarrier.forPreferences(getIt<SharedPreferences>()),
      );
      setState(() => _cubit = cubit);
      await cubit.showIfEligible(DateTime.now());
    } catch (_) {
      // Eligibility failure hides optional education.
    }
  }

  @override
  void dispose() {
    unawaited(_authChanges?.cancel());
    unawaited(_audienceChanges?.cancel());
    unawaited(_cubit?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<SharePromptCubit, SharePromptState?>(
      bloc: cubit,
      builder: (context, state) {
        if (state == null || !getIt<ShareGoodAvailability>().isAvailable) {
          return const SizedBox.shrink();
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputChip(
              label: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * .6,
                ),
                child: Text(
                  context.l10n.shareGoodPromptHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              onPressed: () => InviteModeSheet.show(
                context,
                widget.target,
                InviteMoment.afterActivity,
              ),
              onDeleted: () => unawaited(cubit.dismiss()),
            ),
            if (cubit.showEducation) Text(context.l10n.shareGoodEducation),
          ],
        );
      },
    );
  }
}
