import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/datasources/share_good_local_store.dart';
import '../../domain/entities/invite_activity_target.dart';
import '../../domain/entities/invite_types.dart';
import '../../domain/entities/share_prompt_state.dart';
import '../../domain/repositories/share_good_repository.dart';
import '../../domain/services/invite_target_labeler.dart';
import '../../domain/services/inviter_identity_resolver.dart';

sealed class InviteCreateState extends Equatable {
  const InviteCreateState();
  @override
  List<Object?> get props => [];
}

class InviteCreateIdle extends InviteCreateState {
  const InviteCreateIdle();
}

class InviteCreateNeedsSignIn extends InviteCreateState {
  const InviteCreateNeedsSignIn();
}

class InviteCreateChoosingMode extends InviteCreateState {
  const InviteCreateChoosingMode(this.mode, this.identity, this.preference);
  final InviteMode? mode;
  final InviteIdentityMode identity, preference;
  @override
  List<Object?> get props => [mode, identity, preference];
}

class InviteCreateCreating extends InviteCreateState {
  const InviteCreateCreating();
}

class InviteCreateCreated extends InviteCreateState {
  const InviteCreateCreated(this.invite, this.data);
  final CreatedInvite invite;
  final SocialShareData data;
  @override
  List<Object?> get props => [invite, data];
}

class InviteCreateFailed extends InviteCreateState {
  const InviteCreateFailed(this.failure);
  final ShareGoodFailure failure;
  @override
  List<Object?> get props => [failure];
}

class InviteCreateParentExpired extends InviteCreateState {
  const InviteCreateParentExpired();
}

class InviteCreateCubit extends Cubit<InviteCreateState> {
  InviteCreateCubit({
    required this.target,
    required this.moment,
    required this.repository,
    required this.store,
    required this.labeler,
    required this.auth,
    required this.barrier,
    required this.isChild,
    required this.isAvailable,
    required this.arabic,
    required this.makeShareData,
  }) : super(const InviteCreateIdle());
  final InviteActivityTarget target;
  final InviteMoment moment;
  final ShareGoodRepository repository;
  final ShareGoodLocalStore store;
  final InviteTargetLabeler labeler;
  final AuthCubit auth;
  final AccountDataBarrier barrier;
  final Future<bool> Function() isChild;
  final bool Function() isAvailable;
  final bool arabic;
  final SocialShareData Function(CreatedInvite, InviteTargetLabel)
  makeShareData;
  String? _parentToken;
  bool _chainIntent = false;

  Future<void> startChain(String parentToken) async {
    _parentToken = parentToken;
    _chainIntent = true;
    await begin();
  }

  Future<void> startStandalone() async {
    _parentToken = null;
    await begin();
  }

  Future<void> begin() async {
    if (!isAvailable()) {
      emit(const InviteCreateFailed(ShareGoodFailure.featureUnavailable));
      return;
    }
    try {
      if (await isChild()) {
        if (!isClosed) {
          emit(const InviteCreateFailed(ShareGoodFailure.notEligible));
        }
        return;
      }
      if (isClosed) return;
      final current = auth.state;
      if (current is! AuthAuthenticated) {
        emit(const InviteCreateNeedsSignIn());
        return;
      }
      barrier.capture().checkOwner(current.user.id);
      final preference = store.personalIdentityPreference(current.user.id);
      if (!isClosed) {
        emit(InviteCreateChoosingMode(null, preference, preference));
      }
    } catch (_) {
      if (!isClosed) {
        emit(const InviteCreateFailed(ShareGoodFailure.featureUnavailable));
      }
    }
  }

  void chooseMode(InviteMode mode) {
    final current = state;
    if (current is! InviteCreateChoosingMode) return;
    emit(
      InviteCreateChoosingMode(
        mode,
        mode == InviteMode.public
            ? InviteIdentityMode.anonymous
            : current.preference,
        current.preference,
      ),
    );
  }

