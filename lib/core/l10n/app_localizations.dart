import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale, this._strings);

  final Locale locale;
  final Map<String, dynamic> _strings;

  static const supportedLocales = [Locale('en'), Locale('ar')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isRtl => locale.languageCode == 'ar';

  String t(String key, [Map<String, String>? params]) {
    dynamic current = _strings;
    for (final part in key.split('.')) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return key;
      }
    }
    var value = current?.toString() ?? key;
    params?.forEach((name, replacement) {
      value = value.replaceAll('{$name}', replacement);
    });
    return value;
  }

  String status(String? value) {
    if (value == null || value.isEmpty) {
      return '—';
    }
    final mapped = t('status.$value');
    return mapped == 'status.$value' ? value : mapped;
  }

  String truckType(String? value) {
    if (value == null || value.isEmpty) {
      return '—';
    }
    final mapped = t('truckType.$value');
    return mapped == 'truckType.$value' ? value : mapped;
  }

  String organizationStatus(String? value) {
    switch (value) {
      case 'pending':
        return t('status.org_pending');
      case 'active':
        return t('status.org_active');
      case 'suspended':
        return t('status.org_suspended');
      case 'rejected':
        return t('status.org_rejected');
      default:
        return status(value);
    }
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((item) => item.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final code = isSupported(locale) ? locale.languageCode : 'en';
    final raw = await rootBundle.loadString('assets/i18n/$code.json');
    return AppLocalizations(Locale(code), jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => true;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String key, [Map<String, String>? params]) => l10n.t(key, params);
}
