import 'package:flutter/widgets.dart';

import '../services/zikr_audio_service.dart';

/// Rebuilds [builder] whenever the audio state changes, and stops listening
/// when it leaves the tree.
class ZikrAudioStateBuilder extends StatefulWidget {
  const ZikrAudioStateBuilder({
    super.key,
    required this.source,
    required this.builder,
  });

  final ZikrAudioStateSource source;
  final Widget Function(BuildContext context, ZikrAudioState state) builder;

  @override
  State<ZikrAudioStateBuilder> createState() => _ZikrAudioStateBuilderState();
}

class _ZikrAudioStateBuilderState extends State<ZikrAudioStateBuilder> {
  @override
  void initState() {
    super.initState();
    widget.source.addListener(_onState);
  }

  @override
  void didUpdateWidget(ZikrAudioStateBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      oldWidget.source.removeListener(_onState);
      widget.source.addListener(_onState);
    }
  }

  @override
  void dispose() {
    widget.source.removeListener(_onState);
    super.dispose();
  }

  void _onState(ZikrAudioState _) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.source.state);
}
