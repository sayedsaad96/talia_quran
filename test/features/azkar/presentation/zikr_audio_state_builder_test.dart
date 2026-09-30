import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/presentation/services/zikr_audio_service.dart';
import 'package:talia_quran/features/azkar/presentation/widgets/zikr_audio_state_builder.dart';

class _FakeSource implements ZikrAudioStateSource {
  ZikrAudioState _state = const ZikrAudioState();
  final List<void Function(ZikrAudioState)> listeners = [];

  @override
  ZikrAudioState get state => _state;

  @override
  void addListener(void Function(ZikrAudioState) listener) =>
      listeners.add(listener);

  @override
  void removeListener(void Function(ZikrAudioState) listener) =>
      listeners.remove(listener);

  void emit(ZikrAudioState next) {
    _state = next;
    for (final listener in List.of(listeners)) {
      listener(next);
    }
  }
}

void main() {
  testWidgets('rebuilds when the audio state changes', (tester) async {
    final source = _FakeSource();
    await tester.pumpWidget(
      MaterialApp(
        home: ZikrAudioStateBuilder(
          source: source,
          builder: (context, state) => Text(state.status.name),
        ),
      ),
    );
    expect(find.text('idle'), findsOneWidget);

    source.emit(
      const ZikrAudioState(status: ZikrAudioStatus.playing, zikrId: 'z1'),
    );
    await tester.pump();

    expect(find.text('playing'), findsOneWidget);
  });

  testWidgets('stops listening when removed', (tester) async {
    final source = _FakeSource();
    await tester.pumpWidget(
      MaterialApp(
        home: ZikrAudioStateBuilder(
          source: source,
          builder: (context, state) => const SizedBox(),
        ),
      ),
    );
    expect(source.listeners, hasLength(1));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    expect(source.listeners, isEmpty);
  });
}