  void chooseIdentity(InviteIdentityMode identity) {
    final current = state;
    if (current is! InviteCreateChoosingMode || current.mode == null) return;
    emit(InviteCreateChoosingMode(current.mode, identity, current.preference));
  }

  Future<void> create() async {
    final choice = state;
    if (choice is! InviteCreateChoosingMode || choice.mode == null) return;
    final current = auth.state;
    if (current is! AuthAuthenticated) {
      emit(const InviteCreateNeedsSignIn());
      return;
    }
    emit(const InviteCreateCreating());
    try {
      final lease = barrier.capture()..checkOwner(current.user.id);
      final label = await _validatedLabel(current, lease);
      if (isClosed) return;
      if (label == null) {
        emit(const InviteCreateFailed(ShareGoodFailure.invalidInvite));
        return;
      }
      final identity = const InviterIdentityResolver().resolve(
        choice.identity,
        authDisplayName: current.user.displayName,
      );
      final context = InviteContext(
        target: target,
        moment: _chainIntent ? InviteMoment.afterActivity : moment,
        mode: choice.mode!,
        identity: identity,
      );
      final parent = _parentToken;
      final result = parent == null
          ? await repository.create(context)
          : await repository.continueChain(parent, context);
      lease.checkOwner(current.user.id);
      if (isClosed) return;
      await result.fold(
        (failure) async => emit(
          parent != null && failure == ShareGoodFailure.expired
              ? const InviteCreateParentExpired()
              : InviteCreateFailed(failure),
        ),
        (invite) =>
            _finishCreated(current.user.id, choice, lease, invite, label),
      );
    } catch (_) {
      if (!isClosed) {
        emit(const InviteCreateFailed(ShareGoodFailure.featureUnavailable));
      }
    }
  }

  Future<InviteTargetLabel?> _validatedLabel(
    AuthAuthenticated current,
    AccountDataLease lease,
  ) async {
    if (!isAvailable() || await isChild()) {
      throw const AccountDataUnavailableException();
    }
    final result = await labeler.label(target, arabic: arabic);
    if (isClosed) return null;
    lease.checkOwner(current.user.id);
    final latest = auth.state;
    if (latest is! AuthAuthenticated ||
        latest.user.id != current.user.id ||
        latest.user.displayName != current.user.displayName) {
      throw const AccountDataUnavailableException();
    }
    return result.fold((_) => null, (value) => value);
  }

  Future<void> _finishCreated(
    String owner,
    InviteCreateChoosingMode choice,
    AccountDataLease lease,
    CreatedInvite invite,
    InviteTargetLabel label,
  ) async {
    await _recordCreated(owner, lease);
    lease.checkOwner(owner);
    if (choice.mode == InviteMode.personal) {
      await _savePreference(owner, choice.identity, lease);
      lease.checkOwner(owner);
    }
    if (!isClosed) {
      emit(InviteCreateCreated(invite, makeShareData(invite, label)));
    }
  }

  Future<void> _recordCreated(String owner, AccountDataLease lease) async {
    try {
      await barrier.run(
        (active) => store.updatePromptState(owner, (old) {
          active.checkOwner(owner);
          lease.checkOwner(owner);
          return SharePromptState(
            lastShownAt: old.lastShownAt,
            shownCount: old.shownCount,
            dismissCount: old.dismissCount,
            invitesCreated: old.invitesCreated + 1,
            educationSeen: old.educationSeen,
          );
        }),
        authority: lease,
      );
    } catch (_) {
      // A local hint counter must not discard a created invite link.
    }
  }

  Future<void> _savePreference(
    String owner,
    InviteIdentityMode identity,
    AccountDataLease lease,
  ) async {
    try {
      await barrier.run((active) {
        active.checkOwner(owner);
        return store.setPersonalIdentityPreference(owner, identity);
      }, authority: lease);
    } catch (_) {
      // The created link is only returned once; keep it if this write fails.
    }
  }
}
