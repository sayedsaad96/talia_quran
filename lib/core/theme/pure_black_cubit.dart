import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether dark mode uses the pure-black OLED palette ([AppTheme.oled])
/// instead of the default deep-green dark theme.
///
/// Independent of [ThemeCubit]: it only changes *which* dark theme is used,
/// so it has no effect while the app is in light mode.
class PureBlackCubit extends Cubit<bool> {
  PureBlackCubit(this._prefs) : super(false);

  final SharedPreferences _prefs;
  static const _key = 'theme_pure_black';

  void load() => emit(_prefs.getBool(_key) ?? false);

  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(_key, enabled);
    emit(enabled);
  }
}
