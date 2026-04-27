import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:shared_preferences/shared_preferences.dart';


class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._prefs) : super(const Locale('ar'));

  final SharedPreferences _prefs;
  static const _key = 'app_locale';

  static const supportedLocales = [
    Locale('ar'),
    Locale('en'),
  ];

  void loadLocale() {
    final saved = _prefs.getString(_key) ?? 'ar';
    emit(Locale(saved));
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_key, locale.languageCode);
    emit(locale);
  }

  Future<void> toggleLocale() async {
    final next = state.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    await setLocale(next);
  }

  bool get isArabic => state.languageCode == 'ar';
}
