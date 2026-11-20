import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../azkar/domain/entities/azkar_entities.dart';
import '../../application/active_invite_sessions.dart';
import '../../domain/entities/invite_activity_target.dart';
import '../../domain/entities/invite_types.dart';
import '../../domain/repositories/share_good_repository.dart';

/// Observes completion only for the explicitly launched invitation.
class AzkarInviteCompletion extends StatefulWidget {
  const AzkarInviteCompletion({
    super.key,
    required this.localSessionId,
    required this.category,
    required this.allDone,
    required this.enabled,
    required this.sessions,
    required this.repository,
    this.onCompleted,
  });
  final String localSessionId;
  final AzkarCategory category;
  final bool? allDone;
  final bool enabled;
  final ActiveInviteSessions sessions;
  final ShareGoodRepository repository;
  final ValueChanged<InviteSession>? onCompleted;

  @override
  State<AzkarInviteCompletion> createState() => _AzkarInviteCompletionState();
}

class _AzkarInviteCompletionState extends State<AzkarInviteCompletion> {
  bool? _lastDone;
  bool _confirm = false,
      _submitting = false,
      _completed = false,
      _failed = false,
      _expired = false;
  int _generation = 0;

  InviteSession? get _session {
    if (!widget.enabled ||
        (widget.category != AzkarCategory.morning &&
            widget.category != AzkarCategory.evening)) {
      return null;
    }
    final session = widget.sessions.forLocalSessionId(widget.localSessionId);
    if (session == null ||
        session.snapshot.target !=
            AzkarCollectionInviteTarget(widget.category) ||
        !session.snapshot.expiresAt.isAfter(DateTime.now())) {
      return null;
    }
    return session;
  }

  @override
  void initState() {
    super.initState();
    _observe();
  }

  @override
  void didUpdateWidget(covariant AzkarInviteCompletion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localSessionId != widget.localSessionId ||
        oldWidget.category != widget.category ||
        oldWidget.sessions != widget.sessions) {
      _generation++;
      _lastDone = null;
      _confirm = _submitting = _completed = _failed = _expired = false;
    }
    _observe();
  }

  void _observe() {
    final done = widget.allDone;
    if (done == null || _session == null) return;
    final previous = _lastDone;
    _lastDone = done;
    if (previous == null && done) {
      _confirm = true;
    } else if (previous == false && done && !_completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_complete());
      });
    } else if (!done) {
      _confirm = false;
    }
  }

  Future<void> _complete() async {
    final session = _session;
    if (session == null ||
        widget.allDone != true ||
        _submitting ||
        _completed ||
        _expired) {
      return;
    }
    final generation = _generation;
    setState(() {
      _submitting = true;
      _failed = false;
    });
    try {
      final result = await widget.repository.advance(
        session.token,
        InviteParticipationStatus.completedPrivate,
      );
      if (!mounted || generation != _generation) return;
      result.fold(
        (failure) => setState(() {
          _expired = failure == ShareGoodFailure.expired;
          _failed = !_expired;
        }),
        (completed) {
          final threshold = InviteParticipationStatus.completedPrivate.index;
          if ((completed.serverStatus?.index ?? -1) < threshold &&
              (completed.pendingStatus?.index ?? -1) < threshold) {
            setState(() => _failed = true);
            return;
          }
          widget.sessions.clear(session.token);
          setState(() => _completed = true);
          widget.onCompleted?.call(completed);
        },
      );
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _failed = true);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null ||
        _completed ||
        widget.allDone != true ||
        (!_confirm && !_failed && !_expired)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_confirm) Text(l10n.inviteAzkarAlreadyDone),
            if (_expired)
              Text(l10n.inviteExpiredBody)
            else ...[
              if (_failed) Text(l10n.inviteCompletionError),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _submitting ? null : _complete,
                  child: Text(l10n.inviteConfirmAzkarCompletion),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
