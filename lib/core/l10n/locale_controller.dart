import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'mz_provider_locale';

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    Future.microtask(_restore);
    return const Locale('en');
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> toggle() {
    return setLocale(state.languageCode == 'ar' ? const Locale('en') : const Locale('ar'));
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);
