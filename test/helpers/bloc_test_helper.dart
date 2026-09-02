import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void blocTest<B extends BlocBase<State>, State>(
  String description, {
  required B Function() build,
  FutureOr<void> Function(B bloc)? act,
  Duration? wait,
  dynamic Function()? expect,
  void Function(B bloc)? verify,
}) {
  test(description, () async {
    final bloc = build();
    addTearDown(bloc.close);
    final states = <State>[];
    final subscription = bloc.stream.listen(states.add);

    try {
      if (act != null) {
        await act(bloc);
      }
      if (wait != null) {
        await Future<void>.delayed(wait);
      } else {
        await Future<void>.delayed(Duration.zero);
      }

      if (expect != null) {
        final dynamic expected = expect();
        if (expected is List) {
          expectLater(states, expected);
        } else if (expected is Matcher) {
          expectLater(states, expected);
        }
      }

      if (verify != null) {
        verify(bloc);
      }
    } finally {
      await subscription.cancel();
    }
  });
}
