import 'package:intl/intl.dart';

import '../config/app_config.dart';

class Formatters {
  const Formatters._();

  /// Amounts and quantities always use Western digits, even in Arabic.
  static const numberLocale = 'en';

  static String money(num? value, {String? currency, String? locale}) {
    final amount = value ?? 0;
    final format = NumberFormat.currency(
      locale: _englishNumberLocale(locale),
      symbol: '${currency ?? AppConfig.defaultCurrency} ',
      decimalDigits: 3,
    );
    return latinDigits(format.format(amount));
  }

  static String number(num? value, {String? locale, int decimals = 2}) {
    final format = NumberFormat.decimalPatternDigits(
      locale: _englishNumberLocale(locale),
      decimalDigits: decimals,
    );
    return latinDigits(format.format(value ?? 0));
  }

  static String _englishNumberLocale(String? locale) {
    if (locale != null && locale.startsWith('en')) {
      return locale;
    }
    return numberLocale;
  }

  static String date(String? raw, {String? locale}) {
    if (raw == null || raw.isEmpty) {
      return '—';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return latinDigits(
      DateFormat.yMMMd(locale ?? 'en').format(parsed.toLocal()),
    );
  }

  static String dateTime(String? raw, {String? locale}) {
    if (raw == null || raw.isEmpty) {
      return '—';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return latinDigits(
      DateFormat.yMMMd(locale ?? 'en').add_Hm().format(parsed.toLocal()),
    );
  }

  static String percent(num? value) {
    return '${(value ?? 0).round()}%';
  }
}

/// Keeps Arabic month names while forcing 0-9 digits.
String latinDigits(String value) {
  const easternArabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final easternIndex = easternArabic.indexOf(char);
    if (easternIndex >= 0) {
      buffer.write(easternIndex);
      continue;
    }
    final persianIndex = persian.indexOf(char);
    if (persianIndex >= 0) {
      buffer.write(persianIndex);
      continue;
    }
    buffer.write(char);
  }
  return buffer.toString();
}
