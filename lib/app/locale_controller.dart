import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the app locale (ar/en). Persisted in SharedPreferences (not
/// sensitive). RTL is derived automatically by Flutter from the locale, so
/// switching to Arabic flips the whole layout to right-to-left (spec §36).
class LocaleController extends Notifier<Locale?> {
  static const _key = 'wesal_locale';

  @override
  Locale? build() {
    _load();
    return null; // null = follow system until a stored choice loads
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) state = Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);
