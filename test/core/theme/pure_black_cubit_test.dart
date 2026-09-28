import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/theme/pure_black_cubit.dart';

void main() {
  test('defaults to off and persists the choice', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final cubit = PureBlackCubit(prefs)..load();
    expect(cubit.state, isFalse);

    await cubit.setEnabled(true);
    expect(cubit.state, isTrue);
    await cubit.close();

    final reloaded = PureBlackCubit(prefs)..load();
    expect(reloaded.state, isTrue);
    await reloaded.close();
  });
}
