import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/child_encouragement_inbox_cubit.dart';
import 'child_encouragement_card.dart';

/// One message at a time. Reading alone never acknowledges the server row.
class ChildEncouragementInbox extends StatefulWidget {
  const ChildEncouragementInbox({super.key});

  @override
  State<ChildEncouragementInbox> createState() =>
      _ChildEncouragementInboxState();
}

class _ChildEncouragementInboxState extends State<ChildEncouragementInbox>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final cubit = context.read<ChildEncouragementInboxCubit>();
    unawaited(cubit.retryAcknowledgements());
    if (mounted && !cubit.isClosed) await cubit.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ChildEncouragementInboxCubit, ChildEncouragementInboxState>(
        builder: (context, state) {
          if (state.pending.isEmpty) return const SizedBox.shrink();
          final message = state.pending.first;
          return TweenAnimationBuilder<double>(
            key: ValueKey(message.id),
            tween: Tween(begin: 0, end: 1),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
            builder: (_, opacity, child) =>
                Opacity(opacity: opacity, child: child),
            child: ChildEncouragementCard(
              encouragement: message,
              onDone: () => context
                  .read<ChildEncouragementInboxCubit>()
                  .dismiss(message.id),
            ),
          );
        },
      );
}
