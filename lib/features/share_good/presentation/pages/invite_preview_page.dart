import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../cubits/invite_preview_cubit.dart';

class InvitePreviewPage extends StatefulWidget {
  const InvitePreviewPage({super.key, required this.token});
  final String token;

  @override
  State<InvitePreviewPage> createState() => _InvitePreviewPageState();
}

class _InvitePreviewPageState extends State<InvitePreviewPage> {
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    context.read<InvitePreviewCubit>().load(widget.token);
  }

  @override
  void didUpdateWidget(covariant InvitePreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      context.read<InvitePreviewCubit>().load(widget.token);
    }
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    final token = widget.token;
    final route = await context.read<InvitePreviewCubit>().startActivity();
    if (!mounted) return;
    setState(() => _starting = false);
    if (route != null && token == widget.token) context.go(route);
  }

  String _duration(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    final minutes = remaining.inMinutes.clamp(0, 1 << 30);
    if (minutes >= 1440) {
      return context.l10n.inviteDurationDays(minutes ~/ 1440);
    }
    if (minutes >= 60) return context.l10n.inviteDurationHours(minutes ~/ 60);
    return context.l10n.inviteDurationMinutes(minutes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: BlocBuilder<InvitePreviewCubit, InvitePreviewState>(
                builder: _buildPreview,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, InvitePreviewState state) {
    final l10n = context.l10n;
    return switch (state) {
      InvitePreviewLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      InvitePreviewReady() => _buildReady(context, state),
      InvitePreviewExpired() => _PreviewContent(
        title: l10n.inviteExpiredTitle,
        detail: [
          state.label?.title,
          l10n.inviteExpiredBody,
        ].whereType<String>().join('\n\n'),
        action: l10n.inviteStartFresh,
        onAction: () =>
            context.go(context.read<InvitePreviewCubit>().startFresh()),
      ),
      InvitePreviewOffline() => _PreviewContent(
        title: l10n.inviteOfflineRetry,
        action: l10n.tryAgain,
        onAction: () => context.read<InvitePreviewCubit>().load(widget.token),
      ),
      _ => _PreviewContent(
        title: switch (state) {
          InvitePreviewKidsBlocked() => l10n.inviteKidsBlocked,
          InvitePreviewUnavailable() => l10n.inviteUnavailable,
          _ => l10n.inviteInvalid,
        },
        action: l10n.home,
        onAction: () => context.go('/'),
      ),
    };
  }

  Widget _buildReady(BuildContext context, InvitePreviewReady state) {
    final l10n = context.l10n;
    final snapshot = state.session.snapshot;
    final name = snapshot.inviter.visibleName;
    return _PreviewContent(
      title: name == null || name.trim().isEmpty
          ? l10n.inviteFromAnonymous
          : l10n.inviteFromNamed(name),
      detail: [
        state.label.title,
        l10n.inviteExpiresIn(_duration(snapshot.expiresAt)),
      ].join('\n'),
      action: l10n.inviteStartNow,
      onAction: _starting ? null : _start,
    );
  }
}

class _PreviewContent extends StatelessWidget {
  const _PreviewContent({
    required this.title,
    required this.action,
    this.detail,
    this.onAction,
  });
  final String title, action;
  final String? detail;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.menu_book_rounded,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        if (detail != null) ...[
          const SizedBox(height: 16),
          Text(
            detail!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: 32),
        FilledButton(onPressed: onAction, child: Text(action)),
      ],
    );
  }
}
