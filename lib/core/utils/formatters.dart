import 'package:intl/intl.dart';

import '../config/app_config.dart';

class Formatters {
  const Formatters._();

  static String money(num? value, {String? currency, String? locale}) {
    final amount = value ?? 0;
    final format = NumberFormat.currency(
      locale: locale ?? 'en',
      symbol: '${currency ?? AppConfig.defaultCurrency} ',
      decimalDigits: 3,
    );
    return format.format(amount);
  }

  static String number(num? value, {String? locale, int decimals = 2}) {
    final format = NumberFormat.decimalPatternDigits(
      locale: locale ?? 'en',
      decimalDigits: decimals,
    );
    return format.format(value ?? 0);
  }

  static String date(String? raw, {String? locale}) {
    if (raw == null || raw.isEmpty) {
      return '—';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat.yMMMd(locale ?? 'en').format(parsed.toLocal());
  }

  static String dateTime(String? raw, {String? locale}) {
    if (raw == null || raw.isEmpty) {
      return '—';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat.yMMMd(locale ?? 'en').add_Hm().format(parsed.toLocal());
  }

  static String percent(num? value) {
    return '${(value ?? 0).round()}%';
  }
}
