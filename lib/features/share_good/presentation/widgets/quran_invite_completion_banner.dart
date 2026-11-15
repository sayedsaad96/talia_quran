import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../application/active_invite_sessions.dart';
import '../../domain/entities/invite_types.dart';
import '../../domain/repositories/share_good_repository.dart';
import '../../domain/services/invite_target_labeler.dart';

/// Observes a successful reader confirmation; it never records reading itself.
class QuranInviteCompletionBanner extends StatefulWidget {
  const QuranInviteCompletionBanner({
    super.key,
    required this.localSessionId,
    required this.pageNumber,
    required this.confirmed,
    required this.enabled,
    required this.sessions,
    required this.labeler,
    required this.repository,
    this.onCompleted,
  });

  final String localSessionId;
  final int pageNumber;
  final bool confirmed;
  final bool enabled;
  final ActiveInviteSessions sessions;
  final InviteTargetLabeler labeler;
  final ShareGoodRepository repository;
  final ValueChanged<InviteSession>? onCompleted;

  @override
  State<QuranInviteCompletionBanner> createState() =>
      _QuranInviteCompletionBannerState();
}

class _QuranInviteCompletionBannerState
    extends State<QuranInviteCompletionBanner> {
  InviteSession? _session;
  InviteTargetLabel? _label;
  bool _loading = true,
      _submitting = false,
      _expired = false,
      _failed = false,
      _completed = false;
  int _generation = 0;
  bool? _arabic;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    if (_arabic != arabic) {
      _arabic = arabic;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant QuranInviteCompletionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localSessionId != widget.localSessionId ||
        oldWidget.sessions != widget.sessions ||
        oldWidget.labeler != widget.labeler) {
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _loading = true;
    _session = widget.sessions.forLocalSessionId(widget.localSessionId);
    _label = null;
    _expired = false;
    _failed = false;
    _completed = false;
    _submitting = false;
    final session = _session;
    if (session == null) {
      _loading = false;
      return;
    }
    try {
      final result = await widget.labeler.label(
        session.snapshot.target,
        arabic: _arabic ?? false,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _label = result.fold((_) => null, (value) => value);
        _loading = false;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _complete() async {
    final session = _session;
    final label = _label;
    if (_submitting ||
        _completed ||
        _expired ||
        !widget.enabled ||
        session == null ||
        label == null ||
        !widget.confirmed ||
        widget.pageNumber != label.endPage) {
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
        (failure) {
          setState(() {
            _expired = failure == ShareGoodFailure.expired;
            _failed = !_expired;
          });
        },
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
    final label = _label;
    if (!widget.enabled ||
        _loading ||
        _completed ||
        label == null ||
        widget.pageNumber < label.startPage ||
        widget.pageNumber > label.endPage) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _expired
                    ? l10n.inviteExpiredBody
                    : _failed
                    ? l10n.inviteCompletionError
                    : l10n.inviteActivityLabel(label.title),
              ),
            ),
            if (!_expired)
              TextButton(
                onPressed:
                    !_submitting &&
                        widget.confirmed &&
                        widget.pageNumber == label.endPage
                    ? _complete
                    : null,
                child: Text(l10n.inviteCompleteReading),
              ),
          ],
        ),
      ),
    );
  }
}
