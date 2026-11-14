import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../../data/datasources/share_good_local_store.dart';
import '../../domain/entities/share_prompt_state.dart';
import '../../domain/services/share_prompt_policy.dart';

/// A hint is persisted before it becomes visible, including its cooldown.
class SharePromptCubit extends Cubit<SharePromptState?> {
  SharePromptCubit({
    required this.store,
    required this.owner,
    required this.barrier,
  }) : super(null);
  final ShareGoodLocalStore store;
  final String owner;
  final AccountDataBarrier barrier;
  bool _requested = false;
  bool showEducation = false;

  Future<void> showIfEligible(DateTime now) async {
    if (_requested) return;
    _requested = true;
    try {
      final lease = barrier.capture();
      var eligible = false;
      final previous = await barrier.run(
        (active) => store.updatePromptState(owner, (old) {
          active.checkOwner(owner);
          lease.checkOwner(owner);
          if (!const SharePromptPolicy().shouldPrompt(old, now)) return old;
          eligible = true;
          showEducation = !old.educationSeen;
          return SharePromptState(
            lastShownAt: now,
            shownCount: old.shownCount + 1,
            dismissCount: old.dismissCount,
            invitesCreated: old.invitesCreated,
            educationSeen: true,
          );
        }),
        authority: lease,
      );
      lease.checkOwner(owner);
      if (!isClosed && eligible) emit(previous);
    } catch (_) {
      // A hint must never interrupt the completion screen.
    }
  }

  Future<void> dismiss() async {
    emit(null);
    try {
      final lease = barrier.capture();
      await barrier.run(
        (active) => store.updatePromptState(owner, (old) {
          active.checkOwner(owner);
          lease.checkOwner(owner);
          return SharePromptState(
            lastShownAt: old.lastShownAt,
            shownCount: old.shownCount,
            dismissCount: old.dismissCount + 1,
            invitesCreated: old.invitesCreated,
            educationSeen: old.educationSeen,
          );
        }),
        authority: lease,
      );
    } catch (_) {
      // Storage failure keeps the existing persisted cooldown.
    }
  }
}
